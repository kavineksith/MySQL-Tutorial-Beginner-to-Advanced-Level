-- ============================================================================
-- 01_intro_and_syntax.sql — SQL Intro & Syntax
-- ============================================================================
-- SKILL LEVEL : Beginner
-- PREREQUISITE: 00_setup/00_schema.sql + 01_seed_data.sql
-- TOPICS      : What SQL is, dialects, MySQL specifics, statement anatomy,
--               the SELECT statement template, semicolons, case sensitivity,
--               identifier quoting, identifiers vs. literals.
-- ----------------------------------------------------------------------------
-- TEXTBOOK DEPTH
--   SQL (Structured Query Language) is the only widely-adopted declarative
--   language for relational databases. It was developed at IBM in the early
--   1970s by Donald Chamberlin and Raymond Boyce, originally called SEQUEL
--   (hence the still-common pronunciation "see-quel"). The name was changed
--   to SQL in 1977 because SEQUEL was a trademark of the UK aircraft company
--   Hawker Siddeley.
--
--   SQL is standardized by ANSI (1986) and ISO (1987), but every DBMS extends
--   the standard. The MySQL dialect — the world's most popular open-source
--   database — adds procedural extensions, JSON functions, window functions
--   (since 8.0), and a distinctive set of storage engines.
--
--   MySQL-specific facts you must remember:
--     * Statements end with a semicolon `;`
--     * Keywords are case-INsensitive (SELECT == select == SeLeCt)
--     * Identifiers (table/column names) are case-INsensitive on Windows,
--       but case-SENSITIVE on Linux by default — the safest habit is to
--       always write identifiers in lowercase.
--     * String literals MUST be wrapped in single quotes: 'alice'
--     * Double quotes are identifiers in ANSI SQL but MySQL reinterprets
--       them as strings when `sql_mode` does not include ANSI_QUOTES.
-- ============================================================================

USE ecom;

-- ----------------------------------------------------------------------------
-- 1. The SELECT statement skeleton
-- ----------------------------------------------------------------------------
-- Every read query in SQL follows the same logical shape. The clauses MUST
-- appear in this order even though the database evaluates them in a different
-- order (see section 4 below).
--
--   SELECT  <columns or expressions>
--   FROM    <table or join>
--   WHERE   <row-level filter>
--   GROUP BY <grouping columns>
--   HAVING  <group-level filter>
--   ORDER BY <sort columns>
--   LIMIT   <count> [OFFSET <skip>]
-- ;

-- Example 1 — minimal query: select all columns from the customers table.
SELECT * FROM customers;
-- `*` returns every column. Useful for exploration, AVOID in production code
-- because schema changes silently break downstream consumers.

-- Example 2 — pick specific columns. This is the recommended style.
SELECT first_name, last_name, email
FROM customers;

-- Example 3 — limit rows during exploration.
SELECT first_name, last_name, email
FROM customers
LIMIT 5;

-- ----------------------------------------------------------------------------
-- 2. Case sensitivity: keywords yes, identifiers maybe
-- ----------------------------------------------------------------------------
-- These three are identical because keywords are case-insensitive:
SELECT first_name FROM customers;
select FIRST_NAME from CUSTOMERS;
SeLeCt first_name from customers;

-- On Linux with default `lower_case_table_names=0`, the table name
-- `customers` and `CUSTOMERS` may refer to DIFFERENT files. Always use
-- lowercase identifiers to stay portable.

-- ----------------------------------------------------------------------------
-- 3. Identifier quoting with backticks (MySQL-specific)
-- ----------------------------------------------------------------------------
-- MySQL uses backticks to quote identifiers that would otherwise be illegal
-- (reserved words, spaces, special characters). ANSI SQL uses double quotes.
SELECT `first_name`, `last_name` FROM `customers`;

-- Quoting is REQUIRED when an identifier collides with a reserved word.
-- For example, "order" is reserved, so the table is named "orders" instead.
-- Had it been called "order", you would have to write:
--     SELECT * FROM `order`;     -- valid but confusing — avoid the pattern.

-- ----------------------------------------------------------------------------
-- 4. LOGICAL vs PHYSICAL evaluation order
-- ----------------------------------------------------------------------------
-- You WRITE clauses in this order (the SQL standard requires it):
--
--     1. FROM         (which table?)
--     2. WHERE        (which rows survive?)
--     3. GROUP BY     (which row groups form?)
--     4. HAVING       (which groups survive?)
--     5. SELECT       (which columns/expressions to project?)
--     6. ORDER BY     (how to sort?)
--     7. LIMIT        (how many rows to return?)
--
-- The database engine EVALUATES clauses in roughly this order too, which
-- explains two common surprises:
--
--   SURPRISE 1: You cannot reference a column alias in the WHERE clause.
--     SELECT first_name AS fn FROM customers WHERE fn = 'Alice';  -- ERROR
--   Why? WHERE runs BEFORE SELECT, so the alias `fn` does not yet exist.
--
--   SURPRISE 2: You CAN reference a column alias in ORDER BY / HAVING.
--     SELECT first_name AS fn FROM customers ORDER BY fn;          -- OK
--   Why? ORDER BY runs AFTER SELECT, so the alias is visible.

-- ----------------------------------------------------------------------------
-- 5. Literals: strings, numbers, dates, booleans, NULL
-- ----------------------------------------------------------------------------
SELECT
    'Alice'              AS string_literal,         -- single-quoted string
    "double"             AS mysql_double_quoted,    -- works but discouraged
    42                   AS integer_literal,
    3.14                 AS decimal_literal,
    0x1A                 AS hex_literal,            -- 26
    TRUE                 AS boolean_true,           -- alias for 1
    FALSE                AS boolean_false,          -- alias for 0
    NULL                 AS null_literal,
    DATE '2024-01-15'    AS date_literal,
    TIMESTAMP '2024-01-15 10:23:00' AS timestamp_literal;

-- ----------------------------------------------------------------------------
-- 6. Comments: single-line, multi-line, and MySQL-specific `-- `
-- ----------------------------------------------------------------------------
-- Two dashes followed by a space is a single-line comment to end of line.
-- A `#` also works in MySQL but is non-standard.
-- `/* ... */` is a multi-line comment and can span multiple lines.

# This is a MySQL-style single-line comment (avoid in portable code).

/*
 * Multi-line comment.
 * Useful for header documentation blocks like this one.
 */

-- ----------------------------------------------------------------------------
-- 7. Statement terminators
-- ----------------------------------------------------------------------------
-- Inside the mysql CLI, a statement only executes when you type `;`.
-- Use `\G` instead of `;` to display results vertically (great for wide rows):
--     SELECT * FROM customers\G

-- ----------------------------------------------------------------------------
-- 8. EXERCISES (solutions in solutions/01_foundations_solutions.sql)
-- ----------------------------------------------------------------------------
-- EASY
-- E1.  Select the id and name of every category. Limit to 5 rows.
--
-- MEDIUM
-- E2.  Select the SKU, name, and price of every product, ordering is not
--      required yet. Return only the first 3 rows.
--
-- HARD
-- E3.  The CTO asks: "show me each customer's first name, last name, and
--      email, but only for the first 4 customers we acquired". Write the
--      query. (Hint: see the `created_at` column and the `ORDER BY` lesson
--      coming up — you can already guess the syntax.)
--
-- EXPERT
-- E4.  Without running it, predict what this query returns and why:
--        SELECT 1 AS a, (SELECT 2) AS b, 'three' AS c FROM dual;
--      (Hint: `dual` is a dummy one-row table MySQL provides for SELECTs
--      that don't reference a real table.)
-- ============================================================================

-- End of file 01_intro_and_syntax.sql
