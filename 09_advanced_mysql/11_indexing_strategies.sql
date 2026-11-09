-- ============================================================================
-- 11_indexing_strategies.sql — Indexing Strategy & Best Practices
-- ============================================================================
-- SKILL LEVEL : Advanced
-- TOPICS      : When to index, composite index column order, covering
--               indexes, redundant indexes, index-only scans, index
--               maintenance, monitoring index usage, slow query log.
-- ----------------------------------------------------------------------------
-- TEXTBOOK DEPTH
--   Indexing is the single highest-leverage performance tuning technique
--   in MySQL. A well-chosen index can turn a 60-second full table scan
--   into a 1-millisecond index lookup.
--
--   Index design principles:
--     1. Index columns used in WHERE, JOIN ON, ORDER BY, GROUP BY.
--     2. Choose COMPOSITE indexes with the most selective column first
--        (usually the one with the most distinct values).
--     3. Obey the LEFTMOST-PREFIX rule: an index on (a, b, c) can be used
--        for queries filtering (a), (a, b), or (a, b, c) — not (b) alone.
--     4. Place equality columns before range columns:
--        (equality_col, range_col) beats (range_col, equality_col).
--     5. Add COVERING indexes for hot queries — include all columns
--        referenced in SELECT, WHERE, ORDER BY.
--     6. Avoid indexing low-cardinality columns alone (e.g. boolean
--        is_active has only 2 values — the index is barely selective).
--     7. Don't over-index. Each index slows writes (INSERT/UPDATE/DELETE
--        must maintain every index) and consumes disk.
--
--   Index maintenance:
--     * Run ANALYZE TABLE after large data loads to refresh statistics.
--     * Use OPTIMIZE TABLE periodically for fragmented tables.
--     * Drop unused indexes (check via performance_schema or slow log).
--
--   Monitoring tools:
--     * SHOW INDEX FROM tbl
--     * EXPLAIN (covered in 10_explain_performance.sql)
--     * performance_schema.table_io_waits_summary_by_table
--     * sys.schema_unused_indexes
--     * sys.schema_redundant_indexes
-- ============================================================================

USE ecom;

-- ----------------------------------------------------------------------------
-- 1. Review existing indexes on key tables
-- ----------------------------------------------------------------------------
SHOW INDEX FROM customers;
SHOW INDEX FROM orders;
SHOW INDEX FROM products;

-- ----------------------------------------------------------------------------
-- 2. Composite index design — order matters
-- ----------------------------------------------------------------------------
-- Suppose we frequently query:
--   SELECT * FROM orders WHERE customer_id = ? AND status = ? ORDER BY order_date;
-- The ideal composite index is (customer_id, status, order_date).
-- All three are equality columns except order_date which is a sort.

-- Check if our schema already has it:
SHOW INDEX FROM orders WHERE Key_name = 'idx_orders_customer';
-- We have (customer_id) only. For the above query, MySQL could use it but
-- would still need a filesort on order_date.

-- Demonstrate:
EXPLAIN SELECT * FROM orders
WHERE customer_id = 1 AND status = 'delivered'
ORDER BY order_date;

-- Better index would be (customer_id, status, order_date) — covering for
-- this query.
-- ALTER TABLE orders ADD INDEX idx_cust_status_date (customer_id, status, order_date);

-- ----------------------------------------------------------------------------
-- 3. Covering index — 'Using index' in EXPLAIN
-- ----------------------------------------------------------------------------
-- A covering index includes every column referenced in the query.
-- The engine reads the index alone — never the table rows.
EXPLAIN SELECT customer_id, COUNT(*)
FROM orders
GROUP BY customer_id;
-- If we had idx_orders_customer(customer_id) covering these columns,
-- Extra would show 'Using index'.

-- ----------------------------------------------------------------------------
-- 4. Leftmost-prefix rule demo
-- ----------------------------------------------------------------------------
-- Create a temp table with composite index (a, b, c):
DROP TABLE IF EXISTS tmp_composite;
CREATE TABLE tmp_composite (
    a INT, b INT, c INT, d VARCHAR(20),
    INDEX idx_abc (a, b, c)
);
INSERT INTO tmp_composite VALUES
    (1, 10, 100, 'one'), (1, 10, 200, 'two'), (1, 20, 100, 'three'),
    (2, 10, 100, 'four'), (2, 20, 200, 'five');

-- Uses index (leftmost prefix a):
EXPLAIN SELECT * FROM tmp_composite WHERE a = 1;

-- Uses index (a + b):
EXPLAIN SELECT * FROM tmp_composite WHERE a = 1 AND b = 10;

-- Uses index (a + b + c):
EXPLAIN SELECT * FROM tmp_composite WHERE a = 1 AND b = 10 AND c = 100;

-- Does NOT use index (b is not leftmost):
EXPLAIN SELECT * FROM tmp_composite WHERE b = 10;

-- Does NOT use index (c is not leftmost):
EXPLAIN SELECT * FROM tmp_composite WHERE c = 100;

DROP TABLE tmp_composite;

-- ----------------------------------------------------------------------------
-- 5. Equality before range in composite index
-- ----------------------------------------------------------------------------
-- Index on (status, customer_id, order_date) is suboptimal if we filter
-- status = 'paid' AND customer_id > 5 — because the range on customer_id
-- prevents order_date from being used.
-- Better: (status, order_date) and a separate filter on customer_id.

-- ----------------------------------------------------------------------------
-- 6. Redundant indexes — find and drop
-- ----------------------------------------------------------------------------
-- An index on (a) is REDUNDANT if there's already an index on (a, b) —
-- the composite can serve both queries.
SELECT
    OBJECT_SCHEMA, OBJECT_NAME, INDEX_NAME,
    GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX) AS columns
FROM performance_schema.index_statistics
WHERE OBJECT_SCHEMA = 'ecom'
GROUP BY OBJECT_SCHEMA, OBJECT_NAME, INDEX_NAME;

-- sys.schema_redundant_indexes (if sys schema is installed):
SELECT * FROM sys.schema_redundant_indexes WHERE table_schema = 'ecom';

-- ----------------------------------------------------------------------------
-- 7. Unused indexes — find and drop
-- ----------------------------------------------------------------------------
-- sys.schema_unused_indexes shows indexes not used since server start.
SELECT * FROM sys.schema_unused_indexes WHERE object_schema = 'ecom';
-- Note: requires the server to have been running long enough to gather stats.

-- ----------------------------------------------------------------------------
-- 8. Index hints — FORCE INDEX / USE INDEX / IGNORE INDEX
-- ----------------------------------------------------------------------------
-- USE INDEX (idx_name)         — prefer this index, optimizer may still
--                                 choose another if it thinks it's better.
-- FORCE INDEX (idx_name)       — stronger; assume table scan is expensive.
-- IGNORE INDEX (idx_name)      — don't use this index.

EXPLAIN SELECT * FROM customers USE INDEX (idx_customers_name)
WHERE last_name = 'Johnson';

EXPLAIN SELECT * FROM customers IGNORE INDEX (idx_customers_name)
WHERE last_name = 'Johnson';
-- May fall back to a full table scan.

-- ----------------------------------------------------------------------------
-- 9. Functional index on an expression (MySQL 8.0.13+)
-- ----------------------------------------------------------------------------
-- For WHERE LOWER(email) = '...', create a functional index:
-- CREATE INDEX idx_lower_email ON customers ((LOWER(email)));

DROP TABLE IF EXISTS tmp_func_idx;
CREATE TABLE tmp_func_idx (id INT AUTO_INCREMENT PRIMARY KEY, email VARCHAR(100));
INSERT INTO tmp_func_idx (email) VALUES ('Alice@x.com'), ('Bob@x.com');

CREATE INDEX idx_lower ON tmp_func_idx ((LOWER(email)));
EXPLAIN SELECT * FROM tmp_func_idx WHERE LOWER(email) = 'alice@x.com';
-- Should use idx_lower.

DROP TABLE tmp_func_idx;

-- ----------------------------------------------------------------------------
-- 10. ANALYZE TABLE — refresh statistics
-- ----------------------------------------------------------------------------
ANALYZE TABLE customers;
ANALYZE TABLE orders;
-- Updates the optimizer's row-count estimates so it picks better plans.

-- ----------------------------------------------------------------------------
-- 11. OPTIMIZE TABLE — defragment (InnoDB recreates the table)
-- ----------------------------------------------------------------------------
-- OPTIMIZE TABLE customers;   -- on a small test table this is fine; on
-- large production tables, schedule during a maintenance window.

-- ----------------------------------------------------------------------------
-- 12. Slow query log — find queries that need optimization
-- ----------------------------------------------------------------------------
SHOW VARIABLES LIKE 'slow_query_log';
SHOW VARIABLES LIKE 'long_query_time';
SHOW VARIABLES LIKE 'slow_query_log_file';
-- Enable temporarily:
-- SET GLOBAL slow_query_log = 'ON';
-- SET GLOBAL long_query_time = 1;   -- log queries slower than 1 second

-- ----------------------------------------------------------------------------
-- 13. EXERCISES
-- ----------------------------------------------------------------------------
-- EASY
-- E1.  Show all indexes on the orders table with SHOW INDEX.
-- E2.  Use EXPLAIN to verify a query on orders.customer_id uses the index.
--
-- MEDIUM
-- E3.  Create a temp table with composite index (a, b, c) and demonstrate
--      the leftmost-prefix rule with 5 different queries.
-- E4.  Find redundant or unused indexes using the sys schema views.
--
-- HARD
-- E5.  Design a composite index for the query:
--        SELECT * FROM orders WHERE customer_id = ? AND status = ?
--        ORDER BY order_date;
--      Justify the column order. Verify with EXPLAIN that the filesort
--      disappears.
--
-- EXPERT
-- E6.  Explain in a comment why placing a RANGE column before an EQUALITY
--      column in a composite index is suboptimal. Provide a concrete
--      example with EXPLAIN output.
-- ============================================================================

-- End of file 11_indexing_strategies.sql
