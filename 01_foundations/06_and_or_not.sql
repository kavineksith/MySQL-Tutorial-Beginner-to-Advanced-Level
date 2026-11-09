-- ============================================================================
-- 06_and_or_not.sql — Logical Operators AND, OR, NOT
-- ============================================================================
-- SKILL LEVEL : Beginner
-- TOPICS      : AND, OR, NOT, three-valued logic, operator precedence,
--               De Morgan's laws in SQL, parentheses for clarity, XOR,
--               short-circuit behavior.
-- ----------------------------------------------------------------------------
-- TEXTBOOK DEPTH
--   SQL uses three-valued logic (3VL): every predicate evaluates to TRUE,
--   FALSE, or NULL (UNKNOWN). The truth tables:
--
--     AND | T  F  N         OR | T  F  N         NOT |
--     ----+---------        ----+---------        ----+----
--      T  | T  F  N          T  | T  T  T          T  | F
--      F  | F  F  F          F  | T  F  N          F  | T
--      N  | N  F  N          N  | T  N  N          N  | N
--
--   A row passes WHERE only when the full predicate evaluates to TRUE.
--   FALSE and NULL both exclude the row.
--
--   Precedence (highest to lowest):
--     1. Unary minus, BIT-AND, BIT-OR (rarely used in WHERE)
--     2. Comparison (=, <>, <, >, IS, IN, LIKE, BETWEEN)
--     3. NOT
--     4. AND     (in MySQL)
--     5. XOR
--     6. OR
--
--   So `a OR b AND c` is parsed as `a OR (b AND c)`. ALWAYS use parentheses
--   to make intent explicit — even when they are technically redundant.
-- ============================================================================

USE ecom;

-- ----------------------------------------------------------------------------
-- 1. AND — both predicates must be TRUE
-- ----------------------------------------------------------------------------
SELECT first_name, last_name, country
FROM customers
WHERE country = 'United States'
  AND is_active = 1;

-- ----------------------------------------------------------------------------
-- 2. OR — at least one predicate TRUE
-- ----------------------------------------------------------------------------
SELECT first_name, last_name, country
FROM customers
WHERE country = 'United States'
   OR country = 'United Kingdom';

-- IN is usually cleaner than a chain of OR:
SELECT first_name, last_name, country
FROM customers
WHERE country IN ('United States', 'United Kingdom', 'Canada');

-- ----------------------------------------------------------------------------
-- 3. NOT — negation (binds tighter than AND)
-- ----------------------------------------------------------------------------
SELECT first_name, last_name, country
FROM customers
WHERE NOT country = 'United States';

-- Equivalent with <>
SELECT first_name, last_name, country
FROM customers
WHERE country <> 'United States';

-- NOT with IN
SELECT first_name, last_name, country
FROM customers
WHERE country NOT IN ('United States', 'Canada');

-- ----------------------------------------------------------------------------
-- 4. AND + OR — precedence trap
-- ----------------------------------------------------------------------------
-- INTENT: customers in US or UK who are also active.
-- WRONG (without parens): parsed as country='US' OR (country='UK' AND is_active=1)
SELECT first_name, last_name, country, is_active
FROM customers
WHERE country = 'United States'
   OR country = 'United Kingdom'
  AND is_active = 1;       -- US customers come back regardless of is_active

-- CORRECT (with parens):
SELECT first_name, last_name, country, is_active
FROM customers
WHERE (country = 'United States' OR country = 'United Kingdom')
  AND is_active = 1;

-- ----------------------------------------------------------------------------
-- 5. Three-valued logic in action
-- ----------------------------------------------------------------------------
-- customer #4 has metadata = NULL (let's check)
SELECT first_name, metadata FROM customers WHERE id = 4;

-- This predicate returns NULL for the NULL metadata row, so the row is
-- EXCLUDED from the result.
SELECT first_name, metadata
FROM customers
WHERE metadata = '{"tags":["vip"],"loyalty_points":1250}';
-- Returns only Alice (id 1), not customers with NULL metadata.

-- ----------------------------------------------------------------------------
-- 6. De Morgan's laws in SQL
-- ----------------------------------------------------------------------------
-- NOT (A AND B)  ≡  (NOT A) OR (NOT B)
-- NOT (A OR B)   ≡  (NOT A) AND (NOT B)
--
-- Practical: "customers NOT in US AND NOT active" is identical to "NOT
-- (country=US OR is_active=1)":
SELECT first_name, country, is_active
FROM customers
WHERE NOT (country = 'United States' OR is_active = 1);

SELECT first_name, country, is_active
FROM customers
WHERE country <> 'United States' AND is_active = 0;
-- Same result set — pick whichever is more readable.

-- ----------------------------------------------------------------------------
-- 7. XOR — exactly one TRUE
-- ----------------------------------------------------------------------------
-- Rarely used. Useful for "either A or B but not both".
SELECT first_name, last_name, is_active
FROM customers
WHERE (country = 'United States') XOR (is_active = 1);
-- Returns US customers who are inactive, plus non-US customers who are active.

-- ----------------------------------------------------------------------------
-- 8. Combining AND / OR / NOT with NULL handling
-- ----------------------------------------------------------------------------
-- Find customers who are active and whose metadata is NOT NULL.
SELECT first_name, last_name
FROM customers
WHERE is_active = 1
  AND metadata IS NOT NULL;

-- Find customers who are inactive OR whose metadata is NULL.
SELECT first_name, last_name
FROM customers
WHERE is_active = 0
   OR metadata IS NULL;

-- ----------------------------------------------------------------------------
-- 9. Boolean short-circuit (not guaranteed in SQL)
-- ----------------------------------------------------------------------------
-- Unlike C/Python, SQL does NOT guarantee short-circuit evaluation. A
-- predicate like `WHERE col IS NOT NULL AND FUNC(col) = 5` MAY evaluate
-- FUNC(col) even when col IS NULL. If FUNC throws on NULL, the query may
-- error. Always test for NULL FIRST using a CASE in the SELECT list or by
-- restructuring the predicate.
--
-- Example of safe pattern:
SELECT first_name, last_name
FROM customers
WHERE metadata IS NOT NULL
  AND JSON_VALID(metadata);

-- ----------------------------------------------------------------------------
-- 10. Realistic multi-condition WHERE
-- ----------------------------------------------------------------------------
SELECT
    c.first_name,
    c.last_name,
    c.country,
    c.is_active
FROM customers c
WHERE c.is_active = 1
  AND (c.country = 'United States' OR c.country = 'United Kingdom')
  AND c.email LIKE '%.com'
  AND NOT c.id IN (1, 2, 3)        -- exclude the first three
ORDER BY c.last_name;

-- ----------------------------------------------------------------------------
-- 11. EXERCISES
-- ----------------------------------------------------------------------------
-- EASY
-- E1.  Find all active customers in Japan.
-- E2.  Find all products priced below 100 OR with stock_qty below 10.
--
-- MEDIUM
-- E3.  Find all orders with status 'paid' AND total > 1000, OR status
--      'shipped' AND total > 500. Use parentheses to make the intent clear.
-- E4.  Find customers who are NOT in ('United States', 'Canada', 'Mexico').
--      Use NOT IN.
--
-- HARD
-- E5.  Find all products in category 8 (Laptops) OR 9 (Components) whose
--      gross margin (price - cost) exceeds $200. Sort by margin DESC.
--
-- EXPERT
-- E6.  Write the negation of:
--        WHERE (country = 'US' AND is_active = 1)
--           OR (country = 'UK' AND is_active = 0)
--      Use De Morgan's law to produce an equivalent WHERE clause that uses
--      only AND with <> (no OR, no NOT). Verify both forms return the same
--      result set.
-- ============================================================================

-- End of file 06_and_or_not.sql
