-- ============================================================================
-- 08_database_admin_solutions.sql — Solutions for 08_database_admin
-- ============================================================================

USE ecom;

-- ============================================================================
-- 01_create_drop_db.sql
-- ============================================================================

-- E1. create and drop tmp_practice
CREATE DATABASE IF NOT EXISTS tmp_practice;
SHOW DATABASES LIKE 'tmp_practice';
DROP DATABASE tmp_practice;

-- E2. list databases
SHOW DATABASES;

-- E3. case-sensitive collation demo
DROP DATABASE IF EXISTS tmp_cs_demo;
CREATE DATABASE tmp_cs_demo COLLATE utf8mb4_0900_as_cs;
USE tmp_cs_demo;
CREATE TABLE tmp_cs (val VARCHAR(20));
INSERT INTO tmp_cs VALUES ('Alice'), ('alice');
SELECT * FROM tmp_cs WHERE val = 'Alice';   -- returns only 'Alice'
USE ecom;
DROP DATABASE tmp_cs_demo;

-- E4. drop-and-recreate-flag pattern (comment only)
-- SET @drop := 1;
-- SET @sql := IF(@drop = 1,
--     'DROP DATABASE IF EXISTS ecom; CREATE DATABASE ecom;',
--     'SELECT ''skipped'' AS msg');
-- PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- E5. utf8mb4_0900_ai_ci vs utf8mb4_0900_as_cs
-- _ai = accent-insensitive (café = cafe)
-- _ci = case-insensitive (Alice = alice)
-- _as = accent-sensitive
-- _cs = case-sensitive
-- Choose _ai_ci for most user-facing text (case-insensitive search).
-- Choose _as_cs for password hashes, identifiers, or any case-significant data.

-- ============================================================================
-- 02_create_table.sql
-- ============================================================================

-- E1. tmp_posts table
DROP TABLE IF EXISTS tmp_posts;
CREATE TABLE tmp_posts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(120) NOT NULL,
    body TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
DESCRIBE tmp_posts;
DROP TABLE tmp_posts;

-- E2. temp table with one row
CREATE TEMPORARY TABLE tmp_one (id INT, val VARCHAR(20));
INSERT INTO tmp_one VALUES (1, 'hello');
SELECT * FROM tmp_one;
DROP TEMPORARY TABLE tmp_one;

-- E3. tmp_events with ENUM and JSON
DROP TABLE IF EXISTS tmp_events;
CREATE TABLE tmp_events (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(80) NOT NULL,
    status ENUM('pending','confirmed','cancelled') DEFAULT 'pending',
    metadata JSON NULL,
    CHECK (JSON_VALID(metadata) OR metadata IS NULL)
);
DESCRIBE tmp_events;
DROP TABLE tmp_events;

-- E4. margin_pct STORED + index
DROP TABLE IF EXISTS tmp_prods;
CREATE TABLE tmp_prods (
    id INT AUTO_INCREMENT PRIMARY KEY,
    price DECIMAL(10,2) NOT NULL,
    cost  DECIMAL(10,2) NOT NULL,
    margin_pct DECIMAL(5,2) AS (ROUND((price - cost) / price * 100, 2)) STORED,
    INDEX idx_margin_pct (margin_pct)
);
INSERT INTO tmp_prods (price, cost) VALUES (100, 60), (200, 120);
SELECT * FROM tmp_prods;
DROP TABLE tmp_prods;

-- E5. FK relationship demo
DROP TABLE IF EXISTS tmp_child;
DROP TABLE IF EXISTS tmp_parent;
CREATE TABLE tmp_parent (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(20))
ENGINE=InnoDB;
CREATE TABLE tmp_child (
    id INT AUTO_INCREMENT PRIMARY KEY,
    parent_id INT NOT NULL,
    label VARCHAR(20),
    CONSTRAINT fk_child_parent FOREIGN KEY (parent_id)
        REFERENCES tmp_parent(id) ON DELETE CASCADE
) ENGINE=InnoDB;

INSERT INTO tmp_parent (name) VALUES ('A');
INSERT INTO tmp_child (parent_id, label) VALUES (1, 'c1');
-- INSERT INTO tmp_child (parent_id, label) VALUES (999, 'orphan'); -- ERROR 1452
DELETE FROM tmp_parent WHERE id = 1;
SELECT COUNT(*) FROM tmp_child;   -- 0 (cascade)
DROP TABLE tmp_child;
DROP TABLE tmp_parent;

-- E6. VIRTUAL vs STORED
-- VIRTUAL: computed on read, not stored on disk. No storage cost. Cannot
-- be indexed by default (functional indexes are an exception).
-- STORED: computed on write, persisted. Consumes disk. Can be indexed.
-- Choose VIRTUAL when the computation is cheap and you rarely query it.
-- Choose STORED when you query or index the computed column frequently.

-- ============================================================================
-- 03_alter_table.sql
-- ============================================================================

-- E1. add second column
DROP TABLE IF EXISTS tmp_alter;
CREATE TABLE tmp_alter (id INT AUTO_INCREMENT PRIMARY KEY);
ALTER TABLE tmp_alter ADD COLUMN name VARCHAR(50);
DESCRIBE tmp_alter;
DROP TABLE tmp_alter;

-- E2. rename a column
DROP TABLE IF EXISTS tmp_rename;
CREATE TABLE tmp_rename (id INT AUTO_INCREMENT PRIMARY KEY, val VARCHAR(20));
ALTER TABLE tmp_rename RENAME COLUMN val TO description;
DESCRIBE tmp_rename;
DROP TABLE tmp_rename;

-- E3. CHECK constraint
DROP TABLE IF EXISTS tmp_age;
CREATE TABLE tmp_age (id INT AUTO_INCREMENT PRIMARY KEY, age INT,
    CONSTRAINT chk_age CHECK (age >= 0 AND age <= 150));
-- INSERT INTO tmp_age (age) VALUES (200);  -- ERROR 3819
INSERT INTO tmp_age (age) VALUES (42);
DROP TABLE tmp_age;

-- E4. add UNIQUE index
DROP TABLE IF EXISTS tmp_uniq;
CREATE TABLE tmp_uniq (id INT AUTO_INCREMENT PRIMARY KEY, email VARCHAR(100));
INSERT INTO tmp_uniq (email) VALUES ('a@x.com');
ALTER TABLE tmp_uniq ADD UNIQUE INDEX uq_email (email);
SHOW INDEX FROM tmp_uniq;
DROP TABLE tmp_uniq;

-- E5. add FK via ALTER
DROP TABLE IF EXISTS tmp_kid;
DROP TABLE IF EXISTS tmp_par;
CREATE TABLE tmp_par (id INT AUTO_INCREMENT PRIMARY KEY) ENGINE=InnoDB;
CREATE TABLE tmp_kid (id INT AUTO_INCREMENT PRIMARY KEY, pid INT) ENGINE=InnoDB;
ALTER TABLE tmp_kid
    ADD CONSTRAINT fk_kid_par FOREIGN KEY (pid) REFERENCES tmp_par(id);
-- INSERT INTO tmp_kid (pid) VALUES (999);   -- ERROR 1452
INSERT INTO tmp_par (id) VALUES (1);
INSERT INTO tmp_kid (pid) VALUES (1);  -- OK
DROP TABLE tmp_kid;
DROP TABLE tmp_par;

-- E6. ALGORITHM=INPLACE vs COPY
-- INPLACE: MySQL modifies the table data in-place. Faster, allows
-- concurrent DML during the operation (depending on operation type).
-- COPY: MySQL creates a new table, copies all rows, swaps. Slower,
-- blocks writes during the copy.
-- For large production tables, prefer INPLACE operations (most ADD COLUMN,
-- ADD INDEX). For COPY-only operations (e.g. change column type), schedule
-- during maintenance.

-- ============================================================================
-- 04_constraints.sql
-- ============================================================================

-- E1. NOT NULL violation
DROP TABLE IF EXISTS tmp_acc;
CREATE TABLE tmp_acc (id INT AUTO_INCREMENT PRIMARY KEY, email VARCHAR(100) NOT NULL);
-- INSERT INTO tmp_acc (email) VALUES (NULL);  -- ERROR 1048
DROP TABLE tmp_acc;

-- E2. UNIQUE violation
DROP TABLE IF EXISTS tmp_u;
CREATE TABLE tmp_u (id INT AUTO_INCREMENT PRIMARY KEY, username VARCHAR(40) UNIQUE);
INSERT INTO tmp_u (username) VALUES ('alice');
-- INSERT INTO tmp_u (username) VALUES ('alice');  -- ERROR 1062
DROP TABLE tmp_u;

-- E3. FK violation
DROP TABLE IF EXISTS tmp_c;
DROP TABLE IF EXISTS tmp_p;
CREATE TABLE tmp_p (id INT AUTO_INCREMENT PRIMARY KEY) ENGINE=InnoDB;
CREATE TABLE tmp_c (
    id INT AUTO_INCREMENT PRIMARY KEY, pid INT,
    FOREIGN KEY (pid) REFERENCES tmp_p(id)
) ENGINE=InnoDB;
-- INSERT INTO tmp_c (pid) VALUES (999);   -- ERROR 1452
DROP TABLE tmp_c;
DROP TABLE tmp_p;

-- E4. CHECK on price
DROP TABLE IF EXISTS tmp_p_check;
CREATE TABLE tmp_p_check (id INT AUTO_INCREMENT PRIMARY KEY, price DECIMAL(10,2),
    CONSTRAINT chk_price CHECK (price >= 0));
-- INSERT INTO tmp_p_check (price) VALUES (-5);  -- ERROR 3819
DROP TABLE tmp_p_check;

-- E5. composite UNIQUE
DROP TABLE IF EXISTS tmp_combo;
CREATE TABLE tmp_combo (
    id INT AUTO_INCREMENT PRIMARY KEY,
    region VARCHAR(10),
    cust_no INT,
    UNIQUE KEY uq_region_cust (region, cust_no)
);
INSERT INTO tmp_combo (region, cust_no) VALUES ('US', 1), ('US', 2), ('EU', 1);  -- OK
-- INSERT INTO tmp_combo (region, cust_no) VALUES ('US', 1);  -- ERROR 1062
DROP TABLE tmp_combo;

-- E6. CHECK before MySQL 8.0.16
-- Before 8.0.16, MySQL parsed CHECK constraints but SILENTLY IGNORED them.
-- Invalid data could be inserted despite the constraint.
-- MySQL 8.0.16+ ENFORCES CHECK constraints at INSERT/UPDATE time.
SELECT VERSION();

-- ============================================================================
-- 05_indexes.sql
-- ============================================================================

-- E1. index on customers.last_name (already exists in schema: idx_customers_name)
SHOW INDEX FROM customers WHERE Key_name = 'idx_customers_name';

-- E2. EXPLAIN verification
EXPLAIN SELECT * FROM customers WHERE last_name = 'Johnson';
-- key = idx_customers_name, type = ref

-- E3. composite (country, is_active)
ALTER TABLE customers ADD INDEX idx_country_active (country, is_active);
EXPLAIN SELECT * FROM customers WHERE country = 'United States';
EXPLAIN SELECT * FROM customers WHERE country = 'United States' AND is_active = 1;
ALTER TABLE customers DROP INDEX idx_country_active;

-- E4. leftmost-prefix rule demo
ALTER TABLE customers ADD INDEX idx_country_active2 (country, is_active);
EXPLAIN SELECT * FROM customers WHERE is_active = 1;
-- key = NULL (cannot use index because is_active is not leftmost)
ALTER TABLE customers DROP INDEX idx_country_active2;

-- E5. invisible index demo
ALTER TABLE orders ADD INDEX idx_status_invisible (status) INVISIBLE;
EXPLAIN SELECT * FROM orders WHERE status = 'paid';  -- key = NULL
ALTER TABLE orders ALTER INDEX idx_status_invisible VISIBLE;
EXPLAIN SELECT * FROM orders WHERE status = 'paid';  -- key = idx_status_invisible
ALTER TABLE orders DROP INDEX idx_status_invisible;

-- E6. Why indexes slow INSERTs
-- Each INSERT must update every index on the table (B-tree insert + page
-- split). More indexes = slower writes.
-- Rule of thumb: 5-7 indexes per table is typical; > 10 is suspect for
-- write-heavy tables. Monitor with sys.schema_unused_indexes.

-- ============================================================================
-- 06_auto_increment_dates.sql
-- ============================================================================

-- E1. AUTO_INCREMENT starting at 1000
DROP TABLE IF EXISTS tmp_ai;
CREATE TABLE tmp_ai (id INT AUTO_INCREMENT PRIMARY KEY, val VARCHAR(20))
AUTO_INCREMENT = 1000;
INSERT INTO tmp_ai (val) VALUES ('a'), ('b'), ('c');
SELECT * FROM tmp_ai;   -- ids 1000, 1001, 1002
DROP TABLE tmp_ai;

-- E2. orders in 2024
SELECT id, order_date FROM orders WHERE YEAR(order_date) = 2024;

-- E3. day of week for each order
SELECT id, order_date, DAYNAME(order_date) AS day_name
FROM orders LIMIT 5;

-- E4. days between consecutive orders per customer
SELECT customer_id, id, order_date,
    order_date - LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS days_gap
FROM orders
ORDER BY customer_id, order_date;

-- E5. revenue per year-month
SELECT YEAR(order_date) AS yr, MONTH(order_date) AS mo,
       COUNT(*) AS orders, SUM(total) AS revenue
FROM orders
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY yr, mo;

-- E6. DATE_FORMAT pretty
SELECT id, order_date,
    DATE_FORMAT(order_date, '%b %d, %Y - %h:%i %p') AS pretty
FROM orders LIMIT 3;

-- E7. DATETIME vs TIMESTAMP
-- DATETIME: 8 bytes. Stores literal 'YYYY-MM-DD HH:MM:SS'. Range
-- 1000-01-01 to 9999-12-31. No timezone conversion.
-- TIMESTAMP: 4 bytes. Stored as Unix epoch UTC, converted to session
-- time_zone on read. Range 1970-01-01 to 2038-01-19 (Y2038 problem).
-- Choose DATETIME for events in distant past/future (birth dates, etc.).
-- Choose TIMESTAMP for recent events with timezone-awareness (created_at).

-- ============================================================================
-- 07_views.sql
-- ============================================================================

-- E1. v_product_list
DROP VIEW IF EXISTS v_product_list;
CREATE VIEW v_product_list AS
SELECT sku, name, price FROM products WHERE is_active = 1;
SELECT * FROM v_product_list LIMIT 3;
DROP VIEW v_product_list;

-- E2. v_active_customers
DROP VIEW IF EXISTS v_active_customers;
CREATE VIEW v_active_customers AS
SELECT id, first_name, last_name, email, country FROM customers WHERE is_active = 1;
SELECT * FROM v_active_customers LIMIT 3;
DROP VIEW v_active_customers;

-- E3. v_order_invoices
DROP VIEW IF EXISTS v_order_invoices;
CREATE VIEW v_order_invoices AS
SELECT
    c.first_name, c.last_name, o.id AS order_id, o.order_date,
    p.name AS product_name, oi.quantity, oi.unit_price, oi.line_total
FROM customers c
JOIN orders o       ON o.customer_id   = c.id
JOIN order_items oi ON oi.order_id     = o.id
JOIN products p     ON p.id            = oi.product_id;
SELECT * FROM v_order_invoices LIMIT 3;
DROP VIEW v_order_invoices;

-- E4. v_customer_summary
DROP VIEW IF EXISTS v_customer_summary;
CREATE VIEW v_customer_summary AS
SELECT
    c.id, c.first_name, c.last_name,
    COUNT(o.id) AS order_count,
    COALESCE(SUM(o.total), 0) AS total_spent,
    AVG(o.total) AS avg_order_value
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
GROUP BY c.id, c.first_name, c.last_name;
SELECT * FROM v_customer_summary ORDER BY total_spent DESC LIMIT 3;
DROP VIEW v_customer_summary;

-- E5. security view
DROP VIEW IF EXISTS v_customers_public;
CREATE VIEW v_customers_public AS
SELECT id, first_name, last_name, country, is_active FROM customers;
-- Grant SELECT on v_customers_public to public users; deny SELECT on
-- customers. Now email, phone, birth_date, address are hidden.
SELECT * FROM v_customers_public LIMIT 3;
DROP VIEW v_customers_public;

-- E6. updatable view with CHECK OPTION
DROP TABLE IF EXISTS tmp_src;
DROP VIEW  IF EXISTS v_active_check;
CREATE TABLE tmp_src (
    id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(20), is_active TINYINT(1) DEFAULT 1
);
CREATE VIEW v_active_check AS
SELECT id, name FROM tmp_src WHERE is_active = 1 WITH CHECK OPTION;
INSERT INTO v_active_check (name) VALUES ('alice');   -- OK (defaults to 1)
-- INSERT INTO v_active_check (name, is_active) VALUES ('bob', 0);  -- ERROR 1369
-- Useful: prevents writes that would make rows invisible through the view.
DROP VIEW v_active_check;
DROP TABLE tmp_src;

-- ============================================================================
-- 08_stored_procedures.sql
-- ============================================================================

-- Solutions are illustrated in the source file. Try writing your own
-- first; compare against 08_database_admin/08_stored_procedures.sql.

-- ============================================================================
-- 09_backup_hosting.sql
-- ============================================================================

-- Solutions are command-line examples in the source file.

-- End of file 08_database_admin_solutions.sql
