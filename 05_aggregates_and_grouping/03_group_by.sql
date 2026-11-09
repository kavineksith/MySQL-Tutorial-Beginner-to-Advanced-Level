-- ============================================================================
-- 03_group_by.sql — GROUP BY: Grouping Rows
-- ============================================================================
-- SKILL LEVEL : Intermediate
-- TOPICS      : GROUP BY single column, multi-column, with WHERE, ALL vs
--               DISTINCT, GROUP BY with expressions, WITH ROLLUP, GROUP BY
--               vs DISTINCT, ONLY_FULL_GROUP_BY mode.
-- ----------------------------------------------------------------------------
-- TEXTBOOK DEPTH
--   GROUP BY partitions rows into groups based on equal values of the
--   grouping columns. Aggregates (COUNT, SUM, AVG, etc.) are then computed
--   per group, producing one output row per group.
--
--   Logical order (write order):
--     FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY → LIMIT
--
--   Critical rules:
--     * Any non-aggregated column in SELECT MUST appear in GROUP BY
--       (when ONLY_FULL_GROUP_BY is enabled, the default in MySQL 8).
--     * WHERE filters BEFORE grouping (cannot use aggregates).
--     * HAVING filters AFTER grouping (CAN use aggregates).
--     * NULLs in GROUP BY columns form their own group.
--     * Multi-column GROUP BY creates a group per unique combination.
-- ============================================================================

USE ecom;

-- ----------------------------------------------------------------------------
-- 1. Single-column GROUP BY
-- ----------------------------------------------------------------------------
SELECT country, COUNT(*) AS customer_count
FROM customers
GROUP BY country
ORDER BY customer_count DESC;

-- ----------------------------------------------------------------------------
-- 2. GROUP BY with multiple aggregates
-- ----------------------------------------------------------------------------
SELECT
    country,
    COUNT(*)            AS customer_count,
    SUM(is_active)      AS active_count,
    MIN(created_at)     AS first_signup,
    MAX(created_at)     AS latest_signup
FROM customers
GROUP BY country
ORDER BY customer_count DESC;

-- ----------------------------------------------------------------------------
-- 3. Multi-column GROUP BY
-- ----------------------------------------------------------------------------
SELECT country, is_active, COUNT(*) AS customer_count
FROM customers
GROUP BY country, is_active
ORDER BY country, is_active DESC;

-- ----------------------------------------------------------------------------
-- 4. GROUP BY with WHERE — WHERE filters BEFORE grouping
-- ----------------------------------------------------------------------------
SELECT
    country,
    COUNT(*) AS active_customer_count
FROM customers
WHERE is_active = 1                -- applied BEFORE GROUP BY
GROUP BY country
ORDER BY active_customer_count DESC;

-- ----------------------------------------------------------------------------
-- 5. GROUP BY with JOIN
-- ----------------------------------------------------------------------------
SELECT
    c.country,
    COUNT(o.id) AS order_count,
    COALESCE(SUM(o.total), 0) AS revenue
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
GROUP BY c.country
ORDER BY revenue DESC;

-- ----------------------------------------------------------------------------
-- 6. GROUP BY with expression
-- ----------------------------------------------------------------------------
-- Group orders by year.
SELECT
    YEAR(order_date) AS order_year,
    COUNT(*)         AS order_count,
    SUM(total)       AS revenue
FROM orders
GROUP BY YEAR(order_date)
ORDER BY order_year;

-- Group by year and month
SELECT
    YEAR(order_date)  AS order_year,
    MONTH(order_date) AS order_month,
    COUNT(*)          AS order_count,
    SUM(total)        AS revenue
FROM orders
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY order_year, order_month;

-- ----------------------------------------------------------------------------
-- 7. WITH ROLLUP — subtotals and grand total
-- ----------------------------------------------------------------------------
-- Adds summary rows for each level of grouping, plus a grand total at the end.
SELECT
    COALESCE(country, 'ALL')     AS country,
    COALESCE(is_active, -1)      AS active_flag,
    COUNT(*)                     AS customer_count
FROM customers
GROUP BY country, is_active WITH ROLLUP
ORDER BY country, active_flag;
-- The rollup rows have NULL in the rolled-up column.

-- ----------------------------------------------------------------------------
-- 8. GROUP BY vs DISTINCT
-- ----------------------------------------------------------------------------
-- DISTINCT removes duplicate ROWS.
-- GROUP BY partitions rows into GROUPS (usually to compute aggregates).
-- They are equivalent when no aggregates are used:
SELECT DISTINCT country FROM customers;
SELECT country FROM customers GROUP BY country;
-- Same result.

-- Prefer GROUP BY when you also want aggregates per group.

-- ----------------------------------------------------------------------------
-- 9. ONLY_FULL_GROUP_BY — the strict mode
-- ----------------------------------------------------------------------------
-- MySQL 8 enables ONLY_FULL_GROUP_BY by default. This rejects SELECT with
-- non-aggregated columns not in GROUP BY.
-- WRONG:
--   SELECT first_name, COUNT(*) FROM customers GROUP BY country;
--   -- ERROR 1140: 'first_name' must appear in GROUP BY

-- Check current sql_mode:
SELECT @@sql_mode;

-- To disable temporarily (NOT recommended — leads to non-deterministic results):
-- SET sql_mode = REPLACE(@@sql_mode, 'ONLY_FULL_GROUP_BY', '');

-- ----------------------------------------------------------------------------
-- 10. GROUP BY on a derived table — useful when computing then grouping
-- ----------------------------------------------------------------------------
SELECT
    category,
    COUNT(*) AS product_count,
    AVG(price) AS avg_price
FROM (
    SELECT
        CASE
            WHEN price < 100             THEN 'budget'
            WHEN price < 500             THEN 'mid'
            WHEN price < 1500            THEN 'premium'
            ELSE 'luxury'
        END AS category,
        price
    FROM products
) AS t
GROUP BY category
ORDER BY avg_price;

-- ----------------------------------------------------------------------------
-- 11. NULL forms its own group
-- ----------------------------------------------------------------------------
SELECT phone, COUNT(*) AS customer_count
FROM customers
GROUP BY phone
ORDER BY phone IS NULL DESC, phone;
-- NULL phone numbers all collapse into one "NULL" group.

-- ----------------------------------------------------------------------------
-- 12. GROUP BY with HAVING (full lesson in 05_having.sql)
-- ----------------------------------------------------------------------------
SELECT
    customer_id,
    COUNT(*) AS order_count,
    SUM(total) AS total_spent
FROM orders
GROUP BY customer_id
HAVING COUNT(*) >= 2
ORDER BY total_spent DESC;

-- ----------------------------------------------------------------------------
-- 13. Realistic reporting query
-- ----------------------------------------------------------------------------
SELECT
    c.country,
    YEAR(o.order_date) AS order_year,
    COUNT(DISTINCT c.id) AS unique_customers,
    COUNT(o.id)         AS order_count,
    SUM(o.total)        AS revenue,
    AVG(o.total)        AS avg_order_value
FROM customers c
JOIN orders o ON o.customer_id = c.id
WHERE o.status NOT IN ('cancelled', 'refunded')
GROUP BY c.country, YEAR(o.order_date)
ORDER BY c.country, order_year;

-- ----------------------------------------------------------------------------
-- 14. EXERCISES
-- ----------------------------------------------------------------------------
-- EASY
-- E1.  Count products per category. Order by category_id.
-- E2.  Count customers per country, showing both active and inactive counts.
--
-- MEDIUM
-- E3.  Compute total revenue per order status, including cancelled/refunded.
-- E4.  Compute total revenue per year per month for 2024.
--
-- HARD
-- E5.  Add a WITH ROLLUP row showing the grand total revenue per year.
-- E6.  Compute the total inventory value (price * stock_qty) per category,
--      ordered by value DESC.
--
-- EXPERT
-- E7.  Find the top-spending customer per country. (Hint: group by country,
--      then use a window function or correlated subquery to pick the max
--      per group.)
-- ============================================================================

-- End of file 03_group_by.sql
