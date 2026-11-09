-- ============================================================================
-- 08_locks_isolation.sql — Locks, Isolation Levels, Deadlocks
-- ============================================================================
-- SKILL LEVEL : Advanced
-- TOPICS      : Shared (read) locks, exclusive (write) locks, SELECT FOR
--               UPDATE, SELECT FOR SHARE, LOCK IN SHARE MODE, NOWAIT,
--               SKIP LOCKED, deadlock detection, optimistic vs pessimistic.
-- ----------------------------------------------------------------------------
-- TEXTBOOK DEPTH
--   Locks are how MySQL preserves ISOLATION when multiple transactions
--   touch the same data. InnoDB uses row-level locking (not table locks),
--   which is why it scales better than MyISAM for concurrent workloads.
--
--   Lock types:
--     * Shared lock (S)    — multiple readers can hold it simultaneously.
--                            Acquired by SELECT ... LOCK IN SHARE MODE / FOR SHARE.
--     * Exclusive lock (X) — only one writer at a time; blocks S and X.
--                            Acquired by SELECT ... FOR UPDATE, INSERT, UPDATE, DELETE.
--     * Intention locks   — table-level markers that a transaction intends
--                            to lock rows. IS (intention shared) / IX
--                            (intention exclusive). Acquired implicitly.
--     * Gap locks         — lock the GAP between index entries to prevent
--                            phantom inserts (REPEATABLE READ).
--     * Next-key locks    — record lock + gap lock before it.
--
--   Isolation-level anomalies prevented by locking:
--     Dirty read         → READ COMMITTED and above prevent (write X lock
--                          held until commit).
--     Non-repeatable read→ REPEATABLE READ prevents (read view established
--                          at first read in transaction).
--     Phantom            → REPEATABLE READ in InnoDB prevents (gap locks).
--
--   Deadlocks:
--     T1 holds lock on row A, waits for row B.
--     T2 holds lock on row B, waits for row A.
--     MySQL detects the deadlock and rolls back ONE transaction (the one
--     with smaller undo log). The other continues.
--
--   Mitigation:
--     * Acquire locks in a CONSISTENT ORDER across transactions.
--     * Keep transactions short.
--     * Use indexes for filtering — without an index, InnoDB may escalate
--       to a table lock.
-- ============================================================================

USE ecom;

-- ----------------------------------------------------------------------------
-- 1. SELECT ... FOR UPDATE — acquire an X lock on matching rows
-- ----------------------------------------------------------------------------
-- Use when you READ a row and intend to UPDATE it in the same transaction.
-- Prevents another transaction from modifying the row between your read
-- and write.

START TRANSACTION;
SELECT id, name, stock_qty FROM products WHERE id = 1 FOR UPDATE;
-- Now another transaction cannot UPDATE or SELECT FOR UPDATE this row
-- until we COMMIT/ROLLBACK.
UPDATE products SET stock_qty = stock_qty - 1 WHERE id = 1;
COMMIT;

-- ----------------------------------------------------------------------------
-- 2. SELECT ... FOR SHARE — acquire an S lock
-- ----------------------------------------------------------------------------
-- Use when you READ a row and need it to stay stable (no one modifies it)
-- but you don't intend to modify it yourself.
START TRANSACTION;
SELECT id, name, price FROM products WHERE id = 1 FOR SHARE;
-- Other transactions can also FOR SHARE this row, but cannot FOR UPDATE it.
COMMIT;

-- ----------------------------------------------------------------------------
-- 3. NOWAIT — fail immediately if the row is locked
-- ----------------------------------------------------------------------------
-- Default behavior is to WAIT until the lock is released. NOWAIT makes
-- the SELECT fail with error 3572 immediately.
START TRANSACTION;
-- SELECT id FROM products WHERE id = 1 FOR UPDATE NOWAIT;
COMMIT;

-- ----------------------------------------------------------------------------
-- 4. SKIP LOCKED — skip rows that are locked by another transaction
-- ----------------------------------------------------------------------------
-- Useful for queue-style tables: pull the next available row without
-- waiting on rows already being processed.
START TRANSACTION;
-- SELECT id FROM orders WHERE status = 'pending' ORDER BY id LIMIT 1 FOR UPDATE SKIP LOCKED;
COMMIT;

-- ----------------------------------------------------------------------------
-- 5. Demonstrate a deadlock (run in two concurrent sessions)
-- ----------------------------------------------------------------------------
-- Session 1:
--   START TRANSACTION;
--   UPDATE products SET stock_qty = stock_qty WHERE id = 1;   -- locks row 1
--   -- wait
--   UPDATE products SET stock_qty = stock_qty WHERE id = 2;   -- waits for row 2
--   COMMIT;
--
-- Session 2 (concurrent):
--   START TRANSACTION;
--   UPDATE products SET stock_qty = stock_qty WHERE id = 2;   -- locks row 2
--   -- wait
--   UPDATE products SET stock_qty = stock_qty WHERE id = 1;   -- waits for row 1
--   COMMIT;
--
-- Result: deadlock. One transaction is rolled back with error 1213.

-- ----------------------------------------------------------------------------
-- 6. Inspect current locks
-- ----------------------------------------------------------------------------
SELECT * FROM performance_schema.data_locks;
SELECT * FROM performance_schema.data_lock_waits;

-- ----------------------------------------------------------------------------
-- 7. Optimistic vs pessimistic locking
-- ----------------------------------------------------------------------------
-- PESSIMISTIC: assume conflict will happen; lock rows proactively.
--   BEGIN;
--   SELECT * FROM accounts WHERE id = 1 FOR UPDATE;
--   ... compute ...
--   UPDATE accounts SET balance = balance - 100 WHERE id = 1;
--   COMMIT;

-- OPTIMISTIC: assume conflict is rare; check at commit time using a
-- version column.
--   SELECT id, balance, version FROM accounts WHERE id = 1;
--   ... compute new_balance in app ...
--   UPDATE accounts SET balance = new_balance, version = version + 1
--   WHERE id = 1 AND version = <version seen at read>;
--   -- If affected_rows = 0, someone else modified it → retry.

-- Demonstrate optimistic locking on a temp table:
DROP TABLE IF EXISTS tmp_optimistic;
CREATE TABLE tmp_optimistic (
    id INT PRIMARY KEY,
    name VARCHAR(50),
    version INT NOT NULL DEFAULT 0
);
INSERT INTO tmp_optimistic (id, name) VALUES (1, 'Original');

-- App reads:
SELECT name, version FROM tmp_optimistic WHERE id = 1;   -- name='Original', version=0

-- App attempts to update with the version it saw:
UPDATE tmp_optimistic
SET name = 'Updated', version = version + 1
WHERE id = 1 AND version = 0;
-- affected_rows = 1 — success.

-- If another concurrent app tried to update with version=0 after the
-- first update, it would get affected_rows = 0:
UPDATE tmp_optimistic
SET name = 'Conflict', version = version + 1
WHERE id = 1 AND version = 0;
-- affected_rows = 0 → conflict detected, retry.

SELECT * FROM tmp_optimistic;

DROP TABLE tmp_optimistic;

-- ----------------------------------------------------------------------------
-- 8. LOCK TABLES — explicit table locks (rarely needed with InnoDB)
-- ----------------------------------------------------------------------------
-- InnoDB's row-level locking makes LOCK TABLES mostly unnecessary.
-- Use it for bulk administrative operations like LOAD DATA.
-- LOCK TABLES products WRITE;
-- ... exclusive access ...
-- UNLOCK TABLES;

-- ----------------------------------------------------------------------------
-- 9. EXERCISES
-- ----------------------------------------------------------------------------
-- EASY
-- E1.  Start a transaction, SELECT FOR UPDATE a product, update its
--      stock_qty, COMMIT.
-- E2.  Explain in a comment the difference between a shared (S) lock and
--      an exclusive (X) lock.
--
-- MEDIUM
-- E3.  Implement an optimistic-locking UPDATE with a version column.
--      Demonstrate that a concurrent UPDATE with a stale version returns
--      affected_rows = 0.
-- E4.  Use SELECT ... FOR UPDATE SKIP LOCKED to "claim" the next pending
--      order without blocking on locked rows.
--
-- HARD
-- E5.  Describe a deadlock scenario involving two transactions updating
--      rows in opposite orders. Explain in a comment how MySQL detects
--      and resolves it (which transaction is rolled back).
--
-- EXPERT
-- E6.  Explain in a comment when you'd use pessimistic locking vs
--      optimistic locking. Provide a concrete use case for each.
-- ============================================================================

-- End of file 08_locks_isolation.sql
