-- ============================================================================
-- 04_in_operator.sql — IN Operator
-- ============================================================================
-- SKILL LEVEL : Beginner
-- TOPICS      : IN with literal list, IN with subquery, NOT IN, NULL trap
--               in NOT IN, IN vs OR, IN vs EXISTS performance.
-- ----------------------------------------------------------------------------
-- TEXTBOOK DEPTH
--   IN replaces a chain of OR-equality predicates. It reads cleanly and the
--   optimizer usually transforms `IN (a, b, c)` into the same plan as
--   `= a OR = b OR = c`.
--
--   Two forms:
--     1. Literal list:    WHERE col IN ('a', 'b', 'c')
--     2. Subquery result: WHERE col IN (SELECT ...)
--
--   THE NULL TRAP — critical:
--     NOT IN (subquery) returns ZERO rows if the subquery returns ANY NULL.
--     Why: `x NOT IN (a, b, NULL)` is rewritten as `x <> a AND x <> b AND x <> NULL`.
--     The last term `x <> NULL` is always NULL, so the whole AND is NULL,
--     so no row passes.
--
--   Use NOT EXISTS instead — it is NULL-safe and often faster.
-- ============================================================================

USE ecom;

-- ----------------------------------------------------------------------------
-- 1. IN with literal list
-- ----------------------------------------------------------------------------
SELECT first_name, country
FROM customers
WHERE country IN ('United States', 'United Kingdom', 'Canada');

-- Equivalent OR chain (longer, less readable):
SELECT first_name, country
FROM customers
WHERE country = 'United States'
   OR country = 'United Kingdom'
   OR country = 'Canada';

-- ----------------------------------------------------------------------------
-- 2. IN with numbers
-- ----------------------------------------------------------------------------
SELECT name, price
FROM products
WHERE category_id IN (8, 9, 7);

-- ----------------------------------------------------------------------------
-- 3. IN with dates
-- ----------------------------------------------------------------------------
SELECT id, order_date, status
FROM orders
WHERE DATE(order_date) IN ('2024-01-15', '2024-02-20', '2024-04-12');

-- ----------------------------------------------------------------------------
-- 4. NOT IN with literals
-- ----------------------------------------------------------------------------
SELECT first_name, country
FROM customers
WHERE country NOT IN ('United States', 'Canada', 'Mexico');

-- ----------------------------------------------------------------------------
-- 5. IN with subquery — most common pattern
-- ----------------------------------------------------------------------------
-- Customers who have placed at least one order.
SELECT first_name, last_name
FROM customers
WHERE id IN (SELECT customer_id FROM orders);

-- Customers who have NOT placed any order (use NOT EXISTS — safer).
SELECT first_name, last_name
FROM customers c
WHERE NOT EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.id);

-- ----------------------------------------------------------------------------
-- 6. THE NULL TRAP — demonstrated
-- ----------------------------------------------------------------------------
-- Create a temp table with a NULL value to expose the trap.
CREATE TEMPORARY TABLE tmp_ids (id INT);
INSERT INTO tmp_ids VALUES (1), (2), (NULL), (4);

-- Customers whose id is NOT in {1, 2, NULL, 4}.
-- Expect: ids 3, 5, 6, ... 12 should be returned.
-- ACTUAL: ZERO rows because of the NULL.
SELECT id, first_name
FROM customers
WHERE id NOT IN (SELECT id FROM tmp_ids);

-- FIXED: use NOT EXISTS.
SELECT id, first_name
FROM customers c
WHERE NOT EXISTS (SELECT 1 FROM tmp_ids t WHERE t.id = c.id);

-- OR: filter NULLs out of the subquery.
SELECT id, first_name
FROM customers
WHERE id NOT IN (SELECT id FROM tmp_ids WHERE id IS NOT NULL);

DROP TEMPORARY TABLE tmp_ids;

-- ----------------------------------------------------------------------------
-- 7. IN with multi-column tuples
-- ----------------------------------------------------------------------------
SELECT id, customer_id, status
FROM orders
WHERE (customer_id, status) IN (
    (1, 'delivered'),
    (3, 'cancelled'),
    (8, 'paid')
);

-- ----------------------------------------------------------------------------
-- 8. IN vs EXISTS performance
-- ----------------------------------------------------------------------------
-- IN:   the subquery is materialized ONCE into a list, then the outer query
--       checks each row against the list. Good when the subquery returns
--       small list and outer table is large.
-- EXISTS: short-circuits per outer row, returns TRUE on first match. Good
--       when the subquery needs correlation and the outer table is small.
-- In MySQL 8 the optimizer can rewrite IN to EXISTS automatically (the
-- "subquery materialization" optimization).

-- ----------------------------------------------------------------------------
-- 9. IN with computed values
-- ----------------------------------------------------------------------------
SELECT sku, name, price
FROM products
WHERE ROUND(price, 0) IN (1299, 2499, 799, 349);

-- ----------------------------------------------------------------------------
-- 10. NOT IN with NOT NULL columns is safe
-- ----------------------------------------------------------------------------
-- If the subquery column is declared NOT NULL, NOT IN is safe.
SELECT first_name, last_name
FROM customers
WHERE id NOT IN (SELECT customer_id FROM orders WHERE customer_id IS NOT NULL);
-- `customer_id` in orders is NOT NULL by schema definition, so the WHERE
-- clause is redundant but defensive.

-- ----------------------------------------------------------------------------
-- 11. EXERCISES
-- ----------------------------------------------------------------------------
-- EASY
-- E1.  Find all products in categories 8, 9, 12.
-- E2.  Find all orders with status 'paid', 'shipped', or 'delivered'.
--
-- MEDIUM
-- E3.  Find customers who placed orders in 2024 using IN with a subquery
--      on DATE(order_date) BETWEEN ... (use IN with YEAR()).
-- E4.  Find products that have NEVER been ordered. Use NOT EXISTS (not
--      NOT IN — explain why in a comment).
--
-- HARD
-- E5.  Demonstrate the NULL trap: create a temp table with a NULL value and
--      show that NOT IN returns zero rows. Then fix it with NOT EXISTS.
--
-- EXPERT
-- E6.  Explain in a comment when you would prefer IN over EXISTS, and vice
--      versa. Provide a small benchmark-shaped query for each pattern.
-- ============================================================================

-- End of file 04_in_operator.sql
