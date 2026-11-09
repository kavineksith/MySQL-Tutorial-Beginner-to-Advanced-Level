-- ============================================================================
-- 08_operators.sql — SQL Operators Reference
-- ============================================================================
-- SKILL LEVEL : Beginner
-- TOPICS      : Comparison operators, arithmetic operators, logical
--               operators, bitwise operators, NULL-safe <=>, BETWEEN, IN,
--               LIKE, IS, REGEXP, ALL/ANY/EXISTS.
-- ----------------------------------------------------------------------------
-- TEXTBOOK DEPTH
--   MySQL has 6 operator families:
--
--   COMPARISON  =  <=>  <>  !=  >  >=  <  <=  IS [NOT] NULL
--                 BETWEEN ... AND ...    IN (list)    LIKE    REGEXP/RLIKE
--
--   LOGICAL     AND  &&   OR  ||   NOT  !   XOR
--                 (Note: || and && are OR/AND by default in MySQL; they
--                  become concat/and only under PIPES_AS_CONCAT sql_mode.)
--
--   ARITHMETIC  +  -  *  /  DIV  %  MOD
--
--   BITWISE     &  |  ^  <<  >>  ~   (rarely used in app queries)
--
--   ASSIGNMENT  :=   (SET @var := value)
--
--   SPECIAL     BINARY   CAST   COLLATE   EXISTS   ALL / ANY / SOME
--
--   Precedence (highest first, MySQL 8 docs):
--     !
--     ~ (unary bit NOT)
--     - (unary minus)
--     ^
--     *, /, DIV, %, MOD
--     -, +
--     <<, >>
--     &
--     |
--     =, <=>, >=, >, <=, <, <>, !=, IS, LIKE, REGEXP, IN, BETWEEN, CASE,
--        WHEN, THEN, ELSE
--     NOT
--     AND, &&
--     XOR
--     OR, ||
--     = (assignment), :=
-- ============================================================================

USE ecom;

-- ----------------------------------------------------------------------------
-- 1. Comparison operators
-- ----------------------------------------------------------------------------
SELECT 1 = 1   AS eq_true,   1 = 2 AS eq_false,  NULL = NULL AS eq_null;
SELECT 1 <> 2  AS neq_true,  1 != 2 AS neq_alt,  NULL <> 1 AS neq_null;
SELECT 5 > 3   AS gt, 5 >= 5 AS ge, 5 < 9 AS lt, 5 <= 5 AS le;
SELECT 1 <=> 1 AS nse_eq,  NULL <=> NULL AS nse_nulls_equal, 1 <=> NULL AS nse_null_unequal;

-- IS NULL / IS NOT NULL
SELECT first_name, phone FROM customers WHERE phone IS NULL;
SELECT first_name, phone FROM customers WHERE phone IS NOT NULL;

-- ----------------------------------------------------------------------------
-- 2. Arithmetic operators
-- ----------------------------------------------------------------------------
SELECT
    7 + 3 AS add,
    7 - 3 AS sub,
    7 * 3 AS mul,
    7 / 3 AS div_real,     -- 2.3333 (floating-point)
    7 DIV 3 AS int_div,    -- 2 (integer division)
    7 % 3 AS modulo_pct,
    7 MOD 3 AS modulo_mod,  -- synonym for %
    -7 AS negation;

-- Practical example — discount math.
SELECT
    sku,
    name,
    price,
    ROUND(price * 0.90, 2) AS ten_pct_off,
    ROUND(price - (price * 0.10), 2) AS alt_form
FROM products
LIMIT 3;

-- ----------------------------------------------------------------------------
-- 3. Logical operators
-- ----------------------------------------------------------------------------
SELECT
    (1 = 1) AND (2 = 2) AS and_true,
    (1 = 1) AND (2 = 3) AS and_false,
    (1 = 1) OR  (2 = 3) AS or_true,
    NOT (1 = 2)         AS not_true,
    (1 = 1) XOR (2 = 2) AS xor_false,  -- both true → false
    (1 = 1) XOR (2 = 3) AS xor_true;   -- one true → true

-- Synonymous: && || !  (avoid in portable code; ambiguity with concat in ANSI SQL)
SELECT (1 = 1) && (2 = 2) AS and2, (1 = 1) || (2 = 3) AS or2;

-- ----------------------------------------------------------------------------
-- 4. Bitwise operators (rarely used in app queries)
-- ----------------------------------------------------------------------------
SELECT
    5 & 3 AS bitand,    -- 5=101, 3=011 → 001 = 1
    5 | 3 AS bitor,     -- → 111 = 7
    5 ^ 3 AS bitxor,    -- → 110 = 6
    1 << 4 AS shiftl,   -- 1 << 4 = 16
    256 >> 4 AS shiftr, -- 256 >> 4 = 16
    ~0 AS bitnot;       -- all bits set

-- Common use: bit flags
-- Suppose user_permissions is a bitfield:
--   1=read, 2=write, 4=delete, 8=admin
-- To check if user has delete permission:
SELECT (5 & 4) > 0 AS has_delete_perm;   -- 5=101 (read+delete) → has delete

-- ----------------------------------------------------------------------------
-- 5. BETWEEN, IN, LIKE, REGEXP, IS (already covered in detail)
-- ----------------------------------------------------------------------------
SELECT 5 BETWEEN 1 AND 10 AS in_range;
SELECT 5 IN (1, 3, 5, 7) AS in_list;
SELECT 'hello' LIKE 'h%' AS like_match;
SELECT 'hello' REGEXP '^h[a-z]+$' AS regex_match;

-- ----------------------------------------------------------------------------
-- 6. EXISTS, ANY, ALL — subquery predicates (preview)
-- ----------------------------------------------------------------------------
SELECT first_name, last_name
FROM customers c
WHERE EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.id);

-- ANY and ALL with comparison
SELECT name, price
FROM products
WHERE price > ALL (SELECT price FROM products WHERE category_id = 9);
-- Price greater than EVERY product in category 9.

SELECT name, price
FROM products
WHERE price > ANY (SELECT price FROM products WHERE category_id = 9);
-- Price greater than AT LEAST ONE product in category 9.

-- ----------------------------------------------------------------------------
-- 7. BINARY — force binary string comparison (case-sensitive)
-- ----------------------------------------------------------------------------
SELECT 'abc' = 'ABC' AS ci_equal;             -- 1 (default collation)
SELECT BINARY 'abc' = 'ABC' AS cs_equal;       -- 0
SELECT 'abc' = BINARY 'ABC' AS cs_equal2;      -- 0

-- ----------------------------------------------------------------------------
-- 8. CAST and CONVERT — change type explicitly
-- ----------------------------------------------------------------------------
SELECT
    CAST('2024-01-15' AS DATE)              AS as_date,
    CAST('10.5' AS DECIMAL(8,2))            AS as_decimal,
    CAST(42 AS CHAR)                        AS as_char,
    CAST('2024-01-15 10:23:00' AS DATETIME) AS as_datetime,
    CONVERT('abc', BINARY)                  AS as_binary;

-- ----------------------------------------------------------------------------
-- 9. Operator precedence demo — use parentheses
-- ----------------------------------------------------------------------------
-- Without parens: NOT binds tighter than AND binds tighter than OR.
SELECT
    (1 = 1 OR 2 = 2) AND 3 = 3 AS with_parens,
    1 = 1 OR 2 = 2 AND 3 = 4   AS without_parens;
-- without_parens parses as: 1=1 OR (2=2 AND 3=4) = TRUE OR FALSE = TRUE

-- Arithmetic precedence:
SELECT 2 + 3 * 4 AS without_parens,   -- 14 (multiplication first)
       (2 + 3) * 4 AS with_parens;    -- 20

-- ----------------------------------------------------------------------------
-- 10. EXERCISES
-- ----------------------------------------------------------------------------
-- EASY
-- E1.  Find all customers whose id is in (1, 3, 5, 7).
-- E2.  Find all products whose price is between 100 and 1000.
--
-- MEDIUM
-- E3.  Find products priced higher than EVERY product in category 12
--      (Furniture). Use ALL.
-- E4.  Find products priced higher than AT LEAST ONE product in category 12.
--      Use ANY.
--
-- HARD
-- E5.  Write a query that returns TRUE for each customer who has placed an
--      order with total > 1000, FALSE otherwise. Use EXISTS and IF.
--
-- EXPERT
-- E6.  Without using parentheses, predict the result of:
--        SELECT 1 = 1 OR 2 = 2 AND 3 = 4;
--      Write the equivalent fully-parenthesized version.
-- ============================================================================

-- End of file 08_operators.sql
