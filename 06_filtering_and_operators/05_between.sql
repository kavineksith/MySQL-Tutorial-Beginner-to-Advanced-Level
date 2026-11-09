-- ============================================================================
-- 05_between.sql — BETWEEN Operator
-- ============================================================================
-- SKILL LEVEL : Beginner
-- TOPICS      : BETWEEN (inclusive), NOT BETWEEN, with numbers/dates/strings,
--               boundary precision for TIMESTAMP, NOT BETWEEN NULL behavior.
-- ----------------------------------------------------------------------------
-- TEXTBOOK DEPTH
--   BETWEEN is shorthand for `>= low AND <= high`. The endpoints are
--   INCLUSIVE — a frequent source of off-by-one bugs.
--
--   Equivalent forms:
--     col BETWEEN a AND b   ≡   col >= a AND col <= b
--     col NOT BETWEEN a AND b ≡ col < a OR col > b
--
--   Common pitfalls:
--     * Date precision: `BETWEEN '2024-01-01' AND '2024-01-31'` against a
--       DATETIME column misses anything on 2024-01-31 after 00:00:00.
--       Use `>= '2024-01-01' AND < '2024-02-01'` instead.
--     * NOT BETWEEN excludes NULLs — same trap as NOT IN.
--     * String BETWEEN is collation-dependent and rarely useful.
-- ============================================================================

USE ecom;

-- ----------------------------------------------------------------------------
-- 1. Numeric BETWEEN (inclusive)
-- ----------------------------------------------------------------------------
SELECT name, price
FROM products
WHERE price BETWEEN 100 AND 500
ORDER BY price;

-- Equivalent explicit form:
SELECT name, price
FROM products
WHERE price >= 100 AND price <= 500
ORDER BY price;

-- ----------------------------------------------------------------------------
-- 2. NOT BETWEEN
-- ----------------------------------------------------------------------------
SELECT name, price
FROM products
WHERE price NOT BETWEEN 100 AND 500
ORDER BY price;

-- ----------------------------------------------------------------------------
-- 3. Date BETWEEN — boundary trap
-- ----------------------------------------------------------------------------
-- WRONG for TIMESTAMP/DATETIME columns: misses 2024-01-31 00:00:01 onwards.
SELECT id, order_date, total
FROM orders
WHERE order_date BETWEEN '2024-01-01' AND '2024-01-31'
ORDER BY order_date;

-- CORRECT: use >= and < with the next-day boundary.
SELECT id, order_date, total
FROM orders
WHERE order_date >= '2024-01-01' AND order_date < '2024-02-01'
ORDER BY order_date;

-- For DATE columns (no time component), BETWEEN is fine:
SELECT id, order_date, total
FROM orders
WHERE DATE(order_date) BETWEEN '2024-01-01' AND '2024-01-31';

-- ----------------------------------------------------------------------------
-- 4. Date range across months
-- ----------------------------------------------------------------------------
SELECT id, order_date, status
FROM orders
WHERE order_date BETWEEN '2024-04-01' AND '2024-06-30 23:59:59'
ORDER BY order_date;

-- Cleaner with >= and <:
SELECT id, order_date, status
FROM orders
WHERE order_date >= '2024-04-01' AND order_date < '2024-07-01'
ORDER BY order_date;

-- ----------------------------------------------------------------------------
-- 5. String BETWEEN (rarely useful)
-- ----------------------------------------------------------------------------
-- Names alphabetically between 'A' and 'F' (inclusive, case-insensitive
-- under default collation).
SELECT first_name, last_name
FROM customers
WHERE last_name BETWEEN 'A' AND 'F'
ORDER BY last_name;

-- ----------------------------------------------------------------------------
-- 6. BETWEEN with expressions
-- ----------------------------------------------------------------------------
SELECT name, price, stock_qty
FROM products
WHERE price * stock_qty BETWEEN 1000 AND 50000
ORDER BY price * stock_qty DESC;

-- ----------------------------------------------------------------------------
-- 7. NOT BETWEEN excludes NULLs
-- ----------------------------------------------------------------------------
-- Products whose weight is NOT between 0.1 and 1.0. NULL weights are
-- EXCLUDED from the result.
SELECT name, weight_kg
FROM products
WHERE weight_kg NOT BETWEEN 0.1 AND 1.0
ORDER BY weight_kg;
-- NULL weight rows are missing from result!

-- To include NULLs explicitly:
SELECT name, weight_kg
FROM products
WHERE weight_kg IS NULL
   OR weight_kg NOT BETWEEN 0.1 AND 1.0
ORDER BY weight_kg;

-- ----------------------------------------------------------------------------
-- 8. BETWEEN on a computed column using a subquery
-- ----------------------------------------------------------------------------
-- Products whose price is within 10% of the average.
SELECT name, price
FROM products
WHERE price BETWEEN
    (SELECT AVG(price) * 0.90 FROM products)
  AND
    (SELECT AVG(price) * 1.10 FROM products)
ORDER BY price;

-- ----------------------------------------------------------------------------
-- 9. BETWEEN with columns
-- ----------------------------------------------------------------------------
-- Products whose `cost` is between 50% and 80% of `price` (i.e. reasonable
-- margin).
SELECT name, price, cost
FROM products
WHERE cost BETWEEN price * 0.50 AND price * 0.80
ORDER BY price;

-- ----------------------------------------------------------------------------
-- 10. EXERCISES
-- ----------------------------------------------------------------------------
-- EASY
-- E1.  Find products priced between 50 and 200.
-- E2.  Find orders placed between 2024-03-01 and 2024-05-31 (use the
--      boundary-safe >= / < form).
--
-- MEDIUM
-- E3.  Find customers whose birth_date is between 1980-01-01 and 1995-12-31.
-- E4.  Find products whose stock value (price * stock_qty) is between 1000
--      and 10000.
--
-- HARD
-- E5.  Find orders whose `total` is within 20% of the average order total.
--
-- EXPERT
-- E6.  Explain in a comment why `WHERE order_date BETWEEN '2024-01-01' AND
--      '2024-01-31'` may miss rows when `order_date` is a TIMESTAMP/DATETIME
--      column, even when those rows are clearly in January. Provide the
--      recommended alternative pattern.
-- ============================================================================

-- End of file 05_between.sql
