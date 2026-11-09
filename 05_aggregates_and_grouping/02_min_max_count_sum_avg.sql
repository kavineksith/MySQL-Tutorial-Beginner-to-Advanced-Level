-- ============================================================================
-- 02_min_max_count_sum_avg.sql — Detailed Look at MIN, MAX, COUNT, SUM, AVG
-- ============================================================================
-- SKILL LEVEL : Beginner→Intermediate
-- TOPICS      : Detailed behavior, NULL handling, DISTINCT modifier,
--               performance notes, common pitfalls.
-- ============================================================================

USE ecom;

-- ============================================================================
-- MIN() and MAX()
-- ============================================================================
-- Work on numbers, dates, strings. Ignore NULLs. Return NULL on empty set.
SELECT
    MIN(price)      AS cheapest_price,
    MAX(price)      AS highest_price,
    MIN(name)       AS first_name_alpha,
    MAX(name)       AS last_name_alpha,
    MIN(created_at) AS earliest_customer,
    MAX(created_at) AS latest_customer
FROM products;

-- Find the row that has the MIN/MAX value (the "argmin" problem)
-- WRONG: this returns prices but not the row with that price.
--   SELECT id, name, price FROM products WHERE price = MIN(price);  -- ERROR

-- CORRECT: use a subquery to find the min/max first.
SELECT id, name, price
FROM products
WHERE price = (SELECT MIN(price) FROM products);

-- Or use ORDER BY + LIMIT:
SELECT id, name, price FROM products ORDER BY price ASC LIMIT 1;
SELECT id, name, price FROM products ORDER BY price DESC LIMIT 1;

-- MIN/MAX with GROUP BY
SELECT
    category_id,
    MIN(price) AS cheapest_in_cat,
    MAX(price) AS dearest_in_cat
FROM products
GROUP BY category_id
ORDER BY category_id;

-- MIN/MAX with DISTINCT (rarely needed; ignores NULLs already)
SELECT MIN(DISTINCT price) FROM products;

-- ============================================================================
-- COUNT() — five forms
-- ============================================================================
SELECT
    COUNT(*)              AS count_all_rows,
    COUNT(phone)          AS count_non_null_phones,
    COUNT(DISTINCT country) AS count_distinct_countries,
    COUNT(phone = '555-0101' OR NULL) AS count_with_specific_phone,
    COUNT(IF(is_active = 1, 1, NULL)) AS count_active
FROM customers;

-- The `expr OR NULL` trick: when expr is FALSE, the OR returns NULL which
-- COUNT ignores. When expr is TRUE, OR returns 1 which COUNT includes.
-- Equivalent to using IF:
SELECT
    COUNT(IF(is_active = 1, 1, NULL)) AS count_active,
    COUNT(IF(country = 'United States', 1, NULL)) AS count_us
FROM customers;

-- COUNT with JOIN (beware of fan-out multiplication)
SELECT
    COUNT(*) AS customer_order_rows,        -- 10 (one per order)
    COUNT(DISTINCT c.id) AS distinct_customers_with_orders  -- 8
FROM customers c
JOIN orders o ON o.customer_id = c.id;

-- ============================================================================
-- SUM() — totaling
-- ============================================================================
SELECT
    SUM(price)      AS total_catalog_value,
    SUM(stock_qty)  AS total_inventory_units,
    SUM(price * stock_qty) AS total_inventory_at_retail,
    SUM(cost * stock_qty)  AS total_inventory_at_cost,
    SUM(price * stock_qty) - SUM(cost * stock_qty) AS potential_gross_profit
FROM products;

-- SUM with WHERE
SELECT
    status,
    COUNT(*) AS order_count,
    SUM(total) AS revenue
FROM orders
GROUP BY status;

-- SUM ignores NULLs but be careful with arithmetic:
CREATE TEMPORARY TABLE tmp_arith (id INT, qty INT, price DECIMAL(10,2));
INSERT INTO tmp_arith VALUES
    (1, 5, 10.00),
    (2, NULL, 20.00),    -- qty is NULL
    (3, 3, NULL);        -- price is NULL

SELECT
    SUM(qty * price) AS total_with_nulls,           -- 50 (rows 1 only; rows 2 and 3 propagate NULL)
    SUM(COALESCE(qty, 0) * COALESCE(price, 0)) AS total_zero_filled   -- 50 + 0 + 0 = 50
FROM tmp_arith;

DROP TEMPORARY TABLE tmp_arith;

-- ============================================================================
-- AVG() — average of non-NULL values
-- ============================================================================
SELECT
    AVG(price) AS avg_price,
    AVG(price * stock_qty) AS avg_inventory_value_per_product
FROM products;

-- AVG ignores NULLs — important when computing averages over sparse columns
SELECT
    AVG(weight_kg) AS avg_weight_ignoring_nulls,           -- ignores NULL weights
    AVG(COALESCE(weight_kg, 0)) AS avg_weight_treating_null_as_zero  -- includes NULLs as 0
FROM products;

-- Compute weighted average manually: SUM(price * weight) / SUM(weight)
SELECT
    SUM(price * weight_kg) / NULLIF(SUM(weight_kg), 0) AS weighted_avg_price_by_weight
FROM products
WHERE weight_kg IS NOT NULL;

-- AVG(DISTINCT col) — average of unique values
SELECT AVG(DISTINCT price) AS avg_unique_price FROM products;

-- ============================================================================
-- Common pitfalls and how to avoid them
-- ============================================================================

-- PITFALL 1: AVG of empty set returns NULL, not 0.
SELECT AVG(price) FROM products WHERE 1 = 0;       -- NULL
SELECT COALESCE(AVG(price), 0) FROM products WHERE 1 = 0;  -- 0

-- PITFALL 2: COUNT(col) ignores NULLs. Use COUNT(*) to count all rows.
CREATE TEMPORARY TABLE tmp_pitfall (id INT, phone VARCHAR(20));
INSERT INTO tmp_pitfall VALUES (1, '555-0100'), (2, NULL), (3, '555-0102');

SELECT
    COUNT(*) AS rows_total,           -- 3
    COUNT(phone) AS rows_with_phone;  -- 2 (NULL excluded)

DROP TEMPORARY TABLE tmp_pitfall;

-- PITFALL 3: Aggregates with non-aggregate columns without GROUP BY violate
-- ONLY_FULL_GROUP_BY mode. MySQL 8 enables this by default.
--   SELECT first_name, COUNT(*) FROM customers;   -- ERROR 1140

-- PITFALL 4: Mixing aggregates in a single SELECT with GROUP BY
-- Non-aggregated columns must be in GROUP BY (or functionally dependent
-- on the GROUP BY columns).

-- ============================================================================
-- EXERCISES
-- ============================================================================
-- EASY
-- E1.  Find the cheapest and most expensive product in category 9.
-- E2.  Count how many customers have a non-NULL phone.

-- MEDIUM
-- E3.  Find the average order total for orders placed in 2024 (exclude
--      cancelled and refunded).
-- E4.  Find the total revenue and average order value per order status.

-- HARD
-- E5.  Find the product with the highest price (use a subquery with MAX).
--      Return its full row.
-- E6.  Compute the total inventory value at retail and at cost, plus the
--      potential gross profit margin as a percentage.

-- EXPERT
-- E7.  Write a query that returns each customer's first_name, last_name,
--      COUNT of orders, SUM of order totals, and AVG order value. Use
--      COALESCE so customers without orders show 0 / 0.00 / 0.00.

-- End of file 02_min_max_count_sum_avg.sql
