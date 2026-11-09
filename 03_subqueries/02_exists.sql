-- ============================================================================
-- 02_exists.sql — EXISTS / NOT EXISTS
-- ============================================================================
-- SKILL LEVEL : Intermediate
-- TOPICS      : EXISTS semantics, correlated vs non-correlated, NOT EXISTS
--               anti-join pattern, EXISTS vs IN performance, NULL safety.
-- ----------------------------------------------------------------------------
-- TEXTBOOK DEPTH
--   EXISTS(predicate) returns TRUE if the subquery returns AT LEAST ONE
--   row, FALSE if it returns zero rows. It does NOT care what columns the
--   subquery returns — only whether any row exists. Convention: SELECT 1
--   or SELECT *.
--
--   NOT EXISTS is the NULL-safe alternative to NOT IN.
--   NOT IN(subquery) returns ZERO rows if the subquery contains ANY NULL.
--   NOT EXISTS does not have that trap because it tests row existence, not
--   equality to a list.
--
--   Performance:
--     * EXISTS short-circuits: stops at the first matching row.
--     * IN materializes the full list (unless the optimizer transforms it).
--     * For large outer + small inner → IN usually wins.
--     * For small outer + large inner → EXISTS usually wins.
--     * MySQL 8 can rewrite IN to EXISTS automatically ("subquery
--       materialization" / "first match" optimizations).
-- ============================================================================

USE ecom;

-- ----------------------------------------------------------------------------
-- 1. Basic EXISTS — customers with at least one order
-- ----------------------------------------------------------------------------
SELECT c.first_name, c.last_name
FROM customers c
WHERE EXISTS (
    SELECT 1 FROM orders o WHERE o.customer_id = c.id
);

-- ----------------------------------------------------------------------------
-- 2. NOT EXISTS — customers without any orders (anti-join)
-- ----------------------------------------------------------------------------
SELECT c.first_name, c.last_name
FROM customers c
WHERE NOT EXISTS (
    SELECT 1 FROM orders o WHERE o.customer_id = c.id
);

-- ----------------------------------------------------------------------------
-- 3. NOT EXISTS — products never ordered
-- ----------------------------------------------------------------------------
SELECT p.sku, p.name
FROM products p
WHERE NOT EXISTS (
    SELECT 1 FROM order_items oi WHERE oi.product_id = p.id
);

-- ----------------------------------------------------------------------------
-- 4. EXISTS with multiple conditions in the subquery
-- ----------------------------------------------------------------------------
-- Customers who have placed at least one DELIVERED order.
SELECT c.first_name, c.last_name
FROM customers c
WHERE EXISTS (
    SELECT 1 FROM orders o
    WHERE o.customer_id = c.id
      AND o.status = 'delivered'
);

-- ----------------------------------------------------------------------------
-- 5. NOT EXISTS with multiple conditions
-- ----------------------------------------------------------------------------
-- Customers who have NEVER placed a delivered order.
SELECT c.first_name, c.last_name
FROM customers c
WHERE NOT EXISTS (
    SELECT 1 FROM orders o
    WHERE o.customer_id = c.id
      AND o.status = 'delivered'
);

-- ----------------------------------------------------------------------------
-- 6. EXISTS for double anti-join — "X but not Y"
-- ----------------------------------------------------------------------------
-- Customers who have placed an order BUT NOT a cancelled order.
SELECT c.first_name, c.last_name
FROM customers c
WHERE EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.id)
  AND NOT EXISTS (
      SELECT 1 FROM orders o
      WHERE o.customer_id = c.id AND o.status = 'cancelled'
  );

-- ----------------------------------------------------------------------------
-- 7. EXISTS vs IN — equivalent when subquery has no NULLs
-- ----------------------------------------------------------------------------
-- Equivalent:
SELECT c.first_name FROM customers c
WHERE c.id IN (SELECT customer_id FROM orders);

SELECT c.first_name FROM customers c
WHERE EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.id);

-- ----------------------------------------------------------------------------
-- 8. NOT EXISTS vs NOT IN — the NULL trap
-- ----------------------------------------------------------------------------
-- NOT IN breaks when the subquery returns NULL. NOT EXISTS is always safe.

CREATE TEMPORARY TABLE tmp_with_null (val INT);
INSERT INTO tmp_with_null VALUES (1), (2), (NULL), (4);

-- NOT IN: ZERO rows (the NULL kills it)
SELECT first_name FROM customers
WHERE id NOT IN (SELECT val FROM tmp_with_null);

-- NOT EXISTS: correct result
SELECT first_name FROM customers c
WHERE NOT EXISTS (SELECT 1 FROM tmp_with_null t WHERE t.val = c.id);

DROP TEMPORARY TABLE tmp_with_null;

-- ----------------------------------------------------------------------------
-- 9. EXISTS with JOIN inside the subquery
-- ----------------------------------------------------------------------------
-- Customers who have ordered a Laptop product (category 8).
SELECT c.first_name, c.last_name
FROM customers c
WHERE EXISTS (
    SELECT 1
    FROM orders o
    JOIN order_items oi ON oi.order_id   = o.id
    JOIN products p     ON p.id          = oi.product_id
    WHERE o.customer_id = c.id
      AND p.category_id = 8
);

-- ----------------------------------------------------------------------------
-- 10. EXISTS in SELECT — flag rows that have matching related data
-- ----------------------------------------------------------------------------
SELECT
    c.first_name,
    c.last_name,
    EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.id) AS has_orders,
    EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.id AND o.status = 'cancelled') AS has_cancelled
FROM customers c
ORDER BY c.id
LIMIT 6;

-- ----------------------------------------------------------------------------
-- 11. EXISTS correlated vs non-correlated
-- ----------------------------------------------------------------------------
-- Non-correlated: runs ONCE.
SELECT first_name FROM customers
WHERE EXISTS (SELECT 1 FROM orders WHERE status = 'pending');
-- Returns ALL customers if there is at least one pending order, else NONE.

-- Correlated: runs per outer row.
SELECT c.first_name FROM customers c
WHERE EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.id AND o.status = 'pending');
-- Returns only customers who have a pending order.

-- ----------------------------------------------------------------------------
-- 12. EXERCISES
-- ----------------------------------------------------------------------------
-- EASY
-- E1.  Use EXISTS to find customers who have at least one order.
-- E2.  Use NOT EXISTS to find products that have never been ordered.
--
-- MEDIUM
-- E3.  Use EXISTS to find customers who have placed at least one delivered
--      order.
-- E4.  Use NOT EXISTS to find customers who have never placed a cancelled
--      order.
--
-- HARD
-- E5.  Use a double EXISTS/NOT EXISTS pattern to find customers who have
--      placed an order BUT have NOT placed a delivered order.
-- E6.  Use EXISTS in the SELECT list to flag each customer with two
--      boolean columns: has_orders, has_reviews.
--
-- EXPERT
-- E7.  Demonstrate the NULL trap of NOT IN using a temp table with a NULL
--      value. Then fix it with NOT EXISTS. Explain in a comment why NOT IN
--      fails.
-- ============================================================================

-- End of file 02_exists.sql
