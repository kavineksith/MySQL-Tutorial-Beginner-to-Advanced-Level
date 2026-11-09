-- ============================================================================
-- 10_easy_challenges_solutions.sql — Solutions for EASY challenges
-- ============================================================================

USE ecom;

-- E1. 5 cheapest products
SELECT name, price FROM products ORDER BY price ASC LIMIT 5;

-- E2. Count active customers
SELECT COUNT(*) AS active_count FROM customers WHERE is_active = 1;

-- E3. US customers with @example.com email
SELECT first_name, last_name, email
FROM customers
WHERE country = 'United States' AND email LIKE '%@example.com';

-- E4. Avg price in category 7 (Audio)
SELECT AVG(price) AS avg_audio_price FROM products WHERE category_id = 7;

-- E5. Orders in February 2024
SELECT id, order_date, total
FROM orders
WHERE order_date >= '2024-02-01' AND order_date < '2024-03-01';

-- E6. Most expensive product (single row)
SELECT name, price FROM products ORDER BY price DESC LIMIT 1;

-- E7. Count distinct countries
SELECT COUNT(DISTINCT country) AS distinct_countries FROM customers;

-- E8. Products starting with 'A' or 'S'
SELECT name, price FROM products
WHERE name LIKE 'A%' OR name LIKE 'S%'
ORDER BY name;

-- E9. Total stock
SELECT SUM(stock_qty) AS total_stock FROM products;

-- E10. Emails of inactive customers
SELECT email FROM customers WHERE is_active = 0;

-- E11. 3 most recent orders
SELECT id, customer_id, order_date FROM orders ORDER BY order_date DESC LIMIT 3;

-- E12. Products $50-$150
SELECT name, price FROM products
WHERE price BETWEEN 50 AND 150
ORDER BY price;

-- E13. Unique order statuses
SELECT DISTINCT status FROM orders;

-- E14. Order count per status
SELECT status, COUNT(*) AS cnt FROM orders GROUP BY status ORDER BY cnt DESC;

-- E15. Customers with NULL phone
SELECT first_name, last_name FROM customers WHERE phone IS NULL;

-- E16. Total revenue from delivered orders
SELECT SUM(total) AS delivered_revenue FROM orders WHERE status = 'delivered';

-- E17. Customer with most orders
SELECT c.id, c.first_name, c.last_name, COUNT(o.id) AS order_count
FROM customers c JOIN orders o ON o.customer_id = c.id
GROUP BY c.id, c.first_name, c.last_name
ORDER BY order_count DESC
LIMIT 1;

-- E18. Products with stock 0
SELECT name, stock_qty FROM products WHERE stock_qty = 0;

-- E19. Price tier labels
SELECT name, price,
    CASE
        WHEN price < 100  THEN 'budget'
        WHEN price < 500  THEN 'mid'
        WHEN price < 1500 THEN 'premium'
        ELSE 'luxury'
    END AS label
FROM products;

-- E20. Products per category
SELECT category_id, COUNT(*) AS product_count
FROM products
GROUP BY category_id
ORDER BY product_count DESC;

-- End of file 10_easy_challenges_solutions.sql
