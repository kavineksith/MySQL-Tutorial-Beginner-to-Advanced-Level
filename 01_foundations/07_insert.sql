-- ============================================================================
-- 07_insert.sql — INSERT INTO: Adding Rows
-- ============================================================================
-- SKILL LEVEL : Beginner
-- TOPICS      : INSERT single row, INSERT multiple rows, INSERT with column
--               list, INSERT ... SELECT, INSERT IGNORE, REPLACE, ON DUPLICATE
--               KEY UPDATE, LAST_INSERT_ID().
-- ----------------------------------------------------------------------------
-- TEXTBOOK DEPTH
--   INSERT is the DML (Data Manipulation Language) verb that adds rows. It
--   respects all constraints declared on the target table — PRIMARY KEY,
--   UNIQUE, NOT NULL, FOREIGN KEY, CHECK. A constraint violation aborts the
--   statement (and rolls back any partial work for that statement).
--
--   Three things beginners get wrong:
--     1. Forgetting to list columns — relying on positional order, which
--        silently breaks when the table is altered.
--     2. Using single-row INSERTs in a loop instead of one multi-row INSERT
--        — 10× to 100× slower.
--     3. Ignoring AUTO_INCREMENT interaction with LAST_INSERT_ID() when
--        inserting parent then child rows.
-- ============================================================================

USE ecom;

-- ----------------------------------------------------------------------------
-- 1. Single-row INSERT with explicit column list (RECOMMENDED)
-- ----------------------------------------------------------------------------
INSERT INTO customers (first_name, last_name, email, country)
VALUES ('Test', 'User', 'test.user@example.com', 'United States');

SELECT first_name, last_name, email FROM customers
WHERE email = 'test.user@example.com';

-- Clean up so we don't pollute later lessons
DELETE FROM customers WHERE email = 'test.user@example.com';

-- ----------------------------------------------------------------------------
-- 2. INSERT into all columns in declared order (FRAGILE — avoid)
-- ----------------------------------------------------------------------------
-- Skips the column list and relies on positional order. NEVER use this in
-- production code — adding a new column to the table silently breaks every
-- INSERT that omits the list.
-- INSERT INTO customers VALUES (NULL, 'Test', 'User', ...);

-- ----------------------------------------------------------------------------
-- 3. Multi-row INSERT — much faster than N single INSERTs
-- ----------------------------------------------------------------------------
-- Use a single VALUES list with multiple tuples separated by commas. Each
-- tuple is one row. The whole statement is one transaction, so it commits
-- atomically.
INSERT INTO categories (parent_id, name, slug, description) VALUES
(2, 'Cookbooks',     'cookbooks',     'Recipe collections'),
(2, 'Comics',        'comics',        'Graphic novels'),
(3, 'Garden',        'garden',        'Outdoor and garden tools');

SELECT id, name, slug FROM categories WHERE slug IN ('cookbooks','comics','garden');

-- Clean up
DELETE FROM categories WHERE slug IN ('cookbooks','comics','garden');

-- ----------------------------------------------------------------------------
-- 4. INSERT ... SELECT — copy rows from another table or query
-- ----------------------------------------------------------------------------
-- Useful for archiving, denormalizing, or seeding test data.

-- Copy the names of all current customers into a temp table
CREATE TEMPORARY TABLE tmp_customer_names (
    id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(120)
);

INSERT INTO tmp_customer_names (full_name)
SELECT CONCAT(first_name, ' ', last_name)
FROM customers
WHERE is_active = 1;

SELECT * FROM tmp_customer_names;

DROP TEMPORARY TABLE tmp_customer_names;

-- ----------------------------------------------------------------------------
-- 5. INSERT IGNORE — silently skip conflicting rows
-- ----------------------------------------------------------------------------
-- When a UNIQUE or PRIMARY KEY constraint would be violated, INSERT IGNORE
-- skips the offending row (instead of aborting the whole statement).
-- Use sparingly — silent failures hide bugs.

-- First make sure no conflict
DELETE FROM customers WHERE email = 'alice.johnson@example.com';

INSERT IGNORE INTO customers (first_name, last_name, email, country)
VALUES
('Alice', 'Johnson', 'alice.johnson@example.com', 'United States'),
('Alice', 'Johnson', 'alice.johnson@example.com', 'United States'),
('Real',  'Newuser', 'real.newuser@example.com',  'United States');

SELECT first_name, email FROM customers WHERE email LIKE 'alice.johnson%' OR email = 'real.newuser@example.com';

-- Clean up
DELETE FROM customers WHERE email = 'real.newuser@example.com';
-- Re-insert Alice to restore seed
INSERT INTO customers (id, first_name, last_name, email, phone, birth_date,
                       street, city, state, postal_code, country, is_active, metadata)
VALUES (1, 'Alice','Johnson','alice.johnson@example.com','555-0101','1990-04-12',
        '123 Maple St','Springfield','IL','62704','United States',1,
        '{"tags":["vip"],"loyalty_points":1250}');

-- ----------------------------------------------------------------------------
-- 6. REPLACE — DELETE then INSERT on conflict (MySQL extension)
-- ----------------------------------------------------------------------------
-- If a UNIQUE/PK conflict exists, the existing row is DELETED and the new
-- one is INSERTED. This changes the primary key (AUTO_INCREMENT advances),
-- which BREAKS foreign keys pointing at the old row. AVOID in favor of
-- ON DUPLICATE KEY UPDATE.

REPLACE INTO customers (id, first_name, last_name, email, country)
VALUES (1, 'Alice', 'Johnson', 'alice.johnson@example.com', 'United States');
-- ID stays 1 because we explicitly set it.

-- ----------------------------------------------------------------------------
-- 7. ON DUPLICATE KEY UPDATE — upsert pattern (the right way)
-- ----------------------------------------------------------------------------
-- When a UNIQUE/PK conflict occurs, UPDATE the existing row instead of
-- erroring or replacing.

INSERT INTO customers (first_name, last_name, email, country, is_active)
VALUES ('Alice', 'Johnson', 'alice.johnson@example.com', 'United States', 1)
ON DUPLICATE KEY UPDATE
    first_name = VALUES(first_name),
    last_name  = VALUES(last_name),
    is_active  = VALUES(is_active);

-- MySQL 8.0.19+ supports the cleaner alias form:
INSERT INTO customers (first_name, last_name, email, country, is_active)
VALUES ('Alice', 'Johnson', 'alice.johnson@example.com', 'United States', 1) AS new_row
ON DUPLICATE KEY UPDATE
    first_name = new_row.first_name,
    last_name  = new_row.last_name,
    is_active  = new_row.is_active;

-- ----------------------------------------------------------------------------
-- 8. LAST_INSERT_ID() — getting the AUTO_INCREMENT id of the last INSERT
-- ----------------------------------------------------------------------------
-- Per-connection. Returns the AUTO_INCREMENT id generated by the most recent
-- INSERT on this connection. Returns 0 if no INSERT happened yet.

INSERT INTO categories (parent_id, name, slug) VALUES (4, 'Test Cat', 'test-cat-1');
SELECT LAST_INSERT_ID() AS new_category_id;
DELETE FROM categories WHERE slug = 'test-cat-1';

-- Critical when inserting parent then child in a script:
SET @parent_id := (SELECT MAX(id) + 1 FROM categories);  -- never do this in prod
INSERT INTO categories (id, parent_id, name, slug) VALUES (@parent_id, NULL, 'Parent', 'parent-test');
INSERT INTO categories (parent_id, name, slug)
VALUES (@parent_id, 'Child', 'child-test');
-- The child's parent_id is the auto-generated id of the parent.
SELECT id, parent_id, name, slug FROM categories WHERE slug IN ('parent-test','child-test');
DELETE FROM categories WHERE slug IN ('parent-test','child-test');

-- ----------------------------------------------------------------------------
-- 9. INSERT with DEFAULT and NULL explicitly
-- ----------------------------------------------------------------------------
INSERT INTO customers (first_name, last_name, email, country, is_active, created_at)
VALUES ('Min', 'Lee', 'min.lee@example.com', DEFAULT, NULL, DEFAULT);
-- is_active=DEFAULT → 1, created_at=DEFAULT → CURRENT_TIMESTAMP
SELECT first_name, email, country, is_active, created_at FROM customers WHERE email = 'min.lee@example.com';
DELETE FROM customers WHERE email = 'min.lee@example.com';

-- ----------------------------------------------------------------------------
-- 10. INSERT into a table with a generated column
-- ----------------------------------------------------------------------------
-- order_items.line_total is a STORED generated column: quantity * unit_price.
-- We must NOT supply a value for it.
INSERT INTO orders (customer_id, status, subtotal, tax, shipping, total, shipping_address)
VALUES (1, 'pending', 79.00, 6.32, 5.00, 90.32, '123 Maple St, Springfield, IL 62704');

SET @new_order_id := LAST_INSERT_ID();

INSERT INTO order_items (order_id, product_id, quantity, unit_price)
VALUES (@new_order_id, 10, 1, 79.00);

-- Verify the generated column was computed
SELECT id, order_id, product_id, quantity, unit_price, line_total
FROM order_items WHERE order_id = @new_order_id;

-- Clean up
DELETE FROM order_items WHERE order_id = @new_order_id;
DELETE FROM orders WHERE id = @new_order_id;

-- ----------------------------------------------------------------------------
-- 11. EXERCISES
-- ----------------------------------------------------------------------------
-- EASY
-- E1.  Insert a new customer named 'Sam Tester' with email
--      'sam.tester@example.com' in country 'Canada'.
-- E2.  Insert a new product under category_id=12 (Furniture) with a unique
--      SKU 'FRN-002', name 'Office Chair', price 149.99, cost 65.00,
--      stock 30.
--
-- MEDIUM
-- E3.  Insert 3 categories in a single statement: 'Tablets', 'Wearables',
--      'Cameras' all under parent_id=1 (Electronics).
-- E4.  Create an order for customer 2 with one line item, then delete both
--      the order_item and the order to restore the seed state. (Use
--      LAST_INSERT_ID to capture the order id.)
--
-- HARD
-- E5.  Write an upsert that updates the customer's `updated_at` and
--      `is_active` when an INSERT collides on the email unique key. Use the
--      alias form (MySQL 8.0.19+).
--
-- EXPERT
-- E6.  Insert a new order with two order_items in a SINGLE TRANSACTION so
--      that either both succeed or neither does. (Hint: see
--      09_advanced_mysql/07_transactions.sql for BEGIN/COMMIT.)
-- ============================================================================

-- End of file 07_insert.sql
