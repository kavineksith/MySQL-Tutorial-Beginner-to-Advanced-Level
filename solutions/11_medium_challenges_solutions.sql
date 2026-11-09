-- ============================================================================
-- 11_medium_challenges_solutions.sql — Solutions for MEDIUM challenges
-- ============================================================================

USE ecom;

-- M1. Per-customer order_count + total_spend (LEFT JOIN)
SELECT
    c.first_name,
    c.last_name,
    COUNT(o.id)               AS order_count,
    COALESCE(SUM(o.total), 0) AS total_spent
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
GROUP BY c.id, c.first_name, c.last_name
ORDER BY total_spent DESC;

-- M2. Top 3 customers by spend (excluding cancelled)
SELECT c.id, c.first_name, c.last_name, SUM(o.total) AS total_spend
FROM customers c
JOIN orders o ON o.customer_id = c.id
WHERE o.status <> 'cancelled'
GROUP BY c.id, c.first_name, c.last_name
ORDER BY total_spend DESC
LIMIT 3;

-- M3. Flat invoice (4-table join, 10 rows)
SELECT
    o.id AS order_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    p.name AS product_name,
    oi.quantity,
    oi.line_total
FROM customers c
JOIN orders o       ON o.customer_id   = c.id
JOIN order_items oi ON oi.order_id     = o.id
JOIN products p     ON p.id            = oi.product_id
ORDER BY o.id, oi.id
LIMIT 10;

-- M4. Products ordered at least 2 times
SELECT p.sku, p.name, COUNT(DISTINCT oi.order_id) AS times_ordered
FROM products p
JOIN order_items oi ON oi.product_id = p.id
GROUP BY p.id, p.sku, p.name
HAVING COUNT(DISTINCT oi.order_id) >= 2
ORDER BY times_ordered DESC;

-- M5. Customers with an order but NO delivered order
SELECT c.first_name, c.last_name
FROM customers c
WHERE EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.id)
  AND NOT EXISTS (
      SELECT 1 FROM orders o
      WHERE o.customer_id = c.id AND o.status = 'delivered'
  );

-- M6. Products > category avg via CTE
WITH cat_avg AS (
    SELECT category_id, AVG(price) AS avg_price
    FROM products GROUP BY category_id
)
SELECT p.name, p.price, ca.avg_price
FROM products p
JOIN cat_avg ca ON ca.category_id = p.category_id
WHERE p.price > ca.avg_price
ORDER BY p.category_id;

-- M7. Running total of revenue per month 2024
SELECT
    DATE_FORMAT(order_date, '%Y-%m') AS month,
    SUM(total) AS monthly_revenue,
    SUM(SUM(total)) OVER (ORDER BY DATE_FORMAT(order_date, '%Y-%m')) AS cumulative
FROM orders
WHERE YEAR(order_date) = 2024
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY month;

-- M8. Most expensive per category via ROW_NUMBER
WITH ranked AS (
    SELECT sku, name, category_id, price,
        ROW_NUMBER() OVER (PARTITION BY category_id ORDER BY price DESC) AS rn
    FROM products
)
SELECT category_id, name, price
FROM ranked WHERE rn = 1
ORDER BY category_id;

-- M9. First and last order date per customer
SELECT
    c.first_name,
    c.last_name,
    MIN(o.order_date) AS first_order,
    MAX(o.order_date) AS last_order
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
GROUP BY c.id, c.first_name, c.last_name;

-- M10. Orders > customer's avg order total
SELECT o.customer_id, o.id AS order_id, o.total
FROM orders o
WHERE o.total > (
    SELECT AVG(o2.total) FROM orders o2 WHERE o2.customer_id = o.customer_id
)
ORDER BY o.customer_id, o.total DESC;

-- M11. GROUP_CONCAT of order_ids per customer
SELECT
    c.first_name,
    c.last_name,
    GROUP_CONCAT(o.id ORDER BY o.id SEPARATOR ',') AS order_ids
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
GROUP BY c.id, c.first_name, c.last_name;

-- M12. Pivot: country × year revenue
SELECT
    country,
    SUM(CASE WHEN YEAR(order_date) = 2024 THEN o.total ELSE 0 END) AS revenue_2024,
    SUM(CASE WHEN YEAR(order_date) = 2025 THEN o.total ELSE 0 END) AS revenue_2025
FROM customers c
JOIN orders o ON o.customer_id = c.id
GROUP BY country
ORDER BY country;

-- M13. Duplicate emails via self-join
SELECT a.id AS id_a, b.id AS id_b, a.email
FROM customers a
JOIN customers b ON a.email = b.email AND a.id < b.id;

-- M14. Calendar 2024 LEFT JOINed to orders
WITH RECURSIVE cal(d) AS (
    SELECT DATE '2024-01-01'
    UNION ALL
    SELECT d + INTERVAL 1 DAY FROM cal WHERE d < '2024-12-31'
)
SELECT d AS day, COUNT(o.id) AS orders_placed
FROM cal d
LEFT JOIN orders o ON DATE(o.order_date) = d
GROUP BY d
ORDER BY d
LIMIT 10;

-- M15. Second-highest price per category
WITH ranked AS (
    SELECT sku, name, category_id, price,
        ROW_NUMBER() OVER (PARTITION BY category_id ORDER BY price DESC) AS rn
    FROM products
)
SELECT category_id, name, price
FROM ranked WHERE rn = 2
ORDER BY category_id;

-- M16. Gross margin pct with div/0 protection
SELECT
    name,
    price,
    cost,
    CASE WHEN price = 0 THEN NULL
         ELSE ROUND((price - cost) / price * 100, 2)
    END AS gross_margin_pct
FROM products
ORDER BY gross_margin_pct DESC;

-- M17. loyalty_points from JSON with default
SELECT first_name,
    COALESCE(JSON_UNQUOTE(JSON_EXTRACT(metadata, '$.loyalty_points')), 0) AS loyalty_points
FROM customers;

-- M18. first names in BOTH customers AND employees (INTERSECT pattern)
SELECT first_name FROM customers
WHERE first_name IN (SELECT first_name FROM employees)
ORDER BY first_name;

-- M19. NTILE(4) quartiles by price
SELECT sku, name, price,
    NTILE(4) OVER (ORDER BY price) AS quartile
FROM products
ORDER BY quartile, price;

-- M20. Employee with most direct reports
SELECT m.id, m.first_name, m.last_name, COUNT(e.id) AS direct_reports
FROM employees m
LEFT JOIN employees e ON e.manager_id = m.id
GROUP BY m.id, m.first_name, m.last_name
HAVING COUNT(e.id) > 0
ORDER BY direct_reports DESC
LIMIT 1;

-- End of file 11_medium_challenges_solutions.sql
