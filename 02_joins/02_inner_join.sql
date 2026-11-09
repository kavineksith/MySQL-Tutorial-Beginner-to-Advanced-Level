-- ============================================================================
-- 02_inner_join.sql — INNER JOIN in Depth
-- ============================================================================
-- SKILL LEVEL : Intermediate
-- TOPICS      : INNER JOIN with ON, multi-table chain, INNER JOIN with
--               USING, INNER JOIN with GROUP BY/aggregate, INNER JOIN with
--               subquery, INNER JOIN vs WHERE comma-join.
-- ----------------------------------------------------------------------------
-- TEXTBOOK DEPTH
--   INNER JOIN returns only rows where the ON predicate is TRUE in BOTH
--   tables. Logically: cross product → keep rows where ON is TRUE.
--
--   Performance notes:
--     * MySQL picks a join order — usually starts with the smallest table
--       or the one with the most selective filter.
--     * Join columns should be indexed (typically the foreign key column).
--     * Join columns should have the SAME data type to avoid implicit
--       conversion defeating the index.
-- ============================================================================

USE ecom;

-- ----------------------------------------------------------------------------
-- 1. Basic INNER JOIN with ON
-- ----------------------------------------------------------------------------
SELECT
    c.first_name,
    c.last_name,
    o.id AS order_id,
    o.order_date,
    o.total
FROM customers c
INNER JOIN orders o ON o.customer_id = c.id
ORDER BY o.total DESC;

-- ----------------------------------------------------------------------------
-- 2. INNER JOIN with column alias and projection
-- ----------------------------------------------------------------------------
SELECT
    c.id         AS customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    o.id         AS order_id,
    o.status     AS order_status,
    o.total      AS order_total
FROM customers c
INNER JOIN orders o ON o.customer_id = c.id
ORDER BY customer_id, order_id;

-- ----------------------------------------------------------------------------
-- 3. INNER JOIN with WHERE filter
-- ----------------------------------------------------------------------------
SELECT
    c.first_name,
    c.last_name,
    o.id AS order_id,
    o.total
FROM customers c
INNER JOIN orders o ON o.customer_id = c.id
WHERE c.country = 'United States'
  AND o.status IN ('delivered', 'shipped')
ORDER BY o.total DESC;

-- ----------------------------------------------------------------------------
-- 4. Multi-table INNER JOIN chain
-- ----------------------------------------------------------------------------
-- Customers → Orders → Order_Items → Products → Categories
SELECT
    c.first_name,
    c.last_name,
    o.id AS order_id,
    cat.name AS category,
    p.name AS product,
    oi.quantity,
    oi.unit_price,
    oi.line_total
FROM customers c
INNER JOIN orders o       ON o.customer_id   = c.id
INNER JOIN order_items oi ON oi.order_id     = o.id
INNER JOIN products p     ON p.id            = oi.product_id
INNER JOIN categories cat ON cat.id          = p.category_id
ORDER BY o.id, oi.id
LIMIT 10;

-- ----------------------------------------------------------------------------
-- 5. INNER JOIN with GROUP BY and aggregates
-- ----------------------------------------------------------------------------
SELECT
    c.id,
    c.first_name,
    c.last_name,
    COUNT(o.id)            AS order_count,
    COALESCE(SUM(o.total), 0) AS total_spent,
    AVG(o.total)           AS avg_order_value
FROM customers c
INNER JOIN orders o ON o.customer_id = c.id
GROUP BY c.id, c.first_name, c.last_name
ORDER BY total_spent DESC;

-- ----------------------------------------------------------------------------
-- 6. INNER JOIN with subquery (derived table)
-- ----------------------------------------------------------------------------
-- Join customers with a derived table that summarizes their orders.
SELECT
    c.first_name,
    c.last_name,
    t.order_count,
    t.total_spent
FROM customers c
INNER JOIN (
    SELECT
        customer_id,
        COUNT(*)      AS order_count,
        SUM(total)    AS total_spent
    FROM orders
    WHERE status NOT IN ('cancelled', 'refunded')
    GROUP BY customer_id
) AS t ON t.customer_id = c.id
ORDER BY t.total_spent DESC;

-- ----------------------------------------------------------------------------
-- 7. INNER JOIN with USING (when column names match)
-- ----------------------------------------------------------------------------
CREATE TEMPORARY TABLE tmp_x (id INT, label VARCHAR(10));
CREATE TEMPORARY TABLE tmp_y (id INT, value INT);
INSERT INTO tmp_x VALUES (1, 'one'), (2, 'two'),   (3, 'three');
INSERT INTO tmp_y VALUES (1, 100),    (2, 200),    (4, 400);

SELECT x.id, x.label, y.value
FROM tmp_x x
INNER JOIN tmp_y y USING (id);

DROP TEMPORARY TABLE tmp_x;
DROP TEMPORARY TABLE tmp_y;

-- ----------------------------------------------------------------------------
-- 8. INNER JOIN with composite key
-- ----------------------------------------------------------------------------
-- Join on two columns (rare in OLTP; common in many-to-many link tables).
CREATE TEMPORARY TABLE tmp_emp (emp_id INT, dept_id INT, name VARCHAR(20));
CREATE TEMPORARY TABLE tmp_pay (emp_id INT, dept_id INT, salary INT);
INSERT INTO tmp_emp VALUES (1, 10, 'Alice'), (2, 20, 'Bob'), (3, 10, 'Carol');
INSERT INTO tmp_pay VALUES (1, 10, 90000),   (2, 20, 85000), (3, 20, 95000);

-- Composite-key INNER JOIN
SELECT e.name, e.dept_id, p.salary
FROM tmp_emp e
INNER JOIN tmp_pay p
    ON p.emp_id = e.emp_id AND p.dept_id = e.dept_id;
-- Carol (emp 3, dept 10) has no matching pay row (pay row has emp 3, dept 20)
-- so she is excluded from the result.

DROP TEMPORARY TABLE tmp_emp;
DROP TEMPORARY TABLE tmp_pay;

-- ----------------------------------------------------------------------------
-- 9. INNER JOIN three ways to filter
-- ----------------------------------------------------------------------------
-- Products that have been ordered AND reviewed AND have at least 5 stock.
SELECT
    p.sku,
    p.name,
    p.stock_qty,
    COUNT(DISTINCT o.id)    AS times_ordered,
    COUNT(DISTINCT r.id)    AS review_count
FROM products p
INNER JOIN order_items oi ON oi.product_id = p.id
INNER JOIN orders o       ON o.id          = oi.order_id
INNER JOIN reviews r      ON r.product_id  = p.id
WHERE p.stock_qty >= 5
GROUP BY p.id, p.sku, p.name, p.stock_qty
ORDER BY times_ordered DESC;

-- ----------------------------------------------------------------------------
-- 10. INNER JOIN vs comma-join
-- ----------------------------------------------------------------------------
-- These produce the same result. INNER JOIN ... ON is preferred.
SELECT c.first_name, o.id
FROM customers c, orders o
WHERE c.id = o.customer_id;

SELECT c.first_name, o.id
FROM customers c
INNER JOIN orders o ON c.id = o.customer_id;

-- ----------------------------------------------------------------------------
-- 11. EXERCISES
-- ----------------------------------------------------------------------------
-- EASY
-- E1.  INNER JOIN products to categories. Return product name + category name.
-- E2.  INNER JOIN customers to orders, returning only orders over $500.
--
-- MEDIUM
-- E3.  Build the 5-table chain: customers → orders → order_items → products
--      → categories. Return first 10 rows ordered by order_id, item_id.
-- E4.  Compute total revenue per customer using INNER JOIN + GROUP BY.
--      Return top 5 by revenue.
--
-- HARD
-- E5.  Find products that have been both ordered and reviewed. Show
--      sku, name, times_ordered, review_count, avg_rating.
--
-- EXPERT
-- E6.  INNER JOIN the customers table to a derived table that computes
--      per-customer order stats (count, sum, avg). Only show customers
--      whose avg_order_value exceeds the global avg. Use a subquery
--      in HAVING.
-- ============================================================================

-- End of file 02_inner_join.sql
