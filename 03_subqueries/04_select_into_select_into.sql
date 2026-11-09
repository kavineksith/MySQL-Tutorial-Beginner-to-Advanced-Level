-- ============================================================================
-- 04_select_into_select_into.sql — SELECT INTO & INSERT INTO SELECT
-- ============================================================================
-- SKILL LEVEL : Intermediate
-- TOPICS      : MySQL does NOT support SELECT INTO new_table; CREATE TABLE
--               AS SELECT; CREATE TABLE ... LIKE; INSERT INTO ... SELECT;
--               copying schemas and data.
-- ----------------------------------------------------------------------------
-- TEXTBOOK DEPTH
--   Some tutorials teach "SELECT INTO new_table" because it follows SQL Server
--   syntax:
--     SELECT * INTO new_table FROM source;     -- SQL Server, NOT MySQL
--
--   MySQL DOES NOT support SELECT INTO to create a new table. Instead:
--     CREATE TABLE new_table AS SELECT * FROM source;          -- MySQL
--     CREATE TABLE new_table LIKE source;                       -- copy schema only
--     INSERT INTO target SELECT * FROM source;                  -- copy rows
--
--   SELECT INTO @var in MySQL means something else entirely:
--     SELECT col INTO @var FROM tbl WHERE ... LIMIT 1;          -- store single value in a variable
--
--   So "SELECT INTO" has two unrelated meanings:
--     1. SQL Server: create a new table from a query result. (NOT in MySQL.)
--     2. MySQL/PL-SQL: store a single scalar value in a host variable.
-- ============================================================================

USE ecom;

-- ----------------------------------------------------------------------------
-- 1. CREATE TABLE AS SELECT — the MySQL way to "SELECT INTO new table"
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS tmp_products_archive;
CREATE TABLE tmp_products_archive AS
SELECT
    sku,
    name,
    price,
    cost,
    stock_qty,
    category_id,
    CURRENT_TIMESTAMP AS archived_at
FROM products
WHERE is_active = 1;

SELECT * FROM tmp_products_archive LIMIT 5;

-- Note: the new table has NO indexes, NO primary key, NO constraints.
-- Use LIKE to copy schema, then INSERT SELECT to populate.

DROP TABLE tmp_products_archive;

-- ----------------------------------------------------------------------------
-- 2. CREATE TABLE LIKE — copy schema only
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS tmp_products_clone;
CREATE TABLE tmp_products_clone LIKE products;
-- tmp_products_clone has the same columns, types, indexes, constraints,
-- AUTO_INCREMENT as products, but is EMPTY.

DESCRIBE tmp_products_clone;
SHOW INDEX FROM tmp_products_clone;

-- ----------------------------------------------------------------------------
-- 3. INSERT INTO ... SELECT — populate the clone
-- ----------------------------------------------------------------------------
INSERT INTO tmp_products_clone
SELECT * FROM products WHERE category_id = 8;   -- laptops only

SELECT COUNT(*) AS cloned_rows FROM tmp_products_clone;

DROP TABLE tmp_products_clone;

-- ----------------------------------------------------------------------------
-- 4. SELECT INTO @var — store a scalar value
-- ----------------------------------------------------------------------------
SELECT MAX(price) INTO @max_price FROM products;
SELECT @max_price AS max_price;

SELECT COUNT(*) INTO @total_products FROM products;
SELECT @total_products AS total_products;

-- Useful inside stored procedures to capture scalars for later use.

-- ----------------------------------------------------------------------------
-- 5. Copy rows to an archive table — full pattern
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS tmp_orders_archive;
CREATE TABLE tmp_orders_archive LIKE orders;
ALTER TABLE tmp_orders_archive ADD COLUMN archived_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE tmp_orders_archive DROP FOREIGN KEY fk_orders_customer;  -- may fail if no FK

-- Archive 2024 orders
INSERT INTO tmp_orders_archive (id, customer_id, order_date, status, subtotal,
                                 discount, tax, shipping, total, shipping_address,
                                 notes, created_at, updated_at)
SELECT
    id, customer_id, order_date, status, subtotal,
    discount, tax, shipping, total, shipping_address,
    notes, created_at, updated_at
FROM orders
WHERE YEAR(order_date) = 2024;

SELECT COUNT(*) AS archived_orders FROM tmp_orders_archive;

DROP TABLE tmp_orders_archive;

-- ----------------------------------------------------------------------------
-- 6. CREATE TABLE AS SELECT with index — one step
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS tmp_summary;
CREATE TABLE tmp_summary (
    customer_id BIGINT PRIMARY KEY,
    total_spent DECIMAL(10,2),
    order_count INT,
    INDEX idx_total_spent (total_spent)
) AS
SELECT
    customer_id,
    COALESCE(SUM(total), 0) AS total_spent,
    COUNT(*)                AS order_count
FROM orders
WHERE status NOT IN ('cancelled', 'refunded')
GROUP BY customer_id;

SELECT * FROM tmp_summary ORDER BY total_spent DESC LIMIT 5;

DROP TABLE tmp_summary;

-- ----------------------------------------------------------------------------
-- 7. INSERT INTO ... SELECT with column transformation
-- ----------------------------------------------------------------------------
CREATE TEMPORARY TABLE tmp_customer_summary (
    id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(120),
    email VARCHAR(255),
    country VARCHAR(60),
    is_vip TINYINT(1)
);

INSERT INTO tmp_customer_summary (full_name, email, country, is_vip)
SELECT
    CONCAT(first_name, ' ', last_name),
    email,
    country,
    IF(metadata IS NOT NULL AND JSON_CONTAINS(JSON_EXTRACT(metadata, '$.tags'), '"vip"'), 1, 0)
FROM customers;

SELECT * FROM tmp_customer_summary ORDER BY is_vip DESC, full_name LIMIT 8;

DROP TEMPORARY TABLE tmp_customer_summary;

-- ----------------------------------------------------------------------------
-- 8. Copy data across databases
-- ----------------------------------------------------------------------------
-- Pattern: copy rows from one database to another
-- INSERT INTO other_db.products SELECT * FROM ecom.products WHERE ...;

-- ----------------------------------------------------------------------------
-- 9. EXERCISES
-- ----------------------------------------------------------------------------
-- EASY
-- E1.  Create a new table `tmp_categories_copy` as a SELECT of all
--      categories.
-- E2.  Insert the names of all active customers into a new temp table.
--
-- MEDIUM
-- E3.  Create a temp table `tmp_vip_summary` that stores customer_id,
--      first_name, last_name, total_spent for customers whose metadata
--      contains the tag "vip". Use INSERT INTO ... SELECT.
-- E4.  Use CREATE TABLE LIKE products to clone the schema, then INSERT
--      INTO ... SELECT to copy all laptops into the clone.
--
-- HARD
-- E5.  Build an archive table for cancelled orders with an `archived_at`
--      column. Copy cancelled orders into it.
--
-- EXPERT
-- E6.  Explain in a comment the difference between SQL Server's
--      "SELECT * INTO new_tbl FROM src" and MySQL's "CREATE TABLE new_tbl
--      AS SELECT * FROM src". Note which gets the schema (indexes,
--      constraints) and which does not.
-- ============================================================================

-- End of file 04_select_into_select_into.sql
