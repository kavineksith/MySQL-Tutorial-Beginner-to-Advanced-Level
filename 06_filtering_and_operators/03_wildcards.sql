-- ============================================================================
-- 03_wildcards.sql — SQL Wildcards: % _ [charlist] ^
-- ============================================================================
-- SKILL LEVEL : Beginner
-- TOPICS      : % and _ wildcards (review), SQL Server-style [charlist]
--               and ^, MySQL equivalents via REGEXP, character classes.
-- ----------------------------------------------------------------------------
-- TEXTBOOK DEPTH
--   Some references list five "wildcard" symbols:
--     %              zero or more chars           (LIKE)
--     _              exactly one char             (LIKE)
--     [charlist]     any single char in set       (SQL Server only — NOT MySQL)
--     [^charlist]    any single char NOT in set   (SQL Server only — NOT MySQL)
--     [!charlist]    same as [^charlist]          (MS Access only — NOT MySQL)
--
--   IMPORTANT: MySQL does NOT support the [charlist] syntax in LIKE. You
--   must use REGEXP for character-class matching:
--     [a-c]    any of a, b, c
--     [^a-c]   any char except a, b, c
--     [0-9]    any digit
--     [:alpha:] POSIX class — letters
--     [:digit:] POSIX class — digits
-- ============================================================================

USE ecom;

-- ----------------------------------------------------------------------------
-- 1. Review of % and _
-- ----------------------------------------------------------------------------
SELECT first_name FROM customers WHERE first_name LIKE 'A%';   -- starts A
SELECT first_name FROM customers WHERE first_name LIKE '_v%';  -- 2nd char is v

-- ----------------------------------------------------------------------------
-- 2. SQL Server's [charlist] vs MySQL's REGEXP equivalent
-- ----------------------------------------------------------------------------
-- SQL Server: WHERE last_name LIKE '[A-C]%'
--   Returns rows whose last_name starts with A, B, or C.
-- MySQL equivalent using REGEXP:
SELECT first_name, last_name
FROM customers
WHERE last_name REGEXP '^[A-C]';

-- ----------------------------------------------------------------------------
-- 3. Negated character class [^...]
-- ----------------------------------------------------------------------------
-- SQL Server: WHERE last_name LIKE '[^A-C]%'
--   Returns rows whose last_name does NOT start with A, B, C.
-- MySQL equivalent using REGEXP NOT:
SELECT first_name, last_name
FROM customers
WHERE last_name NOT REGEXP '^[A-C]';

-- ----------------------------------------------------------------------------
-- 4. Character classes [0-9], [a-z]
-- ----------------------------------------------------------------------------
-- Find products whose SKU contains a digit.
SELECT sku, name
FROM products
WHERE sku REGEXP '[0-9]';

-- Find SKUs ending in two digits.
SELECT sku, name
FROM products
WHERE sku REGEXP '[0-9]{2}$';

-- ----------------------------------------------------------------------------
-- 5. POSIX character classes inside REGEXP
-- ----------------------------------------------------------------------------
-- [:alpha:]   letters          [:digit:]   digits
-- [:upper:]   uppercase        [:lower:]   lowercase
-- [:alnum:]   letters+digits   [:space:]   whitespace
-- [:punct:]   punctuation

-- Find emails that contain a digit in the local part.
SELECT first_name, email
FROM customers
WHERE SUBSTRING_INDEX(email, '@', 1) REGEXP '[[:digit:]]';

-- Find customers whose first name is all uppercase letters (data quality check).
SELECT first_name
FROM customers
WHERE first_name REGEXP '^[[:upper:]]+$';

-- ----------------------------------------------------------------------------
-- 6. Combining wildcards and charlists
-- ----------------------------------------------------------------------------
-- Names starting with A or B, followed by any chars.
SELECT first_name
FROM customers
WHERE first_name REGEXP '^[AB]';

-- Names ending in 'n' or 'r'.
SELECT first_name
FROM customers
WHERE first_name REGEXP '[nr]$';

-- ----------------------------------------------------------------------------
-- 7. Wildcard table summary
-- ----------------------------------------------------------------------------
-- Run this to see the comparison side-by-side.
SELECT 'Percent %' AS wildcard,
       'Zero or more characters' AS meaning,
       'Standard SQL' AS support
UNION ALL SELECT 'Underscore _', 'Exactly one character', 'Standard SQL'
UNION ALL SELECT '[charlist]', 'Any single char in set', 'SQL Server / MS Access only'
UNION ALL SELECT '[^charlist]', 'Any single char NOT in set', 'SQL Server / MS Access only'
UNION ALL SELECT '[!charlist]', 'Same as [^charlist]', 'MS Access only'
UNION ALL SELECT 'REGEXP / RLIKE', 'Full regex support', 'MySQL extension';

-- ----------------------------------------------------------------------------
-- 8. EXERCISES
-- ----------------------------------------------------------------------------
-- EASY
-- E1.  Find all customers whose last name starts with any letter from D to F
--      (inclusive). Use REGEXP.
-- E2.  Find all products whose SKU contains a digit.
--
-- MEDIUM
-- E3.  Find all customers whose first name is exactly 4 letters long and
--      starts with a vowel. (Hint: REGEXP '^[AEIOU][a-zA-Z]{3}$'.)
-- E4.  Find all customers whose phone contains a digit other than 0 or 1.
--
-- HARD
-- E5.  Find SKUs whose middle character (position 4, between two dashes) is
--      a digit. Examples: 'LAP-001' (middle of the suffix is 0). Write the
--      REGEXP to match SKU pattern of 3 chars - 3 chars where the suffix
--      starts with a digit.
--
-- EXPERT
-- E6.  Without using REGEXP, write a LIKE-based query that finds customers
--      whose last name starts with A, B, or C. (Hint: chain OR clauses or
--      use a temporary charlist table.)
-- ============================================================================

-- End of file 03_wildcards.sql
