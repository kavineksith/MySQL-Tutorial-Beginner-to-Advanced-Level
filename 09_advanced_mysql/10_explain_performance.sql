-- ============================================================================
-- 10_explain_performance.sql — EXPLAIN, Query Plans, Performance Tuning
-- ============================================================================
-- SKILL LEVEL : Advanced
-- TOPICS      : EXPLAIN, EXPLAIN ANALYZE, type column, key, rows, Extra,
--               filesort, temporary table, covering index, hash join vs
--               nested loop, OPTIMIZER_TRACE.
-- ----------------------------------------------------------------------------
-- TEXTBOOK DEPTH
--   EXPLAIN shows the query plan MySQL's optimizer chose. Reading it tells
--   you whether indexes are being used, how many rows will be scanned,
--   and whether expensive operations (filesort, temp table) will happen.
--
--   EXPLAIN output columns (most important):
--     id            — step id in a multi-step plan
--     select_type   — SIMPLE / PRIMARY / SUBQUERY / DERIVED / UNION
--     table         — which table this step reads
--     type          — access method (CONST, EQ_REF, REF, RANGE, INDEX, ALL)
--                     ALL = full table scan (BAD). INDEX = full index scan
--                     (still bad). RANGE = range scan (good).
--     possible_keys — indexes MySQL could use
--     key           — index MySQL actually chose (NULL = no index)
--     key_len       — bytes of the index used
--     ref           — columns/constants compared to the index
--     rows          — estimated rows MySQL expects to scan
--     filtered      — % of rows passing the WHERE (estimated)
--     Extra         — additional info: 'Using where', 'Using index',
--                     'Using filesort', 'Using temporary' — the last two
--                     are red flags.
--
--   type column access methods (best to worst):
--     system    — table has 0 or 1 row
--     const     — PK or unique lookup, one row
--     eq_ref    — join using PK or unique, one row per outer
--     ref       — non-unique index lookup
//     range     — index range scan (BETWEEN, >, <, IN)
--     index     — full index scan (all index entries)
--     ALL       — full table scan (BAD on large tables)
--
--   Common red flags in Extra:
--     'Using filesort'      — sort happened in memory/disk after the scan
--     'Using temporary'     — a temp table was needed (often with GROUP BY
--                              and DISTINCT)
--     'Using join buffer'   — no usable index for the join
--
--   EXPLAIN ANALYZE (MySQL 8.0.18+) actually runs the query and shows
--   real timings and row counts per step.
-- ============================================================================

USE ecom;

-- ----------------------------------------------------------------------------
-- 1. EXPLAIN a simple lookup by primary key
-- ----------------------------------------------------------------------------
EXPLAIN SELECT * FROM customers WHERE id = 1;
-- type = const, key = PRIMARY, rows = 1. Optimal.

-- ----------------------------------------------------------------------------
-- 2. EXPLAIN an unindexed column lookup — full table scan
-- ----------------------------------------------------------------------------
EXPLAIN SELECT * FROM customers WHERE city = 'Springfield';
-- type = ALL (full scan), key = NULL, rows = 12 (whole table).

-- ----------------------------------------------------------------------------
-- 3. EXPLAIN with index usage
-- ----------------------------------------------------------------------------
EXPLAIN SELECT * FROM customers WHERE last_name = 'Johnson';
-- Uses idx_customers_name.

-- ----------------------------------------------------------------------------
-- 4. EXPLAIN a JOIN
-- ----------------------------------------------------------------------------
EXPLAIN
SELECT c.first_name, o.id, o.total
FROM customers c
JOIN orders o ON o.customer_id = c.id
WHERE c.country = 'United States';

-- Two rows in the output: one for each table.
-- Look at:
--   * which table is the "driving" table (first row in output)
--   * whether the join column uses an index (key column)
--   * whether WHERE filtering used an index

-- ----------------------------------------------------------------------------
-- 5. EXPLAIN FORMAT=TREE (MySQL 8.0+ (SQL:2023 compatible where noted)) — readable join tree
-- ----------------------------------------------------------------------------
EXPLAIN FORMAT=TREE
SELECT c.first_name, o.id
FROM customers c
JOIN orders o ON o.customer_id = c.id
WHERE c.country = 'United States';

-- ----------------------------------------------------------------------------
-- 6. EXPLAIN ANALYZE (MySQL 8.0.18+) — actually run and measure
-- ----------------------------------------------------------------------------
EXPLAIN ANALYZE
SELECT c.first_name, o.id, o.total
FROM customers c
JOIN orders o ON o.customer_id = c.id
WHERE c.country = 'United States';
-- Shows actual rows per step and milliseconds spent.

-- ----------------------------------------------------------------------------
-- 7. Detect filesort and temporary table
-- ----------------------------------------------------------------------------
EXPLAIN
SELECT c.country, COUNT(*) AS cnt
FROM customers c
GROUP BY c.country
ORDER BY cnt DESC;
-- Extra may show 'Using temporary; Using filesort'.

-- Optimization: add an index on the grouping column.
EXPLAIN
SELECT customer_id, COUNT(*)
FROM orders
GROUP BY customer_id;
-- May use the idx_orders_customer index → 'Using index for group-by'.

-- ----------------------------------------------------------------------------
-- 8. Covering index — 'Using index' in Extra
-- ----------------------------------------------------------------------------
-- A covering index contains all columns needed by the query, so the engine
-- reads only the index, not the table rows.
EXPLAIN
SELECT id, last_name, first_name
FROM customers
ORDER BY last_name, first_name;
-- idx_customers_name is on (last_name, first_name) plus the PK is implicit.
-- 'Using index' means it's a covering scan.

-- ----------------------------------------------------------------------------
-- 9. Index merge — using multiple indexes
-- ----------------------------------------------------------------------------
EXPLAIN
SELECT * FROM customers
WHERE last_name = 'Johnson' OR country = 'United States';
-- May show 'Using union(...)' or 'Using sort_union(...)'.

-- ----------------------------------------------------------------------------
-- 10. Range scan
-- ----------------------------------------------------------------------------
EXPLAIN SELECT * FROM orders WHERE order_date BETWEEN '2024-01-01' AND '2024-03-31';
-- type = range, key = idx_orders_date.

-- ----------------------------------------------------------------------------
-- 11. OPTIMIZER_TRACE — see why the optimizer made its choices
-- ----------------------------------------------------------------------------
SET optimizer_trace = 'enabled=on';
SELECT * FROM customers WHERE last_name = 'Johnson';
SELECT * FROM information_schema.OPTIMIZER_TRACE\G
SET optimizer_trace = 'enabled=off';

-- ----------------------------------------------------------------------------
-- 12. Common performance anti-patterns
-- ----------------------------------------------------------------------------
-- ANTI-PATTERN 1: SELECT * when you only need 3 columns.
--   Forces reading entire rows; defeats covering indexes.

-- ANTI-PATTERN 2: WHERE on a function wrapping the indexed column.
--   WHERE DATE(order_date) = '2024-01-15'   -- index NOT used
--   Better: WHERE order_date >= '2024-01-15' AND order_date < '2024-01-16'

-- ANTI-PATTERN 3: Implicit type conversion.
--   WHERE string_col = 123   — defeats the index because of conversion.
--   Better: WHERE string_col = '123'

-- ANTI-PATTERN 4: Leading wildcard LIKE.
--   WHERE name LIKE '%alice%'   — cannot use index.
--   Use FULLTEXT instead.

-- ANTI-PATTERN 5: OR across different columns.
--   WHERE a = 1 OR b = 2   — hard to index; consider UNION.

-- ----------------------------------------------------------------------------
-- 13. EXERCISES
-- ----------------------------------------------------------------------------
-- EASY
-- E1.  Run EXPLAIN on SELECT * FROM products WHERE price > 500. Note the
--      access type and rows.
-- E2.  Run EXPLAIN on SELECT * FROM customers WHERE id = 5. Note type=const.
--
-- MEDIUM
-- E3.  Run EXPLAIN on a 3-table JOIN (customers → orders → order_items).
--      Identify which table is the driving table, which indexes are used.
-- E4.  Find a query whose Extra column shows 'Using filesort'. Modify the
--      query or add an index to eliminate the filesort.
--
-- HARD
-- E5.  Compare two formulations of the same query (one using a function on
--      the column, one without) using EXPLAIN. Show that the function
--      defeats the index.
--
-- EXPERT
-- E6.  Use EXPLAIN ANALYZE to measure actual execution time of a JOIN
--      query. Identify the slowest step. Propose an index that would
--      speed it up.
-- ============================================================================

-- End of file 10_explain_performance.sql
