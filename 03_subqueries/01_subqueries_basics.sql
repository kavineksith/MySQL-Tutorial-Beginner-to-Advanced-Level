-- ============================================================================
-- 01_subqueries_basics.sql — Subqueries: Queries Inside Queries
-- ============================================================================
-- SKILL LEVEL : Intermediate
-- TOPICS      : Subquery in WHERE, subquery in SELECT (correlated), subquery
--               in FROM (derived table), scalar vs row vs table subqueries,
--               nested subqueries, subquery vs JOIN.
-- ----------------------------------------------------------------------------
-- TEXTBOOK DEPTH
--   A subquery is a SELECT nested inside another statement. Subqueries
--   appear in:
--     * WHERE / HAVING  (filter predicate)
--     * SELECT list     (scalar subquery — one column, one row)
--     * FROM clause     (derived table — must be aliased)
--     * INSERT/UPDATE/DELETE
--
--   Classification by what they return:
--     * SCALAR subquery : one row, one column. Used anywhere a value is.
--     * ROW subquery    : one row, multiple columns. Used in row comparisons.
--     * TABLE subquery  : multiple rows. Used with IN, ANY, ALL, EXISTS.
--
--   Classification by correlation:
--     * NON-CORRELATED : runs ONCE; result is reused. Faster for large outer.
--     * CORRELATED     : runs ONCE PER outer row (refs outer column). Slower
--                        but unavoidable for some patterns. MySQL 8 may
--                        transform correlated to non-correlated.
-- ============================================================================

USE ecom;

-- ----------------------------------------------------------------------------
-- 1. Scalar subquery in WHERE
-- ----------------------------------------------------------------------------
-- Products priced higher than the average product price.
SELECT name, price
FROM products
WHERE price > (SELECT AVG(price) FROM products)
ORDER BY price DESC;

-- ----------------------------------------------------------------------------
-- 2. Scalar subquery in SELECT
-- ----------------------------------------------------------------------------
-- Each product with the difference from the average price.
SELECT
    sku,
    name,
    price,
    ROUND(price - (SELECT AVG(price) FROM products), 2) AS price_vs_avg,
    ROUND((price - (SELECT AVG(price) FROM products)) / (SELECT AVG(price) FROM products) * 100, 2) AS pct_diff
FROM products
ORDER BY pct_diff DESC
LIMIT 5;

-- ----------------------------------------------------------------------------
-- 3. Subquery in FROM (derived table)
-- ----------------------------------------------------------------------------
-- Aggregate per customer, then filter the aggregated result.
SELECT t.customer_id, t.order_count, t.total_spent
FROM (
    SELECT
        customer_id,
        COUNT(*)   AS order_count,
        SUM(total) AS total_spent
    FROM orders
    WHERE status NOT IN ('cancelled', 'refunded')
    GROUP BY customer_id
) AS t
WHERE t.total_spent > 500
ORDER BY t.total_spent DESC;

-- ----------------------------------------------------------------------------
-- 4. Correlated subquery in SELECT
-- ----------------------------------------------------------------------------
-- For each customer, count their orders using a correlated subquery.
SELECT
    c.first_name,
    c.last_name,
    (SELECT COUNT(*) FROM orders o WHERE o.customer_id = c.id) AS order_count
FROM customers c
ORDER BY order_count DESC
LIMIT 6;

-- ----------------------------------------------------------------------------
-- 5. Correlated subquery in WHERE
-- ----------------------------------------------------------------------------
-- Products priced higher than the average price in their OWN category.
SELECT p1.sku, p1.name, p1.price, p1.category_id
FROM products p1
WHERE p1.price > (
    SELECT AVG(p2.price)
    FROM products p2
    WHERE p2.category_id = p1.category_id        -- correlated to outer p1
)
ORDER BY p1.category_id, p1.price DESC;

-- ----------------------------------------------------------------------------
-- 6. Nested subqueries (subquery inside subquery)
-- ----------------------------------------------------------------------------
-- Customers whose total spend exceeds the AVERAGE customer total spend.
SELECT customer_id, SUM(total) AS total_spent
FROM orders
WHERE status NOT IN ('cancelled', 'refunded')
GROUP BY customer_id
HAVING SUM(total) > (
    SELECT AVG(cust_total)
    FROM (
        SELECT SUM(total) AS cust_total
        FROM orders
        WHERE status NOT IN ('cancelled', 'refunded')
        GROUP BY customer_id
    ) AS per_cust
)
ORDER BY total_spent DESC;

-- ----------------------------------------------------------------------------
-- 7. Subquery vs JOIN — usually equivalent
-- ----------------------------------------------------------------------------
-- "Customers who have placed at least one order" — three equivalent forms.

-- Form 1: subquery with IN
SELECT c.first_name, c.last_name
FROM customers c
WHERE c.id IN (SELECT customer_id FROM orders);

-- Form 2: JOIN with DISTINCT (dedup needed because join fans out)
SELECT DISTINCT c.first_name, c.last_name
FROM customers c
JOIN orders o ON o.customer_id = c.id;

-- Form 3: EXISTS (often fastest — short-circuits per outer row)
SELECT c.first_name, c.last_name
FROM customers c
WHERE EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.id);

-- ----------------------------------------------------------------------------
-- 8. Row subquery with tuple comparison
-- ----------------------------------------------------------------------------
-- Find the customer matching (first_name='Alice', last_name='Johnson').
SELECT id, first_name, last_name
FROM customers
WHERE (first_name, last_name) = ('Alice', 'Johnson');

-- Find orders matching (customer_id, status) tuples
SELECT id, customer_id, status
FROM orders
WHERE (customer_id, status) IN (
    (1, 'delivered'),
    (8, 'delivered'),
    (3, 'delivered')
);

-- ----------------------------------------------------------------------------
-- 9. Subquery returning a single row used in comparison
-- ----------------------------------------------------------------------------
-- Find the most expensive product (use a scalar subquery).
SELECT id, sku, name, price
FROM products
WHERE price = (SELECT MAX(price) FROM products);

-- ----------------------------------------------------------------------------
-- 10. Subquery in HAVING
-- ----------------------------------------------------------------------------
SELECT customer_id, SUM(total) AS total_spent
FROM orders
GROUP BY customer_id
HAVING SUM(total) > (SELECT AVG(total) FROM orders);

-- ----------------------------------------------------------------------------
-- 11. Subquery inside an UPDATE — set column from a related row
-- ----------------------------------------------------------------------------
-- Use a correlated subquery in SET to update each product's stock_qty from
-- a related table (here, from order_items count — purely illustrative).
START TRANSACTION;
UPDATE products p
SET p.stock_qty = (
    SELECT 50 + COUNT(*) FROM order_items oi WHERE oi.product_id = p.id
)
WHERE EXISTS (SELECT 1 FROM order_items oi WHERE oi.product_id = p.id);
SELECT sku, stock_qty FROM products WHERE stock_qty <> 50 ORDER BY name LIMIT 5;
ROLLBACK;

-- ----------------------------------------------------------------------------
-- 12. EXERCISES
-- ----------------------------------------------------------------------------
-- EASY
-- E1.  Find products priced higher than the average price in category 9.
-- E2.  Find customers whose `created_at` is earlier than the average.
--
-- MEDIUM
-- E3.  Find products priced higher than the average in their OWN category
--      (correlated subquery).
-- E4.  Use a derived table to compute per-customer spend, then filter to
--      customers with total spend > $500.
--
-- HARD
-- E5.  Find customers whose total spend exceeds the average customer total
--      spend. Use nested subqueries.
-- E6.  Use a correlated subquery in SELECT to show each product's
--      `times_ordered` count alongside its name.
--
-- EXPERT
-- E7.  Compare three ways to find "customers with at least one order":
--      IN, JOIN with DISTINCT, EXISTS. Explain in a comment which one you'd
--      expect to be fastest on a 10M-row orders table and why.
-- ============================================================================

-- End of file 01_subqueries_basics.sql
