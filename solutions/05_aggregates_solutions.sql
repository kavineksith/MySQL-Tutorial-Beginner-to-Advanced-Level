-- ============================================================================
-- 05_aggregates_solutions.sql — Solutions for 05_aggregates_and_grouping
-- ============================================================================

USE ecom;

-- ============================================================================
-- 01_aggregate_functions.sql
-- ============================================================================

-- E1. count products in category 7
SELECT COUNT(*) AS audio_product_count FROM products WHERE category_id = 7;

-- E2. avg price of laptops
SELECT AVG(price) AS avg_laptop_price FROM products WHERE category_id = 8;

-- E3. total revenue from delivered/shipped in 2024
SELECT SUM(total) AS revenue_2024
FROM orders
WHERE status IN ('delivered', 'shipped')
  AND YEAR(order_date) = 2024;

-- E4. GROUP_CONCAT of all SKUs ordered alphabetically
SELECT GROUP_CONCAT(sku ORDER BY sku SEPARATOR ', ') AS all_skus
FROM products;

-- E5. per-customer report with COALESCE
SELECT
    c.first_name,
    c.last_name,
    COUNT(o.id) AS order_count,
    COALESCE(SUM(o.total), 0) AS total_spent,
    COALESCE(AVG(o.total), 0) AS avg_order_value
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
GROUP BY c.id, c.first_name, c.last_name
ORDER BY total_spent DESC;

-- E6. JSON_OBJECTAGG mapping customer id → full name
SELECT JSON_OBJECTAGG(id, CONCAT(first_name, ' ', last_name)) AS id_to_name
FROM customers;

-- ============================================================================
-- 02_min_max_count_sum_avg.sql
-- ============================================================================

-- E1. cheapest/most expensive in category 9
SELECT MIN(price) AS cheapest, MAX(price) AS most_expensive
FROM products WHERE category_id = 9;

-- E2. customers with non-NULL phone
SELECT COUNT(phone) AS customers_with_phone FROM customers;

-- E3. avg order total in 2024 (excluding cancelled/refunded)
SELECT AVG(total) AS avg_order_total
FROM orders
WHERE status NOT IN ('cancelled', 'refunded')
  AND YEAR(order_date) = 2024;

-- E4. per-status revenue and avg
SELECT status, SUM(total) AS revenue, AVG(total) AS avg_value
FROM orders
GROUP BY status;

-- E5. product with highest price (full row)
SELECT id, sku, name, price FROM products
WHERE price = (SELECT MAX(price) FROM products);

-- E6. inventory at retail, at cost, margin pct
SELECT
    SUM(price * stock_qty) AS retail_value,
    SUM(cost * stock_qty)  AS cost_value,
    ROUND((SUM(price * stock_qty) - SUM(cost * stock_qty)) /
          SUM(price * stock_qty) * 100, 2) AS gross_margin_pct
FROM products;

-- E7. per-customer stats with COALESCE
SELECT
    c.first_name,
    c.last_name,
    COUNT(o.id)               AS order_count,
    COALESCE(SUM(o.total), 0) AS total_spent,
    COALESCE(AVG(o.total), 0) AS avg_order_value
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
GROUP BY c.id, c.first_name, c.last_name
ORDER BY total_spent DESC;

-- ============================================================================
-- 03_group_by.sql
-- ============================================================================

-- E1. count products per category
SELECT category_id, COUNT(*) AS product_count
FROM products GROUP BY category_id ORDER BY category_id;

-- E2. count customers per country by active status
SELECT country, is_active, COUNT(*) AS customer_count
FROM customers GROUP BY country, is_active ORDER BY country, is_active DESC;

-- E3. revenue per status
SELECT status, SUM(total) AS revenue
FROM orders GROUP BY status;

-- E4. revenue per year-month 2024
SELECT YEAR(order_date) AS yr, MONTH(order_date) AS mo,
       SUM(total) AS revenue
FROM orders
WHERE YEAR(order_date) = 2024
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY yr, mo;

-- E5. with WITH ROLLUP grand total per year
SELECT YEAR(order_date) AS yr, SUM(total) AS revenue
FROM orders
GROUP BY YEAR(order_date) WITH ROLLUP;

-- E6. inventory value per category
SELECT category_id, SUM(price * stock_qty) AS inventory_value
FROM products
GROUP BY category_id
ORDER BY inventory_value DESC;

-- E7. top spender per country
WITH ranked AS (
    SELECT
        c.country,
        c.first_name,
        c.last_name,
        SUM(o.total) AS spend,
        ROW_NUMBER() OVER (PARTITION BY c.country ORDER BY SUM(o.total) DESC) AS rn
    FROM customers c
    JOIN orders o ON o.customer_id = c.id
    GROUP BY c.country, c.first_name, c.last_name
)
SELECT country, first_name, last_name, spend
FROM ranked WHERE rn = 1;

-- ============================================================================
-- 04_having.sql
-- ============================================================================

-- E1. categories with > 2 products
SELECT category_id, COUNT(*) AS product_count
FROM products GROUP BY category_id HAVING COUNT(*) > 2;

-- E2. customers with > 1 order
SELECT customer_id, COUNT(*) AS order_count
FROM orders GROUP BY customer_id HAVING COUNT(*) > 1;

-- E3. products reviewed at least twice
SELECT product_id, COUNT(*) AS review_count
FROM reviews GROUP BY product_id HAVING COUNT(*) >= 2;

-- E4. customers whose non-cancelled spend > $1000
SELECT customer_id, SUM(total) AS total_spent
FROM orders
WHERE status <> 'cancelled'
GROUP BY customer_id
HAVING SUM(total) > 1000;

-- E5. categories with avg price above overall avg
SELECT category_id, AVG(price) AS avg_price
FROM products
GROUP BY category_id
HAVING AVG(price) > (SELECT AVG(price) FROM products);

-- E6. customers with avg order above overall avg
SELECT customer_id, AVG(total) AS avg_order
FROM orders
GROUP BY customer_id
HAVING AVG(total) > (SELECT AVG(total) FROM orders);

-- E7. Why WHERE COUNT(*) > 5 doesn't work:
-- WHERE runs BEFORE grouping, so aggregates aren't yet computed.
-- Use HAVING instead: HAVING COUNT(*) > 5.
-- Example:
SELECT customer_id, COUNT(*) AS cnt
FROM orders
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- End of file 05_aggregates_solutions.sql
