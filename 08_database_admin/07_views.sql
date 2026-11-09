-- ============================================================================
-- 07_views.sql — CREATE VIEW
-- ============================================================================
-- SKILL LEVEL : Intermediate
-- TOPICS      : CREATE VIEW, REPLACE, ALTER VIEW, DROP VIEW, updatable
--               views, CHECK OPTION, WITH CHECK OPTION, view use cases,
--               view vs materialized view.
-- ----------------------------------------------------------------------------
-- TEXTBOOK DEPTH
--   A VIEW is a named, stored SELECT statement. When you SELECT from a
--   view, MySQL runs the underlying query (after view merging/rewrite).
--   Views do NOT store data — they are virtual tables.
--
--   Use cases:
--     * Simplify complex joins into a single named object.
--     * Provide a security layer (GRANT SELECT on view but not underlying
--       tables; restrict columns or rows).
--     * Stabilize API: applications depend on the view name, not the
--       underlying schema. Schema changes can be hidden by view rewrites.
--     * Implement row-level security with WHERE filters.
--
--   Updatable views:
--     * A view over a SINGLE table with no aggregates/distinct/group by
--       can be INSERTed/UPDATEd/DELETEd. The change propagates to the
--       underlying table.
--     * WITH CHECK OPTION prevents INSERT/UPDATE that would make the row
--       fall outside the view's WHERE filter.
--
--   MySQL does NOT have native materialized views. Emulate with a real
--   table that you refresh periodically.
-- ============================================================================

USE ecom;

-- ----------------------------------------------------------------------------
-- 1. CREATE VIEW — simplify a common join
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS v_customer_orders;

CREATE VIEW v_customer_orders AS
SELECT
    c.id            AS customer_id,
    c.first_name,
    c.last_name,
    c.country,
    o.id            AS order_id,
    o.order_date,
    o.status,
    o.total
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id;

SELECT * FROM v_customer_orders ORDER BY total DESC LIMIT 5;

-- ----------------------------------------------------------------------------
-- 2. CREATE OR REPLACE VIEW — idempotent
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_customer_orders AS
SELECT
    c.id            AS customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.country,
    o.id            AS order_id,
    o.order_date,
    o.status,
    o.total
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id;

SELECT * FROM v_customer_orders ORDER BY total DESC LIMIT 5;

-- ----------------------------------------------------------------------------
-- 3. VIEW that aggregates
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS v_customer_summary;

CREATE VIEW v_customer_summary AS
SELECT
    c.id,
    c.first_name,
    c.last_name,
    COUNT(o.id)               AS order_count,
    COALESCE(SUM(o.total), 0) AS total_spent,
    AVG(o.total)              AS avg_order_value
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
GROUP BY c.id, c.first_name, c.last_name;

SELECT * FROM v_customer_summary ORDER BY total_spent DESC LIMIT 5;

-- ----------------------------------------------------------------------------
-- 4. VIEW for security — hide sensitive columns
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS v_customers_public;

CREATE VIEW v_customers_public AS
SELECT
    id,
    first_name,
    last_name,
    country,
    is_active
FROM customers;
-- email, phone, birth_date, address are NOT exposed. Grant SELECT on this
-- view but not on the underlying customers table.

SELECT * FROM v_customers_public LIMIT 5;

-- ----------------------------------------------------------------------------
-- 5. VIEW for row-level security
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS v_us_customers;

CREATE VIEW v_us_customers AS
SELECT * FROM customers WHERE country = 'United States';

SELECT id, first_name, country FROM v_us_customers LIMIT 5;

-- ----------------------------------------------------------------------------
-- 6. Updatable view — INSERT/UPDATE through the view
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS tmp_view_src;
DROP VIEW  IF EXISTS v_tmp_active;

CREATE TABLE tmp_view_src (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50),
    is_active TINYINT(1) DEFAULT 1
);

CREATE VIEW v_tmp_active AS
SELECT id, name FROM tmp_view_src WHERE is_active = 1;

-- INSERT through the view (is_active defaults to 1 via the table default)
INSERT INTO v_tmp_active (name) VALUES ('Alice'), ('Bob');
SELECT * FROM tmp_view_src;

-- UPDATE through the view
UPDATE v_tmp_active SET name = 'Alicia' WHERE name = 'Alice';
SELECT * FROM tmp_view_src;

-- DELETE through the view
DELETE FROM v_tmp_active WHERE name = 'Bob';
SELECT * FROM tmp_view_src;

-- ----------------------------------------------------------------------------
-- 7. WITH CHECK OPTION — prevent rows that fall outside the view
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS v_tmp_active_checked;
CREATE VIEW v_tmp_active_checked AS
SELECT id, name, is_active FROM tmp_view_src WHERE is_active = 1
WITH CHECK OPTION;

-- This INSERT FAILS because the row would not be visible through the view
-- (is_active = 0 fails the CHECK OPTION):
-- INSERT INTO v_tmp_active_checked (name, is_active) VALUES ('Hidden', 0);
-- ERROR 1369 (HY000): CHECK OPTION failed 'ecom.v_tmp_active_checked'

INSERT INTO v_tmp_active_checked (name, is_active) VALUES ('Visible', 1);   -- OK
SELECT * FROM tmp_view_src;

-- ----------------------------------------------------------------------------
-- 8. ALTER VIEW — change definition
-- ----------------------------------------------------------------------------
ALTER VIEW v_tmp_active AS
SELECT id, name FROM tmp_view_src WHERE is_active = 1 ORDER BY name;

SELECT * FROM v_tmp_active;

-- ----------------------------------------------------------------------------
-- 9. SHOW CREATE VIEW
-- ----------------------------------------------------------------------------
SHOW CREATE VIEW v_customer_summary\G

-- ----------------------------------------------------------------------------
-- 10. Inspecting views via information_schema
-- ----------------------------------------------------------------------------
SELECT TABLE_NAME, IS_UPDATABLE, CHECK_OPTION
FROM information_schema.VIEWS
WHERE TABLE_SCHEMA = 'ecom';

-- ----------------------------------------------------------------------------
-- 11. DROP VIEW
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS v_customer_orders;
DROP VIEW IF EXISTS v_customer_summary;
DROP VIEW IF EXISTS v_customers_public;
DROP VIEW IF EXISTS v_us_customers;
DROP VIEW IF EXISTS v_tmp_active;
DROP VIEW IF EXISTS v_tmp_active_checked;
DROP TABLE tmp_view_src;

-- ----------------------------------------------------------------------------
-- 12. EXERCISES
-- ----------------------------------------------------------------------------
-- EASY
-- E1.  Create a view v_product_list that shows sku, name, price from
--      products where is_active = 1.
-- E2.  Create a view v_active_customers that shows only active customers.
--
-- MEDIUM
-- E3.  Create a view v_order_invoices that joins customers, orders,
--      order_items, and products into a single flat invoice-style view.
-- E4.  Create a view v_customer_summary that aggregates per-customer order
--      count, total spend, and avg order value.
--
-- HARD
-- E5.  Create a security view that exposes customers' first/last name and
--      country but HIDES email, phone, and birth_date. Discuss in a
--      comment how this enables row/column-level security.
--
-- EXPERT
-- E6.  Create an updatable view with WITH CHECK OPTION. Demonstrate that
--      inserting a row that would fall outside the view's WHERE clause
--      fails. Explain why this is useful.
-- ============================================================================

-- End of file 07_views.sql
