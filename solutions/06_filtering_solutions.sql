-- ============================================================================
-- 06_filtering_solutions.sql — Solutions for 06_filtering_and_operators
-- ============================================================================

USE ecom;

-- ============================================================================
-- 01_select_top_limit.sql
-- ============================================================================

-- E1. 5 newest customers
SELECT first_name, last_name FROM customers ORDER BY id DESC LIMIT 5;

-- E2. 3 cheapest products
SELECT name, price FROM products ORDER BY price ASC LIMIT 3;

-- E3. 4-row-per-page pagination, three queries
SELECT name, price FROM products ORDER BY id LIMIT 4 OFFSET 0;
SELECT name, price FROM products ORDER BY id LIMIT 4 OFFSET 4;
SELECT name, price FROM products ORDER BY id LIMIT 4 OFFSET 8;

-- E4. most expensive product per category (correlated subquery)
SELECT p.category_id, p.name, p.price
FROM products p
WHERE p.price = (
    SELECT MAX(p2.price) FROM products p2 WHERE p2.category_id = p.category_id
)
ORDER BY p.category_id;

-- E5. top 3 customers by total spend
SELECT c.first_name, c.last_name, SUM(o.total) AS total_spend
FROM customers c
JOIN orders o ON o.customer_id = c.id
GROUP BY c.id, c.first_name, c.last_name
ORDER BY total_spend DESC
LIMIT 3;

-- E6. keyset pagination, 5 per page, 3 pages
-- Page 1
SELECT id, name FROM products WHERE id > 0 ORDER BY id ASC LIMIT 5;
-- After page 1 returns max id 5
SET @last := 5;
SELECT id, name FROM products WHERE id > @last ORDER BY id ASC LIMIT 5;
-- After page 2 returns max id 10
SET @last := 10;
SELECT id, name FROM products WHERE id > @last ORDER BY id ASC LIMIT 5;

-- ============================================================================
-- 02_like.sql
-- ============================================================================

-- E1. customers whose email starts with 'a'
SELECT first_name, email FROM customers WHERE email LIKE 'a%';

-- E2. products whose name starts with 'The '
SELECT name FROM products WHERE name LIKE 'The %';

-- E3. SKUs format XX-NNN (2 chars, dash, 3 chars)
SELECT sku, name FROM products WHERE sku LIKE '___-___';

-- E4. phones matching 555-01XX
SELECT first_name, phone FROM customers WHERE phone LIKE '555-01__';

-- E5. emails matching <first>.<last>@example.com (case-insensitive local part)
SELECT first_name, last_name, email
FROM customers
WHERE LOWER(email) LIKE CONCAT(LOWER(first_name), '.', LOWER(last_name), '@example.com');

-- E6. products containing 'pro' (case-insensitive)
SELECT name FROM products WHERE LOWER(name) LIKE '%pro%';
-- Why LIKE '%pro%' is slow on a million-row table: a leading wildcard
-- prevents index use; the engine scans every row.
-- Faster alternative: FULLTEXT index + MATCH AGAINST (see
-- 09_advanced_mysql/09_fulltext_search.sql).

-- ============================================================================
-- 03_wildcards.sql
-- ============================================================================

-- E1. last names starting with D-F
SELECT first_name, last_name
FROM customers
WHERE last_name REGEXP '^[D-F]';

-- E2. SKUs containing a digit
SELECT sku, name FROM products WHERE sku REGEXP '[0-9]';

-- E3. first name exactly 4 letters starting with vowel
SELECT first_name FROM customers
WHERE first_name REGEXP '^[AEIOU][a-zA-Z]{3}$';

-- E4. phones containing a digit other than 0 or 1
SELECT first_name, phone FROM customers
WHERE phone REGEXP '[2-9]';

-- E5. SKU pattern: 3 chars - 3 chars, suffix starts with digit
SELECT sku, name FROM products
WHERE sku REGEXP '^[A-Z]{3}-[0-9][A-Z0-9]{2}$';

-- E6. LIKE-based equivalent for last names A-C (chain of OR)
SELECT first_name, last_name
FROM customers
WHERE last_name LIKE 'A%' OR last_name LIKE 'B%' OR last_name LIKE 'C%';

-- ============================================================================
-- 04_in_operator.sql
-- ============================================================================

-- E1. products in categories 8, 9, 12
SELECT name, price FROM products WHERE category_id IN (8, 9, 12);

-- E2. orders with status paid/shipped/delivered
SELECT id, status FROM orders WHERE status IN ('paid', 'shipped', 'delivered');

-- E3. customers with orders in 2024
SELECT first_name, last_name
FROM customers
WHERE id IN (SELECT customer_id FROM orders WHERE YEAR(order_date) = 2024);

-- E4. products never ordered (use NOT EXISTS — NOT IN would work but NOT EXISTS is safer)
SELECT sku, name
FROM products p
WHERE NOT EXISTS (SELECT 1 FROM order_items oi WHERE oi.product_id = p.id);
-- Reason NOT EXISTS is safer: NOT IN has the NULL trap if any product_id
-- is NULL in order_items.

-- E5. NULL trap demonstration
CREATE TEMPORARY TABLE tmp_with_null (val INT);
INSERT INTO tmp_with_null VALUES (1), (2), (NULL), (4);

-- NOT IN returns zero rows:
SELECT first_name FROM customers
WHERE id NOT IN (SELECT val FROM tmp_with_null);

-- Fixed with NOT EXISTS:
SELECT first_name FROM customers c
WHERE NOT EXISTS (SELECT 1 FROM tmp_with_null t WHERE t.val = c.id);

DROP TEMPORARY TABLE tmp_with_null;

-- E6. When to prefer IN vs EXISTS:
-- IN: subquery returns small list, outer table large — IN materializes
--     the list once and looks up.
-- EXISTS: subquery needs correlation and outer table small — EXISTS
--     short-circuits per outer row.
-- MySQL 8 optimizes both well; pick whichever is more readable.

-- ============================================================================
-- 05_between.sql
-- ============================================================================

-- E1. products 50-200
SELECT name, price FROM products WHERE price BETWEEN 50 AND 200 ORDER BY price;

-- E2. orders Mar-May 2024 (boundary-safe)
SELECT id, order_date FROM orders
WHERE order_date >= '2024-03-01' AND order_date < '2024-06-01';

-- E3. customers born 1980-1995
SELECT first_name, last_name, birth_date FROM customers
WHERE birth_date BETWEEN '1980-01-01' AND '1995-12-31';

-- E4. products with stock value 1000-10000
SELECT name, price, stock_qty, price * stock_qty AS stock_value
FROM products
WHERE price * stock_qty BETWEEN 1000 AND 10000
ORDER BY stock_value;

-- E5. orders within 20% of average total
SELECT id, total
FROM orders
WHERE total BETWEEN
    (SELECT AVG(total) * 0.80 FROM orders)
  AND
    (SELECT AVG(total) * 1.20 FROM orders);

-- E6. Why BETWEEN with TIMESTAMP misses rows:
-- '2024-01-31' is interpreted as '2024-01-31 00:00:00'. Any row on
-- 2024-01-31 with a time later than 00:00:00 has order_date > '2024-01-31'
-- and is excluded.
-- Recommended pattern:
--   WHERE order_date >= '2024-01-01' AND order_date < '2024-02-01'

-- ============================================================================
-- 06_aliases.sql
-- ============================================================================

-- E1. inventory_value alias
SELECT name, price * stock_qty AS inventory_value FROM products;

-- E2. full email label
SELECT CONCAT(first_name, ' ', last_name, ' <', email, '>') AS full_email_label
FROM customers;

-- E3. total_revenue per order_status
SELECT status, SUM(total) AS total_revenue
FROM orders
GROUP BY status;

-- E4. customer + order join with aliases
SELECT c.first_name, c.last_name, o.total
FROM customers c
JOIN orders o ON o.customer_id = c.id;

-- E5. alias-in-WHERE trap demo
-- This errors:
--   SELECT sku, (price - cost) AS gm FROM products WHERE gm > 200;
-- Fixed with derived table:
SELECT sku, gm
FROM (
    SELECT sku, (price - cost) AS gm FROM products
) AS t
WHERE gm > 200;

-- E6. Why SQL standard forbids aliases in WHERE:
-- WHERE runs BEFORE SELECT in the logical evaluation order. The alias is
-- defined during SELECT, so it doesn't exist yet when WHERE is evaluated.
-- ORDER BY runs AFTER SELECT, so aliases are visible there.

-- ============================================================================
-- 07_null_functions.sql
-- ============================================================================

-- E1. phone or '— none —'
SELECT first_name, IFNULL(phone, '— none —') AS phone_label FROM customers;

-- E2. loyalty_points from JSON, default 0
SELECT first_name,
    COALESCE(JSON_UNQUOTE(JSON_EXTRACT(metadata, '$.loyalty_points')), 0) AS loyalty_points
FROM customers;

-- E3. markup ratio with NULLIF
SELECT sku, price, cost, price / NULLIF(cost, 0) AS markup_ratio FROM products;

-- E4. contact_card with CONCAT_WS
SELECT CONCAT_WS(' | ', first_name, last_name, phone, city) AS contact_card
FROM customers;

-- E5. customer total spend with COALESCE
SELECT c.first_name, c.last_name, COALESCE(SUM(o.total), 0) AS total_spent
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
GROUP BY c.id, c.first_name, c.last_name
ORDER BY total_spent DESC;

-- E6. flag vip/active/new
SELECT
    c.first_name,
    c.last_name,
    IF(
        COALESCE(JSON_UNQUOTE(JSON_EXTRACT(c.metadata, '$.loyalty_points')), 0) >= 1000,
        'vip',
        IF(
            EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.id),
            'active',
            'new'
        )
    ) AS customer_flag
FROM customers c;

-- ============================================================================
-- 08_operators.sql
-- ============================================================================

-- E1. customers with id in (1,3,5,7)
SELECT first_name, last_name FROM customers WHERE id IN (1, 3, 5, 7);

-- E2. products price 100-1000
SELECT name, price FROM products WHERE price BETWEEN 100 AND 1000;

-- E3. products > ALL category 12
SELECT name, price FROM products
WHERE price > ALL (SELECT price FROM products WHERE category_id = 12);

-- E4. products > ANY category 12
SELECT name, price FROM products
WHERE price > ANY (SELECT price FROM products WHERE category_id = 12);

-- E5. customer has order total > 1000 (TRUE/FALSE)
SELECT c.first_name, c.last_name,
    IF(EXISTS (
        SELECT 1 FROM orders o
        WHERE o.customer_id = c.id AND o.total > 1000
    ), 'TRUE', 'FALSE') AS has_high_value_order
FROM customers c;

-- E6. `1 = 1 OR 2 = 2 AND 3 = 4` parses as `1 = 1 OR (2 = 2 AND 3 = 4)` = TRUE
-- Fully parenthesized:
SELECT (1 = 1) OR ((2 = 2) AND (3 = 4)) AS result;

-- ============================================================================
-- 09_comments.sql
-- ============================================================================

-- E1. SELECT with single-line -- comments per column
SELECT
    first_name,    -- customer first name
    last_name,     -- customer last name
    email          -- contact email
FROM customers;

-- E2. SELECT with multi-line /* */ header
/*
 * Customer contact report
 * Generated for sales team
 */
SELECT first_name, last_name, email FROM customers;

-- E3. `SELECT 5 -- 3;` returns 2 because -- (no space) is arithmetic
-- double-negative, not a comment. The space after -- is what makes it a comment.

-- E4. Inline comments distinguishing business rule vs perf filter
SELECT first_name, last_name
FROM customers
WHERE is_active = 1                 -- business rule: only active customers
  AND created_at > '2024-01-01';    -- performance filter: index on created_at

-- E5. CREATE TABLE with /*!ENGINE=InnoDB */
DROP TABLE IF EXISTS tmp_portable_ex;
CREATE TABLE tmp_portable_ex (
    id INT PRIMARY KEY,
    name VARCHAR(20)
) /*!ENGINE=InnoDB */;
DROP TABLE tmp_portable_ex;

-- E6. Comment vs executable comment vs optimizer hint:
-- Regular comment `/* text */` — ignored by all parsers.
-- Executable comment `/*! code */` — executed by MySQL, ignored by other RDBMSs.
-- Optimizer hint `/*+ HINT */` — affects the optimizer's plan choice.
-- Use regular for documentation, executable for MySQL-specific syntax in
-- portable scripts, hints for query tuning.

-- End of file 06_filtering_solutions.sql
