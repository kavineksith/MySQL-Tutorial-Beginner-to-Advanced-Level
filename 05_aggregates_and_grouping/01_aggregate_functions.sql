-- ============================================================================
-- 01_aggregate_functions.sql — Aggregate Functions Overview
-- ============================================================================
-- SKILL LEVEL : Beginner→Intermediate
-- TOPICS      : COUNT, SUM, AVG, MIN, MAX, GROUP_CONCAT, BIT_AND/OR/XOR,
--               STD/STDDEV/VARIANCE, JSON_ARRAYAGG / JSON_OBJECTAGG.
-- ----------------------------------------------------------------------------
-- TEXTBOOK DEPTH
--   An aggregate function reduces many rows to one value. It is the
--   fundamental operation behind reporting, dashboards, and analytics.
--
--   General rules:
--     * Aggregates ignore NULLs (except COUNT(*)).
--     * COUNT(*) counts rows. COUNT(col) counts non-NULL col values.
--     * COUNT(DISTINCT col) counts unique non-NULL values.
--     * SUM/AVG/MIN/MAX over an empty set return NULL. COUNT returns 0.
--     * Aggregates cannot be nested: SUM(COUNT(*)) is illegal.
--     * Combining aggregates with non-aggregate columns requires GROUP BY.
--
--   MySQL-specific aggregates:
--     GROUP_CONCAT(expr SEPARATOR sep)   — concatenate values from a group.
--     BIT_AND / BIT_OR / BIT_XOR         — bitwise aggregates.
--     JSON_ARRAYAGG / JSON_OBJECTAGG     — build JSON arrays/objects.
--     STD, STDDEV, STDDEV_POP, STDDEV_SAMP, VAR_POP, VAR_SAMP, VARIANCE —
--         statistical aggregates.
-- ============================================================================

USE ecom;

-- ----------------------------------------------------------------------------
-- 1. COUNT — three flavors
-- ----------------------------------------------------------------------------
SELECT
    COUNT(*)             AS total_rows,
    COUNT(phone)         AS non_null_phones,
    COUNT(DISTINCT country) AS distinct_countries
FROM customers;

-- COUNT(*) with a WHERE filter
SELECT COUNT(*) AS active_us_customers
FROM customers
WHERE is_active = 1 AND country = 'United States';

-- ----------------------------------------------------------------------------
-- 2. SUM — total of a numeric column
-- ----------------------------------------------------------------------------
SELECT
    SUM(price)      AS total_price_value,
    SUM(stock_qty)  AS total_stock_units,
    SUM(price * stock_qty) AS total_inventory_value
FROM products;

-- SUM with WHERE
SELECT SUM(total) AS revenue_2024
FROM orders
WHERE YEAR(order_date) = 2024 AND status NOT IN ('cancelled', 'refunded');

-- SUM(DISTINCT col) — sum of unique values
SELECT SUM(DISTINCT price) AS sum_unique_prices FROM products;

-- ----------------------------------------------------------------------------
-- 3. AVG — average of non-NULL values
-- ----------------------------------------------------------------------------
SELECT
    AVG(price)            AS avg_price,
    AVG(stock_qty)        AS avg_stock,
    AVG(weight_kg)        AS avg_weight_ignoring_nulls
FROM products;

-- AVG with WHERE
SELECT AVG(total) AS avg_order_total
FROM orders
WHERE status = 'delivered';

-- ----------------------------------------------------------------------------
-- 4. MIN and MAX
-- ----------------------------------------------------------------------------
SELECT
    MIN(price)      AS cheapest,
    MAX(price)      AS most_expensive,
    MIN(created_at) AS first_customer,
    MAX(created_at) AS newest_customer,
    MIN(name)       AS first_alphabetically,
    MAX(name)       AS last_alphabetically
FROM products;

-- MIN/MAX on strings returns the lexicographic extreme.
SELECT MIN(last_name) AS first_alpha, MAX(last_name) AS last_alpha FROM customers;

-- ----------------------------------------------------------------------------
-- 5. GROUP_CONCAT — MySQL-specific value concatenation
-- ----------------------------------------------------------------------------
SELECT
    GROUP_CONCAT(name SEPARATOR ', ') AS all_product_names
FROM products;

-- With ordering and a limit:
SELECT
    GROUP_CONCAT(DISTINCT country ORDER BY country SEPARATOR ', ') AS all_countries
FROM customers;

-- Per-group GROUP_CONCAT (requires GROUP BY):
SELECT
    c.id,
    c.first_name,
    GROUP_CONCAT(o.id ORDER BY o.id SEPARATOR ',') AS order_ids
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
GROUP BY c.id, c.first_name
LIMIT 6;

-- ----------------------------------------------------------------------------
-- 6. STDDEV, VARIANCE — statistical aggregates
-- ----------------------------------------------------------------------------
SELECT
    STDDEV(price)    AS price_std_dev,
    VARIANCE(price)  AS price_variance,
    STDDEV_POP(price) AS population_std_dev,
    STDDEV_SAMP(price) AS sample_std_dev
FROM products;

-- ----------------------------------------------------------------------------
-- 7. BIT aggregates
-- ----------------------------------------------------------------------------
-- Useful for permission/aggregation flags.
CREATE TEMPORARY TABLE tmp_perms (user_id INT, perm INT);
INSERT INTO tmp_perms VALUES (1, 1), (1, 2), (1, 4), (2, 1), (2, 8);

SELECT
    user_id,
    BIT_OR(perm)   AS combined_perms,  -- union of all perms
    BIT_AND(perm)  AS common_perms     -- intersection of perms
FROM tmp_perms
GROUP BY user_id;

DROP TEMPORARY TABLE tmp_perms;

-- ----------------------------------------------------------------------------
-- 8. JSON_ARRAYAGG / JSON_OBJECTAGG (MySQL 8.0+ (SQL:2023 compatible where noted))
-- ----------------------------------------------------------------------------
-- Build JSON arrays/objects from row sets.
SELECT
    c.id,
    c.first_name,
    JSON_ARRAYAGG(o.id) AS order_ids_array
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
GROUP BY c.id, c.first_name
LIMIT 6;

-- JSON_OBJECTAGG(key_expr, value_expr)
SELECT
    JSON_OBJECTAGG(sku, price) AS sku_to_price_map
FROM products;

-- ----------------------------------------------------------------------------
-- 9. Aggregate over empty set — NULL vs 0
-- ----------------------------------------------------------------------------
SELECT
    COUNT(*)   AS count_empty,    -- 0
    SUM(price) AS sum_empty,      -- NULL
    AVG(price) AS avg_empty,      -- NULL
    MAX(price) AS max_empty       -- NULL
FROM products
WHERE 1 = 0;                       -- impossible predicate → empty set

-- Use COALESCE to return 0 instead of NULL:
SELECT COALESCE(SUM(price), 0) AS sum_or_zero
FROM products
WHERE 1 = 0;

-- ----------------------------------------------------------------------------
-- 10. Aggregates ignore NULLs (except COUNT(*))
-- ----------------------------------------------------------------------------
CREATE TEMPORARY TABLE tmp_demo (id INT, val INT);
INSERT INTO tmp_demo VALUES (1, 10), (2, NULL), (3, 20), (4, NULL);

SELECT
    COUNT(*)       AS rows_total,        -- 4
    COUNT(val)     AS rows_with_value,   -- 2
    SUM(val)       AS sum_values,        -- 30 (NULLs ignored)
    AVG(val)       AS avg_values,        -- 15 (30/2, NOT 30/4)
    MIN(val)       AS min_value,         -- 10
    MAX(val)       AS max_value;         -- 20

DROP TEMPORARY TABLE tmp_demo;

-- ----------------------------------------------------------------------------
-- 11. Combining aggregates — single-row "dashboard" query
-- ----------------------------------------------------------------------------
SELECT
    COUNT(*)                                AS total_customers,
    SUM(is_active)                          AS active_count,
    COUNT(DISTINCT country)                 AS distinct_countries,
    MIN(created_at)                         AS first_signup,
    MAX(created_at)                         AS latest_signup
FROM customers;

-- ----------------------------------------------------------------------------
-- 12. EXERCISES
-- ----------------------------------------------------------------------------
-- EASY
-- E1.  Count the number of products in category 7 (Audio).
-- E2.  Compute the average price of products in category 8 (Laptops).
--
-- MEDIUM
-- E3.  Compute total revenue (SUM of total) for orders with status
--      'delivered' OR 'shipped' in 2024.
-- E4.  Use GROUP_CONCAT to return a comma-separated list of every product
--      SKU, ordered alphabetically.
--
-- HARD
-- E5.  For every customer, return their first_name, last_name, total number
--      of orders, total spend, and average order value. Use LEFT JOIN so
--      customers without orders still appear (with zeros via COALESCE).
--
-- EXPERT
-- E6.  Use JSON_OBJECTAGG to build a JSON object mapping each customer id
--      to their full name (first + last). Verify the output is valid JSON.
-- ============================================================================

-- End of file 01_aggregate_functions.sql
