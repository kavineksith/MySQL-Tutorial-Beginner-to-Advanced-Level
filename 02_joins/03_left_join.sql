-- ============================================================================
-- 03_left_join.sql — LEFT OUTER JOIN
-- ============================================================================
-- SKILL LEVEL : Intermediate
-- TOPICS      : LEFT JOIN preserves all left rows, NULL right side on no
--               match, "find rows with no match" pattern, multi-table LEFT
--               JOIN chain ordering, LEFT JOIN with aggregates.
-- ----------------------------------------------------------------------------
-- TEXTBOOK DEPTH
--   LEFT OUTER JOIN returns every row from the LEFT table. For each left
--   row, MySQL looks for matching right rows:
--     * If matches exist, the result contains the cross product of that
--       left row with each matching right row.
--     * If no match exists, the result contains the left row ONCE with
--       NULL in every right-table column.
--
--   Critical use cases:
--     1. "Show me everything from the left, even if there's no match."
--        Example: list every customer and any orders they placed; customers
--        with no orders show NULL order columns.
--     2. "Find left rows that have NO match on the right."
--        Example: customers who have never placed an order.
--        Pattern: LEFT JOIN ... WHERE right.id IS NULL
--
--   Gotcha: WHERE filters applied to the RIGHT table's columns can silently
--   turn a LEFT JOIN into an INNER JOIN. To preserve outer-join semantics,
--   push right-table predicates into the ON clause.
-- ============================================================================

USE ecom;

-- ----------------------------------------------------------------------------
-- 1. Basic LEFT JOIN — every customer, with any orders
-- ----------------------------------------------------------------------------
SELECT
    c.id,
    c.first_name,
    c.last_name,
    o.id AS order_id,
    o.total
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
ORDER BY c.id, o.id;

-- ----------------------------------------------------------------------------
-- 2. The "anti-join" pattern — find rows with NO match
-- ----------------------------------------------------------------------------
-- Customers who have never placed an order.
SELECT c.id, c.first_name, c.last_name
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
WHERE o.id IS NULL;
-- The WHERE o.id IS NULL test identifies rows where the LEFT JOIN padded
-- with NULLs, i.e. no match was found.

-- Equivalent using NOT EXISTS (often faster):
SELECT c.id, c.first_name, c.last_name
FROM customers c
WHERE NOT EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.id);

-- ----------------------------------------------------------------------------
-- 3. Products that have never been ordered
-- ----------------------------------------------------------------------------
SELECT p.sku, p.name
FROM products p
LEFT JOIN order_items oi ON oi.product_id = p.id
WHERE oi.id IS NULL;

-- ----------------------------------------------------------------------------
-- 4. Multi-table LEFT JOIN chain
-- ----------------------------------------------------------------------------
-- The order of LEFT JOINs matters: each subsequent join is applied to the
-- result of the previous one. Preserve "outer" semantics by chaining.
SELECT
    c.first_name,
    c.last_name,
    o.id   AS order_id,
    oi.id  AS line_item_id,
    p.name AS product_name
FROM customers c
LEFT JOIN orders o       ON o.customer_id   = c.id
LEFT JOIN order_items oi ON oi.order_id     = o.id
LEFT JOIN products p     ON p.id            = oi.product_id
ORDER BY c.id, o.id, oi.id
LIMIT 15;

-- ----------------------------------------------------------------------------
-- 5. LEFT JOIN with WHERE on LEFT table — safe
-- ----------------------------------------------------------------------------
SELECT
    c.first_name,
    c.last_name,
    o.id AS order_id
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
WHERE c.country = 'United States'
ORDER BY c.id, o.id;
-- WHERE on the LEFT table is fine — it just filters which left rows we keep.

-- ----------------------------------------------------------------------------
-- 6. LEFT JOIN with WHERE on RIGHT table — TURNS IT INTO INNER JOIN
-- ----------------------------------------------------------------------------
-- WRONG INTENT: list every US customer and their DELIVERED orders.
SELECT
    c.first_name,
    c.last_name,
    o.id AS order_id,
    o.status
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
WHERE c.country = 'United States' AND o.status = 'delivered'
ORDER BY c.id;
-- Customers with no delivered orders are EXCLUDED because the WHERE clause
-- requires o.status = 'delivered', which is NULL when no match — and
-- NULL = 'delivered' is NULL → row excluded.

-- CORRECT INTENT: list every US customer with delivered orders (if any);
-- show NULL when no delivered orders.
SELECT
    c.first_name,
    c.last_name,
    o.id AS order_id,
    o.status
FROM customers c
LEFT JOIN orders o
    ON o.customer_id = c.id
   AND o.status = 'delivered'        -- right-table filter moved to ON
WHERE c.country = 'United States'
ORDER BY c.id, o.id;
-- Note: AND inside ON, not WHERE. This preserves the outer-join semantics.

-- ----------------------------------------------------------------------------
-- 7. LEFT JOIN with aggregate
-- ----------------------------------------------------------------------------
SELECT
    c.id,
    c.first_name,
    c.last_name,
    COUNT(o.id)               AS order_count,
    COALESCE(SUM(o.total), 0) AS total_spent
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
GROUP BY c.id, c.first_name, c.last_name
ORDER BY total_spent DESC;

-- ----------------------------------------------------------------------------
-- 8. LEFT JOIN with derived table
-- ----------------------------------------------------------------------------
-- Use a derived table to compute per-customer aggregates once, then LEFT
-- JOIN to it. Often faster than aggregating the joined result.
SELECT
    c.first_name,
    c.last_name,
    COALESCE(t.total_spent, 0) AS total_spent,
    COALESCE(t.order_count, 0) AS order_count
FROM customers c
LEFT JOIN (
    SELECT customer_id, COUNT(*) AS order_count, SUM(total) AS total_spent
    FROM orders
    WHERE status NOT IN ('cancelled', 'refunded')
    GROUP BY customer_id
) AS t ON t.customer_id = c.id
ORDER BY total_spent DESC;

-- ----------------------------------------------------------------------------
-- 9. LEFT JOIN used to detect orphaned foreign keys
-- ----------------------------------------------------------------------------
-- Orders whose customer_id does not exist in customers (should be empty
-- because of the foreign key, but useful as a data-quality check).
SELECT o.id, o.customer_id
FROM orders o
LEFT JOIN customers c ON c.id = o.customer_id
WHERE c.id IS NULL;

-- ----------------------------------------------------------------------------
-- 10. LEFT JOIN self-join — manager relationship
-- ----------------------------------------------------------------------------
SELECT
    e.first_name AS employee,
    e.title      AS emp_title,
    m.first_name AS manager,
    m.title      AS mgr_title
FROM employees e
LEFT JOIN employees m ON m.id = e.manager_id
ORDER BY e.id;

-- ----------------------------------------------------------------------------
-- 11. LEFT JOIN multiple right tables
-- ----------------------------------------------------------------------------
-- Customer + their latest order (if any) + the product in that order.
SELECT
    c.first_name,
    c.last_name,
    o.id AS order_id,
    p.name AS product_name
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
                  AND o.id = (
                      SELECT MAX(id) FROM orders WHERE customer_id = c.id
                  )
LEFT JOIN order_items oi ON oi.order_id = o.id
                       AND oi.id = (SELECT MIN(id) FROM order_items WHERE order_id = o.id)
LEFT JOIN products p ON p.id = oi.product_id
ORDER BY c.id;

-- ----------------------------------------------------------------------------
-- 12. EXERCISES
-- ----------------------------------------------------------------------------
-- EASY
-- E1.  List every customer with any orders, ordered by customer_id.
-- E2.  List every product with any reviews (LEFT JOIN products → reviews).
--
-- MEDIUM
-- E3.  Find customers who have never placed an order (use LEFT JOIN +
--      IS NULL).
-- E4.  Find products that have never been ordered.
--
-- HARD
-- E5.  List every US customer and their delivered orders, preserving
--      customers who have no delivered orders (use the ON-clause pattern,
--      not WHERE on the right table).
--
-- EXPERT
-- E6.  Compare LEFT JOIN ... WHERE right.id IS NULL vs NOT EXISTS for
--      finding customers with no orders. Explain in a comment when one
--      might be preferred over the other (NULL handling, performance).
-- ============================================================================

-- End of file 03_left_join.sql
