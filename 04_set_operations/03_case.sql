-- ============================================================================
-- 03_case.sql — CASE Expression
-- ============================================================================
-- SKILL LEVEL : Intermediate
-- TOPICS      : Simple CASE (case-when-then), searched CASE (CASE WHEN
--               predicate), CASE in SELECT, CASE in ORDER BY, CASE in
--               aggregate (pivot), CASE in UPDATE, NULLIF and COALESCE as
--               special cases of CASE.
-- ----------------------------------------------------------------------------
-- TEXTBOOK DEPTH
--   CASE is SQL's if/else expression. It returns a value based on
--   conditions. There are two forms:
--
--   SIMPLE CASE:
--     CASE col
--         WHEN val1 THEN result1
--         WHEN val2 THEN result2
--         ELSE default_result
--     END
--
--   SEARCHED CASE (more flexible, preferred):
--     CASE
--         WHEN predicate1 THEN result1
--         WHEN predicate2 THEN result2
--         ELSE default_result
--     END
--
--   Rules:
--     * Returns the FIRST matching branch's result. Subsequent branches
--       are not evaluated.
--     * ELSE is optional. If omitted and no branch matches, returns NULL.
--     * All THEN results must have compatible types.
--     * CASE is an EXPRESSION — you can use it anywhere a value is allowed
--       (SELECT, WHERE, ORDER BY, HAVING, SET, INSERT VALUES, etc.).
--
--   Special cases of CASE:
--     * NULLIF(a, b)        ≡  CASE WHEN a = b THEN NULL ELSE a END
--     * COALESCE(a, b, ...) ≡  CASE WHEN a IS NOT NULL THEN a ELSE ... END
--     * IF(cond, x, y)      ≡  CASE WHEN cond THEN x ELSE y END  (MySQL only)
-- ============================================================================

USE ecom;

-- ----------------------------------------------------------------------------
-- 1. Simple CASE
-- ----------------------------------------------------------------------------
SELECT
    sku,
    name,
    price,
    CASE
        WHEN price < 100             THEN 'budget'
        WHEN price < 500             THEN 'mid'
        WHEN price < 1500            THEN 'premium'
        ELSE 'luxury'
    END AS price_tier
FROM products
ORDER BY price;

-- ----------------------------------------------------------------------------
-- 2. Searched CASE with complex predicates
-- ----------------------------------------------------------------------------
SELECT
    first_name,
    last_name,
    country,
    is_active,
    CASE
        WHEN is_active = 0                       THEN 'inactive'
        WHEN country = 'United States'           THEN 'us_active'
        WHEN country IN ('United Kingdom', 'Canada') THEN 'uk_ca_active'
        ELSE 'international_active'
    END AS customer_segment
FROM customers
ORDER BY customer_segment, last_name;

-- ----------------------------------------------------------------------------
-- 3. CASE in aggregate — manual pivot
-- ----------------------------------------------------------------------------
-- Count of customers per country per active-status, in a single row per country.
SELECT
    country,
    SUM(CASE WHEN is_active = 1 THEN 1 ELSE 0 END) AS active_count,
    SUM(CASE WHEN is_active = 0 THEN 1 ELSE 0 END) AS inactive_count,
    COUNT(*) AS total
FROM customers
GROUP BY country
ORDER BY country;

-- ----------------------------------------------------------------------------
-- 4. CASE in aggregate — sum conditionally
-- ----------------------------------------------------------------------------
-- Total revenue from delivered orders vs. all other statuses.
SELECT
    SUM(CASE WHEN status = 'delivered' THEN total ELSE 0 END) AS delivered_revenue,
    SUM(CASE WHEN status <> 'delivered' THEN total ELSE 0 END) AS other_revenue,
    SUM(total) AS total_revenue
FROM orders;

-- ----------------------------------------------------------------------------
-- 5. CASE in ORDER BY — custom sort order
-- ----------------------------------------------------------------------------
SELECT id, status, total
FROM orders
ORDER BY
    CASE status
        WHEN 'pending'   THEN 1
        WHEN 'paid'      THEN 2
        WHEN 'shipped'   THEN 3
        WHEN 'delivered' THEN 4
        WHEN 'cancelled' THEN 5
        WHEN 'refunded'  THEN 6
        ELSE 99
    END,
    total DESC;

-- ----------------------------------------------------------------------------
-- 6. CASE to compute a derived column then sort by it
-- ----------------------------------------------------------------------------
SELECT
    sku,
    name,
    price,
    cost,
    CASE
        WHEN cost = 0 THEN NULL
        ELSE ROUND((price - cost) / cost * 100, 2)
    END AS markup_pct
FROM products
ORDER BY markup_pct DESC;

-- ----------------------------------------------------------------------------
-- 7. CASE in WHERE — usually unnecessary, but valid
-- ----------------------------------------------------------------------------
SELECT first_name, last_name, country
FROM customers
WHERE
    CASE
        WHEN country = 'United States' THEN is_active = 1
        ELSE TRUE
    END;
-- Equivalent to: WHERE country <> 'United States' OR is_active = 1
-- Prefer the simpler form; CASE in WHERE is rarely clearer.

-- ----------------------------------------------------------------------------
-- 8. CASE in UPDATE
-- ----------------------------------------------------------------------------
-- Update with conditional logic per row.
UPDATE products
SET price = CASE
    WHEN category_id = 8 THEN ROUND(price * 1.05, 2)   -- laptops +5%
    WHEN category_id = 9 THEN ROUND(price * 1.03, 2)   -- components +3%
    ELSE price
END
WHERE category_id IN (8, 9);

SELECT sku, name, price FROM products WHERE category_id IN (8, 9) ORDER BY sku;

-- Restore seed prices
UPDATE products SET price = 1299.00 WHERE sku = 'LAP-001';
UPDATE products SET price = 2499.00 WHERE sku = 'LAP-002';
UPDATE products SET price = 599.00  WHERE sku = 'CPU-001';
UPDATE products SET price = 1099.00 WHERE sku = 'GPU-001';
UPDATE products SET price = 149.00  WHERE sku = 'RAM-001';

-- ----------------------------------------------------------------------------
-- 9. CASE in GROUP BY — bucketing
-- ----------------------------------------------------------------------------
SELECT
    CASE
        WHEN price < 100             THEN 'budget'
        WHEN price < 500             THEN 'mid'
        WHEN price < 1500            THEN 'premium'
        ELSE 'luxury'
    END AS price_tier,
    COUNT(*) AS product_count,
    AVG(price) AS avg_price
FROM products
GROUP BY price_tier
ORDER BY avg_price;

-- ----------------------------------------------------------------------------
-- 10. CASE for NULL handling
-- ----------------------------------------------------------------------------
SELECT
    first_name,
    COALESCE(phone, '— no phone —') AS phone_label,
    CASE
        WHEN phone IS NULL        THEN 'missing'
        WHEN phone LIKE '+%'      THEN 'international'
        ELSE 'domestic'
    END AS phone_type
FROM customers
LIMIT 6;

-- ----------------------------------------------------------------------------
-- 11. CASE in COUNT for filtering rows counted
-- ----------------------------------------------------------------------------
SELECT
    COUNT(*) AS total_orders,
    COUNT(CASE WHEN status = 'delivered' THEN 1 END) AS delivered_count,
    COUNT(CASE WHEN status = 'cancelled' THEN 1 END) AS cancelled_count,
    COUNT(CASE WHEN status = 'paid'      THEN 1 END) AS paid_count
FROM orders;

-- ----------------------------------------------------------------------------
-- 12. EXERCISES
-- ----------------------------------------------------------------------------
-- EASY
-- E1.  Add a `price_tier` column to the products table output: budget if
--      price < 100, mid if < 500, premium otherwise.
-- E2.  Add a `customer_segment` column: 'US' if country is United States,
--      'EU' if United Kingdom, 'Other' otherwise.
--
-- MEDIUM
-- E3.  Build a pivot table of customer counts per country, with separate
--      columns for active vs inactive.
-- E4.  Use CASE in ORDER BY to sort orders by a custom status priority
--      (pending first, then paid, then shipped, etc.).
--
-- HARD
-- E5.  Compute the markup percentage for each product, returning NULL when
--      cost is 0 (avoid division by zero). Sort by markup_pct DESC.
-- E6.  Use CASE inside COUNT to count delivered, cancelled, and paid orders
--      in a single row.
--
-- EXPERT
-- E7.  Use CASE inside an UPDATE to apply different price adjustments per
--      category: laptops +5%, components +3%, audio +2%, others unchanged.
--      Then restore original prices.
-- ============================================================================

-- End of file 03_case.sql
