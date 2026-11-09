-- ============================================================================
-- 13_expert_challenges_solutions.sql — Solutions for EXPERT challenges
-- ============================================================================

USE ecom;

-- X1. Customer cohort retention table
-- Each row = cohort month; columns = retention at month 0..N.
WITH first_orders AS (
    SELECT customer_id, DATE_FORMAT(MIN(order_date), '%Y-%m') AS cohort_month,
           MIN(order_date) AS cohort_start
    FROM orders
    GROUP BY customer_id
),
activity AS (
    SELECT
        fo.cohort_month,
        fo.customer_id,
        PERIOD_DIFF(
            EXTRACT(YEAR_MONTH FROM o.order_date),
            EXTRACT(YEAR_MONTH FROM fo.cohort_start)
        ) AS month_offset
    FROM first_orders fo
    JOIN orders o ON o.customer_id = fo.customer_id
)
SELECT
    cohort_month,
    COUNT(DISTINCT CASE WHEN month_offset = 0  THEN customer_id END) AS month_0,
    COUNT(DISTINCT CASE WHEN month_offset = 1  THEN customer_id END) AS month_1,
    COUNT(DISTINCT CASE WHEN month_offset = 2  THEN customer_id END) AS month_2,
    COUNT(DISTINCT CASE WHEN month_offset = 3  THEN customer_id END) AS month_3,
    COUNT(DISTINCT CASE WHEN month_offset = 6  THEN customer_id END) AS month_6,
    COUNT(DISTINCT CASE WHEN month_offset = 12 THEN customer_id END) AS month_12
FROM activity
GROUP BY cohort_month
ORDER BY cohort_month;

-- X2. Recursive CTE: all descendants of Electronics
WITH RECURSIVE descendants AS (
    SELECT id, parent_id, name, 0 AS depth, CAST(name AS CHAR(500)) AS path
    FROM categories WHERE id = 1
    UNION ALL
    SELECT c.id, c.parent_id, c.name, d.depth + 1, CONCAT(d.path, ' > ', c.name)
    FROM categories c JOIN descendants d ON c.parent_id = d.id
)
SELECT depth, id, name, path FROM descendants ORDER BY path;

-- X3. Optimistic locking
ALTER TABLE products ADD COLUMN version INT NOT NULL DEFAULT 0;

SELECT price, version FROM products WHERE id = 1;
-- Assume we read version=0.

UPDATE products
SET stock_qty = stock_qty - 1, version = version + 1
WHERE id = 1 AND version = 0;
-- affected_rows = 1 → success.

-- Simulate a conflicting UPDATE (stale version):
UPDATE products
SET stock_qty = stock_qty - 1, version = version + 1
WHERE id = 1 AND version = 0;
-- affected_rows = 0 → conflict detected, retry in app.

ALTER TABLE products DROP COLUMN version;

-- X4. Trigger maintaining denormalized total_spent on customers
ALTER TABLE customers ADD COLUMN total_spent DECIMAL(10,2) NOT NULL DEFAULT 0;
UPDATE customers c SET c.total_spent = COALESCE(
    (SELECT SUM(total) FROM orders o WHERE o.customer_id = c.id
     AND o.status NOT IN ('cancelled', 'refunded')), 0);

DELIMITER //
DROP TRIGGER IF EXISTS customers_total_after_insert //
CREATE TRIGGER customers_total_after_insert
AFTER INSERT ON orders
FOR EACH ROW
BEGIN
    IF NEW.status NOT IN ('cancelled', 'refunded') THEN
        UPDATE customers
        SET total_spent = total_spent + NEW.total
        WHERE id = NEW.customer_id;
    END IF;
END //

DROP TRIGGER IF EXISTS customers_total_after_update //
CREATE TRIGGER customers_total_after_update
AFTER UPDATE ON orders
FOR EACH ROW
BEGIN
    DECLARE delta DECIMAL(10,2);
    SET delta := 0;
    IF OLD.status NOT IN ('cancelled','refunded') AND NEW.status IN ('cancelled','refunded') THEN
        SET delta := -OLD.total;
    ELSEIF OLD.status IN ('cancelled','refunded') AND NEW.status NOT IN ('cancelled','refunded') THEN
        SET delta := NEW.total;
    ELSEIF OLD.status NOT IN ('cancelled','refunded') AND NEW.status NOT IN ('cancelled','refunded') THEN
        SET delta := NEW.total - OLD.total;
    END IF;
    IF delta <> 0 THEN
        UPDATE customers SET total_spent = total_spent + delta WHERE id = NEW.customer_id;
    END IF;
END //

DROP TRIGGER IF EXISTS customers_total_after_delete //
CREATE TRIGGER customers_total_after_delete
AFTER DELETE ON orders
FOR EACH ROW
BEGIN
    IF OLD.status NOT IN ('cancelled','refunded') THEN
        UPDATE customers SET total_spent = total_spent - OLD.total WHERE id = OLD.customer_id;
    END IF;
END //
DELIMITER ;

-- Test:
INSERT INTO orders (customer_id, status, subtotal, tax, shipping, total)
VALUES (5, 'pending', 79, 6.32, 5, 90.32);
SELECT first_name, total_spent FROM customers WHERE id = 5;
ROLLBACK;  -- not in a tx but just to demo; alternatively delete
DELETE FROM orders WHERE customer_id = 5 AND total = 90.32;

DROP TRIGGER customers_total_after_insert;
DROP TRIGGER customers_total_after_update;
DROP TRIGGER customers_total_after_delete;
ALTER TABLE customers DROP COLUMN total_spent;

-- X5. JSON_TABLE multi-level extraction
SET @j := '[
    {"order_id": 1, "items":[{"sku":"A","qty":2},{"sku":"B","qty":1}]},
    {"order_id": 2, "items":[{"sku":"C","qty":3}]}
]';
SELECT
    jt.order_id,
    items.sku,
    items.qty
FROM JSON_TABLE(@j, '$[*]'
    COLUMNS (
        order_id INT PATH '$.order_id',
        items JSON PATH '$.items'
    )
) AS jt,
JSON_TABLE(jt.items, '$[*]'
    COLUMNS (
        sku VARCHAR(20) PATH '$.sku',
        qty INT PATH '$.qty'
    )
) AS items;

-- X6. Top 5 errors from performance_schema
SELECT
    ERROR_NUMBER,
    ERROR_NAME,
    SUM_ERROR_RAISED AS count
FROM performance_schema.events_errors_summary_global_by_error
WHERE ERROR_NUMBER <> 0
ORDER BY SUM_ERROR_RAISED DESC
LIMIT 5;

-- X7. Top product per month via window function
WITH ranked AS (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m') AS month,
        p.name AS product_name,
        SUM(oi.line_total) AS revenue,
        ROW_NUMBER() OVER (PARTITION BY DATE_FORMAT(o.order_date, '%Y-%m')
                            ORDER BY SUM(oi.line_total) DESC) AS rn
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.id
    JOIN products p     ON p.id = oi.product_id
    GROUP BY DATE_FORMAT(o.order_date, '%Y-%m'), p.name
)
SELECT month, product_name, revenue
FROM ranked WHERE rn = 1
ORDER BY month;

-- X8. Hash join vs nested loop comparison (use EXPLAIN ANALYZE)
-- MySQL 8.0.18+ chooses hash join automatically when no index is usable.
-- Force nested loop with NO_HASH_JOIN hint (MySQL Enterprise only; on
-- community you can drop the join index to force hash).
EXPLAIN ANALYZE
SELECT c.first_name, o.id
FROM customers c
JOIN orders o ON o.customer_id = c.id
WHERE c.country = 'United States';

-- X9. Stored procedure for revenue report
DROP TABLE IF EXISTS tmp_revenue_log;
CREATE TABLE tmp_revenue_log (id INT AUTO_INCREMENT PRIMARY KEY, msg VARCHAR(200), ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP);

DROP PROCEDURE IF EXISTS sp_revenue_report;
DELIMITER //
CREATE PROCEDURE sp_revenue_report(IN p_year INT)
BEGIN
    DECLARE v_total DECIMAL(12,2);
    SELECT SUM(total) INTO v_total
    FROM orders WHERE YEAR(order_date) = p_year
      AND status NOT IN ('cancelled', 'refunded');

    INSERT INTO tmp_revenue_log (msg)
    VALUES (CONCAT('revenue report for ', p_year, ' ran at ', NOW()));

    SELECT
        DATE_FORMAT(order_date, '%Y-%m') AS month,
        SUM(total) AS revenue,
        ROUND(SUM(total) / v_total * 100, 2) AS pct_of_year
    FROM orders
    WHERE YEAR(order_date) = p_year
      AND status NOT IN ('cancelled', 'refunded')
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
    ORDER BY month;
END //
DELIMITER ;

CALL sp_revenue_report(2024);
DROP PROCEDURE sp_revenue_report;
DROP TABLE tmp_revenue_log;

-- X10. Backup verification (commands, not SQL — see README for shell script)
-- mysqldump -u root -p --single-transaction ecom > /tmp/ecom_backup.sql
-- mysql -u root -p -e "CREATE DATABASE ecom_verify"
-- mysql -u root -p ecom_verify < /tmp/ecom_backup.sql
-- Row count comparison query:
SELECT
    (SELECT COUNT(*) FROM ecom.customers)    AS ecom_customers,
    (SELECT COUNT(*) FROM ecom_verify.customers) AS verify_customers,
    (SELECT COUNT(*) FROM ecom.products)     AS ecom_products,
    (SELECT COUNT(*) FROM ecom_verify.products)  AS verify_products;

-- X11. Multi-valued JSON index for tags
DROP TABLE IF EXISTS tmp_mvi;
CREATE TABLE tmp_mvi (
    id INT AUTO_INCREMENT PRIMARY KEY,
    data JSON,
    INDEX idx_tags ((CAST(data->'$.tags' AS CHAR(20) ARRAY)))
);
INSERT INTO tmp_mvi (data) VALUES
    ('{"tags":["vip","newsletter"]}'),
    ('{"tags":["newsletter","new"]}'),
    ('{"tags":["vip","early"]}');

-- Without index (member-of would scan):
-- With index, lookups use idx_tags.
EXPLAIN SELECT id, data FROM tmp_mvi
WHERE 'vip' MEMBER OF (data->'$.tags')
   OR 'newsletter' MEMBER OF (data->'$.tags');

DROP TABLE tmp_mvi;

-- X12. Top 10 slow queries by total execution time
SELECT
    DIGEST_TEXT,
    COUNT_STAR AS calls,
    ROUND(SUM_TIMER_WAIT / 1000000000, 2) AS total_ms,
    ROUND(AVG_TIMER_WAIT / 1000000000, 2) AS avg_ms
FROM performance_schema.events_statements_summary_by_digest
WHERE DIGEST_TEXT IS NOT NULL
ORDER BY SUM_TIMER_WAIT DESC
LIMIT 10;

-- X13. Row-level security via VIEW + CURRENT_USER()
DROP TABLE IF EXISTS tmp_owned;
CREATE TABLE tmp_owned (
    id INT AUTO_INCREMENT PRIMARY KEY,
    owner VARCHAR(80) NOT NULL,
    note VARCHAR(100)
);
INSERT INTO tmp_owned (owner, note) VALUES
    (CURRENT_USER(), 'mine'),
    ('someone_else@localhost', 'not mine'),
    (CURRENT_USER(), 'also mine');

DROP VIEW IF EXISTS v_my_rows;
CREATE VIEW v_my_rows AS
SELECT id, owner, note FROM tmp_owned WHERE owner = CURRENT_USER();

SELECT * FROM v_my_rows;   -- only rows owned by current user
DROP VIEW v_my_rows;
DROP TABLE tmp_owned;

-- X14. Fibonacci via recursive CTE
WITH RECURSIVE fib(n, cur, nxt) AS (
    SELECT 0, 0, 1
    UNION ALL
    SELECT n + 1, nxt, cur + nxt FROM fib WHERE n < 19
)
SELECT n, cur AS fib_value FROM fib;

-- X15. Materialized view refresh job (EVENT)
DROP TABLE IF EXISTS mv_customer_summary;
CREATE TABLE mv_customer_summary (
    customer_id BIGINT PRIMARY KEY,
    order_count INT,
    total_spent DECIMAL(10,2),
    refreshed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP EVENT IF EXISTS ev_refresh_mv;
SET GLOBAL event_scheduler = ON;
CREATE EVENT ev_refresh_mv
ON SCHEDULE EVERY 1 HOUR
DO
    BEGIN
        TRUNCATE TABLE mv_customer_summary;
        INSERT INTO mv_customer_summary (customer_id, order_count, total_spent, refreshed_at)
        SELECT customer_id, COUNT(*), SUM(total), NOW()
        FROM orders
        WHERE status NOT IN ('cancelled', 'refunded')
        GROUP BY customer_id;
    END;

-- Inspect
SELECT * FROM mv_customer_summary LIMIT 5;
DROP EVENT ev_refresh_mv;
DROP TABLE mv_customer_summary;

-- X16. Find queries with filesort/temp table
SELECT
    DIGEST_TEXT,
    SUM_CREATED_TMP_TABLES AS tmp_tables,
    SUM_SORT_SCAN          AS sort_scans,
    COUNT_STAR             AS calls
FROM performance_schema.events_statements_summary_by_digest
WHERE SUM_CREATED_TMP_TABLES > 0 OR SUM_SORT_SCAN > 0
ORDER BY (SUM_CREATED_TMP_TABLES + SUM_SORT_SCAN) DESC
LIMIT 10;
-- For each: an index on the GROUP BY / ORDER BY columns would typically
-- eliminate the temp table or filesort.

-- X17. Optimizer trace investigation
SET optimizer_trace = 'enabled=on';
SELECT * FROM customers WHERE last_name = 'Johnson';
SELECT TRACE INTO OUTFILE '/tmp/trace.json' FROM information_schema.OPTIMIZER_TRACE;
SET optimizer_trace = 'enabled=off';

-- X18. Write-through cache via triggers
DROP TABLE IF EXISTS cached_customers;
CREATE TABLE cached_customers (
    customer_id BIGINT PRIMARY KEY,
    full_name VARCHAR(120),
    order_count INT DEFAULT 0,
    total_spent DECIMAL(10,2) DEFAULT 0
);

-- Initialize from current state
INSERT INTO cached_customers (customer_id, full_name, order_count, total_spent)
SELECT c.id, CONCAT(c.first_name, ' ', c.last_name),
       COUNT(o.id), COALESCE(SUM(o.total), 0)
FROM customers c LEFT JOIN orders o ON o.customer_id = c.id
GROUP BY c.id;

DELIMITER //
DROP TRIGGER IF EXISTS cache_after_order_insert //
CREATE TRIGGER cache_after_order_insert
AFTER INSERT ON orders
FOR EACH ROW
BEGIN
    INSERT INTO cached_customers (customer_id, full_name, order_count, total_spent)
    SELECT c.id, CONCAT(c.first_name, ' ', c.last_name), 1, NEW.total
    FROM customers c WHERE c.id = NEW.customer_id
    ON DUPLICATE KEY UPDATE
        order_count = VALUES(order_count) + 0,  -- unchanged via INSERT
        total_spent = cached_customers.total_spent + NEW.total;
    -- Actually simpler: just bump
END //
DELIMITER ;

-- Cleanup
DROP TRIGGER cache_after_order_insert;
DROP TABLE cached_customers;

-- X19. CTE chained three deep for customer spend quartile
WITH per_cust AS (
    SELECT customer_id, SUM(total) AS spend
    FROM orders
    WHERE status NOT IN ('cancelled', 'refunded')
    GROUP BY customer_id
),
quartiles AS (
    SELECT
        spend,
        NTILE(4) OVER (ORDER BY spend) AS quartile
    FROM per_cust
),
enriched AS (
    SELECT pc.customer_id, pc.spend, q.quartile
    FROM per_cust pc
    JOIN quartiles q ON q.spend = pc.spend
)
SELECT customer_id, spend, quartile
FROM enriched
ORDER BY quartile, spend DESC;

-- X20. Longest consecutive streak of days with orders
-- Technique: row_number by date - row_number grouped by date with same order
-- gives a "group id" for each consecutive run.
WITH dates AS (
    SELECT DISTINCT DATE(order_date) AS d
    FROM orders
),
ranked AS (
    SELECT
        d,
        ROW_NUMBER() OVER (ORDER BY d) AS rn,
        DENSE_RANK() OVER (ORDER BY d) AS dr
    FROM dates
),
runs AS (
    SELECT
        d,
        rn - dr AS grp
    FROM ranked
),
streaks AS (
    SELECT grp, MIN(d) AS start_d, MAX(d) AS end_d, COUNT(*) AS length
    FROM runs
    GROUP BY grp
)
SELECT start_d, end_d, length AS streak_length
FROM streaks
ORDER BY length DESC
LIMIT 1;

-- End of file 13_expert_challenges_solutions.sql
