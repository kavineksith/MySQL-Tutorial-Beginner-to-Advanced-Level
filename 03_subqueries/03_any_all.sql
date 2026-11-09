-- ============================================================================
-- 03_any_all.sql — ANY / ALL / SOME Operators
-- ============================================================================
-- SKILL LEVEL : Intermediate
-- TOPICS      : ANY, ALL, SOME (alias for ANY), comparison operators with
--               ANY/ALL, equivalent formulations using MIN/MAX.
-- ----------------------------------------------------------------------------
-- TEXTBOOK DEPTH
--   ANY and ALL are subquery operators used with a comparison operator.
--
--     expr > ANY (subquery)   → TRUE if expr > at least one value
--     expr > ALL (subquery)   → TRUE if expr > every value
--     expr = ANY (subquery)   → TRUE if expr equals at least one value
--                               (equivalent to IN)
--     expr <> ANY (subquery)  → almost always TRUE (unless subquery empty)
--     expr <> ALL (subquery)  → TRUE if expr matches NO value
--                               (equivalent to NOT IN, with same NULL trap)
--
--   SOME is a synonym for ANY.
--
--   Equivalent rewritings (when subquery returns no NULLs):
--     > ANY  ≡  > (SELECT MIN(...) FROM ...)
--     > ALL  ≡  > (SELECT MAX(...) FROM ...)
--     = ANY  ≡  IN
--     <> ALL ≡  NOT IN  (with the same NULL trap!)
--
--   In practice ANY/ALL are rarely used — IN/NOT EXISTS are clearer.
-- ============================================================================

USE ecom;

-- ----------------------------------------------------------------------------
-- 1. > ANY — greater than at least one
-- ----------------------------------------------------------------------------
-- Products priced higher than at least one product in category 12 (Furniture).
SELECT sku, name, price
FROM products
WHERE price > ANY (
    SELECT price FROM products WHERE category_id = 12
)
ORDER BY price DESC;

-- Equivalent using MIN:
SELECT sku, name, price
FROM products
WHERE price > (SELECT MIN(price) FROM products WHERE category_id = 12)
ORDER BY price DESC;

-- ----------------------------------------------------------------------------
-- 2. > ALL — greater than every
-- ----------------------------------------------------------------------------
-- Products priced higher than every product in category 12.
SELECT sku, name, price
FROM products
WHERE price > ALL (
    SELECT price FROM products WHERE category_id = 12
)
ORDER BY price DESC;

-- Equivalent using MAX:
SELECT sku, name, price
FROM products
WHERE price > (SELECT MAX(price) FROM products WHERE category_id = 12)
ORDER BY price DESC;

-- ----------------------------------------------------------------------------
-- 3. = ANY — same as IN
-- ----------------------------------------------------------------------------
SELECT first_name, country
FROM customers
WHERE country = ANY ('United States', 'United Kingdom');  -- not valid syntax
-- The correct syntax requires a subquery:
SELECT first_name, country
FROM customers
WHERE id = ANY (SELECT customer_id FROM orders WHERE status = 'delivered');

-- Cleaner with IN:
SELECT first_name, country
FROM customers
WHERE id IN (SELECT customer_id FROM orders WHERE status = 'delivered');

-- ----------------------------------------------------------------------------
-- 4. <> ALL — same as NOT IN (NULL trap applies!)
-- ----------------------------------------------------------------------------
-- Customers who have NOT placed any delivered order.
SELECT first_name, last_name
FROM customers
WHERE id <> ALL (SELECT customer_id FROM orders WHERE status = 'delivered');

-- Equivalent (safer) with NOT EXISTS:
SELECT first_name, last_name
FROM customers c
WHERE NOT EXISTS (
    SELECT 1 FROM orders o WHERE o.customer_id = c.id AND o.status = 'delivered'
);

-- ----------------------------------------------------------------------------
-- 5. < ALL — less than every
-- ----------------------------------------------------------------------------
-- Products cheaper than every product in category 5 (Computers).
SELECT sku, name, price
FROM products
WHERE price < ALL (
    SELECT price FROM products WHERE category_id = 5
)
ORDER BY price;

-- Equivalent using MIN:
SELECT sku, name, price
FROM products
WHERE price < (SELECT MIN(price) FROM products WHERE category_id = 5)
ORDER BY price;

-- ----------------------------------------------------------------------------
-- 6. ANY with multiple comparison operators
-- ----------------------------------------------------------------------------
SELECT
    5 > ANY (SELECT 3)          AS gt_any,
    5 > ALL (SELECT 3)          AS gt_all,
    5 < ANY (SELECT 3, 10)      AS lt_any_2vals,
    5 < ALL (SELECT 3, 10)      AS lt_all_2vals,
    5 = ANY (SELECT 5, 6)       AS eq_any,
    5 <> ALL (SELECT 6, 7)      AS neq_all;

-- ----------------------------------------------------------------------------
-- 7. NULL trap with <> ALL (same as NOT IN)
-- ----------------------------------------------------------------------------
CREATE TEMPORARY TABLE tmp_vals (v INT);
INSERT INTO tmp_vals VALUES (10), (20), (NULL);

-- Returns ZERO rows because of the NULL.
SELECT first_name FROM customers
WHERE id <> ALL (SELECT v FROM tmp_vals);

-- Fixed with NOT EXISTS:
SELECT first_name FROM customers c
WHERE NOT EXISTS (SELECT 1 FROM tmp_vals t WHERE t.v = c.id);

DROP TEMPORARY TABLE tmp_vals;

-- ----------------------------------------------------------------------------
-- 8. Realistic example — "customers whose max order exceeds our top-3 average"
-- ----------------------------------------------------------------------------
SELECT customer_id, MAX(total) AS max_order
FROM orders
GROUP BY customer_id
HAVING MAX(total) > ALL (
    SELECT total FROM orders ORDER BY total DESC LIMIT 3
);
-- Empty result because the top 3 orders' totals can't all be lower than
-- any one customer's max (the top 3 customer max IS one of those orders).

-- ----------------------------------------------------------------------------
-- 9. ANY / ALL equivalence table
-- ----------------------------------------------------------------------------
SELECT '> ANY' AS op, 'Greater than at least one (equivalent to > MIN)' AS meaning
UNION ALL SELECT '> ALL', 'Greater than every (equivalent to > MAX)'
UNION ALL SELECT '< ANY', 'Less than at least one (equivalent to < MAX)'
UNION ALL SELECT '< ALL', 'Less than every (equivalent to < MIN)'
UNION ALL SELECT '= ANY', 'Same as IN'
UNION ALL SELECT '<> ALL', 'Same as NOT IN (NULL trap applies!)'
UNION ALL SELECT '<> ANY', 'Almost always TRUE — rarely useful';

-- ----------------------------------------------------------------------------
-- 10. EXERCISES
-- ----------------------------------------------------------------------------
-- EASY
-- E1.  Find products priced higher than every product in category 11
--      (Non-Fiction books). Use > ALL.
-- E2.  Find products priced lower than at least one product in category 12.
--      Use < ANY.
--
-- MEDIUM
-- E3.  Rewrite E1 using a subquery with MAX instead of > ALL.
-- E4.  Find orders whose total exceeds every order placed in 2024. Use > ALL.
--
-- HARD
-- E5.  Demonstrate that `<> ALL` is equivalent to `NOT IN`, including the
--      NULL trap. Create a temp table with a NULL value and show both
--      return zero rows.
--
-- EXPERT
-- E6.  Explain in a comment when you'd prefer ANY/ALL over MIN/MAX
--      subqueries, and when you'd prefer the IN/EXISTS equivalents. Note
--      any readability trade-offs.
-- ============================================================================

-- End of file 03_any_all.sql
