-- ============================================================================
-- 07_transactions.sql — Transactions & ACID
-- ============================================================================
-- SKILL LEVEL : Advanced
-- TOPICS      : BEGIN / START TRANSACTION, COMMIT, ROLLBACK, SAVEPOINT,
--               ROLLBACK TO SAVEPOINT, autocommit, isolation levels, READ
--               COMMITTED vs REPEATABLE READ vs SERIALIZABLE, ACID.
-- ----------------------------------------------------------------------------
-- TEXTBOOK DEPTH
--   A transaction is a sequence of statements that execute ATOMICALLY:
--   either all succeed (COMMIT) or none do (ROLLBACK). ACID is the
--   defining property:
--     A — Atomicity:    all-or-nothing.
--     C — Consistency:  the database moves from one valid state to another.
--     I — Isolation:    concurrent transactions appear to run sequentially.
--     D — Durability:   once committed, the change survives crashes.
--
--   MySQL with InnoDB provides full ACID compliance.
--
--   MySQL autocommit:
--     * By default, autocommit = ON: every statement commits immediately.
--     * With START TRANSACTION, autocommit is suspended until COMMIT/ROLLBACK.
--     * SET autocommit = 0 disables autocommit for the session.
--
--   Isolation levels (from weakest to strongest):
--     READ UNCOMMITTED — dirty reads possible (rarely used; dangerous).
--     READ COMMITTED   — only committed data is visible. PostgreSQL default.
--                        No dirty reads, but non-repeatable reads and
--                        phantoms possible.
--     REPEATABLE READ  — within a transaction, repeated reads return the
--                        same data. MySQL's DEFAULT. InnoDB also prevents
--                        phantoms via next-key locking.
--     SERIALIZABLE     — strongest; reads acquire locks. May serialize
--                        concurrent transactions.
--
--   SAVEPOINTs let you roll back PART of a transaction without aborting
--   the whole thing.
-- ============================================================================

USE ecom;

SHOW VARIABLES LIKE 'autocommit';
SHOW VARIABLES LIKE 'transaction_isolation';

-- ----------------------------------------------------------------------------
-- 1. Basic BEGIN / COMMIT
-- ----------------------------------------------------------------------------
START TRANSACTION;
INSERT INTO categories (parent_id, name, slug) VALUES (NULL, 'Tx Test Cat', 'tx-test-1');
SELECT COUNT(*) AS in_transaction_count FROM categories WHERE slug = 'tx-test-1';
COMMIT;
SELECT COUNT(*) AS after_commit_count FROM categories WHERE slug = 'tx-test-1';

-- Clean up
DELETE FROM categories WHERE slug = 'tx-test-1';

-- ----------------------------------------------------------------------------
-- 2. Basic ROLLBACK
-- ----------------------------------------------------------------------------
START TRANSACTION;
INSERT INTO categories (parent_id, name, slug) VALUES (NULL, 'Tx Test Cat', 'tx-test-2');
SELECT COUNT(*) AS in_transaction_count FROM categories WHERE slug = 'tx-test-2';
ROLLBACK;
SELECT COUNT(*) AS after_rollback_count FROM categories WHERE slug = 'tx-test-2';
-- Should be 0 — the insert was rolled back.

-- ----------------------------------------------------------------------------
-- 3. SAVEPOINT — partial rollback
-- ----------------------------------------------------------------------------
START TRANSACTION;

INSERT INTO categories (parent_id, name, slug) VALUES (NULL, 'Before SP', 'tx-before-sp');
SAVEPOINT sp1;

INSERT INTO categories (parent_id, name, slug) VALUES (NULL, 'After SP', 'tx-after-sp');
SELECT slug FROM categories WHERE slug LIKE 'tx-%-sp';

ROLLBACK TO SAVEPOINT sp1;
-- 'After SP' is rolled back, 'Before SP' remains.
SELECT slug FROM categories WHERE slug LIKE 'tx-%-sp';

COMMIT;
SELECT slug FROM categories WHERE slug LIKE 'tx-%-sp';
-- Only 'Before SP' survived.

DELETE FROM categories WHERE slug = 'tx-before-sp';

-- ----------------------------------------------------------------------------
-- 4. RELEASE SAVEPOINT — discard a savepoint (can no longer roll back to it)
-- ----------------------------------------------------------------------------
-- SAVEPOINT sp2;
-- ... statements ...
-- RELEASE SAVEPOINT sp2;
-- ROLLBACK TO SAVEPOINT sp2;   -- ERROR: SAVEPOINT does not exist

-- ----------------------------------------------------------------------------
-- 5. Multi-statement transaction — atomic order placement
-- ----------------------------------------------------------------------------
-- Place an order with line items atomically: if any line item fails, the
-- whole order is rolled back.

DROP TABLE IF EXISTS tmp_tx_log;
CREATE TABLE tmp_tx_log (id INT AUTO_INCREMENT PRIMARY KEY, msg VARCHAR(100));

DELIMITER //
DROP PROCEDURE IF EXISTS sp_place_order //
CREATE PROCEDURE sp_place_order(
    IN p_customer_id BIGINT,
    IN p_product_id BIGINT,
    IN p_qty INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        INSERT INTO tmp_tx_log (msg) VALUES (CONCAT('Order failed: ', p_customer_id));
        SELECT 'Order failed and rolled back' AS result;
    END;

    DECLARE v_order_id BIGINT;
    DECLARE v_unit_price DECIMAL(10,2);

    START TRANSACTION;

    -- Snapshot the product's current price
    SELECT price INTO v_unit_price FROM products WHERE id = p_product_id;

    -- Insert the order
    INSERT INTO orders (customer_id, status, subtotal, tax, shipping, total, shipping_address)
    VALUES (p_customer_id, 'pending', v_unit_price * p_qty, 0, 0, v_unit_price * p_qty, 'Demo');
    SET v_order_id := LAST_INSERT_ID();

    -- Insert the line item
    INSERT INTO order_items (order_id, product_id, quantity, unit_price)
    VALUES (v_order_id, p_product_id, p_qty, v_unit_price);

    COMMIT;
    INSERT INTO tmp_tx_log (msg) VALUES (CONCAT('Order ', v_order_id, ' placed'));
    SELECT v_order_id AS new_order_id, 'Order placed' AS result;
END //
DELIMITER ;

-- Call the procedure
CALL sp_place_order(2, 1, 1);

-- Inspect the order and item
SELECT id, customer_id, status, total FROM orders WHERE customer_id = 2 ORDER BY id DESC LIMIT 1;
SELECT * FROM order_items WHERE order_id = (SELECT MAX(id) FROM orders WHERE customer_id = 2);

-- Clean up
DROP PROCEDURE sp_place_order;
DELETE FROM order_items WHERE order_id IN (SELECT id FROM orders WHERE customer_id = 2 AND total = 1299);
DELETE FROM orders WHERE customer_id = 2 AND total = 1299;
DROP TABLE tmp_tx_log;

-- ----------------------------------------------------------------------------
-- 6. Isolation levels — set per session
-- ----------------------------------------------------------------------------
-- Set the isolation level for the current session:
SET SESSION transaction_isolation = 'READ-COMMITTED';
SELECT @@session.transaction_isolation AS current_level;

-- Restore default
SET SESSION transaction_isolation = 'REPEATABLE-READ';

-- ----------------------------------------------------------------------------
-- 7. READ ONLY transactions — hint for replication routing
-- ----------------------------------------------------------------------------
START TRANSACTION READ ONLY;
SELECT COUNT(*) FROM customers;
COMMIT;

-- ----------------------------------------------------------------------------
-- 8. Implicit commits — DDL inside a transaction
-- ----------------------------------------------------------------------------
-- Most DDL statements (ALTER TABLE, CREATE TABLE, DROP TABLE, TRUNCATE)
-- IMPLICITLY COMMIT the current transaction. This is a common surprise:
START TRANSACTION;
INSERT INTO categories (parent_id, name, slug) VALUES (NULL, 'Implicit', 'implicit-test');
CREATE TABLE tmp_ddl_in_tx (id INT);    -- IMPLICIT COMMIT here
ROLLBACK;
-- The INSERT was committed by the CREATE TABLE.
SELECT COUNT(*) AS still_present FROM categories WHERE slug = 'implicit-test';

-- Clean up
DELETE FROM categories WHERE slug = 'implicit-test';
DROP TABLE IF EXISTS tmp_ddl_in_tx;

-- ----------------------------------------------------------------------------
-- 9. EXERCISES
-- ----------------------------------------------------------------------------
-- EASY
-- E1.  Start a transaction, insert a row into a temp table, ROLLBACK, and
--      verify the row is gone.
-- E2.  Start a transaction, insert a row, COMMIT, and verify the row
--      persists.
--
-- MEDIUM
-- E3.  Use SAVEPOINT to roll back PART of a transaction. Insert row A,
--      SAVEPOINT, insert row B, ROLLBACK TO SAVEPOINT, COMMIT. Verify A
--      survived and B did not.
-- E4.  Write a stored procedure that places an order with line items
--      atomically. Use DECLARE EXIT HANDLER FOR SQLEXCEPTION to ROLLBACK
--      on error.
--
-- HARD
-- E5.  Explain in a comment why DDL inside a transaction implicitly
--      commits. Provide an example that surprises a developer.
--
-- EXPERT
-- E6.  Explain in a comment the four isolation levels and the anomalies
--      each prevents (dirty read, non-repeatable read, phantom). Which
--      level does MySQL default to, and what extra guarantee does InnoDB
--      provide at that level?
-- ============================================================================

-- End of file 07_transactions.sql
