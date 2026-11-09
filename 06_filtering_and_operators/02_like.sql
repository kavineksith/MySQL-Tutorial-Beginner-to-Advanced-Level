-- ============================================================================
-- 02_like.sql — LIKE: Pattern Matching in Strings
-- ============================================================================
-- SKILL LEVEL : Beginner
-- TOPICS      : LIKE, % wildcard, _ wildcard, NOT LIKE, case sensitivity,
--               LIKE vs REGEXP, performance implications, escaping.
-- ----------------------------------------------------------------------------
-- TEXTBOOK DEPTH
--   LIKE performs simple pattern matching using two wildcards:
--     %  matches zero or more characters (any string)
--     _  matches exactly one character
--
--   Examples:
--     'a%'      starts with 'a'
--     '%a'      ends with 'a'
--     '%a%'     contains 'a'
--     'a_c'     'a', any single char, 'c'  → abc, aXc, a c, etc.
--     '_%'      at least one character (excludes empty string)
--     'cat'     literal (no wildcards)
--
--   Case sensitivity depends on the column collation. The default
--   utf8mb4_0900_ai_ci is case-insensitive ('_ci' suffix), so LIKE 'alice'
--   matches 'Alice'.
--
--   Performance: a leading wildcard `'%alice'` CANNOT use a B-tree index
--   (the index is sorted left-to-right). A trailing wildcard `'alice%'`
--   CAN use a range scan. This is why prefix search is fast and "contains"
--   search is slow on large tables. For full-text search use MATCH AGAINST
--   (see 09_advanced_mysql/09_fulltext_search.sql).
-- ============================================================================

USE ecom;

-- ----------------------------------------------------------------------------
-- 1. % wildcard — zero or more characters
-- ----------------------------------------------------------------------------
SELECT first_name, last_name, email
FROM customers
WHERE email LIKE 'a%';        -- starts with 'a'

SELECT first_name, last_name, email
FROM customers
WHERE email LIKE '%@example.com';     -- ends with this domain

SELECT first_name, last_name, email
FROM customers
WHERE email LIKE '%smith%';   -- contains 'smith' anywhere

-- ----------------------------------------------------------------------------
-- 2. _ wildcard — exactly one character
-- ----------------------------------------------------------------------------
-- Find customers whose phone has the pattern 555-01XX (any 2 chars at end).
SELECT first_name, phone
FROM customers
WHERE phone LIKE '555-01__';   -- two underscores match any 2 chars

-- Find SKUs with format XXX-001 (3 chars, dash, exactly 3 chars).
SELECT sku, name
FROM products
WHERE sku LIKE '___-___';

-- ----------------------------------------------------------------------------
-- 3. NOT LIKE — exclude patterns
-- ----------------------------------------------------------------------------
SELECT first_name, email
FROM customers
WHERE email NOT LIKE '%.com';

-- ----------------------------------------------------------------------------
-- 4. Case sensitivity via COLLATE
-- ----------------------------------------------------------------------------
-- Default collation is case-insensitive:
SELECT 'Johnson' LIKE 'JOHNSON' AS case_insensitive_match;
-- Returns 1 (TRUE).

-- Force case-sensitive matching:
SELECT first_name, last_name
FROM customers
WHERE last_name COLLATE utf8mb4_0900_as_cs LIKE 'J%';
-- `_as_cs` = accent-sensitive, case-sensitive.

-- ----------------------------------------------------------------------------
-- 5. Escaping wildcards
-- ----------------------------------------------------------------------------
-- What if your pattern contains a literal % or _? Use ESCAPE.
CREATE TEMPORARY TABLE tmp_codes (code VARCHAR(20));
INSERT INTO tmp_codes VALUES ('discount_10'), ('discount_50'), ('discount%10');

-- Find codes that literally contain an underscore:
SELECT code FROM tmp_codes WHERE code LIKE '%\_%';   -- backslash escapes _ in MySQL
-- Returns: discount_10, discount_50

-- Find codes that literally contain a percent sign:
SELECT code FROM tmp_codes WHERE code LIKE '%\%%';
-- Returns: discount%10

-- Use ESCAPE to choose a different escape char (cleaner when text has many backslashes):
SELECT code FROM tmp_codes WHERE code LIKE '%|_%' ESCAPE '|';

DROP TEMPORARY TABLE tmp_codes;

-- ----------------------------------------------------------------------------
-- 6. LIKE vs = (no wildcards in pattern)
-- ----------------------------------------------------------------------------
SELECT first_name FROM customers WHERE last_name LIKE 'Johnson';
-- Equivalent to: WHERE last_name = 'Johnson';
-- Use = when there are no wildcards — clearer intent.

-- ----------------------------------------------------------------------------
-- 7. LIKE on numeric columns (implicit conversion)
-- ----------------------------------------------------------------------------
SELECT sku, name, price
FROM products
WHERE price LIKE '12%';
-- Implicit conversion: price → string. Matches 12, 1299, 129.99 etc.

-- ----------------------------------------------------------------------------
-- 8. LIKE vs REGEXP (RLIKE)
-- ----------------------------------------------------------------------------
-- LIKE handles only % and _. For complex patterns use REGEXP:
SELECT first_name, email
FROM customers
WHERE email REGEXP '^[a-z]+\\.[a-z]+@example\\.com$';
-- Matches first.last@example.com pattern.

-- NOT REGEXP
SELECT first_name, email
FROM customers
WHERE email NOT REGEXP '@example\\.com$';

-- ----------------------------------------------------------------------------
-- 9. Common mistakes
-- ----------------------------------------------------------------------------
-- MISTAKE 1: Forgetting that % matches ZERO chars.
--   'a%' matches 'a' alone (length 1).
-- MISTAKE 2: Using `*` instead of `%` (regex vs LIKE confusion).
--   'alice*' is literal; only '*' wildcard is regex.

-- ----------------------------------------------------------------------------
-- 10. EXERCISES
-- ----------------------------------------------------------------------------
-- EASY
-- E1.  Find all customers whose email starts with 'a'.
-- E2.  Find all products whose name starts with 'The '.
--
-- MEDIUM
-- E3.  Find all SKUs in the format 'XX-NNN' (2 chars, dash, 3 chars).
-- E4.  Find all customers whose phone matches '555-01XX' where XX are any
--      two digits.
--
-- HARD
-- E5.  Find all customers whose email matches the pattern
--      `<first>.<last>@example.com` (case-insensitive on the local part
--      would be ideal, but we'll accept simple prefix match). Hint:
--      LOWER(first_name) || '.' || ...
--
-- EXPERT
-- E6.  Write a query that returns all products whose name contains the word
--      'pro' (case-insensitive). Then explain why a query using LIKE
--      '%pro%' might be slow on a million-row products table, and what the
--      faster alternative is (see 09_advanced_mysql/09_fulltext_search.sql).
-- ============================================================================

-- End of file 02_like.sql
