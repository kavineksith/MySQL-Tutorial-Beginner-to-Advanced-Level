-- ============================================================================
-- 08_null_values.sql — NULL Values: The Three-Valued Logic
-- ============================================================================
-- SKILL LEVEL : Beginner
-- TOPICS      : What NULL means, IS NULL, IS NOT NULL, NULL in arithmetic,
--               NULL in aggregates, NULL in string concatenation, IFNULL,
--               COALESCE, NULLIF, comparison with NULL, <=> operator.
-- ----------------------------------------------------------------------------
-- TEXTBOOK DEPTH
--   NULL is not zero, not empty string, not "unknown value". NULL is the
--   SQL marker meaning "value is missing or not applicable". It introduces
--   three-valued logic (3VL): predicates can be TRUE, FALSE, or NULL
--   (often called UNKNOWN).
--
--   Critical facts:
--     * NULL = NULL   evaluates to NULL, not TRUE.
--     * NULL <> NULL  evaluates to NULL, not TRUE.
--     * NULL + 5      evaluates to NULL.  (Arithmetic with NULL yields NULL.)
--     * NULL || 'x'   evaluates to NULL in standard SQL.
--       (MySQL's `||` is logical OR by default, not concatenation.)
--     * COUNT(*) counts all rows; COUNT(col) counts non-NULL col values.
--     * SUM/AVG/MIN/MAX ignore NULLs.
--     * ORDER BY puts NULLs FIRST in ASC, LAST in DESC (MySQL behavior).
--
--   Design rule: prefer NULL over a sentinel value (0, '', -1) for missing
--   data. Sentinels corrupt aggregates and force every query to remember
--   the magic value. Use NOT NULL constraints on columns that MUST have a
--   value (e.g. email, created_at).
-- ============================================================================

USE ecom;

-- ----------------------------------------------------------------------------
-- 1. Inspect NULLs in our seed data
-- ----------------------------------------------------------------------------
SELECT first_name, last_name, phone, metadata
FROM customers
WHERE phone IS NULL OR metadata IS NULL;

-- ----------------------------------------------------------------------------
-- 2. IS NULL / IS NOT NULL — the only correct test
-- ----------------------------------------------------------------------------
SELECT first_name, last_name, phone
FROM customers
WHERE phone IS NULL;

SELECT first_name, last_name, phone
FROM customers
WHERE phone IS NOT NULL;

-- WRONG (returns 0 rows):
-- SELECT first_name, phone FROM customers WHERE phone = NULL;

-- ----------------------------------------------------------------------------
-- 3. NULL-safe equality <=>
-- ----------------------------------------------------------------------------
SELECT first_name, last_name,
       (phone = NULL)        AS regular_eq,
       (phone <=> NULL)      AS null_safe_eq
FROM customers
LIMIT 5;

-- Practical: find customers whose phone matches a parameter, INCLUDING NULL
-- when the parameter itself is NULL.
SET @phone_param := NULL;
SELECT first_name, last_name, phone
FROM customers
WHERE phone <=> @phone_param;

-- ----------------------------------------------------------------------------
-- 4. NULL in arithmetic — propagates
-- ----------------------------------------------------------------------------
SELECT
    sku,
    price,
    cost,
    weight_kg,
    price * weight_kg AS shipping_weight_estimate
FROM products
LIMIT 5;
-- Any row with weight_kg = NULL yields NULL for shipping_weight_estimate.

-- ----------------------------------------------------------------------------
-- 5. NULL in string concatenation
-- ----------------------------------------------------------------------------
-- In standard SQL, CONCAT('a', NULL) → NULL.
-- MySQL's CONCAT also propagates NULL:
SELECT CONCAT(first_name, ' ', last_name, ' - ', phone) AS label
FROM customers
LIMIT 4;
-- Rows with NULL phone produce NULL label.

-- CONCAT_WS (with separator) skips NULLs instead of propagating:
SELECT CONCAT_WS(' - ', first_name, last_name, phone) AS label
FROM customers
LIMIT 4;

-- ----------------------------------------------------------------------------
-- 6. NULL in aggregates
-- ----------------------------------------------------------------------------
-- COUNT(*) counts rows. COUNT(col) counts non-NULL col values.
SELECT
    COUNT(*)              AS total_rows,
    COUNT(phone)          AS non_null_phones,
    COUNT(*) - COUNT(phone) AS null_phones,
    COUNT(metadata)       AS non_null_metadata
FROM customers;

-- AVG ignores NULLs — this is a critical behavior.
-- AVG = SUM(non-NULL values) / COUNT(non-NULL values).
SELECT AVG(weight_kg) AS avg_weight_ignoring_nulls FROM products;
-- vs. AVG including NULLs as zero:
SELECT AVG(COALESCE(weight_kg, 0)) AS avg_weight_treating_null_as_zero FROM products;

-- ----------------------------------------------------------------------------
-- 7. COALESCE — return first non-NULL value
-- ----------------------------------------------------------------------------
SELECT
    first_name,
    last_name,
    COALESCE(phone, 'no phone on file') AS phone_or_default
FROM customers
LIMIT 6;

-- Multi-arg COALESCE — pick first available from a chain.
SELECT
    first_name,
    COALESCE(JSON_UNQUOTE(JSON_EXTRACT(metadata, '$.loyalty_points')), 0) AS loyalty_points
FROM customers
LIMIT 6;

-- ----------------------------------------------------------------------------
-- 8. IFNULL — MySQL-specific, two-argument version of COALESCE
-- ----------------------------------------------------------------------------
SELECT first_name, IFNULL(phone, 'no phone on file') AS phone_or_default
FROM customers LIMIT 6;
-- Prefer COALESCE — it is ANSI standard and accepts N arguments.

-- ----------------------------------------------------------------------------
-- 9. NULLIF(a, b) — returns NULL if a = b, else a
-- ----------------------------------------------------------------------------
-- Classic use: avoid division by zero.
SELECT
    sku,
    price,
    cost,
    price / NULLIF(cost, 0) AS markup_ratio
FROM products;
-- When cost = 0, NULLIF returns NULL, so division returns NULL instead of
-- throwing error 1365 (division by zero).

-- ----------------------------------------------------------------------------
-- 10. NULL in ORDER BY — MySQL puts NULLs FIRST in ASC
-- ----------------------------------------------------------------------------
SELECT first_name, phone
FROM customers
ORDER BY phone ASC;          -- NULLs first

SELECT first_name, phone
FROM customers
ORDER BY phone IS NULL DESC, phone DESC;  -- NULLs last

-- ----------------------------------------------------------------------------
-- 11. NULL in GROUP BY — all NULLs form one group
-- ----------------------------------------------------------------------------
SELECT phone, COUNT(*) AS customer_count
FROM customers
GROUP BY phone
ORDER BY phone IS NULL DESC, phone;
-- One group with phone = NULL containing all customers without a phone.

-- ----------------------------------------------------------------------------
-- 12. NOT IN trap with NULL
-- ----------------------------------------------------------------------------
-- This query can return ZERO rows if the subquery returns ANY NULL:
--   SELECT * FROM customers WHERE id NOT IN (SELECT customer_id FROM x);
-- Why: `NOT IN (a, b, NULL)` evaluates to `id <> a AND id <> b AND id <> NULL`
-- and `id <> NULL` is always NULL, which kills the whole predicate.
--
-- Use NOT EXISTS instead — it is NULL-safe:
--   SELECT * FROM customers c
--   WHERE NOT EXISTS (SELECT 1 FROM x WHERE x.customer_id = c.id);

-- Demo:
-- Safe — uses EXISTS / NOT EXISTS
SELECT first_name, last_name
FROM customers c
WHERE NOT EXISTS (
    SELECT 1 FROM orders o WHERE o.customer_id = c.id
);
-- Customers who have never placed an order.

-- ----------------------------------------------------------------------------
-- 13. NULL vs empty string — they are different
-- ----------------------------------------------------------------------------
-- '' (empty string) is a real value, NOT NULL.
SELECT '' IS NULL AS empty_is_null, LENGTH('') AS empty_length;
-- Returns: empty_is_null = 0, empty_length = 0.

-- Design: use NULL for missing values, not empty string. Empty string
-- usually means "I have a value and it's the empty string" — semantically
-- distinct from "I don't have a value".

-- ----------------------------------------------------------------------------
-- 14. EXERCISES
-- ----------------------------------------------------------------------------
-- EASY
-- E1.  Count how many customers have a NULL `metadata` value.
-- E2.  Return the first 5 products with a non-NULL `weight_kg`.
--
-- MEDIUM
-- E3.  For every customer, return first_name, last_name, and a `phone_label`
--      column that is either the phone or the literal '— no phone —' when
--      phone is NULL. Use COALESCE.
-- E4.  Calculate the average weight of products, treating NULL weights as 0
--      vs. ignoring NULLs. Show both numbers side-by-side.
--
-- HARD
-- E5.  Write a query that finds customers who have a NULL phone AND a NULL
--      metadata. (Hint: think carefully — NULL metadata can't be tested
--      with `= NULL`.)
-- E6.  Calculate the markup ratio (price/cost) for every product, returning
--      NULL when cost is 0 instead of throwing an error. Use NULLIF.
--
-- EXPERT
-- E7.  Explain in a comment why this query returns ZERO rows when the
--      subquery contains a NULL:
--        SELECT * FROM customers WHERE id NOT IN (SELECT customer_id FROM x);
--      Provide the equivalent NOT EXISTS query that handles NULLs correctly.
-- ============================================================================

-- End of file 08_null_values.sql
