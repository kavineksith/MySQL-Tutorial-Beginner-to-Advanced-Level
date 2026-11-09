-- ============================================================================
-- 07_null_functions.sql — NULL-Handling Functions
-- ============================================================================
-- SKILL LEVEL : Beginner
-- TOPICS      : IFNULL, COALESCE, NULLIF, ISNULL, IF, NVL (compat), NULL
--               propagation rules, choosing the right function.
-- ----------------------------------------------------------------------------
-- TEXTBOOK DEPTH
--   MySQL provides several functions for handling NULLs. They look similar
--   but behave differently. Pick the right one for the job.
--
--   Function reference:
--     IFNULL(expr1, expr2)        Returns expr1 if not NULL, else expr2.
--                                 MySQL-specific, max 2 args.
--     COALESCE(expr1, expr2, ...) Returns first non-NULL expr. ANSI standard.
--     NULLIF(expr1, expr2)        Returns NULL if expr1 = expr2, else expr1.
--     ISNULL(expr)                Returns 1 if NULL, 0 otherwise.
--     IF(expr, true_val, false_val) Returns true_val if expr is TRUE (non-zero,
--                                    non-NULL), else false_val.
--     NVL(expr, replacement)      Oracle function — NOT in MySQL; use IFNULL.
--
--   Propagation rules:
--     * Any arithmetic with NULL → NULL.  (NULL + 5 = NULL)
--     * Any string concat with NULL → NULL (CONCAT).
--     * CONCAT_WS skips NULL instead of propagating.
--     * SUM/AVG/MIN/MAX/COUNT(col) ignore NULLs.
--     * COUNT(*) counts rows including NULL ones.
-- ============================================================================

USE ecom;

-- ----------------------------------------------------------------------------
-- 1. IFNULL — MySQL's two-arg coalesce
-- ----------------------------------------------------------------------------
SELECT
    first_name,
    last_name,
    IFNULL(phone, '— no phone —') AS phone_label
FROM customers
LIMIT 6;

-- ----------------------------------------------------------------------------
-- 2. COALESCE — ANSI standard, accepts N args
-- ----------------------------------------------------------------------------
-- Returns the first non-NULL value in the chain. Use COALESCE instead of
-- IFNULL for portability and richer semantics.
SELECT
    first_name,
    COALESCE(phone, 'no phone', 'fallback') AS phone_label
FROM customers
LIMIT 6;

-- Multi-column COALESCE — pick the first available contact method.
SELECT
    first_name,
    COALESCE(phone, email) AS preferred_contact
FROM customers
LIMIT 6;

-- COALESCE on JSON extract (with default 0 if missing).
SELECT
    first_name,
    COALESCE(
        JSON_UNQUOTE(JSON_EXTRACT(metadata, '$.loyalty_points')),
        0
    ) AS loyalty_points
FROM customers
LIMIT 6;

-- ----------------------------------------------------------------------------
-- 3. NULLIF — convert a sentinel value to NULL
-- ----------------------------------------------------------------------------
-- NULLIF(a, b) returns NULL when a = b, else returns a.
-- Classic use: prevent division by zero.
SELECT
    sku,
    price,
    cost,
    price / NULLIF(cost, 0) AS markup_ratio
FROM products
LIMIT 5;

-- Another use: turn the sentinel 'N/A' into NULL for clean aggregations.
CREATE TEMPORARY TABLE tmp_status (status VARCHAR(20));
INSERT INTO tmp_status VALUES ('shipped'), ('N/A'), ('delivered'), ('N/A');

SELECT
    status,
    NULLIF(status, 'N/A') AS clean_status
FROM tmp_status;

DROP TEMPORARY TABLE tmp_status;

-- ----------------------------------------------------------------------------
-- 4. ISNULL — returns 1 or 0 (a predicate, not a coalescer)
-- ----------------------------------------------------------------------------
SELECT
    first_name,
    ISNULL(phone) AS phone_is_null,
    IF(ISNULL(phone), 'missing', 'present') AS phone_label
FROM customers
LIMIT 6;

-- Common mistake: confusing ISNULL() with IS NULL.
-- ISNULL(phone)   → returns 1 or 0 (function)
-- phone IS NULL   → returns TRUE or FALSE (operator)
-- Both work in WHERE but IS NULL is the standard idiom:
SELECT first_name, phone FROM customers WHERE phone IS NULL;       -- preferred
SELECT first_name, phone FROM customers WHERE ISNULL(phone) = 1;   -- works

-- ----------------------------------------------------------------------------
-- 5. IF — MySQL's ternary
-- ----------------------------------------------------------------------------
SELECT
    first_name,
    IF(is_active = 1, 'active', 'inactive') AS status_label,
    IF(metadata IS NULL, 'no metadata', 'has metadata') AS meta_label
FROM customers
LIMIT 6;

-- IF is equivalent to a simple CASE:
SELECT
    first_name,
    CASE WHEN is_active = 1 THEN 'active' ELSE 'inactive' END AS status_label
FROM customers
LIMIT 6;
-- Prefer CASE for portability; IF is fine in MySQL-only code.

-- ----------------------------------------------------------------------------
-- 6. COALESCE with aggregates — avoid NULL in aggregates
-- ----------------------------------------------------------------------------
-- If you want 0 instead of NULL when a customer has no orders:
SELECT
    c.first_name,
    COALESCE(SUM(o.total), 0) AS total_spent
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
GROUP BY c.id, c.first_name
ORDER BY total_spent DESC
LIMIT 6;

-- ----------------------------------------------------------------------------
-- 7. NULL propagation in arithmetic — wrap with COALESCE
-- ----------------------------------------------------------------------------
SELECT
    sku,
    price,
    weight_kg,
    price * weight_kg AS inventory_weight_value,
    price * COALESCE(weight_kg, 0) AS safe_inventory_weight_value
FROM products
LIMIT 5;

-- ----------------------------------------------------------------------------
-- 8. CONCAT_WS — concat with separator, skips NULLs
-- ----------------------------------------------------------------------------
SELECT
    CONCAT_WS(' | ', first_name, last_name, phone, city) AS label
FROM customers
LIMIT 6;

-- Compare with plain CONCAT (NULL-propagating):
SELECT
    CONCAT(first_name, ' | ', last_name, ' | ', phone, ' | ', city) AS label
FROM customers
LIMIT 6;
-- Rows with NULL phone or NULL city produce NULL label.

-- ----------------------------------------------------------------------------
-- 9. Comparison table for quick reference
-- ----------------------------------------------------------------------------
SELECT
    'IFNULL(a, b)'              AS fn,
    'If a not NULL → a, else b' AS meaning,
    'MySQL only, 2 args'        AS notes
UNION ALL SELECT
    'COALESCE(a, b, ...)', 'First non-NULL', 'ANSI standard, N args'
UNION ALL SELECT
    'NULLIF(a, b)', 'NULL if a=b else a', 'Prevents div/0'
UNION ALL SELECT
    'ISNULL(a)', '1 if NULL else 0', 'Predicate'
UNION ALL SELECT
    'IF(cond, x, y)', 'x if cond else y', 'MySQL only — use CASE for portability'
UNION ALL SELECT
    'CONCAT_WS(sep, ...)', 'Join with sep, skip NULLs', 'Avoids NULL propagation';

-- ----------------------------------------------------------------------------
-- 10. EXERCISES
-- ----------------------------------------------------------------------------
-- EASY
-- E1.  Return the customer list with phone shown, or '— none —' when phone
--      is NULL.
-- E2.  Compute the loyalty_points from `metadata` JSON for each customer,
--      defaulting to 0 when missing.
--
-- MEDIUM
-- E3.  Compute the markup ratio (price / cost) for every product. Use NULLIF
--      to avoid division-by-zero errors when cost is 0.
-- E4.  Build a single-column `contact_card` that combines first_name, last_name,
--      phone, and city with ' | ' separator. NULL fields should be SKIPPED
--      (use CONCAT_WS).
--
-- HARD
-- E5.  For every customer, return their total spend (SUM of order totals).
--      If they have no orders, return 0 (not NULL). Use COALESCE.
--
-- EXPERT
-- E6.  Write a query that flags each customer as 'vip', 'active', or 'new'
--      using these rules:
--        vip    — loyalty_points >= 1000 (from metadata JSON, default 0)
--        active — has placed at least one order
--        new    — loyalty_points < 100 (or NULL) AND no orders
--      Otherwise 'standard'. Use IF, COALESCE, JSON_EXTRACT, and EXISTS.
-- ============================================================================

-- End of file 07_null_functions.sql
