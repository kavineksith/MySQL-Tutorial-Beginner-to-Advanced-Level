-- ============================================================================
-- 06_aliases.sql — Aliases: Column and Table Aliases
-- ============================================================================
-- SKILL LEVEL : Beginner
-- TOPICS      : Column aliases with AS, table aliases, alias scope rules,
--               alias in WHERE/GROUP BY/HAVING/ORDER BY, quoting aliases.
-- ----------------------------------------------------------------------------
-- TEXTBOOK DEPTH
--   Aliases rename a column or a table for the duration of a single query.
--   Two flavors:
--     COLUMN alias  : renames the output column header.
--                     SELECT first_name AS fn  →  result column named "fn"
--     TABLE alias   : short name for a table reference inside the query.
--                     FROM customers c  →  c.first_name works inside the query
--
--   Alias scope (when can you reference an alias?):
--     * WHERE     : NO.   WHERE runs BEFORE SELECT.
--     * GROUP BY  : YES in MySQL (extension; standard SQL says no).
--     * HAVING    : YES in MySQL.
--     * ORDER BY  : YES (standard SQL).
--     * Subsequent SELECT list exprs : NO in MySQL (no forward references).
--
--   Quoting rules:
--     * Aliases that look like identifiers (no spaces/special chars) need no
--       quotes: AS gross_margin
--     * Aliases with spaces or special chars MUST be quoted with backticks
--       in MySQL: AS `Gross Margin`
--     * Double quotes work if sql_mode contains ANSI_QUOTES.
-- ============================================================================

USE ecom;

-- ----------------------------------------------------------------------------
-- 1. Column alias with AS (recommended)
-- ----------------------------------------------------------------------------
SELECT
    first_name AS given_name,
    last_name  AS family_name,
    email      AS contact_email
FROM customers
LIMIT 3;

-- ----------------------------------------------------------------------------
-- 2. Column alias without AS (works, less readable)
-- ----------------------------------------------------------------------------
SELECT first_name given_name, last_name family_name
FROM customers LIMIT 3;

-- ----------------------------------------------------------------------------
-- 3. Alias for computed columns
-- ----------------------------------------------------------------------------
SELECT
    sku,
    name,
    price,
    cost,
    (price - cost)                       AS gross_margin,
    ROUND((price - cost) / price * 100, 2) AS gross_margin_pct
FROM products
LIMIT 5;

-- ----------------------------------------------------------------------------
-- 4. Alias with spaces — backticks required
-- ----------------------------------------------------------------------------
SELECT
    first_name AS `First Name`,
    last_name  AS `Last Name`,
    (price - cost) AS `Gross Margin $`
FROM products
LIMIT 3;

-- ----------------------------------------------------------------------------
-- 5. Table alias — short name used throughout the query
-- ----------------------------------------------------------------------------
SELECT c.first_name, c.last_name, c.country
FROM customers c
WHERE c.country = 'United States';

-- ----------------------------------------------------------------------------
-- 6. Table alias with JOIN
-- ----------------------------------------------------------------------------
SELECT
    c.first_name,
    c.last_name,
    o.id AS order_id,
    o.total
FROM customers c
JOIN orders o ON o.customer_id = c.id
ORDER BY o.total DESC
LIMIT 5;

-- ----------------------------------------------------------------------------
-- 7. Alias scope — the WHERE trap
-- ----------------------------------------------------------------------------
-- WRONG: alias `gm` is not visible in WHERE (WHERE runs before SELECT).
--   SELECT sku, (price - cost) AS gm FROM products WHERE gm > 200;   -- ERROR 1054

-- WORKAROUND 1: repeat the expression in WHERE.
SELECT sku, (price - cost) AS gm
FROM products
WHERE (price - cost) > 200;

-- WORKAROUND 2: push the computation into a derived table, then filter.
SELECT sku, gm
FROM (
    SELECT sku, (price - cost) AS gm FROM products
) AS t
WHERE gm > 200;

-- ----------------------------------------------------------------------------
-- 8. Alias visible in ORDER BY and HAVING
-- ----------------------------------------------------------------------------
-- ORDER BY can use the alias — ORDER BY runs AFTER SELECT.
SELECT sku, (price - cost) AS gm
FROM products
ORDER BY gm DESC
LIMIT 5;

-- HAVING (in MySQL) can use the alias too.
SELECT
    category_id,
    COUNT(*) AS product_count,
    AVG(price) AS avg_price
FROM products
GROUP BY category_id
HAVING avg_price > 100
ORDER BY avg_price DESC;

-- ----------------------------------------------------------------------------
-- 9. GROUP BY alias (MySQL extension)
-- ----------------------------------------------------------------------------
-- MySQL allows aliases in GROUP BY (standard SQL forbids it).
SELECT
    YEAR(order_date) AS order_year,
    COUNT(*) AS order_count
FROM orders
GROUP BY order_year           -- alias used here
ORDER BY order_year;

-- For portability, prefer the underlying expression:
SELECT
    YEAR(order_date) AS order_year,
    COUNT(*) AS order_count
FROM orders
GROUP BY YEAR(order_date)
ORDER BY order_year;

-- ----------------------------------------------------------------------------
-- 10. Self-join requires table aliases
-- ----------------------------------------------------------------------------
-- Find each employee's manager (same table joined to itself).
SELECT
    e.first_name AS employee,
    m.first_name AS manager
FROM employees e
LEFT JOIN employees m ON m.id = e.manager_id;

-- Without aliases, you'd have to write `employees` twice — MySQL would
-- reject that because the table name must be unique in a join.

-- ----------------------------------------------------------------------------
-- 11. AS keyword is optional everywhere
-- ----------------------------------------------------------------------------
-- These two are identical:
SELECT c.first_name FROM customers AS c WHERE c.country = 'Japan';
SELECT c.first_name FROM customers   c WHERE c.country = 'Japan';
-- The form with AS is clearer for beginners.

-- ----------------------------------------------------------------------------
-- 12. EXERCISES
-- ----------------------------------------------------------------------------
-- EASY
-- E1.  Select product name and a computed column `inventory_value` =
--      price * stock_qty, aliased.
-- E2.  Select each customer's first_name, last_name, and a column
--      `full_email_label` that looks like 'Alice Johnson <alice@...>'.
--
-- MEDIUM
-- E3.  Write a query that returns total_revenue per order_status. Use
--      aliases for clarity.
-- E4.  Use table aliases `c` and `o` to join customers to orders. Return
--      customer first_name, last_name, and the order total.
--
-- HARD
-- E5.  Demonstrate the alias-in-WHERE trap by writing a query that errors,
--      then provide the corrected version using a derived table.
--
-- EXPERT
-- E6.  Explain in a comment why the SQL standard forbids aliases in WHERE
--      but allows them in ORDER BY and HAVING. (Hint: the order of logical
--      processing.)
-- ============================================================================

-- End of file 06_aliases.sql
