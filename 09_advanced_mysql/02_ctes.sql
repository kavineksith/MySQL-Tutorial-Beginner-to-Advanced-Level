-- ============================================================================
-- 02_ctes.sql — Common Table Expressions (CTEs)
-- ============================================================================
-- SKILL LEVEL : Advanced
-- TOPICS      : WITH clause, single and multiple CTEs, CTE vs subquery vs
--               view, CTE in INSERT/UPDATE/DELETE, performance notes.
-- ----------------------------------------------------------------------------
-- TEXTBOOK DEPTH
--   A CTE is a named temporary result set that exists for the duration of
--   a single statement. Syntax:
--
--     WITH cte_name [(col1, col2, ...)] AS (
--         SELECT ...
--     )
--     SELECT ... FROM cte_name;
--
--   Multiple CTEs comma-separated:
--     WITH a AS (...), b AS (...) SELECT ... FROM a JOIN b;
--
--   Benefits over inline subqueries:
--     1. READABILITY — give a name to a complex query, then reference it.
--     2. REUSE — reference the same CTE multiple times in one statement.
--     3. RECURSION — see 03_recursive_ctes.sql.
--
--   CTEs are NOT materialized by default in MySQL — the optimizer may
--   inline them (merge into the outer query) or materialize them, picking
--   whichever is cheaper. You can hint: WITH cte AS (...) [[NOT] MATERIALIZED].
-- ============================================================================

USE ecom;

-- ----------------------------------------------------------------------------
-- 1. Simple CTE — replace an inline subquery
-- ----------------------------------------------------------------------------
WITH customer_totals AS (
    SELECT
        customer_id,
        COUNT(*)   AS order_count,
        SUM(total) AS total_spent
    FROM orders
    WHERE status NOT IN ('cancelled', 'refunded')
    GROUP BY customer_id
)
SELECT
    c.first_name,
    c.last_name,
    ct.order_count,
    ct.total_spent
FROM customers c
JOIN customer_totals ct ON ct.customer_id = c.id
ORDER BY ct.total_spent DESC;

-- ----------------------------------------------------------------------------
-- 2. Multiple CTEs in one statement
-- ----------------------------------------------------------------------------
WITH
order_summary AS (
    SELECT customer_id, COUNT(*) AS order_count, SUM(total) AS total_spent
    FROM orders
    WHERE status NOT IN ('cancelled', 'refunded')
    GROUP BY customer_id
),
review_summary AS (
    SELECT customer_id, COUNT(*) AS review_count, AVG(rating) AS avg_rating
    FROM reviews
    GROUP BY customer_id
)
SELECT
    c.first_name,
    c.last_name,
    COALESCE(os.order_count, 0)  AS order_count,
    COALESCE(os.total_spent, 0)  AS total_spent,
    COALESCE(rs.review_count, 0) AS review_count,
    ROUND(rs.avg_rating, 2)      AS avg_rating_given
FROM customers c
LEFT JOIN order_summary  os ON os.customer_id = c.id
LEFT JOIN review_summary rs ON rs.customer_id = c.id
ORDER BY total_spent DESC;

-- ----------------------------------------------------------------------------
-- 3. CTE referenced multiple times
-- ----------------------------------------------------------------------------
WITH avg_order AS (
    SELECT AVG(total) AS overall_avg FROM orders
)
SELECT
    o.customer_id,
    o.id AS order_id,
    o.total,
    (SELECT overall_avg FROM avg_order) AS overall_avg,
    ROUND(o.total - (SELECT overall_avg FROM avg_order), 2) AS diff_from_avg
FROM orders o
ORDER BY diff_from_avg DESC
LIMIT 5;

-- ----------------------------------------------------------------------------
-- 4. CTE with explicit column names
-- ----------------------------------------------------------------------------
WITH cust_summary (cid, name, count, spend) AS (
    SELECT
        c.id,
        CONCAT(c.first_name, ' ', c.last_name),
        COUNT(o.id),
        COALESCE(SUM(o.total), 0)
    FROM customers c
    LEFT JOIN orders o ON o.customer_id = c.id
    GROUP BY c.id, c.first_name, c.last_name
)
SELECT cid, name, count, spend
FROM cust_summary
ORDER BY spend DESC
LIMIT 5;

-- ----------------------------------------------------------------------------
-- 5. CTE in INSERT ... SELECT
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS tmp_customer_summary;
CREATE TABLE tmp_customer_summary (
    customer_id BIGINT PRIMARY KEY,
    name VARCHAR(120),
    total_spent DECIMAL(10,2)
);

WITH spend AS (
    SELECT customer_id, SUM(total) AS total_spent
    FROM orders
    WHERE status NOT IN ('cancelled', 'refunded')
    GROUP BY customer_id
)
INSERT INTO tmp_customer_summary (customer_id, name, total_spent)
SELECT c.id, CONCAT(c.first_name, ' ', c.last_name), spend.total_spent
FROM customers c
JOIN spend ON spend.customer_id = c.id;

SELECT * FROM tmp_customer_summary ORDER BY total_spent DESC LIMIT 5;

DROP TABLE tmp_customer_summary;

-- ----------------------------------------------------------------------------
-- 6. CTE in UPDATE (via derived table join)
-- ----------------------------------------------------------------------------
-- Mark customers as inactive if their last order was cancelled.
-- Use a CTE to compute the latest status per customer, then JOIN in UPDATE.

-- Note: MySQL UPDATE doesn't directly accept WITH, so we use a derived
-- table or temp table.
DROP TEMPORARY TABLE IF EXISTS tmp_last_status;
CREATE TEMPORARY TABLE tmp_last_status AS
WITH latest AS (
    SELECT customer_id, status,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date DESC) AS rn
    FROM orders
)
SELECT customer_id, status FROM latest WHERE rn = 1;

START TRANSACTION;
UPDATE customers c
JOIN tmp_last_status t ON t.customer_id = c.id
SET c.is_active = 0
WHERE t.status = 'cancelled';

SELECT c.id, c.first_name, c.is_active FROM customers c
JOIN tmp_last_status t ON t.customer_id = c.id WHERE t.status = 'cancelled';
ROLLBACK;

DROP TEMPORARY TABLE tmp_last_status;

-- ----------------------------------------------------------------------------
-- 7. CTE in DELETE
-- ----------------------------------------------------------------------------
-- Delete customers who have no orders (would normally NOT delete — just demo).
-- WITH no_orders AS (
--     SELECT c.id FROM customers c
--     LEFT JOIN orders o ON o.customer_id = c.id
--     WHERE o.id IS NULL
-- )
-- DELETE c FROM customers c JOIN no_orders n ON n.id = c.id;
-- (CTE directly in DELETE is supported in MySQL 8.)

-- ----------------------------------------------------------------------------
-- 8. CTE with MATERIALIZED hint (MySQL 8.0+ (SQL:2023 compatible where noted))
-- ----------------------------------------------------------------------------
-- Force the optimizer to materialize (compute once, store, reuse) vs inline
-- (merge into the outer query).
WITH expensive_cte AS (
    SELECT customer_id, SUM(total) AS total FROM orders GROUP BY customer_id
) /* MATERIALIZED */
SELECT COUNT(*) FROM expensive_cte WHERE total > 1000;

-- ----------------------------------------------------------------------------
-- 9. CTE chained (one references another)
-- ----------------------------------------------------------------------------
WITH
base AS (
    SELECT customer_id, COUNT(*) AS n, SUM(total) AS s
    FROM orders
    GROUP BY customer_id
),
enriched AS (
    SELECT customer_id, n, s, s / NULLIF(n, 0) AS avg_order
    FROM base
)
SELECT customer_id, n, s, ROUND(avg_order, 2) AS avg_order
FROM enriched
ORDER BY s DESC;

-- ----------------------------------------------------------------------------
-- 10. EXERCISES
-- ----------------------------------------------------------------------------
-- EASY
-- E1.  Write a CTE that selects products with price > 500, then SELECT
--      from it sorted by price.
-- E2.  Write a CTE `cust_orders` that joins customers to orders, then use
--      it to return the top 5 by total.
--
-- MEDIUM
-- E3.  Write two CTEs: order_summary and review_summary, then JOIN them to
--      produce a single customer report.
-- E4.  Use a CTE in an INSERT ... SELECT to populate a summary table.
--
-- HARD
-- E5.  Use a CTE with ROW_NUMBER() to find the latest order status per
--      customer. Then mark customers inactive whose latest order was
--      cancelled (use UPDATE with a JOIN to a temp table built from the CTE).
--
-- EXPERT
-- E6.  Explain in a comment when the optimizer might choose to materialize
--      vs inline a CTE. Use the MATERIALIZED / NOT MATERIALIZED hints to
--      force one or the other.
-- ============================================================================

-- End of file 02_ctes.sql
