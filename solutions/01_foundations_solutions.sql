-- ============================================================================
-- 01_foundations_solutions.sql — Solutions for 01_foundations exercises
-- ============================================================================
-- These are reference solutions for the exercises embedded in the
-- 01_foundations/*.sql files. Try the exercises first; check here only
-- when stuck or to compare approaches.
-- ============================================================================

USE ecom;

-- ============================================================================
-- 01_intro_and_syntax.sql
-- ============================================================================

-- E1. id and name of every category, limit 5
SELECT id, name FROM categories LIMIT 5;

-- E2. SKU, name, price of every product, first 3 rows
SELECT sku, name, price FROM products LIMIT 3;

-- E3. First 4 customers we acquired (oldest by created_at)
SELECT first_name, last_name, email
FROM customers
ORDER BY created_at ASC
LIMIT 4;

-- E4. Predict: SELECT 1 AS a, (SELECT 2) AS b, 'three' AS c FROM dual;
-- Returns one row: a=1, b=2, c='three'. dual is a one-row dummy table.
SELECT 1 AS a, (SELECT 2) AS b, 'three' AS c FROM dual;

-- ============================================================================
-- 02_select.sql
-- ============================================================================

-- E1. name and price for every product
SELECT name, price FROM products;

-- E2. with price_with_tax (10%)
SELECT name, price, ROUND(price * 1.10, 2) AS price_with_tax FROM products;

-- E3. first_name, last_name, city_state = "City, ST", limit 6
SELECT
    first_name,
    last_name,
    CONCAT(city, ', ', state) AS city_state
FROM customers
LIMIT 6;

-- E4. email and position of '@'
SELECT email, LOCATE('@', email) AS at_position FROM employees;

-- E5. full name + length of email after '@'
SELECT
    CONCAT(first_name, ' ', last_name) AS full_name,
    LENGTH(SUBSTRING_INDEX(email, '@', -1)) AS domain_length
FROM customers;

-- E6. price_tier using CASE
SELECT
    sku,
    CASE
        WHEN price < 100  THEN 'budget'
        WHEN price < 500  THEN 'mid'
        WHEN price < 1500 THEN 'premium'
        ELSE 'luxury'
    END AS price_tier
FROM products;

-- ============================================================================
-- 03_select_distinct.sql
-- ============================================================================

-- E1. distinct order statuses
SELECT DISTINCT status FROM orders;

-- E2. distinct slugs that have been ordered
SELECT DISTINCT p.sku
FROM order_items oi
JOIN products p ON p.id = oi.product_id;

-- E3. count of distinct customers with at least one order
SELECT COUNT(DISTINCT customer_id) AS distinct_customers_with_orders
FROM orders;

-- E4. distinct (status, year) pairs
SELECT DISTINCT status, YEAR(order_date) AS order_year
FROM orders
ORDER BY status, order_year;

-- E5. distinct countries with orders total > 1000
SELECT DISTINCT c.country
FROM customers c
JOIN orders o ON o.customer_id = c.id
WHERE o.total > 1000;

-- E6. GROUP BY equivalent of SELECT DISTINCT country, city
SELECT country, city
FROM customers
GROUP BY country, city;

-- ============================================================================
-- 04_where.sql
-- ============================================================================

-- E1. products with stock_qty = 0
SELECT name FROM products WHERE stock_qty = 0;

-- E2. customers in Japan
SELECT first_name, last_name FROM customers WHERE country = 'Japan';

-- E3. orders with status shipped OR paid
SELECT id, status, total FROM orders WHERE status IN ('shipped', 'paid');

-- E4. reviews with rating 4 or 5
SELECT customer_id, product_id, rating FROM reviews WHERE rating IN (4, 5);

-- E5. products with gross margin >= 40% of price
SELECT name, price, cost,
       ROUND((price - cost) / price * 100, 2) AS margin_pct
FROM products
WHERE (price - cost) / price >= 0.40;

-- E6. customers with NULL phone who have placed an order
SELECT c.first_name, c.last_name
FROM customers c
WHERE c.phone IS NULL
  AND c.id IN (SELECT customer_id FROM orders);

-- E7. Why does WHERE is_active = NULL return 0 rows?
-- Because NULL = NULL evaluates to NULL (not TRUE), so no row passes.
-- Corrected:
SELECT * FROM customers WHERE id = 4 AND is_active IS NULL;  -- if is_active were nullable
-- Actually is_active is NOT NULL by schema. Use:
SELECT * FROM customers WHERE id = 4 AND is_active = 0;

-- ============================================================================
-- 05_order_by.sql
-- ============================================================================

-- E1. products sorted by name (A→Z)
SELECT name, price FROM products ORDER BY name;

-- E2. 5 customers with highest id (proxy for newest)
SELECT first_name, last_name FROM customers ORDER BY id DESC LIMIT 5;

-- E3. orders sorted by custom status priority
SELECT id, status, total
FROM orders
ORDER BY FIELD(status, 'cancelled', 'refunded', 'pending', 'paid', 'shipped', 'delivered');

-- E4. customers sorted by country ASC, created_at DESC
SELECT first_name, last_name, country, created_at
FROM customers
ORDER BY country ASC, created_at DESC;

-- E5. products with gross_margin_pct, sorted DESC, rounded to 1dp
SELECT
    name,
    price,
    ROUND((price - cost) / price * 100, 1) AS gross_margin_pct
FROM products
ORDER BY gross_margin_pct DESC;

-- E6. top 3 customers by total spend
SELECT c.id, c.first_name, c.last_name, SUM(o.total) AS total_spent
FROM customers c
JOIN orders o ON o.customer_id = c.id
GROUP BY c.id, c.first_name, c.last_name
ORDER BY total_spent DESC
LIMIT 3;

-- E7. NULL phone LAST, then alphabetical by last_name
SELECT first_name, last_name, phone
FROM customers
ORDER BY phone IS NULL DESC, last_name ASC;

-- ============================================================================
-- 06_and_or_not.sql
-- ============================================================================

-- E1. active customers in Japan
SELECT first_name, last_name FROM customers
WHERE country = 'Japan' AND is_active = 1;

-- E2. products priced < 100 OR stock < 10
SELECT name, price, stock_qty FROM products
WHERE price < 100 OR stock_qty < 10;

-- E3. paid orders > 1000 OR shipped > 500
SELECT id, status, total FROM orders
WHERE (status = 'paid' AND total > 1000)
   OR (status = 'shipped' AND total > 500);

-- E4. customers NOT IN (US, Canada, Mexico)
SELECT first_name, last_name, country FROM customers
WHERE country NOT IN ('United States', 'Canada', 'Mexico');

-- E5. cat 8 or 9 with margin > $200
SELECT name, price, cost, (price - cost) AS margin
FROM products
WHERE (category_id = 8 OR category_id = 9)
  AND (price - cost) > 200
ORDER BY margin DESC;

-- E6. Negation via De Morgan
-- Original: (country='US' AND is_active=1) OR (country='UK' AND is_active=0)
-- Negation: NOT(country='US' AND is_active=1) AND NOT(country='UK' AND is_active=0)
--         ≡ (country<>'US' OR is_active<>1) AND (country<>'UK' OR is_active<>0)
SELECT first_name, last_name, country, is_active
FROM customers
WHERE (country <> 'United States' OR is_active <> 1)
  AND (country <> 'United Kingdom' OR is_active <> 0);

-- ============================================================================
-- 07_insert.sql
-- ============================================================================

-- E1. insert Sam Tester in Canada
INSERT INTO customers (first_name, last_name, email, country)
VALUES ('Sam', 'Tester', 'sam.tester@example.com', 'Canada');
DELETE FROM customers WHERE email = 'sam.tester@example.com';

-- E2. insert Office Chair under Furniture
INSERT INTO products (category_id, sku, name, price, cost, stock_qty)
VALUES (12, 'FRN-002', 'Office Chair', 149.99, 65.00, 30);
DELETE FROM products WHERE sku = 'FRN-002';

-- E3. insert 3 categories in one statement
INSERT INTO categories (parent_id, name, slug) VALUES
(1, 'Tablets',    'tablets'),
(1, 'Wearables',  'wearables'),
(1, 'Cameras',    'cameras');
DELETE FROM categories WHERE slug IN ('tablets', 'wearables', 'cameras');

-- E4. order + line item, then cleanup
START TRANSACTION;
INSERT INTO orders (customer_id, status, subtotal, tax, shipping, total, shipping_address)
VALUES (2, 'pending', 79.00, 6.32, 5.00, 90.32, '456 Oak Ave, Austin, TX');
SET @oid := LAST_INSERT_ID();
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
VALUES (@oid, 10, 1, 79.00);
DELETE FROM order_items WHERE order_id = @oid;
DELETE FROM orders WHERE id = @oid;
COMMIT;

-- E5. upsert with alias form
INSERT INTO customers (first_name, last_name, email, country, is_active)
VALUES ('Alice', 'Johnson', 'alice.johnson@example.com', 'United States', 1) AS new_row
ON DUPLICATE KEY UPDATE
    first_name = new_row.first_name,
    is_active  = new_row.is_active,
    updated_at = CURRENT_TIMESTAMP;

-- E6. atomic order with two line items
START TRANSACTION;
INSERT INTO orders (customer_id, status, subtotal, tax, shipping, total)
VALUES (5, 'pending', 159.00, 12.72, 0.00, 171.72);
SET @oid := LAST_INSERT_ID();
INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES (@oid, 9, 1, 129.00);
INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES (@oid, 10, 1, 79.00);
-- Verify
SELECT * FROM orders WHERE id = @oid;
SELECT * FROM order_items WHERE order_id = @oid;
ROLLBACK;

-- ============================================================================
-- 08_null_values.sql
-- ============================================================================

-- E1. count NULL metadata
SELECT COUNT(*) AS null_metadata_count
FROM customers WHERE metadata IS NULL;

-- E2. first 5 products with non-NULL weight
SELECT name, weight_kg FROM products WHERE weight_kg IS NOT NULL LIMIT 5;

-- E3. phone or '— no phone —'
SELECT first_name, last_name,
       COALESCE(phone, '— no phone —') AS phone_label
FROM customers;

-- E4. avg weight: NULL-as-0 vs ignoring-NULLs side by side
SELECT
    AVG(weight_kg)              AS avg_ignoring_nulls,
    AVG(COALESCE(weight_kg, 0)) AS avg_treating_null_as_zero
FROM products;

-- E5. customers with NULL phone AND NULL metadata
SELECT first_name, last_name
FROM customers
WHERE phone IS NULL AND metadata IS NULL;

-- E6. markup ratio with NULLIF for div/0
SELECT sku, name, price, cost, price / NULLIF(cost, 0) AS markup_ratio
FROM products;

-- E7. Why NOT IN returns 0 rows with NULL in subquery:
-- x NOT IN (a, b, NULL) is rewritten as x<>a AND x<>b AND x<>NULL.
-- x<>NULL is NULL, so the whole AND is NULL, so no row passes.
-- Fixed with NOT EXISTS:
SELECT first_name, last_name FROM customers c
WHERE NOT EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.id);

-- ============================================================================
-- 09_update.sql
-- ============================================================================

-- E1. update customer 7's phone
UPDATE customers SET phone = '555-0199' WHERE id = 7;

-- E2. restore phone to NULL
UPDATE customers SET phone = NULL WHERE id = 7;

-- E3. raise Audio prices 8%
UPDATE products SET price = ROUND(price * 1.08, 2) WHERE category_id = 7;
-- Restore:
UPDATE products SET price = 349.00 WHERE sku = 'AUD-001';
UPDATE products SET price = 129.00 WHERE sku = 'AUD-002';
UPDATE products SET price = 79.00  WHERE sku = 'AUD-003';

-- E4. set is_active=0 for example.com non-US customers
UPDATE customers SET is_active = 0
WHERE email LIKE '%@example.com' AND country <> 'United States';
-- Restore
UPDATE customers SET is_active = 1 WHERE id IN (5, 10, 11);
UPDATE customers SET is_active = 0 WHERE id = 4;

-- E5. set cost = price * 0.7 in a transaction
START TRANSACTION;
UPDATE products SET cost = ROUND(price * 0.7, 2);
SELECT name, price, cost FROM products LIMIT 5;
ROLLBACK;

-- E6. update order 3 from sum of line items
UPDATE orders o
SET o.subtotal = (SELECT SUM(line_total) FROM order_items WHERE order_id = o.id),
    o.tax      = (SELECT SUM(line_total) FROM order_items WHERE order_id = o.id) * 0.08,
    o.total    = (SELECT SUM(line_total) FROM order_items WHERE order_id = o.id) * 1.08
WHERE o.id = 3;

-- ============================================================================
-- 10_delete.sql
-- ============================================================================

-- E1. insert then delete a temp customer
INSERT INTO customers (first_name, last_name, email) VALUES ('E1', 'User', 'e1.delete@example.com');
DELETE FROM customers WHERE email = 'e1.delete@example.com';

-- E2. temp table, delete 2 oldest
CREATE TEMPORARY TABLE tmp_del (id INT AUTO_INCREMENT PRIMARY KEY, ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP, val INT);
INSERT INTO tmp_del (val) VALUES (10), (20), (30), (40), (50);
DELETE FROM tmp_del ORDER BY ts ASC LIMIT 2;
SELECT * FROM tmp_del;
DROP TEMPORARY TABLE tmp_del;

-- E3. cancellable orders list
SELECT o.id
FROM orders o
WHERE o.status = 'cancelled'
  AND EXISTS (
      SELECT 1 FROM orders o2
      WHERE o2.customer_id = o.customer_id
        AND o2.status <> 'cancelled'
  );

-- E4. DELETE vs TRUNCATE differences (comment):
-- 1. TRUNCATE is DDL; DELETE is DML.
-- 2. TRUNCATE does NOT fire triggers; DELETE does.
-- 3. TRUNCATE cannot be inside a transaction (implicit COMMIT); DELETE can.
-- 4. TRUNCATE resets AUTO_INCREMENT; DELETE does not.
-- 5. TRUNCATE is faster on large tables.

-- E5. Why DELETE customers WHERE id=1 fails:
-- Customer 1 has orders, and the FK is ON DELETE RESTRICT.
-- Fix: delete children first, then parent.
-- DELETE FROM order_items WHERE order_id IN (SELECT id FROM orders WHERE customer_id = 1);
-- DELETE FROM orders WHERE customer_id = 1;
-- DELETE FROM customers WHERE id = 1;
-- Or change FK to ON DELETE CASCADE.

-- E6. soft-delete migration
ALTER TABLE reviews ADD COLUMN deleted_at TIMESTAMP NULL;
UPDATE reviews SET deleted_at = NOW() WHERE id = 14;
SELECT * FROM reviews WHERE deleted_at IS NULL;   -- live rows only
ALTER TABLE reviews DROP COLUMN deleted_at;

-- End of file 01_foundations_solutions.sql
