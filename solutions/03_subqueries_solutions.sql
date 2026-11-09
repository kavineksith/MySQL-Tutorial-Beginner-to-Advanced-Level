-- ============================================================================
-- 03_subqueries_solutions.sql — Solutions for 03_subqueries
-- ============================================================================

USE ecom;

-- ============================================================================
-- 01_subqueries_basics.sql
-- ============================================================================

-- E1. products > avg price in category 9
SELECT name, price FROM products
WHERE price > (SELECT AVG(price) FROM products WHERE category_id = 9);

-- E2. customers whose created_at < overall avg
SELECT first_name, last_name, created_at
FROM customers
WHERE created_at < (SELECT AVG(created_at) FROM customers);

-- E3. products > avg in OWN category (correlated)
SELECT p1.sku, p1.name, p1.price, p1.category_id
FROM products p1
WHERE p1.price > (
    SELECT AVG(p2.price) FROM products p2 WHERE p2.category_id = p1.category_id
)
ORDER BY p1.category_id, p1.price DESC;

-- E4. derived table per-customer spend > 500
SELECT t.customer_id, t.order_count, t.total_spent
FROM (
    SELECT customer_id, COUNT(*) AS order_count, SUM(total) AS total_spent
    FROM orders
    WHERE status NOT IN ('cancelled', 'refunded')
    GROUP BY customer_id
) AS t
WHERE t.total_spent > 500
ORDER BY t.total_spent DESC;

-- E5. customers whose spend > avg customer spend (nested)
SELECT customer_id, SUM(total) AS total_spent
FROM orders
WHERE status NOT IN ('cancelled', 'refunded')
GROUP BY customer_id
HAVING SUM(total) > (
    SELECT AVG(cust_total) FROM (
        SELECT SUM(total) AS cust_total
        FROM orders
        WHERE status NOT IN ('cancelled', 'refunded')
        GROUP BY customer_id
    ) AS per_cust
)
ORDER BY total_spent DESC;

-- E6. correlated subquery in SELECT for times_ordered
SELECT
    p.sku,
    p.name,
    (SELECT COUNT(*) FROM order_items oi WHERE oi.product_id = p.id) AS times_ordered
FROM products p
ORDER BY times_ordered DESC;

-- E7. IN vs JOIN-with-DISTINCT vs EXISTS for "customers with at least one order"
-- IN: simple, subquery materialized once. Good when subquery is small.
-- JOIN with DISTINCT: works but forces dedup sort.
-- EXISTS: short-circuits per outer row. Best when subquery needs correlation
-- and outer table is small. On a 10M-row orders table with selective index
-- on customer_id, EXISTS often wins because it stops at first match.

-- ============================================================================
-- 02_exists.sql
-- ============================================================================

-- E1. customers with at least one order
SELECT c.first_name, c.last_name
FROM customers c
WHERE EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.id);

-- E2. products never ordered
SELECT p.sku, p.name
FROM products p
WHERE NOT EXISTS (SELECT 1 FROM order_items oi WHERE oi.product_id = p.id);

-- E3. customers with at least one delivered order
SELECT c.first_name, c.last_name
FROM customers c
WHERE EXISTS (
    SELECT 1 FROM orders o
    WHERE o.customer_id = c.id AND o.status = 'delivered'
);

-- E4. customers without any cancelled order
SELECT c.first_name, c.last_name
FROM customers c
WHERE NOT EXISTS (
    SELECT 1 FROM orders o
    WHERE o.customer_id = c.id AND o.status = 'cancelled'
);

-- E5. placed order but no delivered (double EXISTS/NOT EXISTS)
SELECT c.first_name, c.last_name
FROM customers c
WHERE EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.id)
  AND NOT EXISTS (
      SELECT 1 FROM orders o
      WHERE o.customer_id = c.id AND o.status = 'delivered'
  );

-- E6. has_orders / has_reviews flags
SELECT
    c.first_name,
    c.last_name,
    EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.id) AS has_orders,
    EXISTS (SELECT 1 FROM reviews r WHERE r.customer_id = c.id) AS has_reviews
FROM customers c
ORDER BY c.id;

-- E7. NULL trap demonstration
CREATE TEMPORARY TABLE tmp_with_null (id INT);
INSERT INTO tmp_with_null VALUES (1), (2), (NULL), (4);

-- NOT IN returns ZERO rows because the NULL in the subquery makes
-- x <> NULL → NULL for every x, so the AND chain is always NULL.
SELECT first_name FROM customers
WHERE id NOT IN (SELECT id FROM tmp_with_null);

-- NOT EXISTS is NULL-safe — it tests row existence, not equality.
SELECT first_name FROM customers c
WHERE NOT EXISTS (SELECT 1 FROM tmp_with_null t WHERE t.id = c.id);

DROP TEMPORARY TABLE tmp_with_null;

-- ============================================================================
-- 03_any_all.sql
-- ============================================================================

-- E1. products > ALL in category 11
SELECT name, price FROM products
WHERE price > ALL (SELECT price FROM products WHERE category_id = 11);

-- E2. products < ANY in category 12
SELECT name, price FROM products
WHERE price < ANY (SELECT price FROM products WHERE category_id = 12);

-- E3. rewrite using MAX
SELECT name, price FROM products
WHERE price > (SELECT MAX(price) FROM products WHERE category_id = 11);

-- E4. orders whose total > every 2024 order total
SELECT id, total FROM orders
WHERE total > ALL (SELECT total FROM orders WHERE YEAR(order_date) = 2024);

-- E5. <> ALL ≡ NOT IN, with NULL trap
CREATE TEMPORARY TABLE tmp_v (v INT);
INSERT INTO tmp_v VALUES (10), (20), (NULL);

-- Both return ZERO rows:
SELECT first_name FROM customers WHERE id <> ALL (SELECT v FROM tmp_v);
SELECT first_name FROM customers WHERE id NOT IN (SELECT v FROM tmp_v);

-- Fixed with NOT EXISTS:
SELECT first_name FROM customers c
WHERE NOT EXISTS (SELECT 1 FROM tmp_v t WHERE t.v = c.id);

DROP TEMPORARY TABLE tmp_v;

-- E6. ANY/ALL vs MIN/MAX vs IN/EXISTS
-- ANY/ALL are explicit but rarely used in practice.
-- MIN/MAX subqueries are clearer and equally efficient.
-- IN/EXISTS are clearer still for the common cases.
-- Prefer IN/EXISTS for readability; use MIN/MAX when a scalar comparison
-- is needed; reserve ANY/ALL for the rare case where the predicate form
-- is more natural.

-- ============================================================================
-- 04_select_into_select_into.sql
-- ============================================================================

-- E1. CREATE TABLE AS SELECT of categories
DROP TABLE IF EXISTS tmp_categories_copy;
CREATE TABLE tmp_categories_copy AS SELECT * FROM categories;
SELECT * FROM tmp_categories_copy LIMIT 3;
DROP TABLE tmp_categories_copy;

-- E2. temp table with names of active customers
CREATE TEMPORARY TABLE tmp_active_names AS
SELECT first_name, last_name FROM customers WHERE is_active = 1;
SELECT * FROM tmp_active_names LIMIT 3;
DROP TEMPORARY TABLE tmp_active_names;

-- E3. VIP customer summary
CREATE TEMPORARY TABLE tmp_vip_summary AS
SELECT
    c.id AS customer_id,
    c.first_name,
    c.last_name,
    COALESCE(SUM(o.total), 0) AS total_spent
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
WHERE c.metadata IS NOT NULL
  AND JSON_CONTAINS(c.metadata->'$.tags', '"vip"')
GROUP BY c.id, c.first_name, c.last_name;
SELECT * FROM tmp_vip_summary;
DROP TEMPORARY TABLE tmp_vip_summary;

-- E4. clone schema + copy laptops
DROP TABLE IF EXISTS tmp_laptops_clone;
CREATE TABLE tmp_laptops_clone LIKE products;
INSERT INTO tmp_laptops_clone SELECT * FROM products WHERE category_id = 8;
SELECT sku, name FROM tmp_laptops_clone;
DROP TABLE tmp_laptops_clone;

-- E5. cancelled orders archive
DROP TABLE IF EXISTS tmp_cancelled_archive;
CREATE TABLE tmp_cancelled_archive LIKE orders;
ALTER TABLE tmp_cancelled_archive ADD COLUMN archived_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
INSERT INTO tmp_cancelled_archive
    (id, customer_id, order_date, status, subtotal, discount, tax, shipping,
     total, shipping_address, notes, created_at, updated_at)
SELECT
    id, customer_id, order_date, status, subtotal, discount, tax, shipping,
    total, shipping_address, notes, created_at, updated_at
FROM orders WHERE status = 'cancelled';
SELECT COUNT(*) AS archived FROM tmp_cancelled_archive;
DROP TABLE tmp_cancelled_archive;

-- E6. SQL Server SELECT INTO vs MySQL CREATE TABLE AS
-- SQL Server: SELECT * INTO new_tbl FROM src — creates and populates new_tbl.
--   Does NOT copy indexes, constraints, or defaults.
-- MySQL: CREATE TABLE new_tbl AS SELECT * FROM src — creates and populates.
--   Also does NOT copy indexes/constraints.
--   Use CREATE TABLE new_tbl LIKE src to copy the full schema (indexes,
--   constraints, AUTO_INCREMENT) and then INSERT INTO new_tbl SELECT * FROM src.

-- End of file 03_subqueries_solutions.sql
