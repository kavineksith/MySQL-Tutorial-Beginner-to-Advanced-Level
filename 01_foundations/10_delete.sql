-- ============================================================================
-- 10_delete.sql — DELETE: Removing Rows
-- ============================================================================
-- SKILL LEVEL : Beginner
-- TOPICS      : DELETE single row, DELETE bulk, DELETE with JOIN, TRUNCATE
--               vs DELETE, DELETE with LIMIT/ORDER BY, foreign key
--               constraints, soft delete pattern.
-- ----------------------------------------------------------------------------
-- TEXTBOOK DEPTH
--   DELETE removes rows. It is irreversible outside a transaction. It honors
--   foreign key constraints: if a parent row has children declared with
--   `ON DELETE RESTRICT` (the default), MySQL refuses the DELETE.
--
--   DELETE vs TRUNCATE:
--     * DELETE is DML, fires triggers, can be in a transaction, can use WHERE.
--     * TRUNCATE is DDL, drops and recreates the table, fires NO triggers,
--       cannot be rolled back inside a transaction, resets AUTO_INCREMENT.
--     * TRUNCATE is much faster on large tables.
--
--   Two safety patterns to adopt in production code:
--     1. ALWAYS use a WHERE clause (enable --safe-updates in the CLI).
--     2. Prefer "soft delete" (set is_active=0 or deleted_at=timestamp)
--        over hard DELETE for any data you might need to audit.
-- ============================================================================

USE ecom;

-- ----------------------------------------------------------------------------
-- 1. DELETE by primary key — the safe, common case
-- ----------------------------------------------------------------------------
INSERT INTO customers (first_name, last_name, email) VALUES ('Temp', 'User', 'temp.delete@example.com');
SET @temp_id := LAST_INSERT_ID();
SELECT first_name, email FROM customers WHERE id = @temp_id;

DELETE FROM customers WHERE id = @temp_id;
SELECT ROW_COUNT() AS rows_deleted;
SELECT COUNT(*) AS remaining FROM customers WHERE id = @temp_id;   -- 0

-- ----------------------------------------------------------------------------
-- 2. DELETE with WHERE
-- ----------------------------------------------------------------------------
INSERT INTO customers (first_name, last_name, email, country)
VALUES ('D1', 'User', 'd1@example.com', 'Canada'),
       ('D2', 'User', 'd2@example.com', 'Canada'),
       ('D3', 'User', 'd3@example.com', 'Canada');

DELETE FROM customers
WHERE email IN ('d1@example.com', 'd2@example.com', 'd3@example.com')
  AND country = 'Canada';

SELECT COUNT(*) AS remaining FROM customers WHERE email LIKE 'd%@example.com';

-- ----------------------------------------------------------------------------
-- 3. DELETE all rows (DANGEROUS — never run on production without a backup)
-- ----------------------------------------------------------------------------
CREATE TEMPORARY TABLE tmp_delete_demo (id INT PRIMARY KEY, name VARCHAR(20));
INSERT INTO tmp_delete_demo VALUES (1, 'A'), (2, 'B'), (3, 'C');

DELETE FROM tmp_delete_demo;        -- removes every row, fires triggers
SELECT COUNT(*) FROM tmp_delete_demo;   -- 0

DROP TEMPORARY TABLE tmp_delete_demo;

-- ----------------------------------------------------------------------------
-- 4. DELETE ORDER BY + LIMIT — delete only the N oldest / N matching
-- ----------------------------------------------------------------------------
-- Useful for queue-style tables: delete the 5 oldest pending notifications.
CREATE TEMPORARY TABLE tmp_notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    queued_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20)
);
INSERT INTO tmp_notifications (status)
VALUES ('pending'),('pending'),('pending'),('sent'),('sent'),
       ('pending'),('pending'),('sent'),('pending'),('sent');

-- Delete the 3 oldest 'pending' notifications
DELETE FROM tmp_notifications
WHERE status = 'pending'
ORDER BY queued_at ASC
LIMIT 3;

SELECT * FROM tmp_notifications ORDER BY queued_at;

DROP TEMPORARY TABLE tmp_notifications;

-- ----------------------------------------------------------------------------
-- 5. DELETE with JOIN — delete rows based on a related table
-- ----------------------------------------------------------------------------
-- Delete customers who have ONLY cancelled orders.
CREATE TEMPORARY TABLE tmp_customers_to_delete AS
SELECT c.id
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
GROUP BY c.id
HAVING COUNT(o.id) > 0
   AND SUM(CASE WHEN o.status <> 'cancelled' THEN 1 ELSE 0 END) = 0;

-- Preview which rows would be deleted
SELECT * FROM tmp_customers_to_delete;

-- Actual delete (would skip if seed data has no such customer)
DELETE c FROM customers c
JOIN tmp_customers_to_delete td ON td.id = c.id;

DROP TEMPORARY TABLE tmp_customers_to_delete;

-- ----------------------------------------------------------------------------
-- 6. Foreign key constraint refusal
-- ----------------------------------------------------------------------------
-- Customer 1 has orders. Trying to delete customer 1 fails because the
-- orders foreign key uses ON DELETE RESTRICT.
-- Uncomment to see error 1451:
-- DELETE FROM customers WHERE id = 1;
-- ERROR 1451 (23000): Cannot delete or update a parent row: a foreign key
-- constraint fails (`ecom`.`orders`, CONSTRAINT `fk_orders_customer` ...)

-- ----------------------------------------------------------------------------
-- 7. TRUNCATE — fast, all-or-nothing, resets AUTO_INCREMENT
-- ----------------------------------------------------------------------------
CREATE TEMPORARY TABLE tmp_trunc_demo (
    id INT AUTO_INCREMENT PRIMARY KEY,
    val INT
);
INSERT INTO tmp_trunc_demo (val) VALUES (10), (20), (30);
SELECT * FROM tmp_trunc_demo;

TRUNCATE TABLE tmp_trunc_demo;
-- After TRUNCATE, AUTO_INCREMENT counter restarts at 1.
INSERT INTO tmp_trunc_demo (val) VALUES (99);
SELECT * FROM tmp_trunc_demo;   -- id = 1, val = 99

DROP TEMPORARY TABLE tmp_trunc_demo;

-- ----------------------------------------------------------------------------
-- 8. Soft delete pattern — preferred for audited business data
-- ----------------------------------------------------------------------------
-- Instead of DELETE, set is_active=0 or a deleted_at timestamp. Queries
-- filter `WHERE deleted_at IS NULL` to see live rows.

-- Example schema pattern (do not run on our ecom DB):
-- ALTER TABLE customers ADD COLUMN deleted_at TIMESTAMP NULL;
-- UPDATE customers SET deleted_at = NOW() WHERE id = 4;
-- SELECT * FROM customers WHERE deleted_at IS NULL;

-- ----------------------------------------------------------------------------
-- 9. DELETE inside a transaction
-- ----------------------------------------------------------------------------
-- Wrap risky DELETEs in BEGIN...ROLLBACK while testing.
START TRANSACTION;
DELETE FROM customers WHERE id = 12;       -- customer 12 has no orders → safe
SELECT COUNT(*) AS remaining FROM customers WHERE id = 12;  -- 0
ROLLBACK;
SELECT COUNT(*) AS restored FROM customers WHERE id = 12;   -- 1

-- ----------------------------------------------------------------------------
-- 10. EXERCISES
-- ----------------------------------------------------------------------------
-- EASY
-- E1.  Insert a temporary customer with email 'e1.delete@example.com',
--      then DELETE it.
-- E2.  Insert 5 rows into a new TEMPORARY table, then DELETE the 2 oldest
--      using ORDER BY + LIMIT.
--
-- MEDIUM
-- E3.  Without actually deleting, write a query that lists the IDs of all
--      orders that could be safely deleted because they have status
--      'cancelled' AND their customer has at least one non-cancelled order.
-- E4.  Compare DELETE FROM tmp_x vs TRUNCATE TABLE tmp_x — write a comment
--      listing at least three differences (triggers, transaction, AUTO_INC).
--
-- HARD
-- E5.  Explain in a comment why this query fails and how to fix it:
--        DELETE FROM customers WHERE id = 1;
--      Provide a safe ordering of DELETE statements that would let us
--      remove customer 1 and all her data.
--
-- EXPERT
-- E6.  Write a soft-delete migration: add a `deleted_at TIMESTAMP NULL`
--      column to the `reviews` table, "delete" review id=14 (set
--      deleted_at), then write a query that returns only live reviews
--      (deleted_at IS NULL). Rollback the migration at the end so the
--      schema matches the original.
-- ============================================================================

-- End of file 10_delete.sql
