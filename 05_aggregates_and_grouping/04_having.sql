-- ============================================================================
-- 04_having.sql — HAVING: Filtering Groups
-- ============================================================================
-- SKILL LEVEL : Intermediate
-- TOPICS      : HAVING vs WHERE, HAVING with aggregates, HAVING without
--               GROUP BY, multi-condition HAVING, HAVING with aliases.
-- ----------------------------------------------------------------------------
-- TEXTBOOK DEPTH
--   HAVING filters GROUPS after GROUP BY runs. It is the only clause that
--   can reference aggregates (COUNT, SUM, AVG, MIN, MAX).
--
--   WHERE  vs  HAVING  — the canonical distinction:
--     * WHERE   filters ROWS BEFORE grouping. Cannot use aggregates.
--     * HAVING  filters GROUPS AFTER grouping. Can use aggregates.
--
--   Logical order of execution:
--     FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY → LIMIT
--
--   Common patterns:
--     HAVING COUNT(*) > 5         — groups with more than 5 rows
--     HAVING SUM(total) > 1000    — groups with sum over threshold
--     HAVING AVG(price) < 100     — groups with average below threshold
--
--   MySQL extensions:
--     * HAVING can use SELECT aliases (e.g. HAVING avg_price > 100).
--     * HAVING works without GROUP BY (treats whole table as one group).
-- ============================================================================

USE ecom;

-- ----------------------------------------------------------------------------
-- 1. HAVING with COUNT
-- ----------------------------------------------------------------------------
SELECT customer_id, COUNT(*) AS order_count
FROM orders
GROUP BY customer_id
HAVING COUNT(*) >= 2
ORDER BY order_count DESC;

-- ----------------------------------------------------------------------------
-- 2. HAVING with SUM
-- ----------------------------------------------------------------------------
SELECT customer_id, SUM(total) AS total_spent
FROM orders
WHERE status NOT IN ('cancelled', 'refunded')
GROUP BY customer_id
HAVING SUM(total) > 500
ORDER BY total_spent DESC;

-- ----------------------------------------------------------------------------
-- 3. HAVING with AVG
-- ----------------------------------------------------------------------------
SELECT category_id, AVG(price) AS avg_price
FROM products
GROUP BY category_id
HAVING AVG(price) > 200
ORDER BY avg_price DESC;

-- ----------------------------------------------------------------------------
-- 4. HAVING with multiple conditions (AND/OR)
-- ----------------------------------------------------------------------------
SELECT
    customer_id,
    COUNT(*)      AS order_count,
    SUM(total)    AS total_spent,
    AVG(total)    AS avg_order_value
FROM orders
GROUP BY customer_id
HAVING COUNT(*) >= 1
   AND SUM(total) > 500
   AND AVG(total) > 200
ORDER BY total_spent DESC;

-- ----------------------------------------------------------------------------
-- 5. WHERE + HAVING together — the canonical pattern
-- ----------------------------------------------------------------------------
-- WHERE filters rows before grouping.
-- HAVING filters groups after grouping.
SELECT
    customer_id,
    COUNT(*)    AS paid_order_count,
    SUM(total)  AS paid_revenue
FROM orders
WHERE status IN ('paid', 'shipped', 'delivered')   -- exclude cancelled BEFORE grouping
GROUP BY customer_id
HAVING SUM(total) > 100                            -- only customers who spent > 100
ORDER BY paid_revenue DESC;

-- ----------------------------------------------------------------------------
-- 6. HAVING with alias (MySQL extension)
-- ----------------------------------------------------------------------------
-- MySQL allows the alias `avg_price` in HAVING. Other RDBMSs may not.
SELECT
    category_id,
    AVG(price) AS avg_price
FROM products
GROUP BY category_id
HAVING avg_price > 200          -- alias used here
ORDER BY avg_price DESC;

-- For portability, repeat the aggregate in HAVING:
SELECT
    category_id,
    AVG(price) AS avg_price
FROM products
GROUP BY category_id
HAVING AVG(price) > 200
ORDER BY avg_price DESC;

-- ----------------------------------------------------------------------------
-- 7. HAVING without GROUP BY — whole table as one group
-- ----------------------------------------------------------------------------
-- Useful for sanity checks: "does any data fail this rule?"
SELECT COUNT(*) AS suspicious_rows
FROM products
HAVING COUNT(*) > 0
   AND MIN(price) <= 0;
-- Returns one row with the count if any product has price <= 0, otherwise
-- returns one row with COUNT(*) for the whole table.

-- A more practical use: report total only if it exceeds a threshold.
SELECT SUM(total) AS grand_total_revenue
FROM orders
WHERE status NOT IN ('cancelled', 'refunded')
HAVING SUM(total) > 5000;

-- ----------------------------------------------------------------------------
-- 8. HAVING with subquery
-- ----------------------------------------------------------------------------
-- Find customers whose total spend exceeds the average customer spend.
SELECT
    customer_id,
    SUM(total) AS total_spent
FROM orders
WHERE status NOT IN ('cancelled', 'refunded')
GROUP BY customer_id
HAVING SUM(total) > (SELECT AVG(cust_total) FROM (
    SELECT SUM(total) AS cust_total
    FROM orders
    WHERE status NOT IN ('cancelled', 'refunded')
    GROUP BY customer_id
) AS avg_tbl)
ORDER BY total_spent DESC;

-- ----------------------------------------------------------------------------
-- 9. HAVING with GROUP_CONCAT
-- ----------------------------------------------------------------------------
SELECT
    customer_id,
    GROUP_CONCAT(id ORDER BY id) AS order_ids
FROM orders
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- ----------------------------------------------------------------------------
-- 10. HAVING with date functions
-- ----------------------------------------------------------------------------
-- Customers who placed at least 2 orders in the same year.
SELECT
    customer_id,
    YEAR(order_date) AS order_year,
    COUNT(*) AS orders_that_year
FROM orders
GROUP BY customer_id, YEAR(order_date)
HAVING COUNT(*) >= 2
ORDER BY order_year, customer_id;

-- ----------------------------------------------------------------------------
-- 11. Compare WHERE vs HAVING side-by-side
-- ----------------------------------------------------------------------------
-- Question: "Which categories have more than 5 active products priced over $50?"
-- WHERE: filter to active products over $50 BEFORE grouping.
-- HAVING: keep only groups with more than 5 such products.

SELECT
    category_id,
    COUNT(*) AS premium_active_count
FROM products
WHERE is_active = 1
  AND price > 50
GROUP BY category_id
HAVING COUNT(*) > 0           -- in our seed data most categories have <5
ORDER BY premium_active_count DESC;

-- ----------------------------------------------------------------------------
-- 12. EXERCISES
-- ----------------------------------------------------------------------------
-- EASY
-- E1.  Find categories with more than 2 products.
-- E2.  Find customers who placed more than 1 order.
--
-- MEDIUM
-- E3.  Find products that have been reviewed at least 2 times.
-- E4.  Find customers whose total spend (excluding cancelled) exceeds $1000.
--
-- HARD
-- E5.  Find product categories whose average price exceeds the overall
--      average product price.
-- E6.  Find customers whose average order value is higher than the overall
--      average order value.
--
-- EXPERT
-- E7.  Explain in a comment why you cannot use WHERE COUNT(*) > 5 and what
--      the correct alternative is. Provide an example query.
-- ============================================================================

-- End of file 04_having.sql
