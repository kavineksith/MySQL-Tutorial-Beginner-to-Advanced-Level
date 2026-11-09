-- ============================================================================
-- 04_right_join.sql — RIGHT OUTER JOIN
-- ============================================================================
-- SKILL LEVEL : Intermediate
-- TOPICS      : RIGHT JOIN preserves all right rows, when to use, why it's
--               rarely used (always rewrite as LEFT JOIN), multi-table
--               RIGHT JOIN, RIGHT JOIN with aggregates.
-- ----------------------------------------------------------------------------
-- TEXTBOOK DEPTH
--   RIGHT OUTER JOIN returns every row from the RIGHT table. For each right
--   row, MySQL looks for matching left rows:
--     * Matches → cross product.
--     * No match → right row with NULL in left columns.
--
--   RIGHT JOIN is the mirror image of LEFT JOIN. In practice you almost
--   always rewrite `A RIGHT JOIN B` as `B LEFT JOIN A` because:
--     * Most people read left-to-right and find LEFT JOIN more natural.
--     * Mixing LEFT and RIGHT in a multi-table join produces confusing
--       semantics (which side is preserved?). Many style guides forbid
--       RIGHT JOIN entirely.
--
--   Legitimate uses:
--     * Quick exploration when you've already typed a JOIN and want to see
--       what right-only rows exist.
--     * Schema introspection against information_schema.
-- ============================================================================

USE ecom;

-- ----------------------------------------------------------------------------
-- 1. Basic RIGHT JOIN — every order, with any matching customer
-- ----------------------------------------------------------------------------
SELECT
    c.first_name,
    c.last_name,
    o.id AS order_id,
    o.customer_id,
    o.total
FROM customers c
RIGHT JOIN orders o ON o.customer_id = c.id
ORDER BY o.id;
-- Every order appears; if customer_id were orphaned (impossible under FK),
-- customer columns would be NULL.

-- ----------------------------------------------------------------------------
-- 2. RIGHT JOIN — find orders whose customer is missing (data quality)
-- ----------------------------------------------------------------------------
SELECT o.id AS orphan_order_id, o.customer_id
FROM customers c
RIGHT JOIN orders o ON o.customer_id = c.id
WHERE c.id IS NULL;
-- Empty under our schema (FK prevents this), but useful for diagnostic
-- queries when FKs are missing or disabled.

-- ----------------------------------------------------------------------------
-- 3. RIGHT JOIN rewritten as LEFT JOIN (preferred form)
-- ----------------------------------------------------------------------------
-- A RIGHT JOIN B  ≡  B LEFT JOIN A
SELECT
    c.first_name,
    c.last_name,
    o.id AS order_id,
    o.total
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.id
ORDER BY o.id;

-- ----------------------------------------------------------------------------
-- 4. RIGHT JOIN with aggregate — preserve all right rows
-- ----------------------------------------------------------------------------
-- Order count per product, INCLUDING products with zero orders.
SELECT
    p.sku,
    p.name,
    COUNT(oi.id) AS times_ordered
FROM order_items oi
RIGHT JOIN products p ON p.id = oi.product_id
GROUP BY p.id, p.sku, p.name
ORDER BY times_ordered DESC, p.sku;

-- Cleaner as LEFT JOIN:
SELECT
    p.sku,
    p.name,
    COUNT(oi.id) AS times_ordered
FROM products p
LEFT JOIN order_items oi ON oi.product_id = p.id
GROUP BY p.id, p.sku, p.name
ORDER BY times_ordered DESC, p.sku;

-- ----------------------------------------------------------------------------
-- 5. RIGHT JOIN with multi-table chain (confusing — avoid)
-- ----------------------------------------------------------------------------
-- Mixing LEFT and RIGHT joins in one query is legal but confusing.
-- Avoid; rewrite as all-LEFT.
SELECT
    c.first_name,
    o.id AS order_id,
    p.name AS product_name
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
RIGHT JOIN order_items oi ON oi.order_id = o.id
LEFT JOIN products p ON p.id = oi.product_id
ORDER BY c.id, o.id, oi.id
LIMIT 5;
-- Reads: "All order_items, optionally joined to (customer-orders joined
-- to customers) and to products." This is correct but hard to reason about.

-- ----------------------------------------------------------------------------
-- 6. RIGHT JOIN to find right-only rows
-- ----------------------------------------------------------------------------
-- Products that have never been ordered, using RIGHT JOIN.
SELECT p.sku, p.name
FROM order_items oi
RIGHT JOIN products p ON p.id = oi.product_id
WHERE oi.id IS NULL;

-- ----------------------------------------------------------------------------
-- 7. EXERCISES
-- ----------------------------------------------------------------------------
-- EASY
-- E1.  Write a RIGHT JOIN of customers → orders. Verify it returns the
--      same row count as orders.
-- E2.  Rewrite the query from E1 as a LEFT JOIN.
--
-- MEDIUM
-- E3.  Use RIGHT JOIN to find products that have never been reviewed.
-- E4.  Use RIGHT JOIN to compute the review count per product, preserving
--      products with zero reviews.
--
-- HARD
-- E5.  Explain in a comment why most style guides forbid RIGHT JOIN. Give
--      an example of a query that mixes LEFT and RIGHT joins and is hard
--      to reason about.
--
-- EXPERT
-- E6.  Take any query you wrote using RIGHT JOIN and rewrite it as an
--      all-LEFT-JOIN chain. Verify both produce the same row count and
--      column values.
-- ============================================================================

-- End of file 04_right_join.sql
