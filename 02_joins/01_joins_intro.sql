-- ============================================================================
-- 01_joins_intro.sql — Joins: Concepts and Overview
-- ============================================================================
-- SKILL LEVEL : Intermediate
-- TOPICS      : What joins are, Venn-diagram mental model, join types
--               (INNER, LEFT, RIGHT, FULL, CROSS, SELF, NATURAL),
--               join syntax variants (USING, ON, NATURAL), join execution.
-- ----------------------------------------------------------------------------
-- TEXTBOOK DEPTH
--   A JOIN combines columns from two (or more) tables into a single result
--   set based on a related column between them. The relationship is usually
--   a foreign key, but any expression that yields TRUE/FALSE works.
--
--   Join families (SQL standard):
--     1. CROSS JOIN        — Cartesian product: every left row × every right row.
--     2. INNER JOIN        — only matching rows survive.
--     3. LEFT OUTER JOIN   — all left rows; NULLs on right when no match.
--     4. RIGHT OUTER JOIN  — all right rows; NULLs on left when no match.
--     5. FULL OUTER JOIN   — all rows from both; NULLs on whichever side
--                            has no match. MySQL DOES NOT support FULL JOIN
--                            directly — emulate with LEFT JOIN ∪ RIGHT JOIN.
--     6. SELF JOIN         — a table joined to itself (useful for hierarchies).
--     7. NATURAL JOIN      — joins on columns with the same name (avoid!).
--
--   Join syntax variants:
--     * ON predicate      — most common, explicit, flexible
--     * USING (col1,...)  — short form when join columns share the same name
--     * NATURAL           — implicit join on all common columns (surprising)
--     * Comma-join        — `FROM a, b WHERE a.id = b.id` (legacy; avoid)
--
--   Execution model (conceptual):
--     1. Cross-product all input tables.
--     2. Apply the ON predicate (for INNER JOIN), keeping matching rows.
--     3. For OUTER JOIN, add back the unmatched rows from the preserved
--        side, padded with NULLs.
--     4. Apply WHERE.
--     5. Apply GROUP BY / HAVING / SELECT / ORDER BY / LIMIT.
--
--   In practice MySQL uses nested-loop join, hash join (8.0.18+), or batched
--   key access — the optimizer chooses based on indexes and statistics.
-- ============================================================================

USE ecom;

-- ----------------------------------------------------------------------------
-- 1. CROSS JOIN — every combination
-- ----------------------------------------------------------------------------
SELECT
    c.first_name,
    p.name AS product_name
FROM customers c
CROSS JOIN products p
LIMIT 5;
-- 12 customers × 16 products = 192 rows. Useful for generating combinations
-- or seed data; almost never what you want in app queries.

-- ----------------------------------------------------------------------------
-- 2. INNER JOIN — only matching rows
-- ----------------------------------------------------------------------------
SELECT
    c.first_name,
    c.last_name,
    o.id AS order_id,
    o.total
FROM customers c
INNER JOIN orders o ON o.customer_id = c.id
ORDER BY o.total DESC
LIMIT 5;

-- ----------------------------------------------------------------------------
-- 3. LEFT OUTER JOIN — all left rows, NULLs when no match
-- ----------------------------------------------------------------------------
SELECT
    c.first_name,
    c.last_name,
    o.id AS order_id,
    o.total
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
ORDER BY c.id
LIMIT 12;
-- Customers without orders appear with NULL in the order columns.

-- ----------------------------------------------------------------------------
-- 4. RIGHT OUTER JOIN — all right rows, NULLs when no match
-- ----------------------------------------------------------------------------
SELECT
    c.first_name,
    c.last_name,
    o.id AS order_id
FROM customers c
RIGHT JOIN orders o ON o.customer_id = c.id;
-- All orders appear; NULL customer columns if a customer_id is orphaned.

-- ----------------------------------------------------------------------------
-- 5. FULL OUTER JOIN — MySQL does NOT support it
-- ----------------------------------------------------------------------------
-- Emulate via UNION of LEFT JOIN and RIGHT JOIN:
SELECT
    c.first_name AS cfn, c.last_name AS cln,
    o.id AS oid, o.total AS ot
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
UNION
SELECT
    c.first_name AS cfn, c.last_name AS cln,
    o.id AS oid, o.total AS ot
FROM customers c
RIGHT JOIN orders o ON o.customer_id = c.id;
-- The UNION (not UNION ALL) removes the duplicate matched rows.

-- ----------------------------------------------------------------------------
-- 6. SELF JOIN — table joined to itself with aliases
-- ----------------------------------------------------------------------------
SELECT
    e.first_name AS employee,
    e.title      AS employee_title,
    m.first_name AS manager,
    m.title      AS manager_title
FROM employees e
LEFT JOIN employees m ON m.id = e.manager_id
ORDER BY e.id;

-- ----------------------------------------------------------------------------
-- 7. USING clause — short form when columns share the same name
-- ----------------------------------------------------------------------------
-- If the join column has the same name in both tables, you can write
-- USING (col) instead of ON left.col = right.col.
-- In our schema the join column is named differently (id vs customer_id),
-- so we use ON. Here's a self-demo:
CREATE TEMPORARY TABLE tmp_a (id INT, val INT);
CREATE TEMPORARY TABLE tmp_b (id INT, val INT);
INSERT INTO tmp_a VALUES (1, 10), (2, 20), (3, 30);
INSERT INTO tmp_b VALUES (1, 100), (3, 300), (5, 500);

SELECT a.id, a.val AS a_val, b.val AS b_val
FROM tmp_a a
JOIN tmp_b b USING (id);
-- Joins where tmp_a.id = tmp_b.id

DROP TEMPORARY TABLE tmp_a;
DROP TEMPORARY TABLE tmp_b;

-- ----------------------------------------------------------------------------
-- 8. Comma-join (legacy syntax — avoid)
-- ----------------------------------------------------------------------------
SELECT c.first_name, o.id
FROM customers c, orders o
WHERE c.id = o.customer_id
LIMIT 3;
-- Equivalent to INNER JOIN ... ON but harder to read and easy to forget the
-- WHERE, accidentally producing a CROSS JOIN.

-- ----------------------------------------------------------------------------
-- 9. Multi-table JOIN
-- ----------------------------------------------------------------------------
SELECT
    c.first_name,
    c.last_name,
    o.id AS order_id,
    o.order_date,
    p.name AS product_name,
    oi.quantity,
    oi.unit_price
FROM customers c
JOIN orders o       ON o.customer_id   = c.id
JOIN order_items oi ON oi.order_id     = o.id
JOIN products p     ON p.id            = oi.product_id
ORDER BY o.id, oi.id
LIMIT 10;

-- ----------------------------------------------------------------------------
-- 10. NATURAL JOIN (avoid)
-- ----------------------------------------------------------------------------
-- NATURAL JOIN automatically joins on all columns that have the same name
-- in both tables. It's terse but fragile — adding a new column with the
-- same name silently changes the join semantics. NEVER use in production.

-- ----------------------------------------------------------------------------
-- 11. JOIN with WHERE filter
-- ----------------------------------------------------------------------------
SELECT
    c.first_name,
    c.last_name,
    o.id AS order_id,
    o.total
FROM customers c
JOIN orders o ON o.customer_id = c.id
WHERE c.country = 'United States'
  AND o.status = 'delivered'
ORDER BY o.total DESC;

-- ----------------------------------------------------------------------------
-- 12. EXERCISES
-- ----------------------------------------------------------------------------
-- EASY
-- E1.  INNER JOIN customers to orders and return the first 5 rows.
-- E2.  CROSS JOIN products to categories — how many rows? (Compute the
--      expected count before running.)
--
-- MEDIUM
-- E3.  LEFT JOIN customers to orders. How many customers have NULL in the
--      order_id column? (Use COUNT with a filter.)
-- E4.  JOIN customers, orders, order_items, products in a single query
--      to return a flat "invoice" view for order id=2.
--
-- HARD
-- E5.  Emulate a FULL OUTER JOIN of customers and orders using UNION of
--      LEFT JOIN and RIGHT JOIN. Explain why UNION (not UNION ALL) is
--      required.
--
-- EXPERT
-- E6.  SELF JOIN employees: find pairs of employees who share the same
--      manager. Return employee_a, employee_b, manager_id.
-- ============================================================================

-- End of file 01_joins_intro.sql
