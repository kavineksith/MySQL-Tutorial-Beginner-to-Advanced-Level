-- ============================================================================
-- 02_select.sql — SELECT Statement & Projection
-- ============================================================================
-- SKILL LEVEL : Beginner
-- TOPICS      : Column projection, SELECT *, column aliases, computed columns,
--               DISTINCT (light intro — full treatment in 03_select_distinct),
--               literal selects, dual table, MySQL functions in SELECT.
-- ----------------------------------------------------------------------------
-- WHY SELECT FIRST?
--   The SELECT statement is to SQL what a function call is to a programming
--   language: the universal entry point. ~80% of real-world SQL written by
--   application developers is a SELECT. Getting fluent with projection (the
--   columns you choose to return) is the foundation of every later topic.
-- ============================================================================

USE ecom;

-- ----------------------------------------------------------------------------
-- 1. SELECT * — the universal exploration query
-- ----------------------------------------------------------------------------
SELECT * FROM customers;
-- Returns ALL columns of ALL rows. Fine for poking around in the CLI.
-- In application code, ALWAYS enumerate the columns you need. Two reasons:
--   (1) Schema changes (new column added) won't change your result shape.
--   (2) Transferring unneeded columns wastes memory and bandwidth.

-- ----------------------------------------------------------------------------
-- 2. SELECT col1, col2, ... — explicit projection
-- ----------------------------------------------------------------------------
SELECT
    first_name,
    last_name,
    email,
    country
FROM customers;

-- ----------------------------------------------------------------------------
-- 3. Column aliases with AS
-- ----------------------------------------------------------------------------
-- Aliases rename columns in the result set. The `AS` keyword is optional but
-- improves readability — always use it.
SELECT
    first_name AS given_name,
    last_name  AS family_name,
    email      AS contact_email
FROM customers;

-- Aliases with spaces or special characters MUST be quoted with backticks.
SELECT
    first_name AS `First Name`,
    last_name  AS `Last Name`
FROM customers;

-- ----------------------------------------------------------------------------
-- 4. Computed columns — arithmetic and functions in SELECT
-- ----------------------------------------------------------------------------
-- The SELECT list can contain any expression, not just column names.
SELECT
    sku,
    name,
    price,
    cost,
    (price - cost)                       AS gross_margin,
    (price - cost) / price * 100         AS gross_margin_pct,
    ROUND((price - cost) / price * 100, 2) AS gross_margin_pct_rounded
FROM products;

-- ----------------------------------------------------------------------------
-- 5. Literal selects — useful for constants and labels
-- ----------------------------------------------------------------------------
SELECT
    'ecommerce'              AS source_system,
    'customers'              AS table_name,
    CURRENT_TIMESTAMP        AS exported_at,
    first_name,
    last_name
FROM customers
LIMIT 3;

-- ----------------------------------------------------------------------------
-- 6. The DUAL table — selecting without a real table
-- ----------------------------------------------------------------------------
-- MySQL lets you write `SELECT 1+1;` but the SQL standard requires a FROM
-- clause. The `dual` dummy table satisfies that requirement.
SELECT
    NOW()                    AS current_time,
    VERSION()                AS mysql_version,
    USER()                   AS current_user,
    DATABASE()               AS current_database,
    CONNECTION_ID()          AS connection_id;

-- Equivalent using DUAL (more portable to other RDBMSs):
SELECT NOW() AS current_time FROM dual;

-- ----------------------------------------------------------------------------
-- 7. DISTINCT — preview (full treatment in 03_select_distinct.sql)
-- ----------------------------------------------------------------------------
-- DISTINCT removes duplicate rows from the result. It applies to the entire
-- row, not to a single column.
SELECT DISTINCT country FROM customers;
SELECT DISTINCT country, is_active FROM customers ORDER BY country;

-- ----------------------------------------------------------------------------
-- 8. CONCAT and string functions in SELECT
-- ----------------------------------------------------------------------------
SELECT
    CONCAT(first_name, ' ', last_name)            AS full_name,
    CONCAT(first_name, ' <', email, '>')          AS formatted_email,
    UPPER(email)                                  AS email_uppercase,
    LENGTH(email)                                 AS email_length
FROM customers
LIMIT 5;

-- ----------------------------------------------------------------------------
-- 9. Conditional expression — CASE (full treatment in 04_set_operations/03)
-- ----------------------------------------------------------------------------
-- A quick preview so you can practice writing branching logic.
SELECT
    first_name,
    last_name,
    is_active,
    CASE
        WHEN is_active = 1 THEN 'Active'
        WHEN is_active = 0 THEN 'Inactive'
        ELSE 'Unknown'
    END AS status_label
FROM customers
LIMIT 6;

-- ----------------------------------------------------------------------------
-- 10. Selecting with simple WHERE (full treatment in 04_where.sql)
-- ----------------------------------------------------------------------------
SELECT first_name, last_name, country
FROM customers
WHERE country = 'United States';

-- ----------------------------------------------------------------------------
-- 11. Selecting from a derived table (subquery in FROM)
-- ----------------------------------------------------------------------------
-- A query in the FROM clause produces a temporary table you can SELECT from.
-- This is the building block of more complex queries.
SELECT t.full_name, t.email_length
FROM (
    SELECT
        CONCAT(first_name, ' ', last_name) AS full_name,
        LENGTH(email)                      AS email_length
    FROM customers
) AS t
WHERE t.email_length > 20
ORDER BY t.email_length DESC;

-- ----------------------------------------------------------------------------
-- 12. EXERCISES
-- ----------------------------------------------------------------------------
-- EASY
-- E1.  Write a SELECT that returns product `name` and `price` for every row
--      in the `products` table.
-- E2.  Add a computed column `price_with_tax` that adds 10% to each price,
--      rounded to 2 decimals.
--
-- MEDIUM
-- E3.  Return first_name, last_name, and a single column called `city_state`
--      that looks like "Springfield, IL". Limit to 6 rows.
-- E4.  For every employee, return the email and the position of the `@`
--      character in the email (use `LOCATE('@', email)`).
--
-- HARD
-- E5.  Return one row per customer showing their full name and the number of
--      characters in their email after the `@` symbol. (Hint: SUBSTRING_INDEX
--      or SUBSTRING with LOCATE.)
--
-- EXPERT
-- E6.  Build a SELECT that returns, for each product, the SKU and a computed
--      column `price_tier` that maps to:
--         'budget'   if price < 100
--         'mid'      if 100 <= price < 500
--         'premium'  if 500 <= price < 1500
--         'luxury'   if price >= 1500
--      Use CASE.
-- ============================================================================

-- End of file 02_select.sql
