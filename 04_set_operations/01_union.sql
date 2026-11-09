-- ============================================================================
-- 01_union.sql — UNION: Combining Result Sets
-- ============================================================================
-- SKILL LEVEL : Intermediate
-- TOPICS      : UNION (removes duplicates), UNION ALL (keeps duplicates),
--               column count and type rules, ORDER BY and LIMIT with UNION,
--               UNION vs JOIN, mixing tables.
-- ----------------------------------------------------------------------------
-- TEXTBOOK DEPTH
--   UNION vertically stacks the result sets of two or more SELECTs into a
--   single result. JOIN horizontally combines columns; UNION vertically
--   combines rows.
--
--   UNION rules:
--     * Every SELECT must return the SAME NUMBER of columns.
--     * Corresponding columns must have compatible types (MySQL will
--       implicitly convert).
--     * Column names come from the FIRST SELECT.
--     * UNION removes duplicate rows (forces a sort/hash).
--     * UNION ALL keeps duplicates (faster — prefer when no dups expected).
--     * ORDER BY / LIMIT apply to the WHOLE union, placed at the end.
--
--   When to use UNION vs UNION ALL:
--     * If you know the inputs are mutually exclusive → use UNION ALL (faster).
--     * If duplicates are possible and you want them removed → use UNION.
--     * Default to UNION ALL unless you specifically need deduplication.
-- ============================================================================

USE ecom;

-- ----------------------------------------------------------------------------
-- 1. Basic UNION ALL — combine two result sets
-- ----------------------------------------------------------------------------
-- All customer first names + all employee first names (with origin label)
SELECT first_name, 'customer' AS person_type FROM customers
UNION ALL
SELECT first_name, 'employee' AS person_type FROM employees
ORDER BY first_name
LIMIT 10;

-- ----------------------------------------------------------------------------
-- 2. UNION removes duplicates
-- ----------------------------------------------------------------------------
-- Names that appear in BOTH customers and employees
SELECT first_name FROM customers
UNION
SELECT first_name FROM employees
ORDER BY first_name;

-- Compared to UNION ALL:
SELECT first_name FROM customers
UNION ALL
SELECT first_name FROM employees
ORDER BY first_name;
-- UNION ALL preserves duplicates; total row count = 12 + 9 = 21.
-- UNION removes them; some first_names may collapse.

-- ----------------------------------------------------------------------------
-- 3. UNION with column type mixing
-- ----------------------------------------------------------------------------
-- Numbers and strings — MySQL coerces to a common type.
SELECT 'text' AS col UNION SELECT 42;
-- Returns 'text' and '42' (both strings).

-- ----------------------------------------------------------------------------
-- 4. UNION with different column counts — ERROR
-- ----------------------------------------------------------------------------
-- This fails: SELECT first_name FROM customers UNION SELECT first_name, last_name FROM employees;
-- ERROR 1222: The used SELECT statements have a different number of columns

-- ----------------------------------------------------------------------------
-- 5. UNION with column aliases from the FIRST SELECT
-- ----------------------------------------------------------------------------
SELECT first_name AS fn, last_name AS ln, email AS contact FROM customers
UNION ALL
SELECT first_name, last_name, email FROM employees
ORDER BY fn
LIMIT 5;
-- Column names come from the first SELECT.

-- ----------------------------------------------------------------------------
-- 6. UNION with WHERE filters on each branch
-- ----------------------------------------------------------------------------
-- Active customers + active employees
SELECT first_name, last_name, email, 'customer' AS role
FROM customers
WHERE is_active = 1
UNION ALL
SELECT first_name, last_name, email, title
FROM employees
WHERE is_active = 1
ORDER BY last_name
LIMIT 10;

-- ----------------------------------------------------------------------------
-- 7. UNION with aggregate across different tables
-- ----------------------------------------------------------------------------
-- Total counts of customers, products, orders, reviews in one result set.
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL
SELECT 'products',         COUNT(*) FROM products
UNION ALL
SELECT 'orders',           COUNT(*) FROM orders
UNION ALL
SELECT 'order_items',      COUNT(*) FROM order_items
UNION ALL
SELECT 'reviews',          COUNT(*) FROM reviews
UNION ALL
SELECT 'employees',        COUNT(*) FROM employees
UNION ALL
SELECT 'categories',       COUNT(*) FROM categories;

-- ----------------------------------------------------------------------------
-- 8. UNION ALL with computed "virtual" rows
-- ----------------------------------------------------------------------------
-- Add a summary row to a per-category report.
SELECT category_id, COUNT(*) AS product_count
FROM products
GROUP BY category_id
UNION ALL
SELECT NULL, COUNT(*) FROM products
ORDER BY category_id;
-- NULL category_id row at the end is the grand total.

-- ----------------------------------------------------------------------------
-- 9. UNION with ORDER BY applied to the whole result
-- ----------------------------------------------------------------------------
-- ORDER BY applies to the entire unioned result, must come at the END.
SELECT 'high_value' AS bucket, id, total FROM orders WHERE total > 1000
UNION ALL
SELECT 'low_value', id, total FROM orders WHERE total <= 1000
ORDER BY total DESC;

-- ----------------------------------------------------------------------------
-- 10. UNION to emulate FULL OUTER JOIN (review)
-- ----------------------------------------------------------------------------
-- Already covered in 02_joins/05_full_join.sql — UNION of LEFT + RIGHT join.

-- ----------------------------------------------------------------------------
-- 11. UNION ALL with different column types via CAST
-- ----------------------------------------------------------------------------
SELECT CAST(price AS CHAR) AS value, 'price' AS source FROM products WHERE price > 1000
UNION ALL
SELECT name, 'name' AS source FROM products WHERE name LIKE 'A%'
ORDER BY value;

-- ----------------------------------------------------------------------------
-- 12. EXERCISES
-- ----------------------------------------------------------------------------
-- EASY
-- E1.  List every email from both customers and employees, in one column.
-- E2.  List the names of all categories and all products, in one column,
--      with a 'category' or 'product' label.
--
-- MEDIUM
-- E3.  Use UNION ALL to produce a single result set showing:
--        - customer id, name, type='customer'
--        - employee id, name, type='employee'
--      Order by name.
-- E4.  Count rows in every table using a single UNION ALL query.
--
-- HARD
-- E5.  Use UNION to emulate a FULL OUTER JOIN of customers and orders.
--      Explain why UNION (not UNION ALL) is required.
--
-- EXPERT
-- E6.  Explain in a comment when you would prefer UNION ALL over UNION,
--      and the performance implications of each. Provide an example query
--      where UNION ALL is the right choice.
-- ============================================================================

-- End of file 01_union.sql
