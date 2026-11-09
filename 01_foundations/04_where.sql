-- ============================================================================
-- 04_where.sql — The WHERE Clause: Row Filtering
-- ============================================================================
-- SKILL LEVEL : Beginner
-- TOPICS      : WHERE, comparison operators, AND/OR/NOT (preview),
--               string equality, numeric comparison, date comparison, NULL
--               handling in WHERE, operator precedence.
-- ----------------------------------------------------------------------------
-- TEXTBOOK DEPTH
--   The WHERE clause filters ROWS before grouping and projection happen. It
--   accepts any expression that evaluates to TRUE, FALSE, or NULL. Rows for
--   which the expression is TRUE are kept; rows for which it is FALSE or
--   NULL are discarded.
--
--   The three-valued logic of SQL (TRUE / FALSE / NULL) is the single most
--   common source of bugs in WHERE clauses. Remember:
--     * `NULL = NULL` evaluates to NULL, NOT to TRUE.
--     * `NULL <> 5`    evaluates to NULL, NOT to TRUE.
--     * A row passes WHERE only if the predicate is exactly TRUE.
--   Therefore `WHERE col <> 5` silently EXCLUDES rows where col IS NULL —
--   a frequent cause of "where did my data go?" reports.
-- ============================================================================

USE ecom;

-- ----------------------------------------------------------------------------
-- 1. Equality and inequality
-- ----------------------------------------------------------------------------
SELECT first_name, last_name, country
FROM customers
WHERE country = 'United States';

SELECT first_name, last_name
FROM customers
WHERE country <> 'United States';

-- ----------------------------------------------------------------------------
-- 2. Numeric comparison operators
-- ----------------------------------------------------------------------------
-- =, <>, !=, <, <=, >, >=
-- Note: != and <> are synonymous in MySQL; <> is the ANSI standard.
SELECT name, price FROM products WHERE price > 500;
SELECT name, price FROM products WHERE price <= 100;
SELECT name, stock_qty FROM products WHERE stock_qty < 20;

-- ----------------------------------------------------------------------------
-- 3. Date comparison
-- ----------------------------------------------------------------------------
SELECT id, order_date, total
FROM orders
WHERE order_date >= '2024-06-01';

SELECT id, order_date, status
FROM orders
WHERE order_date BETWEEN '2024-01-01' AND '2024-03-31';

-- Comparing DATE columns to TIMESTAMP values: MySQL performs implicit
-- conversion. Prefer explicit CAST to avoid surprises.
SELECT id, order_date
FROM orders
WHERE DATE(order_date) = '2024-02-20';

-- ----------------------------------------------------------------------------
-- 4. Boolean / TINYINT(1) columns
-- ----------------------------------------------------------------------------
-- In MySQL, TRUE = 1 and FALSE = 0. `WHERE is_active` is shorthand for
-- `WHERE is_active = 1` — both are valid; the explicit form is clearer.
SELECT first_name, last_name FROM customers WHERE is_active = 1;
SELECT first_name, last_name FROM customers WHERE is_active = TRUE;
SELECT first_name, last_name FROM customers WHERE is_active;

SELECT first_name, last_name FROM customers WHERE is_active = 0;
SELECT first_name, last_name FROM customers WHERE NOT is_active;

-- ----------------------------------------------------------------------------
-- 5. String comparison — case sensitivity
-- ----------------------------------------------------------------------------
-- Default collation `utf8mb4_0900_ai_ci` is case-INSENSITIVE (the `_ci`).
-- So 'United States' = 'UNITED STATES' returns TRUE.
SELECT first_name FROM customers WHERE last_name = 'JOHNSON';

-- Force case-sensitive comparison with COLLATE:
SELECT first_name FROM customers
WHERE last_name COLLATE utf8mb4_0900_as_cs = 'Johnson';

-- ----------------------------------------------------------------------------
-- 6. AND, OR, NOT — combinators (preview; full lesson in 06_and_or_not.sql)
-- ----------------------------------------------------------------------------
-- Precedence: NOT binds tighter than AND, AND binds tighter than OR.
-- Use parentheses liberally to make intent unambiguous.
SELECT first_name, country
FROM customers
WHERE country = 'United States' AND is_active = 1;

SELECT first_name, country
FROM customers
WHERE (country = 'United States' OR country = 'Canada')
  AND is_active = 1;

SELECT first_name, country
FROM customers
WHERE NOT country = 'United States';

-- ----------------------------------------------------------------------------
-- 7. NULL handling — the gotcha that catches everyone
-- ----------------------------------------------------------------------------
-- CORRECT: use IS NULL or IS NOT NULL.
SELECT first_name, last_name, metadata
FROM customers
WHERE metadata IS NULL;

SELECT first_name, last_name, metadata
FROM customers
WHERE metadata IS NOT NULL;

-- WRONG: this returns ZERO rows even if metadata has NULLs.
--   SELECT * FROM customers WHERE metadata = NULL;
-- Why: NULL = NULL evaluates to NULL, not TRUE, so no row passes.

-- ----------------------------------------------------------------------------
-- 8. NULL-safe equality operator <=>
-- ----------------------------------------------------------------------------
-- MySQL provides `<=>` (NULL-safe equal). It returns TRUE when both sides
-- are NULL, unlike `=`.
SELECT
    NULL =  NULL  AS regular_eq_null,   -- NULL
    NULL <=> NULL AS null_safe_eq_null, -- 1 (TRUE)
    1     =  1    AS regular_eq,        -- 1
    1     <=> 1   AS null_safe_eq;      -- 1

-- Practical use: find customers whose phone matches a given number, including
-- customers whose phone is NULL when you pass NULL.
SELECT first_name, last_name, phone
FROM customers
WHERE phone <=> NULL;

-- ----------------------------------------------------------------------------
-- 9. WHERE on a computed column — watch the alias trap
-- ----------------------------------------------------------------------------
-- WRONG: cannot reference alias `gross_margin` in WHERE (alias not yet
-- defined when WHERE runs).
--   SELECT sku, (price - cost) AS gross_margin
--   FROM products WHERE gross_margin > 200;   -- ERROR 1054

-- CORRECT: repeat the expression in WHERE, OR push the expression into a
-- derived table.
SELECT sku, (price - cost) AS gross_margin
FROM products
WHERE (price - cost) > 200;

-- Or use a derived table — handy when the expression is complex:
SELECT sku, gross_margin
FROM (
    SELECT sku, (price - cost) AS gross_margin
    FROM products
) AS t
WHERE gross_margin > 200
ORDER BY gross_margin DESC;

-- ----------------------------------------------------------------------------
-- 10. WHERE with functions
-- ----------------------------------------------------------------------------
SELECT first_name, last_name
FROM customers
WHERE LENGTH(email) > 20;

SELECT name, price
FROM products
WHERE LEFT(sku, 3) = 'LAP';

SELECT name, price
FROM products
WHERE ROUND(price, 0) = 1299;

-- Warning: applying a function to a column usually defeats indexes. We'll
-- revisit this in 09_advanced_mysql/11_indexing_strategies.sql.

-- ----------------------------------------------------------------------------
-- 11. WHERE with a subquery
-- ----------------------------------------------------------------------------
SELECT first_name, last_name
FROM customers
WHERE id IN (SELECT DISTINCT customer_id FROM orders);

-- ----------------------------------------------------------------------------
-- 12. Combining multiple conditions — the realistic query
-- ----------------------------------------------------------------------------
SELECT
    c.first_name,
    c.last_name,
    c.country,
    c.is_active
FROM customers c
WHERE c.country IN ('United States', 'United Kingdom', 'Canada')
  AND c.is_active = 1
  AND c.email LIKE '%@example.com'
  AND c.birth_date IS NOT NULL
ORDER BY c.last_name;

-- ----------------------------------------------------------------------------
-- 13. EXERCISES
-- ----------------------------------------------------------------------------
-- EASY
-- E1.  Return all products whose `stock_qty` is 0.
-- E2.  Return all customers whose `country` is Japan.
--
-- MEDIUM
-- E3.  Return all orders with status 'shipped' OR status 'paid'.
-- E4.  Return all reviews with rating 4 or 5 (use IN).
--
-- HARD
-- E5.  Find products whose gross margin (price - cost) is at least 40% of
--      their price. Show name, price, cost, margin_pct.
-- E6.  Find customers whose phone number is NULL but who have placed at
--      least one order (use a subquery in WHERE).
--
-- EXPERT
-- E7.  Why does this query return 0 rows even though customer #4 has
--      is_active = 0?
--         SELECT * FROM customers WHERE is_active = NULL;
--      Explain in a comment and provide the corrected query.
-- ============================================================================

-- End of file 04_where.sql
