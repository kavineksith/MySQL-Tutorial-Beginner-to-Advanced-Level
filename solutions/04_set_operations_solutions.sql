-- ============================================================================
-- 04_set_operations_solutions.sql — Solutions for 04_set_operations
-- ============================================================================

USE ecom;

-- ============================================================================
-- 01_union.sql
-- ============================================================================

-- E1. all emails from customers + employees
SELECT email FROM customers
UNION
SELECT email FROM employees
ORDER BY email;

-- E2. category + product names with label
SELECT name, 'category' AS kind FROM categories
UNION ALL
SELECT name, 'product' FROM products
ORDER BY name;

-- E3. customers and employees with type
SELECT id, CONCAT(first_name, ' ', last_name) AS name, 'customer' AS type
FROM customers
UNION ALL
SELECT id, CONCAT(first_name, ' ', last_name) AS name, 'employee' AS type
FROM employees
ORDER BY name;

-- E4. count rows in every table
SELECT 'customers' AS t, COUNT(*) AS n FROM customers
UNION ALL SELECT 'employees',  COUNT(*) FROM employees
UNION ALL SELECT 'products',   COUNT(*) FROM products
UNION ALL SELECT 'orders',     COUNT(*) FROM orders
UNION ALL SELECT 'reviews',    COUNT(*) FROM reviews
UNION ALL SELECT 'categories', COUNT(*) FROM categories
UNION ALL SELECT 'order_items',COUNT(*) FROM order_items;

-- E5. UNION emulates FULL OUTER JOIN
-- UNION (not UNION ALL) is required because matched rows appear in both
-- the LEFT JOIN and RIGHT JOIN branches; UNION removes the duplicates.
SELECT c.id AS cid, c.first_name, o.id AS oid
FROM customers c LEFT JOIN orders o ON o.customer_id = c.id
UNION
SELECT c.id AS cid, c.first_name, o.id AS oid
FROM customers c RIGHT JOIN orders o ON o.customer_id = c.id;

-- E6. UNION ALL vs UNION performance
-- UNION ALL just appends; no dedup sort/hash. Faster when inputs are
-- mutually exclusive OR when duplicates are wanted.
-- UNION forces a sort/hash to remove duplicates — extra cost.
-- Use UNION ALL when you don't need dedup. Use UNION when dups would
-- corrupt the result (e.g., combining overlapping lists).

-- ============================================================================
-- 02_union_all.sql
-- ============================================================================

-- E1. count rows in three tables
SELECT 'customers' AS t, COUNT(*) AS n FROM customers
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'orders',   COUNT(*) FROM orders;

-- E2. names of customers + employees
SELECT first_name AS name FROM customers
UNION ALL
SELECT first_name FROM employees;

-- E3. grand-total row via UNION ALL
SELECT status, COUNT(*) AS cnt, SUM(total) AS revenue
FROM orders GROUP BY status
UNION ALL
SELECT 'ALL', COUNT(*), SUM(total) FROM orders
ORDER BY cnt DESC;

-- E4. numbers 1 to 5 via UNION ALL
SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5;

-- E5. Top 3 + Other rollup
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

-- E6. Why UNION ALL faster than UNION
-- UNION ALL doesn't dedup; no extra sort/hash step. O(n) append.
-- UNION does dedup → typically O(n log n) sort or O(n) hash with extra memory.

-- ============================================================================
-- 03_case.sql
-- ============================================================================

-- E1. price_tier column
SELECT name, price,
    CASE
        WHEN price < 100  THEN 'budget'
        WHEN price < 500  THEN 'mid'
        ELSE 'premium'
    END AS price_tier
FROM products;

-- E2. customer_segment
SELECT first_name, last_name, country,
    CASE country
        WHEN 'United States'  THEN 'US'
        WHEN 'United Kingdom' THEN 'EU'
        ELSE 'Other'
    END AS customer_segment
FROM customers;

-- E3. pivot table
SELECT
    country,
    SUM(CASE WHEN is_active = 1 THEN 1 ELSE 0 END) AS active,
    SUM(CASE WHEN is_active = 0 THEN 1 ELSE 0 END) AS inactive,
    COUNT(*) AS total
FROM customers
GROUP BY country
ORDER BY country;

-- E4. CASE in ORDER BY custom priority
SELECT id, status, total FROM orders
ORDER BY
    CASE status
        WHEN 'pending'   THEN 1
        WHEN 'paid'      THEN 2
        WHEN 'shipped'   THEN 3
        WHEN 'delivered' THEN 4
        WHEN 'cancelled' THEN 5
        WHEN 'refunded'  THEN 6
    END,
    total DESC;

-- E5. markup_pct with div/0 protection
SELECT name, price, cost,
    CASE WHEN cost = 0 THEN NULL
         ELSE ROUND((price - cost) / cost * 100, 2)
    END AS markup_pct
FROM products
ORDER BY markup_pct DESC;

-- E6. CASE inside COUNT for status counts
SELECT
    COUNT(*) AS total,
    COUNT(CASE WHEN status = 'delivered' THEN 1 END) AS delivered,
    COUNT(CASE WHEN status = 'cancelled' THEN 1 END) AS cancelled,
    COUNT(CASE WHEN status = 'paid'      THEN 1 END) AS paid
FROM orders;

-- E7. CASE in UPDATE for per-category adjustments
START TRANSACTION;
UPDATE products
SET price = CASE
    WHEN category_id = 8 THEN ROUND(price * 1.05, 2)
    WHEN category_id = 9 THEN ROUND(price * 1.03, 2)
    WHEN category_id = 7 THEN ROUND(price * 1.02, 2)
    ELSE price
END
WHERE category_id IN (7, 8, 9);
SELECT sku, category_id, price FROM products WHERE category_id IN (7, 8, 9);
ROLLBACK;

-- End of file 04_set_operations_solutions.sql
