-- ============================================================================
-- 05_full_join.sql — FULL OUTER JOIN (Emulated in MySQL)
-- ============================================================================
-- SKILL LEVEL : Intermediate
-- TOPICS      : FULL OUTER JOIN concept, MySQL emulation via UNION of LEFT
--               and RIGHT joins, when you actually need FULL JOIN.
-- ----------------------------------------------------------------------------
-- TEXTBOOK DEPTH
--   FULL OUTER JOIN returns ALL rows from BOTH tables:
--     * Matching rows: cross product.
--     * Left-only rows: left columns + NULL right columns.
--     * Right-only rows: NULL left columns + right columns.
--
--   MySQL does NOT implement FULL OUTER JOIN syntax. You must emulate it
--   using a UNION of LEFT JOIN and RIGHT JOIN:
--
--     SELECT cols FROM A LEFT JOIN B ON ...
--     UNION
--     SELECT cols FROM A RIGHT JOIN B ON ...
--
--   Why UNION (not UNION ALL)?
--     * The matched rows appear in BOTH the LEFT and RIGHT joins.
--     * UNION removes the duplicates.
--     * UNION ALL would double the matched rows.
--
--   When do you actually need FULL JOIN?
--     * Reconciling two lists where each has rows the other lacks.
--     * Comparing two snapshots.
--     * Merging two tables with overlapping but not identical key sets.
-- ============================================================================

USE ecom;

-- ----------------------------------------------------------------------------
-- 1. FULL OUTER JOIN emulation — basic
-- ----------------------------------------------------------------------------
-- Customers and their orders; show customers without orders AND any
-- orphaned orders (impossible under FK but the pattern is what matters).
SELECT
    c.id   AS customer_id,
    c.first_name,
    c.last_name,
    o.id   AS order_id,
    o.total
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id

UNION   -- removes duplicate matched rows

SELECT
    c.id   AS customer_id,
    c.first_name,
    c.last_name,
    o.id   AS order_id,
    o.total
FROM customers c
RIGHT JOIN orders o ON o.customer_id = c.id
ORDER BY customer_id, order_id;

-- ----------------------------------------------------------------------------
-- 2. FULL OUTER JOIN with derived "table comparison" use case
-- ----------------------------------------------------------------------------
-- Compare two lists: customers with their orders vs. a wishlist of orders
-- we expect (simulated).

CREATE TEMPORARY TABLE tmp_expected_orders (
    expected_id INT,
    customer_id INT
);
INSERT INTO tmp_expected_orders VALUES (1, 1), (2, 3), (3, 99), (4, 1);

-- FULL JOIN between actual orders and expected orders
SELECT
    a.id             AS actual_order,
    a.customer_id    AS actual_customer,
    e.expected_id    AS expected_order_id,
    e.customer_id    AS expected_customer
FROM orders a
LEFT JOIN tmp_expected_orders e ON e.expected_id = a.id

UNION

SELECT
    a.id             AS actual_order,
    a.customer_id    AS actual_customer,
    e.expected_id    AS expected_order_id,
    e.customer_id    AS expected_customer
FROM orders a
RIGHT JOIN tmp_expected_orders e ON e.expected_id = a.id
ORDER BY actual_order, expected_order_id;
-- Shows matched rows, plus expected rows with no actual (missing) and
-- actual rows with no expected (extra).

DROP TEMPORARY TABLE tmp_expected_orders;

-- ----------------------------------------------------------------------------
-- 3. FULL OUTER JOIN alternative using two LEFT JOINs and UNION ALL
-- ----------------------------------------------------------------------------
-- Sometimes clearer: explicitly list A-LEFT-B, B-LEFT-A-without-match.
SELECT
    c.id, c.first_name, c.last_name, o.id AS order_id
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id

UNION ALL    -- keep duplicates this time...

SELECT
    NULL, NULL, NULL, o.id
FROM orders o
LEFT JOIN customers c ON c.id = o.customer_id
WHERE c.id IS NULL;
-- The second query only returns the right-only rows (where no match was
-- found). UNION ALL preserves the matched rows from query 1 plus the
-- right-only rows from query 2 — no duplicate-removal sort needed.

-- ----------------------------------------------------------------------------
-- 4. When FULL JOIN is the right tool
-- ----------------------------------------------------------------------------
-- Two snapshots of customer totals — find who's in snapshot 1 only, who's
-- in snapshot 2 only, and who's in both.
CREATE TEMPORARY TABLE tmp_q1_spend (customer_id INT, total DECIMAL(10,2));
CREATE TEMPORARY TABLE tmp_q2_spend (customer_id INT, total DECIMAL(10,2));
INSERT INTO tmp_q1_spend VALUES (1, 1402.92), (3, 1131.84), (5, 0);
INSERT INTO tmp_q2_spend VALUES (3, 527.99),  (8, 2590.92), (2, 1694.51);

SELECT
    COALESCE(q1.customer_id, q2.customer_id) AS customer_id,
    q1.total AS q1_spend,
    q2.total AS q2_spend,
    CASE
        WHEN q1.customer_id IS NULL THEN 'new in q2'
        WHEN q2.customer_id IS NULL THEN 'gone in q2'
        ELSE 'in both'
    END AS status
FROM tmp_q1_spend q1
LEFT JOIN tmp_q2_spend q2 ON q2.customer_id = q1.customer_id

UNION

SELECT
    COALESCE(q1.customer_id, q2.customer_id) AS customer_id,
    q1.total AS q1_spend,
    q2.total AS q2_spend,
    CASE
        WHEN q1.customer_id IS NULL THEN 'new in q2'
        WHEN q2.customer_id IS NULL THEN 'gone in q2'
        ELSE 'in both'
    END AS status
FROM tmp_q1_spend q1
RIGHT JOIN tmp_q2_spend q2 ON q2.customer_id = q1.customer_id
ORDER BY customer_id;

DROP TEMPORARY TABLE tmp_q1_spend;
DROP TEMPORARY TABLE tmp_q2_spend;

-- ----------------------------------------------------------------------------
-- 5. EXERCISES
-- ----------------------------------------------------------------------------
-- EASY
-- E1.  Emulate a FULL OUTER JOIN of customers and orders. Verify the row
--      count equals COUNT(customers) + COUNT(orders) - COUNT(matched).
--
-- MEDIUM
-- E2.  Compare two derived "customer spend" snapshots (use the orders
--      table partitioned by year) using FULL JOIN emulation. Identify
--      customers who:
--        * spent in 2024 only
--        * spent in 2025 only
--        * spent in both
--
-- HARD
-- E3.  Write the alternative FULL JOIN emulation using LEFT JOIN + UNION
--      ALL + WHERE right.id IS NULL. Explain why this avoids the
--      duplicate-removal sort that UNION performs.
--
-- EXPERT
-- E4.  Explain in a comment when a FULL OUTER JOIN is genuinely the right
--      tool (vs. just using LEFT JOIN or a UNION of two separate queries).
--      Provide an example use case.
-- ============================================================================

-- End of file 05_full_join.sql
