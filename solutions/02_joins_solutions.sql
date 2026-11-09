-- ============================================================================
-- 02_joins_solutions.sql — Solutions for 02_joins exercises
-- ============================================================================

USE ecom;

-- ============================================================================
-- 01_joins_intro.sql
-- ============================================================================

-- E1. INNER JOIN customers → orders, first 5 rows
SELECT c.first_name, o.id, o.total
FROM customers c
INNER JOIN orders o ON o.customer_id = c.id
LIMIT 5;

-- E2. CROSS JOIN products × categories — expected 16 × 15 = 240 rows
SELECT COUNT(*) AS cross_join_count
FROM products
CROSS JOIN categories;
-- 16 * 15 = 240

-- E3. LEFT JOIN customers → orders, count NULL order_ids
SELECT COUNT(*) AS customers_without_orders
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
WHERE o.id IS NULL;

-- E4. flat invoice view for order 2
SELECT
    c.first_name, c.last_name,
    o.id AS order_id, o.order_date, o.status,
    p.name AS product_name, oi.quantity, oi.unit_price, oi.line_total
FROM customers c
JOIN orders o       ON o.customer_id   = c.id
JOIN order_items oi ON oi.order_id     = o.id
JOIN products p     ON p.id            = oi.product_id
WHERE o.id = 2;

-- E5. FULL OUTER JOIN emulation
-- UNION (not UNION ALL) because matched rows appear in both LEFT and RIGHT
-- join; UNION removes the duplicates.
SELECT c.id AS cid, c.first_name, o.id AS oid
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
UNION
SELECT c.id AS cid, c.first_name, o.id AS oid
FROM customers c
RIGHT JOIN orders o ON o.customer_id = c.id
ORDER BY cid, oid;

-- E6. pairs of employees sharing same manager
SELECT a.first_name AS emp_a, b.first_name AS emp_b, a.manager_id
FROM employees a
JOIN employees b ON a.manager_id = b.manager_id AND a.id < b.id;

-- ============================================================================
-- 02_inner_join.sql
-- ============================================================================

-- E1. products → categories
SELECT p.name, c.name AS category_name
FROM products p
INNER JOIN categories c ON c.id = p.category_id;

-- E2. orders > $500
SELECT c.first_name, o.id, o.total
FROM customers c
INNER JOIN orders o ON o.customer_id = c.id
WHERE o.total > 500;

-- E3. 5-table chain, first 10 rows
SELECT
    c.first_name, o.id AS order_id,
    cat.name AS category, p.name AS product,
    oi.quantity, oi.unit_price, oi.line_total
FROM customers c
JOIN orders o       ON o.customer_id   = c.id
JOIN order_items oi ON oi.order_id     = o.id
JOIN products p     ON p.id            = oi.product_id
JOIN categories cat ON cat.id          = p.category_id
ORDER BY o.id, oi.id
LIMIT 10;

-- E4. revenue per customer, top 5
SELECT c.first_name, c.last_name, SUM(o.total) AS revenue
FROM customers c
JOIN orders o ON o.customer_id = c.id
GROUP BY c.id, c.first_name, c.last_name
ORDER BY revenue DESC
LIMIT 5;

-- E5. products both ordered AND reviewed
SELECT p.sku, p.name,
       COUNT(DISTINCT o.id) AS times_ordered,
       COUNT(DISTINCT r.id) AS review_count,
       ROUND(AVG(r.rating), 2) AS avg_rating
FROM products p
JOIN order_items oi ON oi.product_id = p.id
JOIN orders o       ON o.id = oi.order_id
JOIN reviews r      ON r.product_id = p.id
GROUP BY p.id, p.sku, p.name
ORDER BY times_ordered DESC;

-- E6. derived table + HAVING against global avg
SELECT t.customer_id, t.cust_total
FROM (
    SELECT customer_id, SUM(total) AS cust_total
    FROM orders
    WHERE status NOT IN ('cancelled', 'refunded')
    GROUP BY customer_id
) AS t
HAVING t.cust_total > (SELECT AVG(cust_total) FROM (
    SELECT SUM(total) AS cust_total
    FROM orders
    WHERE status NOT IN ('cancelled', 'refunded')
    GROUP BY customer_id
) AS global_avg);

-- ============================================================================
-- 03_left_join.sql
-- ============================================================================

-- E1. every customer with any orders
SELECT c.first_name, c.last_name, o.id AS order_id
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
ORDER BY c.id;

-- E2. every product with any reviews
SELECT p.sku, p.name, r.id AS review_id, r.rating
FROM products p
LEFT JOIN reviews r ON r.product_id = p.id
ORDER BY p.id;

-- E3. customers without orders (anti-join)
SELECT c.first_name, c.last_name
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
WHERE o.id IS NULL;

-- E4. products never ordered
SELECT p.sku, p.name
FROM products p
LEFT JOIN order_items oi ON oi.product_id = p.id
WHERE oi.id IS NULL;

-- E5. every US customer + delivered orders (preserving no-delivered-rows)
SELECT c.first_name, c.last_name, o.id AS order_id, o.status
FROM customers c
LEFT JOIN orders o
    ON o.customer_id = c.id
   AND o.status = 'delivered'
WHERE c.country = 'United States'
ORDER BY c.id, o.id;

-- E6. LEFT JOIN+IS NULL vs NOT EXISTS
-- LEFT JOIN pattern: simple and intuitive; good when you also want other
--   columns from the right table to be NULL.
-- NOT EXISTS: often faster because the optimizer can short-circuit per
--   outer row; also handles NULLs in the subquery safely.
-- Use NOT EXISTS for "anti-join" pure-existence checks.

-- ============================================================================
-- 04_right_join.sql
-- ============================================================================

-- E1. RIGHT JOIN customers → orders
SELECT c.first_name, o.id AS order_id
FROM customers c
RIGHT JOIN orders o ON o.customer_id = c.id;

-- E2. Same as LEFT JOIN orders → customers
SELECT c.first_name, o.id AS order_id
FROM orders o
LEFT JOIN customers c ON c.id = o.customer_id;

-- E3. RIGHT JOIN to find products without reviews
SELECT p.sku, p.name
FROM reviews r
RIGHT JOIN products p ON p.id = r.product_id
WHERE r.id IS NULL;

-- E4. review count per product (preserving zero-review products)
SELECT p.sku, p.name, COUNT(r.id) AS review_count
FROM reviews r
RIGHT JOIN products p ON p.id = r.product_id
GROUP BY p.id, p.sku, p.name
ORDER BY review_count DESC, p.sku;

-- E5. Why style guides forbid RIGHT JOIN
-- Mixing LEFT and RIGHT in one query makes it ambiguous which table is
-- preserved. Rewriting all as LEFT JOIN makes intent clear.
-- Example confusion: A LEFT JOIN B RIGHT JOIN C — preserves C, then within
-- each C row, optionally matches (A LEFT JOIN B). The two outer-join
-- directions fight each other.

-- E6. all-LEFT rewrite
SELECT p.sku, p.name, COUNT(r.id) AS review_count
FROM products p
LEFT JOIN reviews r ON r.product_id = p.id
GROUP BY p.id, p.sku, p.name
ORDER BY review_count DESC, p.sku;

-- ============================================================================
-- 05_full_join.sql
-- ============================================================================

-- E1. FULL JOIN emulation
SELECT COUNT(*) FROM (
    SELECT c.id AS cid, c.first_name, o.id AS oid
    FROM customers c
    LEFT JOIN orders o ON o.customer_id = c.id
    UNION
    SELECT c.id AS cid, c.first_name, o.id AS oid
    FROM customers c
    RIGHT JOIN orders o ON o.customer_id = c.id
) AS full_join;
-- Row count = COUNT(customers) + COUNT(orders) - COUNT(matched) = 12 + 10 - 10 = 12

-- E2. year-over-year spend comparison
WITH q1 AS (
    SELECT customer_id, SUM(total) AS spend
    FROM orders WHERE YEAR(order_date) = 2024
    GROUP BY customer_id
),
q2 AS (
    SELECT customer_id, SUM(total) AS spend
    FROM orders WHERE YEAR(order_date) = 2025
    GROUP BY customer_id
)
SELECT
    COALESCE(q1.customer_id, q2.customer_id) AS customer_id,
    q1.spend AS q1_spend,
    q2.spend AS q2_spend,
    CASE
        WHEN q1.customer_id IS NULL THEN 'new in q2'
        WHEN q2.customer_id IS NULL THEN 'gone in q2'
        ELSE 'in both'
    END AS status
FROM q1
LEFT JOIN q2 ON q2.customer_id = q1.customer_id
UNION
SELECT
    COALESCE(q1.customer_id, q2.customer_id) AS customer_id,
    q1.spend AS q1_spend,
    q2.spend AS q2_spend,
    CASE
        WHEN q1.customer_id IS NULL THEN 'new in q2'
        WHEN q2.customer_id IS NULL THEN 'gone in q2'
        ELSE 'in both'
    END AS status
FROM q1
RIGHT JOIN q2 ON q2.customer_id = q1.customer_id
ORDER BY customer_id;

-- E3. LEFT + UNION ALL + WHERE right.id IS NULL
SELECT c.id AS cid, c.first_name, o.id AS oid
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
UNION ALL
SELECT NULL, NULL, o.id
FROM orders o
LEFT JOIN customers c ON c.id = o.customer_id
WHERE c.id IS NULL;
-- Avoids UNION's duplicate-removal sort by explicitly listing only the
-- right-only rows in the second query.

-- E4. When FULL JOIN is the right tool
-- Use cases: comparing two snapshots, reconciling two lists with overlapping
-- keys, syncing two tables. Example: comparing yesterday's customer spend
-- to today's to identify who's new, who's gone, and who's in both.

-- ============================================================================
-- 06_self_join.sql
-- ============================================================================

-- E1. category with parent name
SELECT c.name AS category, p.name AS parent
FROM categories c
LEFT JOIN categories p ON p.id = c.parent_id
ORDER BY c.id;

-- E2. employee with manager first name
SELECT e.first_name AS employee, m.first_name AS manager
FROM employees e
LEFT JOIN employees m ON m.id = e.manager_id;

-- E3. pairs sharing same country
SELECT a.first_name AS cust_a, b.first_name AS cust_b, a.country
FROM customers a
JOIN customers b ON a.country = b.country AND a.id < b.id
WHERE a.country IS NOT NULL
ORDER BY a.country, a.id, b.id;

-- E4. employees whose salary > manager's salary
SELECT e.first_name, e.salary AS emp_salary, m.first_name AS manager, m.salary AS mgr_salary
FROM employees e
JOIN employees m ON m.id = e.manager_id
WHERE e.salary > m.salary;

-- E5. manager team size + budget
SELECT m.id, m.first_name AS manager,
       COUNT(e.id) AS reports, SUM(e.salary) AS team_budget
FROM employees m
LEFT JOIN employees e ON e.manager_id = m.id
GROUP BY m.id, m.first_name
HAVING COUNT(e.id) > 0
ORDER BY team_budget DESC;

-- E6. 3-level hierarchy to ICs
SELECT ceo.first_name AS ceo, vp.first_name AS vp,
       mgr.first_name AS manager, ic.first_name AS engineer
FROM employees ic
LEFT JOIN employees mgr ON mgr.id = ic.manager_id
LEFT JOIN employees vp  ON vp.id  = mgr.manager_id
LEFT JOIN employees ceo ON ceo.id = vp.manager_id
WHERE ic.title = 'Software Engineer'
ORDER BY ic.id;

-- E7. Self-join vs LAG() for "previous row"
-- Self-join requires a join predicate (e.g. max id less than current).
-- LAG() OVER (PARTITION BY ... ORDER BY ...) is cleaner and faster.
-- Prefer LAG() in MySQL 8+.

-- End of file 02_joins_solutions.sql
