-- ============================================================================
-- 09_update.sql — UPDATE: Modifying Rows
-- ============================================================================
-- SKILL LEVEL : Beginner
-- TOPICS      : UPDATE single column, UPDATE multiple columns, UPDATE with
--               WHERE, multi-table UPDATE, UPDATE with subquery, UPDATE with
--               JOIN, ORDER BY + LIMIT in UPDATE, safe update patterns.
-- ----------------------------------------------------------------------------
-- TEXTBOOK DEPTH
--   UPDATE modifies existing rows. The full syntax is:
--     UPDATE table
--     SET col1 = expr1 [, col2 = expr2 ...]
--     [WHERE predicate]
--     [ORDER BY ...]
--     [LIMIT n]
--
--   DANGERS:
--     * FORGETTING WHERE updates EVERY row in the table. The MySQL CLI has a
--       `--safe-updates` mode that refuses UPDATE/DELETE without a key in
--       the WHERE clause — enable it when learning.
--     * UPDATE is atomic per statement (all changed rows commit together)
--       but NOT per-row. If row 5 violates a constraint, rows 1-4 are NOT
--       rolled back; the whole statement rolls back.
--     * UPDATE fires BEFORE/AFTER UPDATE triggers per row.
--     * The `updated_at` column declared with `ON UPDATE CURRENT_TIMESTAMP`
--       is automatically refreshed — you do NOT need to set it manually.
-- ============================================================================

USE ecom;

-- ----------------------------------------------------------------------------
-- 1. Single-row UPDATE by primary key
-- ----------------------------------------------------------------------------
UPDATE customers
SET first_name = 'Alicia'
WHERE id = 1;

SELECT id, first_name, last_name, updated_at FROM customers WHERE id = 1;

-- Restore seed value
UPDATE customers SET first_name = 'Alice' WHERE id = 1;

-- ----------------------------------------------------------------------------
-- 2. Multi-column UPDATE
-- ----------------------------------------------------------------------------
UPDATE customers
SET city = 'Chicago', state = 'IL', postal_code = '60602'
WHERE id = 1;

SELECT id, first_name, city, state, postal_code FROM customers WHERE id = 1;

-- Restore seed
UPDATE customers
SET city = 'Springfield', state = 'IL', postal_code = '62704'
WHERE id = 1;

-- ----------------------------------------------------------------------------
-- 3. Bulk UPDATE with WHERE
-- ----------------------------------------------------------------------------
-- Mark all UK customers as inactive (then restore).
UPDATE customers SET is_active = 0 WHERE country = 'United Kingdom';
SELECT first_name, country, is_active FROM customers WHERE country = 'United Kingdom';

-- Restore
UPDATE customers SET is_active = 1 WHERE country = 'United Kingdom';

-- ----------------------------------------------------------------------------
-- 4. UPDATE with computed value
-- ----------------------------------------------------------------------------
-- Raise the price of all products in category 5 (Computers) by 5%.
UPDATE products
SET price = ROUND(price * 1.05, 2)
WHERE category_id = 5;

SELECT name, price FROM products WHERE category_id = 5;

-- Restore original prices
UPDATE products SET price = 1299.00 WHERE sku = 'LAP-001';
UPDATE products SET price = 2499.00 WHERE sku = 'LAP-002';
UPDATE products SET price = 599.00  WHERE sku = 'CPU-001';
UPDATE products SET price = 1099.00 WHERE sku = 'GPU-001';
UPDATE products SET price = 149.00  WHERE sku = 'RAM-001';

-- ----------------------------------------------------------------------------
-- 5. UPDATE with CASE — conditional update per row
-- ----------------------------------------------------------------------------
-- Increase prices selectively: 10% on premium laptops, 5% on others.
UPDATE products
SET price = CASE
    WHEN price > 2000 THEN ROUND(price * 1.10, 2)
    WHEN price > 500  THEN ROUND(price * 1.05, 2)
    ELSE price
END
WHERE category_id = 5;

SELECT name, price FROM products WHERE category_id = 5;

-- Restore
UPDATE products SET price = 1299.00 WHERE sku = 'LAP-001';
UPDATE products SET price = 2499.00 WHERE sku = 'LAP-002';
UPDATE products SET price = 599.00  WHERE sku = 'CPU-001';
UPDATE products SET price = 1099.00 WHERE sku = 'GPU-001';
UPDATE products SET price = 149.00  WHERE sku = 'RAM-001';

-- ----------------------------------------------------------------------------
-- 6. UPDATE with subquery in SET
-- ----------------------------------------------------------------------------
-- Set stock_qty of each product to 2× the number of times it appears in
-- current orders.
UPDATE products p
SET p.stock_qty = (
    SELECT 2 * COUNT(*) FROM order_items oi WHERE oi.product_id = p.id
)
WHERE EXISTS (SELECT 1 FROM order_items oi WHERE oi.product_id = p.id);

SELECT name, stock_qty FROM products WHERE stock_qty <> 0 ORDER BY name LIMIT 10;

-- Restore seed stock values
UPDATE products SET stock_qty = 25 WHERE sku = 'LAP-001';
UPDATE products SET stock_qty = 12 WHERE sku = 'LAP-002';
UPDATE products SET stock_qty = 40 WHERE sku = 'CPU-001';
UPDATE products SET stock_qty = 18 WHERE sku = 'GPU-001';
UPDATE products SET stock_qty = 60 WHERE sku = 'RAM-001';
UPDATE products SET stock_qty = 35 WHERE sku = 'PHN-001';
UPDATE products SET stock_qty = 80 WHERE sku = 'PHN-002';
UPDATE products SET stock_qty = 50 WHERE sku = 'AUD-001';
UPDATE products SET stock_qty = 120 WHERE sku = 'AUD-002';
UPDATE products SET stock_qty = 90 WHERE sku = 'AUD-003';
UPDATE products SET stock_qty = 200 WHERE sku = 'BK-001';
UPDATE products SET stock_qty = 150 WHERE sku = 'BK-002';
UPDATE products SET stock_qty = 8 WHERE sku = 'FRN-001';
UPDATE products SET stock_qty = 75 WHERE sku = 'CW-001';
UPDATE products SET stock_qty = 45 WHERE sku = 'AP-001';
UPDATE products SET stock_qty = 60 WHERE sku = 'AP-002';

-- ----------------------------------------------------------------------------
-- 7. Multi-table UPDATE with JOIN
-- ----------------------------------------------------------------------------
-- Set is_active=0 for customers whose latest order was cancelled.
UPDATE customers c
JOIN orders o ON o.customer_id = c.id
SET c.is_active = 0
WHERE o.status = 'cancelled';

SELECT c.id, c.first_name, c.is_active, o.status
FROM customers c JOIN orders o ON o.customer_id = c.id
WHERE o.status = 'cancelled';

-- Restore (customer 3 had a cancelled order but is normally active)
UPDATE customers SET is_active = 1 WHERE id = 3;

-- ----------------------------------------------------------------------------
-- 8. UPDATE ORDER BY + LIMIT — update only the N oldest/matching rows
-- ----------------------------------------------------------------------------
-- Give a 10% discount to the 3 cheapest products.
UPDATE products
SET price = ROUND(price * 0.90, 2)
ORDER BY price ASC
LIMIT 3;

SELECT name, price FROM products ORDER BY price ASC LIMIT 5;

-- Restore — the 3 cheapest were the book, knife, dress
UPDATE products SET price = 14.99 WHERE sku = 'BK-001';
UPDATE products SET price = 59.99 WHERE sku = 'CW-001';
UPDATE products SET price = 69.99 WHERE sku = 'AP-002';

-- ----------------------------------------------------------------------------
-- 9. UPDATE returns the number of affected rows
-- ----------------------------------------------------------------------------
-- Use ROW_COUNT() immediately after to see how many rows changed.
UPDATE customers SET is_active = 1 WHERE is_active = 0;
SELECT ROW_COUNT() AS rows_updated;
-- (Customer 4 was inactive in seed; ROW_COUNT should report 1, then 0 on
-- subsequent identical runs.)

-- Restore customer 4 to inactive to match the seed
UPDATE customers SET is_active = 0 WHERE id = 4;

-- ----------------------------------------------------------------------------
-- 10. UPDATE inside a transaction (full treatment in 09_advanced_mysql/07)
-- ----------------------------------------------------------------------------
-- Wrap risky UPDATEs in BEGIN...COMMIT so you can ROLLBACK if something
-- looks wrong.
START TRANSACTION;
UPDATE customers SET is_active = 0 WHERE country = 'Japan';
SELECT first_name, is_active FROM customers WHERE country = 'Japan';
ROLLBACK;
SELECT first_name, is_active FROM customers WHERE country = 'Japan';

-- ----------------------------------------------------------------------------
-- 11. Common mistakes
-- ----------------------------------------------------------------------------
-- MISTAKE 1: UPDATE without WHERE → updates every row.
-- MISTAKE 2: Using column alias in SET:
--     UPDATE products SET gross_margin = price - cost;
--   -- fails; SET takes only real columns.
-- MISTAKE 3: Forgetting to commit when inside a manual transaction.

-- ----------------------------------------------------------------------------
-- 12. EXERCISES
-- ----------------------------------------------------------------------------
-- EASY
-- E1.  Update customer 7's `phone` to '555-0199'.
-- E2.  Restore customer 7's phone to NULL.
--
-- MEDIUM
-- E3.  Increase the price of every product in category 7 (Audio) by 8%.
--      Then restore original prices by writing UPDATE statements per SKU.
-- E4.  Set `is_active = 0` for every customer whose email domain is
--      'example.com' AND who lives outside the US.
--
-- HARD
-- E5.  For every product, set `cost = price * 0.7` (so margin is 30%).
--      Wrap in a transaction so you can ROLLBACK after testing.
--
-- EXPERT
-- E6.  Update the `subtotal`, `tax`, and `total` columns of order 3 from
--      the live sum of its order_items (use a subquery in SET). Verify the
--      new totals match the snapshot.
-- ============================================================================

-- End of file 09_update.sql
