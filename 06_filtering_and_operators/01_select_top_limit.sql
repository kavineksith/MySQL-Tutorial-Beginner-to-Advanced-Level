-- ============================================================================
-- 01_select_top_limit.sql — LIMIT, OFFSET, and FETCH (Top-N Queries)
-- ============================================================================
-- SKILL LEVEL : Beginner
-- TOPICS      : LIMIT, LIMIT/OFFSET, SQL Server TOP equivalent, pagination,
--               Top-N with ORDER BY, deferred join optimization.
-- ----------------------------------------------------------------------------
-- TEXTBOOK DEPTH
--   Some tutorials teach "SELECT TOP n" because it follows SQL Server syntax.
--   MySQL uses the LIMIT clause instead. They serve the same purpose:
--   restrict the number of rows returned.
--
--   Syntax variants:
--     LIMIT n                  -- first n rows
--     LIMIT n OFFSET m         -- skip m rows, return next n
--     LIMIT m, n               -- MySQL legacy form: skip m, return n
--                               (rarely used; confusing argument order)
--
--   Key facts:
--     * Without ORDER BY, the rows returned are arbitrary. ALWAYS pair LIMIT
--       with ORDER BY when you care about which rows come back.
--     * LIMIT applied AFTER the result set is materialized, so the engine
--       still has to compute the full result then discard. For huge tables,
--       use a "deferred join" or keyset pagination.
--     * OFFSET is EXPENSIVE on large tables: the engine still reads all
--       skipped rows. Prefer keyset (seek) pagination for deep pages.
-- ============================================================================

USE ecom;

-- ----------------------------------------------------------------------------
-- 1. Simple LIMIT
-- ----------------------------------------------------------------------------
SELECT first_name, last_name
FROM customers
LIMIT 5;

-- ----------------------------------------------------------------------------
-- 2. LIMIT with ORDER BY — the correct pattern
-- ----------------------------------------------------------------------------
SELECT name, price
FROM products
ORDER BY price DESC
LIMIT 3;                       -- three most expensive products

-- ----------------------------------------------------------------------------
-- 3. LIMIT + OFFSET — pagination
-- ----------------------------------------------------------------------------
-- Page 1: rows 1-3
SELECT name, price FROM products ORDER BY price DESC LIMIT 3 OFFSET 0;
-- Page 2: rows 4-6
SELECT name, price FROM products ORDER BY price DESC LIMIT 3 OFFSET 3;
-- Page 3: rows 7-9
SELECT name, price FROM products ORDER BY price DESC LIMIT 3 OFFSET 6;

-- ----------------------------------------------------------------------------
-- 4. Legacy comma form (avoid)
-- ----------------------------------------------------------------------------
-- LIMIT 3, 5 means OFFSET 3 LIMIT 5 — confusing and easy to get wrong.
-- Always write the explicit OFFSET form.
SELECT name, price FROM products ORDER BY price DESC LIMIT 3, 3;   -- rows 4-6

-- ----------------------------------------------------------------------------
-- 5. Top-N per category — without window functions
-- ----------------------------------------------------------------------------
-- Find the single most expensive product per category (pre-window-function
-- pattern using a correlated subquery):
SELECT p.category_id, p.name, p.price
FROM products p
WHERE p.price = (
    SELECT MAX(p2.price)
    FROM products p2
    WHERE p2.category_id = p.category_id
)
ORDER BY p.category_id;
-- Modern way uses ROW_NUMBER() — see 09_advanced_mysql/01_window_functions.sql.

-- ----------------------------------------------------------------------------
-- 6. Deferred join — speed up deep LIMIT/OFFSET
-- ----------------------------------------------------------------------------
-- Naive deep pagination (page 1000):
--   SELECT * FROM orders ORDER BY id LIMIT 20 OFFSET 19980;
-- The engine scans 20000 rows then discards 19980.
--
-- Deferred join: first SELECT only the IDs we need, then JOIN back to fetch
-- full rows. The inner subquery can use a covering index on the PK:
SELECT o.*
FROM orders o
JOIN (
    SELECT id FROM orders ORDER BY id LIMIT 20 OFFSET 19980
) AS ids ON ids.id = o.id;

-- ----------------------------------------------------------------------------
-- 7. Keyset (seek) pagination — the right way for deep pages
-- ----------------------------------------------------------------------------
-- Instead of OFFSET, remember the last seen value of the sort key and ask
-- for rows strictly greater than it. O(log n) lookup, no skipped-row cost.
SET @last_seen_id := 0;
SELECT id, name, price
FROM products
WHERE id > @last_seen_id
ORDER BY id ASC
LIMIT 5;
-- Next "page": set @last_seen_id := (last id from result), re-run.

-- ----------------------------------------------------------------------------
-- 8. LIMIT in UPDATE / DELETE
-- ----------------------------------------------------------------------------
-- Update the 2 cheapest products (see 09_update.sql).
-- Delete the 3 oldest pending rows (see 10_delete.sql).

-- ----------------------------------------------------------------------------
-- 9. SQL standard: FETCH FIRST n ROWS ONLY (MySQL 8.0.19+)
-- ----------------------------------------------------------------------------
SELECT name, price FROM products
ORDER BY price DESC
FETCH FIRST 3 ROWS ONLY;

SELECT name, price FROM products
ORDER BY price DESC
OFFSET 3 ROWS
FETCH NEXT 3 ROWS ONLY;

-- ----------------------------------------------------------------------------
-- 10. EXERCISES
-- ----------------------------------------------------------------------------
-- EASY
-- E1.  Return the 5 newest customers (highest id).
-- E2.  Return the 3 cheapest products.
--
-- MEDIUM
-- E3.  Implement a 4-row-per-page pagination over the products table.
--      Write 3 queries that return rows 1-4, 5-8, and 9-12.
-- E4.  Find the most expensive product in each category using a correlated
--      subquery (the pre-window-function approach shown above).
--
-- HARD
-- E5.  Find the top 3 customers by total spend. Use a subquery that sums
--      `total` from orders per customer, then ORDER BY DESC LIMIT 3.
--
-- EXPERT
-- E6.  Write a keyset (seek) pagination loop that returns 5 products at a
--      time starting from id=0, with two follow-up "pages" by passing the
--      last id seen. Demonstrate by running 3 queries that fetch rows
--      1-5, 6-10, 11-15 without using OFFSET.
-- ============================================================================

-- End of file 01_select_top_limit.sql
