-- ============================================================================
-- 03_select_distinct.sql — DISTINCT: Removing Duplicates
-- ============================================================================
-- SKILL LEVEL : Beginner
-- TOPICS      : SELECT DISTINCT, DISTINCT with multiple columns, DISTINCT vs
--               GROUP BY, performance implications, COUNT(DISTINCT ...).
-- ----------------------------------------------------------------------------
-- TEXTBOOK DEPTH
--   DISTINCT is a row-level deduplicator. After the WHERE and GROUP BY
--   phases run, MySQL scans the projected columns and discards any row whose
--   value tuple exactly matches a row already emitted.
--
--   Important nuances:
--     * DISTINCT applies to the ENTIRE row of selected columns, not to a
--       single column. `SELECT DISTINCT a, b FROM t` returns unique (a,b)
--       pairs, not unique values of a followed by unique values of b.
--     * NULLs are treated as equal under DISTINCT: two NULLs collapse to one.
--     * DISTINCT is logically equivalent to `GROUP BY all-selected-columns`
--       but the optimizer may choose different execution plans.
--     * DISTINCT forces a sort or hash operation — on large result sets it
--       can be expensive. Use COUNT(DISTINCT col) to count unique values
--       without materializing the duplicates.
-- ============================================================================

USE ecom;

-- ----------------------------------------------------------------------------
-- 1. Single-column DISTINCT
-- ----------------------------------------------------------------------------
SELECT DISTINCT country FROM customers ORDER BY country;
-- Returns one row per country: Australia, France, Japan, United Kingdom,
-- United States. Five distinct countries out of 12 customers.

-- ----------------------------------------------------------------------------
-- 2. Multi-column DISTINCT — unique combinations
-- ----------------------------------------------------------------------------
SELECT DISTINCT country, is_active FROM customers ORDER BY country, is_active;
-- Returns unique (country, is_active) pairs. The US has both active=1 and
-- active=0 customers, so it appears twice.

-- ----------------------------------------------------------------------------
-- 3. DISTINCT on expressions
-- ----------------------------------------------------------------------------
SELECT DISTINCT YEAR(order_date) AS order_year
FROM orders
ORDER BY order_year;
-- Returns 2024 and 2025.

-- Distinct price tiers using a CASE expression
SELECT DISTINCT
    CASE
        WHEN price < 100             THEN 'budget'
        WHEN price < 500             THEN 'mid'
        WHEN price < 1500            THEN 'premium'
        ELSE 'luxury'
    END AS price_tier
FROM products
ORDER BY price_tier;

-- ----------------------------------------------------------------------------
-- 4. DISTINCT with computed columns
-- ----------------------------------------------------------------------------
SELECT DISTINCT
    CONCAT(country, '-', UPPER(SUBSTRING(city, 1, 3))) AS country_city_code
FROM customers
ORDER BY country_city_code;

-- ----------------------------------------------------------------------------
-- 5. COUNT(DISTINCT col) — count unique values without showing them
-- ----------------------------------------------------------------------------
SELECT
    COUNT(*)                AS total_customers,
    COUNT(DISTINCT country) AS distinct_countries,
    COUNT(DISTINCT city)    AS distinct_cities
FROM customers;

-- ----------------------------------------------------------------------------
-- 6. DISTINCT inside an aggregate — not the same as DISTINCT outside
-- ----------------------------------------------------------------------------
-- Average price over UNIQUE products (no duplicates to remove here, but the
-- pattern matters when joins fan out rows).
SELECT AVG(DISTINCT price) AS avg_unique_price FROM products;

-- Same idea with SUM
SELECT SUM(DISTINCT stock_qty) AS sum_unique_stock FROM products;

-- ----------------------------------------------------------------------------
-- 7. DISTINCT vs GROUP BY — when to use which
-- ----------------------------------------------------------------------------
-- These two queries are logically equivalent:
SELECT DISTINCT country FROM customers;

SELECT country FROM customers GROUP BY country;

-- RULE OF THUMB:
--   * Use DISTINCT when you want unique rows from a query result.
--   * Use GROUP BY when you also want aggregates per group.
-- They can be combined:
SELECT country, COUNT(*) AS customer_count
FROM customers
GROUP BY country;        -- already unique, no DISTINCT needed.

-- ----------------------------------------------------------------------------
-- 8. DISTINCT with JOIN — beware of fan-out
-- ----------------------------------------------------------------------------
-- If a join multiplies rows (e.g. customer → many orders), DISTINCT can
-- recover uniqueness, but it is often the wrong tool. Prefer EXISTS or a
-- subquery. Example — customers who placed at least one order:

-- Using DISTINCT (works, but forces a sort):
SELECT DISTINCT c.id, c.first_name, c.last_name
FROM customers c
JOIN orders o ON o.customer_id = c.id;

-- Using EXISTS (often faster — no deduplication sort needed):
SELECT c.id, c.first_name, c.last_name
FROM customers c
WHERE EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.id);

-- ----------------------------------------------------------------------------
-- 9. DISTINCT and NULL
-- ----------------------------------------------------------------------------
-- NULLs are treated as equal under DISTINCT.
CREATE TEMPORARY TABLE tmp_distinct_demo (val INT);
INSERT INTO tmp_distinct_demo VALUES (1), (2), (NULL), (NULL), (1), (2);

SELECT DISTINCT val FROM tmp_distinct_demo ORDER BY val;
-- Returns: NULL, 1, 2  (one NULL, not two)

DROP TEMPORARY TABLE tmp_distinct_demo;

-- ----------------------------------------------------------------------------
-- 10. Common mistakes
-- ----------------------------------------------------------------------------
-- MISTAKE: expecting DISTINCT to deduplicate only the first column.
--   SELECT DISTINCT a, b FROM t   -- returns unique (a,b) pairs, NOT unique a's
-- Each pair (1,1), (1,2), (1,3) is distinct — three rows even though a=1.

-- MISTAKE: putting DISTINCT inside COUNT(*) — that's meaningless.
--   SELECT COUNT(DISTINCT *) ...   -- SYNTAX ERROR

-- ----------------------------------------------------------------------------
-- 11. EXERCISES
-- ----------------------------------------------------------------------------
-- EASY
-- E1.  Return the distinct list of order statuses from the `orders` table.
-- E2.  Return the distinct list of product slugs that have ever appeared in
--      an order (use order_items JOIN products).
--
-- MEDIUM
-- E3.  Count how many distinct customers have placed at least one order.
-- E4.  Return distinct (status, order_year) pairs from the orders table.
--
-- HARD
-- E5.  Find distinct countries of customers whose orders have a `total`
--      value over $1000.
--
-- EXPERT
-- E6.  Without using DISTINCT, write a GROUP BY query that returns the same
--      result set as:  SELECT DISTINCT country, city FROM customers;
--      Verify both return identical rows.
-- ============================================================================

-- End of file 03_select_distinct.sql
