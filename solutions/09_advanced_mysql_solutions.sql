-- ============================================================================
-- 09_advanced_mysql_solutions.sql — Solutions for 09_advanced_mysql
-- ============================================================================

USE ecom;

-- ============================================================================
-- 01_window_functions.sql
-- ============================================================================

-- E1. row_number ordered by price DESC
SELECT sku, name, price,
    ROW_NUMBER() OVER (ORDER BY price DESC) AS rn
FROM products;

-- E2. rank within category by price
SELECT sku, name, category_id, price,
    RANK() OVER (PARTITION BY category_id ORDER BY price DESC) AS rank_in_cat
FROM products
ORDER BY category_id, rank_in_cat;

-- E3. previous order's total per customer + delta
SELECT customer_id, id AS order_id, order_date, total,
    LAG(total) OVER (PARTITION BY customer_id ORDER BY order_date) AS prev_total,
    total - LAG(total) OVER (PARTITION BY customer_id ORDER BY order_date) AS delta
FROM orders
ORDER BY customer_id, order_date;

-- E4. running_total per customer
SELECT customer_id, id AS order_id, order_date, total,
    SUM(total) OVER (PARTITION BY customer_id ORDER BY order_date) AS running_total
FROM orders
WHERE status NOT IN ('cancelled', 'refunded')
ORDER BY customer_id, order_date;

-- E5. top 2 products per category
WITH ranked AS (
    SELECT sku, name, category_id, price,
        ROW_NUMBER() OVER (PARTITION BY category_id ORDER BY price DESC) AS rn
    FROM products
)
SELECT sku, name, category_id, price
FROM ranked WHERE rn <= 2
ORDER BY category_id, rn;

-- E6. first/last order total per customer
SELECT customer_id, id AS order_id, total,
    FIRST_VALUE(total) OVER (
        PARTITION BY customer_id ORDER BY order_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS first_total,
    LAST_VALUE(total) OVER (
        PARTITION BY customer_id ORDER BY order_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS last_total
FROM orders
ORDER BY customer_id, order_date;

-- E7. cumulative revenue + pct of cumulative + pct of total
SELECT customer_id, order_date, total,
    SUM(total) OVER (PARTITION BY customer_id ORDER BY order_date) AS cum_revenue,
    SUM(total) OVER (PARTITION BY customer_id) AS total_revenue,
    ROUND(total / SUM(total) OVER (PARTITION BY customer_id) * 100, 2) AS pct_of_total
FROM orders
WHERE status NOT IN ('cancelled', 'refunded')
ORDER BY customer_id, order_date;

-- ============================================================================
-- 02_ctes.sql
-- ============================================================================

-- E1. CTE selecting products > 500, sorted by price
WITH expensive AS (
    SELECT sku, name, price FROM products WHERE price > 500
)
SELECT * FROM expensive ORDER BY price DESC;

-- E2. cust_orders CTE → top 5 by total
WITH cust_orders AS (
    SELECT c.first_name, c.last_name, o.id AS order_id, o.total
    FROM customers c JOIN orders o ON o.customer_id = c.id
)
SELECT first_name, last_name, SUM(total) AS grand_total
FROM cust_orders
GROUP BY first_name, last_name
ORDER BY grand_total DESC
LIMIT 5;

-- E3. two CTEs joined
WITH order_summary AS (
    SELECT customer_id, COUNT(*) AS n, SUM(total) AS s
    FROM orders WHERE status NOT IN ('cancelled', 'refunded')
    GROUP BY customer_id
),
review_summary AS (
    SELECT customer_id, COUNT(*) AS n, AVG(rating) AS avg_rating
    FROM reviews GROUP BY customer_id
)
SELECT c.first_name, c.last_name,
    COALESCE(os.n, 0) AS orders, COALESCE(os.s, 0) AS spent,
    COALESCE(rs.n, 0) AS reviews, ROUND(rs.avg_rating, 2) AS avg_rating
FROM customers c
LEFT JOIN order_summary os ON os.customer_id = c.id
LEFT JOIN review_summary rs ON rs.customer_id = c.id
ORDER BY spent DESC;

-- E4. CTE in INSERT ... SELECT
DROP TABLE IF EXISTS tmp_summary;
CREATE TABLE tmp_summary (customer_id BIGINT, total DECIMAL(10,2));
WITH spend AS (
    SELECT customer_id, SUM(total) AS total
    FROM orders WHERE status NOT IN ('cancelled', 'refunded')
    GROUP BY customer_id
)
INSERT INTO tmp_summary (customer_id, total)
SELECT customer_id, total FROM spend;
SELECT * FROM tmp_summary ORDER BY total DESC LIMIT 5;
DROP TABLE tmp_summary;

-- E5. latest order status per customer → mark inactive
DROP TEMPORARY TABLE IF EXISTS tmp_latest;
CREATE TEMPORARY TABLE tmp_latest AS
WITH ranked AS (
    SELECT customer_id, status,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date DESC) AS rn
    FROM orders
)
SELECT customer_id, status FROM ranked WHERE rn = 1;

START TRANSACTION;
UPDATE customers c
JOIN tmp_latest t ON t.customer_id = c.id
SET c.is_active = 0
WHERE t.status = 'cancelled';
ROLLBACK;
DROP TEMPORARY TABLE tmp_latest;

-- E6. MATERIALIZED vs inline
-- The optimizer usually inlines (merges) CTEs into the outer query — same
-- as a subquery. It materializes (computes once, stores) when:
--   * The CTE is referenced multiple times.
--   * The CTE is non-mergeable (e.g. uses LIMIT, aggregate without GROUP BY).
--   * You force with MATERIALIZED hint.
-- Force inline with NOT MATERIALIZED.

-- ============================================================================
-- 03_recursive_ctes.sql
-- ============================================================================

-- E1. numbers 1-20
WITH RECURSIVE nums(n) AS (
    SELECT 1 UNION ALL SELECT n+1 FROM nums WHERE n < 20
)
SELECT n FROM nums;

-- E2. every day of Feb 2024
WITH RECURSIVE cal(d) AS (
    SELECT DATE '2024-02-01'
    UNION ALL
    SELECT d + INTERVAL 1 DAY FROM cal WHERE d < '2024-02-29'
)
SELECT d FROM cal;

-- E3. org chart CEO down with depth + path
WITH RECURSIVE org AS (
    SELECT id, first_name, last_name, manager_id, title, 1 AS depth,
           CAST(CONCAT(first_name, ' ', last_name) AS CHAR(500)) AS path
    FROM employees WHERE manager_id IS NULL
    UNION ALL
    SELECT e.id, e.first_name, e.last_name, e.manager_id, e.title, o.depth+1,
           CONCAT(o.path, ' > ', e.first_name, ' ', e.last_name)
    FROM employees e JOIN org o ON e.manager_id = o.id
)
SELECT depth, id, first_name, last_name, title, path FROM org ORDER BY path;

-- E4. management chain for emp 9 up to CEO
WITH RECURSIVE chain AS (
    SELECT id, first_name, last_name, manager_id, title, 1 AS depth
    FROM employees WHERE id = 9
    UNION ALL
    SELECT e.id, e.first_name, e.last_name, e.manager_id, e.title, c.depth+1
    FROM employees e JOIN chain c ON c.manager_id = e.id
)
SELECT depth, id, first_name, last_name, title FROM chain ORDER BY depth;

-- E5. descendant count per root category
WITH RECURSIVE descendants AS (
    SELECT id AS root_id, id AS desc_id FROM categories
    UNION ALL
    SELECT d.root_id, c.id
    FROM descendants d JOIN categories c ON c.parent_id = d.desc_id
)
SELECT r.name AS root, COUNT(DISTINCT d.desc_id) - 1 AS descendant_count
FROM descendants d JOIN categories r ON r.id = d.root_id
GROUP BY r.id, r.name
ORDER BY descendant_count DESC;

-- E6. date series LEFT JOINed to orders
WITH RECURSIVE cal(d) AS (
    SELECT DATE '2024-01-01'
    UNION ALL
    SELECT d + INTERVAL 1 DAY FROM cal WHERE d < '2024-12-31'
)
SELECT d AS day, COUNT(o.id) AS orders_placed
FROM cal d
LEFT JOIN orders o ON DATE(o.order_date) = d
GROUP BY d
ORDER BY d
LIMIT 10;

-- E7. cycle detection
-- Naive recursion loops forever because each step finds the cycle's next
-- node, never reaching a base case. Detect by tracking visited ids in a
-- path column and stopping when the next node is already in the path.
CREATE TEMPORARY TABLE tmp_cyc (id INT, parent_id INT);
INSERT INTO tmp_cyc VALUES (1, 2), (2, 3), (3, 1);
WITH RECURSIVE walk AS (
    SELECT id, parent_id, CAST(CONCAT(',', id, ',') AS CHAR(500)) AS visited
    FROM tmp_cyc WHERE id = 1
    UNION ALL
    SELECT c.id, c.parent_id, CONCAT(w.visited, c.id, ',')
    FROM tmp_cyc c JOIN walk w ON c.id = w.parent_id
    WHERE FIND_IN_SET(c.id, REPLACE(SUBSTRING(w.visited, 2), ',', ',')) = 0
)
SELECT * FROM walk;
DROP TEMPORARY TABLE tmp_cyc;

-- ============================================================================
-- 04_json_functions.sql
-- ============================================================================

-- E1. loyalty_points via ->>
SELECT first_name, metadata->>'$.loyalty_points' AS loyalty_points
FROM customers WHERE metadata IS NOT NULL;

-- E2. tags contains newsletter
SELECT first_name, metadata FROM customers
WHERE metadata IS NOT NULL
  AND JSON_CONTAINS(metadata->'$.tags', '"newsletter"');

-- E3. add signup_source path then remove
UPDATE customers
SET metadata = JSON_SET(metadata, '$.signup_source', 'web')
WHERE id = 1;
SELECT metadata FROM customers WHERE id = 1;
UPDATE customers
SET metadata = JSON_REMOVE(metadata, '$.signup_source')
WHERE id = 1;

-- E4. JSON_ARRAYAGG order ids per customer
SELECT c.id, c.first_name, JSON_ARRAYAGG(o.id) AS order_ids
FROM customers c LEFT JOIN orders o ON o.customer_id = c.id
GROUP BY c.id, c.first_name
LIMIT 5;

-- E5. JSON_TABLE flatten
SET @j := '[{"id":1,"name":"A"},{"id":2,"name":"B"},{"id":3,"name":"C"}]';
SELECT * FROM JSON_TABLE(
    @j, '$[*]' COLUMNS (
        id INT PATH '$.id',
        name VARCHAR(50) PATH '$.name'
    )
) AS jt;

-- E6. multi-valued index + MEMBER OF
DROP TABLE IF EXISTS tmp_mvi;
CREATE TABLE tmp_mvi (
    id INT AUTO_INCREMENT PRIMARY KEY,
    data JSON,
    INDEX idx_tags ((CAST(data->'$.tags' AS CHAR(20) ARRAY)))
);
INSERT INTO tmp_mvi (data) VALUES
    ('{"tags":["vip","newsletter"]}'),
    ('{"tags":["new"]}');
SELECT * FROM tmp_mvi WHERE 'vip' MEMBER OF (data->'$.tags');
DROP TABLE tmp_mvi;

-- E7. JSON columns vs normalization
-- Use JSON when:
--   * The schema is genuinely variable per row (e.g. user-defined
--     attributes, plugin settings).
--   * The data is read as a whole and rarely queried by individual keys.
-- Normalize into columns when:
--   * A field is queried or aggregated often — index it properly.
--   * The field has constraints (NOT NULL, UNIQUE, FK).
--   * The field participates in JOINs.
-- Concrete example: tags should be a separate tags table + link table
-- if you need to query "all customers with tag X" efficiently. JSON array
-- + multi-valued index is fine for simpler use cases.

-- ============================================================================
-- 05_triggers.sql
-- ============================================================================

-- E1. BEFORE INSERT trigger sets created_at if NULL
DROP TABLE IF EXISTS tmp_trig1;
CREATE TABLE tmp_trig1 (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(20), created_at TIMESTAMP NULL);

DELIMITER //
DROP TRIGGER IF EXISTS tmp_trig1_before_insert //
CREATE TRIGGER tmp_trig1_before_insert
BEFORE INSERT ON tmp_trig1
FOR EACH ROW
BEGIN
    IF NEW.created_at IS NULL THEN
        SET NEW.created_at = NOW();
    END IF;
END //
DELIMITER ;

INSERT INTO tmp_trig1 (name) VALUES ('alice');
SELECT * FROM tmp_trig1;
DROP TRIGGER tmp_trig1_before_insert;
DROP TABLE tmp_trig1;

-- E2. AFTER INSERT trigger logs
DROP TABLE IF EXISTS tmp_src2;
DROP TABLE IF EXISTS tmp_log2;
CREATE TABLE tmp_src2 (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(20));
CREATE TABLE tmp_log2 (id INT AUTO_INCREMENT PRIMARY KEY, msg VARCHAR(100), ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP);

DELIMITER //
DROP TRIGGER IF EXISTS tmp_src2_after_insert //
CREATE TRIGGER tmp_src2_after_insert
AFTER INSERT ON tmp_src2
FOR EACH ROW
BEGIN
    INSERT INTO tmp_log2 (msg) VALUES (CONCAT('inserted id=', NEW.id, ' name=', NEW.name));
END //
DELIMITER ;

INSERT INTO tmp_src2 (name) VALUES ('alice');
SELECT * FROM tmp_log2;
DROP TRIGGER tmp_src2_after_insert;
DROP TABLE tmp_src2;
DROP TABLE tmp_log2;

-- E3-E6: patterns are illustrated in the source file. Try writing your
-- own first; compare against 09_advanced_mysql/05_triggers.sql.

-- ============================================================================
-- 06_events.sql — Solutions
-- ============================================================================

-- E1. one-shot event 1 min from now
DROP EVENT IF EXISTS ev_e1;
SET GLOBAL event_scheduler = ON;   -- if not already
CREATE EVENT ev_e1
ON SCHEDULE AT CURRENT_TIMESTAMP + INTERVAL 1 MINUTE
ON COMPLETION NOT PRESERVE
DO
    INSERT INTO tmp_e1_log (msg) VALUES (CONCAT('ev_e1 fired at ', NOW()));

-- E2. every 1 minute log
DROP TABLE IF EXISTS tmp_e1_log;
CREATE TABLE tmp_e1_log (id INT AUTO_INCREMENT PRIMARY KEY, msg VARCHAR(100), ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP);

DROP EVENT IF EXISTS ev_e2;
CREATE EVENT ev_e2
ON SCHEDULE EVERY 1 MINUTE
DO
    INSERT INTO tmp_e1_log (msg) VALUES (CONCAT('ev_e2 fired at ', NOW()));

-- After a minute, disable:
-- ALTER EVENT ev_e2 DISABLE;
-- DROP EVENT ev_e2;
-- DROP TABLE tmp_e1_log;

-- ============================================================================
-- 07_transactions.sql — Solutions
-- ============================================================================

-- E1. transaction rollback
DROP TABLE IF EXISTS tmp_tx1;
CREATE TABLE tmp_tx1 (id INT PRIMARY KEY, val VARCHAR(20));
START TRANSACTION;
INSERT INTO tmp_tx1 VALUES (1, 'a');
SELECT COUNT(*) FROM tmp_tx1;
ROLLBACK;
SELECT COUNT(*) FROM tmp_tx1;   -- 0
DROP TABLE tmp_tx1;

-- E2. transaction commit
DROP TABLE IF EXISTS tmp_tx2;
CREATE TABLE tmp_tx2 (id INT PRIMARY KEY, val VARCHAR(20));
START TRANSACTION;
INSERT INTO tmp_tx2 VALUES (1, 'a');
COMMIT;
SELECT COUNT(*) FROM tmp_tx2;   -- 1
DROP TABLE tmp_tx2;

-- E3. SAVEPOINT partial rollback
DROP TABLE IF EXISTS tmp_tx3;
CREATE TABLE tmp_tx3 (id INT PRIMARY KEY, val VARCHAR(20));
START TRANSACTION;
INSERT INTO tmp_tx3 VALUES (1, 'A');
SAVEPOINT sp;
INSERT INTO tmp_tx3 VALUES (2, 'B');
ROLLBACK TO SAVEPOINT sp;
COMMIT;
SELECT * FROM tmp_tx3;   -- only id=1
DROP TABLE tmp_tx3;

-- E4-E6: see source file patterns.

-- ============================================================================
-- 08_locks_isolation.sql — Solutions
-- ============================================================================

-- E1. SELECT FOR UPDATE
START TRANSACTION;
SELECT id, name, stock_qty FROM products WHERE id = 1 FOR UPDATE;
UPDATE products SET stock_qty = stock_qty - 1 WHERE id = 1;
COMMIT;

-- E2. S vs X lock
-- Shared (S) lock: multiple readers can hold simultaneously; blocks writers.
-- Exclusive (X) lock: only one writer at a time; blocks both readers
-- (under SERIALIZABLE) and writers.

-- E3. optimistic locking demo
DROP TABLE IF EXISTS tmp_opt;
CREATE TABLE tmp_opt (id INT PRIMARY KEY, name VARCHAR(20), version INT DEFAULT 0);
INSERT INTO tmp_opt (id, name) VALUES (1, 'orig');
SELECT name, version FROM tmp_opt WHERE id = 1;   -- version=0
UPDATE tmp_opt SET name='v1', version=version+1 WHERE id=1 AND version=0;
-- Affected rows = 1 (success)
UPDATE tmp_opt SET name='conflict', version=version+1 WHERE id=1 AND version=0;
-- Affected rows = 0 (stale version detected → retry)
SELECT * FROM tmp_opt;
DROP TABLE tmp_opt;

-- E4. SKIP LOCKED claim pattern
START TRANSACTION;
SELECT id FROM orders WHERE status = 'pending'
ORDER BY id LIMIT 1 FOR UPDATE SKIP LOCKED;
-- Process the order, then UPDATE its status.
COMMIT;

-- E5. Deadlock scenario
-- T1: locks row A, then requests row B.
-- T2: locks row B, then requests row A.
-- Neither can proceed. MySQL's deadlock detector picks the transaction
-- with the smaller undo log as the victim and rolls it back (error 1213).

-- E6. Pessimistic vs optimistic
-- Pessimistic: assume conflicts happen; lock rows upfront with FOR UPDATE.
-- Use when contention is high (e.g. updating bank balances, inventory).
-- Optimistic: assume conflicts rare; check version on commit. Use when
-- contention is low and reads outnumber writes (e.g. editing a profile).

-- ============================================================================
-- 09_fulltext_search.sql — Solutions
-- ============================================================================

-- E1. natural language mode wireless
SELECT id, name FROM products
WHERE MATCH(name, description) AGAINST('wireless');

-- E2. boolean mode +audio -phone
SELECT id, name FROM products
WHERE MATCH(name, description) AGAINST('+audio -phone' IN BOOLEAN MODE);

-- E3. reviews "battery life" phrase
SELECT id, title, body FROM reviews
WHERE MATCH(title, body) AGAINST('"battery life"' IN BOOLEAN MODE);

-- E4. query expansion 'phone'
SELECT id, name FROM products
WHERE MATCH(name, description) AGAINST('phone' WITH QUERY EXPANSION);

-- E5. boolean mode +pro optional laptop
SELECT id, name,
    MATCH(name, description) AGAINST('+pro >laptop' IN BOOLEAN MODE) AS relevance
FROM products
WHERE MATCH(name, description) AGAINST('+pro >laptop' IN BOOLEAN MODE)
ORDER BY relevance DESC;

-- E6. Why FULLTEXT faster than LIKE '%word%'
-- LIKE '%word%' scans every row of the table (O(n)) and matches the
-- pattern character by character.
-- FULLTEXT uses an INVERTED INDEX: a sorted list of (word → row ids).
-- Lookup is O(log n) per word, then intersection of row id sets.
-- On a 1M-row table, the difference is seconds vs milliseconds.

-- ============================================================================
-- 10_explain_performance.sql — Solutions
-- ============================================================================

-- E1.
EXPLAIN SELECT * FROM products WHERE price > 500;
-- type=range, key=idx_products_price, rows=estimated count.

-- E2.
EXPLAIN SELECT * FROM customers WHERE id = 5;
-- type=const, key=PRIMARY, rows=1.

-- E3.
EXPLAIN
SELECT c.first_name, o.id, oi.id
FROM customers c
JOIN orders o       ON o.customer_id   = c.id
JOIN order_items oi ON oi.order_id     = o.id;
-- Driving table is whichever the optimizer estimates is smaller / more
-- selective. Look at the first row's table column.

-- E4. filesort demo + elimination
EXPLAIN SELECT * FROM orders ORDER BY status;
-- Likely 'Using filesort'.
-- Add index on status:
-- ALTER TABLE orders ADD INDEX idx_status (status);
-- EXPLAIN SELECT * FROM orders ORDER BY status;
-- No more filesort.

-- E5. function defeats index
EXPLAIN SELECT * FROM orders WHERE DATE(order_date) = '2024-02-20';
-- type=ALL, key=NULL — index NOT used because of DATE() wrapper.

EXPLAIN SELECT * FROM orders
WHERE order_date >= '2024-02-20' AND order_date < '2024-02-21';
-- type=range, key=idx_orders_date — index used.

-- E6.
EXPLAIN ANALYZE
SELECT c.first_name, o.id, o.total
FROM customers c JOIN orders o ON o.customer_id = c.id
WHERE c.country = 'United States';
-- Look at the timings per step. The slowest step is usually the table
-- scan or the join. Add an index on orders.customer_id (already exists
-- as idx_orders_customer) to make the join use the index.

-- ============================================================================
-- 11_indexing_strategies.sql — Solutions
-- ============================================================================

-- E1.
SHOW INDEX FROM orders;

-- E2.
EXPLAIN SELECT * FROM orders WHERE customer_id = 1;
-- Uses idx_orders_customer.

-- E3. leftmost-prefix rule demo
DROP TABLE IF EXISTS tmp_abc;
CREATE TABLE tmp_abc (a INT, b INT, c INT, INDEX idx_abc (a, b, c));
INSERT INTO tmp_abc VALUES (1,1,1), (1,2,1), (2,1,1);
EXPLAIN SELECT * FROM tmp_abc WHERE a = 1;              -- uses idx_abc
EXPLAIN SELECT * FROM tmp_abc WHERE a = 1 AND b = 2;    -- uses idx_abc
EXPLAIN SELECT * FROM tmp_abc WHERE a = 1 AND b = 2 AND c = 1;  -- uses idx_abc
EXPLAIN SELECT * FROM tmp_abc WHERE b = 1;              -- does NOT use idx_abc
EXPLAIN SELECT * FROM tmp_abc WHERE c = 1;              -- does NOT use idx_abc
DROP TABLE tmp_abc;

-- E4.
SELECT * FROM sys.schema_unused_indexes WHERE object_schema = 'ecom';
SELECT * FROM sys.schema_redundant_indexes WHERE table_schema = 'ecom';

-- E5. optimal composite index
-- ALTER TABLE orders ADD INDEX idx_cust_status_date (customer_id, status, order_date);
-- Justification: equality columns (customer_id, status) first, then the
-- sort column (order_date). This allows the index to satisfy WHERE +
-- ORDER BY without a separate sort.
-- After adding, EXPLAIN should show no 'Using filesort'.

-- E6. Why range before equality is suboptimal
-- Index (range_col, equality_col): once the engine does a range scan on
-- the first column, the index can't efficiently seek on the second.
-- It must scan all matching range rows and filter.
-- Better: (equality_col, range_col) — seek to the equality, then range
-- within that subset.
-- Concrete example:
--   Index (price, category_id): WHERE price > 100 AND category_id = 8
--   → range scan on price, filter category_id on each row.
--   Index (category_id, price): WHERE price > 100 AND category_id = 8
--   → seek to category_id=8, then range on price within that subset. Much faster.

-- End of file 09_advanced_mysql_solutions.sql
