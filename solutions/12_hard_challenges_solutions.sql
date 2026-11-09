-- ============================================================================
-- 12_hard_challenges_solutions.sql — Solutions for HARD challenges
-- ============================================================================

USE ecom;

-- H1. Top spender per country
WITH ranked AS (
    SELECT
        c.country,
        c.first_name,
        c.last_name,
        SUM(o.total) AS spend,
        ROW_NUMBER() OVER (PARTITION BY c.country ORDER BY SUM(o.total) DESC) AS rn
    FROM customers c
    JOIN orders o ON o.customer_id = c.id
    WHERE o.status <> 'cancelled'
    GROUP BY c.country, c.first_name, c.last_name
)
SELECT country, first_name, last_name, spend
FROM ranked WHERE rn = 1
ORDER BY spend DESC;

-- H2. Product with is_top_seller flag
WITH top10 AS (
    SELECT product_id, SUM(quantity) AS total_qty
    FROM order_items
    GROUP BY product_id
    ORDER BY total_qty DESC
    LIMIT 10
)
SELECT
    p.name,
    p.price,
    cat.name AS category,
    CASE WHEN t.product_id IS NOT NULL THEN TRUE ELSE FALSE END AS is_top_seller
FROM products p
JOIN categories cat ON cat.id = p.category_id
LEFT JOIN top10 t ON t.product_id = p.id
ORDER BY is_top_seller DESC, p.name;

-- H3. Month-over-month revenue growth 2024
WITH monthly AS (
    SELECT DATE_FORMAT(order_date, '%Y-%m') AS month,
           SUM(total) AS revenue
    FROM orders
    WHERE YEAR(order_date) = 2024
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
)
SELECT
    month,
    revenue,
    LAG(revenue) OVER (ORDER BY month) AS prev_revenue,
    ROUND((revenue - LAG(revenue) OVER (ORDER BY month)) /
          NULLIF(LAG(revenue) OVER (ORDER BY month), 0) * 100, 2) AS growth_pct
FROM monthly
ORDER BY month;

-- H4. Customers with orders in both 2024 AND 2025
SELECT c.first_name, c.last_name
FROM customers c
WHERE EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.id AND YEAR(o.order_date) = 2024)
  AND EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.id AND YEAR(o.order_date) = 2025);

-- H5. Org chart top-down with depth + path
WITH RECURSIVE org AS (
    SELECT id, first_name, last_name, manager_id, title, 1 AS depth,
           CAST(CONCAT(first_name, ' ', last_name) AS CHAR(500)) AS path
    FROM employees WHERE manager_id IS NULL
    UNION ALL
    SELECT e.id, e.first_name, e.last_name, e.manager_id, e.title, o.depth+1,
           CONCAT(o.path, ' > ', e.first_name, ' ', e.last_name)
    FROM employees e JOIN org o ON e.manager_id = o.id
)
SELECT depth, id, first_name, last_name, title, path
FROM org ORDER BY path;

-- H6. Customer retention cohort (Q1 2024 cohort, retention in Q2/Q3/Q4)
WITH first_orders AS (
    SELECT customer_id, MIN(order_date) AS first_order
    FROM orders
    GROUP BY customer_id
),
cohort AS (
    SELECT customer_id, first_order,
        YEAR(first_order) AS cohort_year,
        QUARTER(first_order) AS cohort_q
    FROM first_orders
)
SELECT
    CONCAT(cohort_year, '-Q', cohort_q) AS cohort,
    COUNT(DISTINCT c.customer_id) AS cohort_size,
    COUNT(DISTINCT CASE WHEN o.order_date >= DATE_ADD(c.first_order, INTERVAL 1 MONTH)
                        AND o.order_date < DATE_ADD(c.first_order, INTERVAL 4 MONTH)
                   THEN c.customer_id END) AS retained_q_next,
    COUNT(DISTINCT CASE WHEN o.order_date >= DATE_ADD(c.first_order, INTERVAL 4 MONTH)
                        AND o.order_date < DATE_ADD(c.first_order, INTERVAL 7 MONTH)
                   THEN c.customer_id END) AS retained_q_plus2
FROM cohort c
LEFT JOIN orders o ON o.customer_id = c.customer_id
WHERE cohort_year = 2024 AND cohort_q = 1
GROUP BY cohort;

-- H7. Product whose removal would most reduce inventory value
SELECT name, price * stock_qty AS inventory_value
FROM products
ORDER BY inventory_value DESC
LIMIT 1;

-- H8. Top 5 + Other report
SELECT product_name AS label, revenue FROM (
    SELECT p.name AS product_name, SUM(oi.line_total) AS revenue
    FROM order_items oi JOIN products p ON p.id = oi.product_id
    GROUP BY p.name
    ORDER BY revenue DESC
    LIMIT 5
) AS top5
UNION ALL
SELECT 'Other', SUM(revenue) FROM (
    SELECT p.name AS product_name, SUM(oi.line_total) AS revenue
    FROM order_items oi JOIN products p ON p.id = oi.product_id
    GROUP BY p.name
    ORDER BY revenue DESC
    LIMIT 5 OFFSET 5
) AS rest
ORDER BY revenue DESC;

-- H9. Per-order item aggregates
SELECT
    o.id AS order_id,
    COUNT(oi.id) AS items_count,
    SUM(oi.quantity) AS total_quantity,
    AVG(oi.unit_price) AS avg_unit_price,
    MAX(oi.unit_price) AS max_unit_price,
    MIN(oi.unit_price) AS min_unit_price
FROM orders o
LEFT JOIN order_items oi ON oi.order_id = o.id
GROUP BY o.id
ORDER BY o.id;

-- H10. Orders whose total differs from sum of line items by > $1
SELECT
    o.id AS order_id,
    o.total AS order_total,
    COALESCE(SUM(oi.line_total), 0) AS sum_lines,
    o.total - COALESCE(SUM(oi.line_total), 0) AS diff
FROM orders o
LEFT JOIN order_items oi ON oi.order_id = o.id
GROUP BY o.id
HAVING ABS(o.total - COALESCE(SUM(oi.line_total), 0)) > 1;

-- H11. JSON_TABLE flatten tags
SELECT
    c.id AS customer_id,
    c.first_name,
    jt.tag
FROM customers c,
JSON_TABLE(c.metadata, '$.tags[*]'
    COLUMNS (tag VARCHAR(50) PATH '$')
) AS jt
WHERE c.metadata IS NOT NULL
ORDER BY c.id, jt.tag;

-- H12. Moving average over 3-order window per customer
SELECT
    customer_id,
    id AS order_id,
    total,
    ROUND(AVG(total) OVER (
        PARTITION BY customer_id
        ORDER BY order_date
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS moving_avg_3
FROM orders
WHERE customer_id IN (SELECT customer_id FROM orders GROUP BY customer_id HAVING COUNT(*) >= 3)
ORDER BY customer_id, order_date;

-- H13. Per-category product stats
SELECT
    cat.name AS category,
    COUNT(*) AS product_count,
    ROUND(AVG(p.price), 2) AS avg_price,
    MAX(p.price) AS max_price,
    MIN(p.price) AS min_price,
    MAX(p.price) - MIN(p.price) AS price_range
FROM products p
JOIN categories cat ON cat.id = p.category_id
GROUP BY cat.id, cat.name
ORDER BY product_count DESC;

-- H14. VIP customers whose spend > avg of all
SELECT c.first_name, c.last_name, SUM(o.total) AS spend
FROM customers c
JOIN orders o ON o.customer_id = c.id
WHERE c.metadata IS NOT NULL
  AND JSON_CONTAINS(c.metadata->'$.tags', '"vip"')
  AND o.status NOT IN ('cancelled', 'refunded')
GROUP BY c.id, c.first_name, c.last_name
HAVING SUM(o.total) > (SELECT AVG(s) FROM (
    SELECT SUM(total) AS s FROM orders
    WHERE status NOT IN ('cancelled', 'refunded')
    GROUP BY customer_id
) AS per_cust)
ORDER BY spend DESC;

-- H15. Latest order per customer via CTE + ROW_NUMBER
WITH ranked AS (
    SELECT customer_id, id AS order_id, order_date, status, total,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date DESC) AS rn
    FROM orders
)
SELECT
    c.first_name,
    c.last_name,
    r.order_date AS latest_order_date,
    r.status AS latest_status,
    r.total AS latest_total
FROM customers c
LEFT JOIN ranked r ON r.customer_id = c.id AND r.rn = 1
ORDER BY c.id;

-- H16. Revenue contribution % per status in 2024
SELECT
    status,
    SUM(total) AS revenue,
    ROUND(SUM(total) / (SELECT SUM(total) FROM orders WHERE YEAR(order_date) = 2024) * 100, 2) AS pct_of_total
FROM orders
WHERE YEAR(order_date) = 2024
GROUP BY status
ORDER BY pct_of_total DESC;

-- H17. Products reviewed but never ordered
SELECT p.sku, p.name
FROM products p
WHERE EXISTS (SELECT 1 FROM reviews r WHERE r.product_id = p.id)
  AND NOT EXISTS (SELECT 1 FROM order_items oi WHERE oi.product_id = p.id);

-- H18. Hierarchical WITH ROLLUP report
SELECT
    COALESCE(country, 'ALL') AS country,
    COALESCE(city, 'ALL')    AS city,
    COUNT(*) AS customer_count
FROM customers
GROUP BY country, city WITH ROLLUP
ORDER BY country, city;

-- H19. Employee salary as % of manager's salary
SELECT
    e.first_name AS employee,
    e.salary AS emp_salary,
    m.first_name AS manager,
    m.salary AS mgr_salary,
    ROUND(e.salary / m.salary * 100, 2) AS pct_of_manager
FROM employees e
JOIN employees m ON m.id = e.manager_id
ORDER BY pct_of_manager DESC;

-- H20. EXPLAIN comparison: function vs range
EXPLAIN SELECT * FROM orders WHERE DATE(order_date) = '2024-02-20';
-- type=ALL, key=NULL — function defeats index.
EXPLAIN SELECT * FROM orders
WHERE order_date >= '2024-02-20' AND order_date < '2024-02-21';
-- type=range, key=idx_orders_date — index used.

-- End of file 12_hard_challenges_solutions.sql
