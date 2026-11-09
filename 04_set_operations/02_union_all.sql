-- ============================================================================
-- 02_union_all.sql — UNION ALL (focus on performance and use cases)
-- ============================================================================
-- SKILL LEVEL : Intermediate
-- TOPICS      : UNION ALL vs UNION, performance, when ALL is the right
--               choice, building summary rollups, multi-source combining.
-- ============================================================================

USE ecom;

-- ----------------------------------------------------------------------------
-- 1. UNION ALL preserves duplicates — no sort/hash for dedup
-- ----------------------------------------------------------------------------
-- Use UNION ALL when you KNOW there are no duplicates between the branches,
-- or when you WANT duplicates preserved.
SELECT 'customer' AS role, first_name FROM customers
UNION ALL
SELECT 'employee', first_name FROM employees;
-- 12 + 9 = 21 rows. UNION would have collapsed duplicate first_names.

-- ----------------------------------------------------------------------------
-- 2. UNION ALL for grand-total row
-- ----------------------------------------------------------------------------
SELECT
    COALESCE(status, 'ALL') AS status,
    COUNT(*)                AS order_count,
    SUM(total)              AS revenue
FROM orders
GROUP BY status WITH ROLLUP;

-- Equivalent using UNION ALL (more verbose but more flexible):
SELECT status, COUNT(*) AS order_count, SUM(total) AS revenue
FROM orders GROUP BY status
UNION ALL
SELECT 'ALL', COUNT(*), SUM(total) FROM orders
ORDER BY order_count DESC;

-- ----------------------------------------------------------------------------
-- 3. UNION ALL to combine identical-structure tables
-- ----------------------------------------------------------------------------
-- Suppose we had `orders_archive` for old years. Combine for a unified view:
-- SELECT * FROM orders WHERE YEAR(order_date) = 2024
-- UNION ALL
-- SELECT * FROM orders_archive WHERE YEAR(order_date) < 2024
-- ORDER BY order_date;

-- ----------------------------------------------------------------------------
-- 4. UNION ALL to build a synthetic "rows" table
-- ----------------------------------------------------------------------------
-- Generate a series of numbers 1..10 without a numbers table.
SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
UNION ALL SELECT 9 UNION ALL SELECT 10;

-- Modern alternative: a recursive CTE (MySQL 8.0+ (SQL:2023 compatible where noted)):
WITH RECURSIVE nums(n) AS (
    SELECT 1
    UNION ALL
    SELECT n + 1 FROM nums WHERE n < 10
)
SELECT n FROM nums;

-- ----------------------------------------------------------------------------
-- 5. UNION ALL to combine multiple aggregations
-- ----------------------------------------------------------------------------
-- Per-status revenue AND per-year revenue in a single result set with a
-- dimension label.
SELECT 'by_status' AS dimension, status AS bucket, SUM(total) AS revenue
FROM orders GROUP BY status
UNION ALL
SELECT 'by_year', CAST(YEAR(order_date) AS CHAR), SUM(total)
FROM orders GROUP BY YEAR(order_date)
ORDER BY dimension, bucket;

-- ----------------------------------------------------------------------------
-- 6. UNION ALL with tables of slightly different shape — pad with NULLs
-- ----------------------------------------------------------------------------
-- Combine customer info with employee info, padding missing columns with NULL.
SELECT
    id,
    first_name,
    last_name,
    email,
    NULL      AS title,
    'customer' AS kind
FROM customers
UNION ALL
SELECT
    id,
    first_name,
    last_name,
    email,
    title,
    'employee'
FROM employees
ORDER BY kind, last_name, first_name
LIMIT 10;

-- ----------------------------------------------------------------------------
-- 7. UNION ALL for "Top N + Other" rollups
-- ----------------------------------------------------------------------------
-- Show top 3 product categories by revenue + an "Other" rollup row.
SELECT category_name, revenue FROM (
    SELECT cat.name AS category_name, SUM(oi.line_total) AS revenue
    FROM order_items oi
    JOIN products p     ON p.id  = oi.product_id
    JOIN categories cat ON cat.id = p.category_id
    GROUP BY cat.name
    ORDER BY revenue DESC
    LIMIT 3
) AS top3
UNION ALL
SELECT 'Other', SUM(revenue) FROM (
    SELECT cat.name AS category_name, SUM(oi.line_total) AS revenue
    FROM order_items oi
    JOIN products p     ON p.id  = oi.product_id
    JOIN categories cat ON cat.id = p.category_id
    GROUP BY cat.name
    ORDER BY revenue DESC
    LIMIT 3 OFFSET 3
) AS rest
ORDER BY revenue DESC;

-- ----------------------------------------------------------------------------
-- 8. EXERCISES
-- ----------------------------------------------------------------------------
-- EASY
-- E1.  Use UNION ALL to count rows in customers, products, and orders.
-- E2.  Use UNION ALL to combine the names of customers and employees into
--      one column.
--
-- MEDIUM
-- E3.  Add a grand-total row to a per-status revenue report using UNION ALL.
-- E4.  Generate the numbers 1 through 5 using UNION ALL.
--
-- HARD
-- E5.  Build a "Top 3 + Other" report showing the top 3 product categories
--      by revenue and a single "Other" row for the rest.
--
-- EXPERT
-- E6.  Explain in a comment why UNION ALL is faster than UNION, and when
--      each is appropriate. Provide an example where UNION ALL would
--      produce wrong results (i.e., where you actually need UNION).
-- ============================================================================

-- End of file 02_union_all.sql
