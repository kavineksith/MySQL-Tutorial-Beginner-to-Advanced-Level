-- ============================================================================
-- 05_order_by.sql — ORDER BY: Sorting Result Sets
-- ============================================================================
-- SKILL LEVEL : Beginner
-- TOPICS      : ORDER BY, ASC/DESC, multi-column sorting, sorting by
--               expression, sorting by alias, NULL sort order, natural sort,
--               FIELD() for custom ordering, collation effects.
-- ----------------------------------------------------------------------------
-- TEXTBOOK DEPTH
--   ORDER BY is the ONLY clause that guarantees row order in the result.
--   Without ORDER BY, MySQL may return rows in any order — usually the order
--   of the underlying index scan, but this is an implementation detail, not
--   a guarantee. Relying on insertion order is a common bug.
--
--   Sorting rules you must memorize:
--     * ASC is the default; NULLs sort FIRST in ASC, LAST in DESC.
--     * Multiple sort keys apply left-to-right: the first column dominates,
--       ties are broken by the second, and so on.
--     * You may sort by a column NOT in the SELECT list.
--     * You may sort by an alias defined in SELECT (because ORDER BY runs
--       AFTER SELECT).
--     * You may sort by an expression: ORDER BY LENGTH(name).
--     * Sort is case-insensitive under the default `_ci` collation.
-- ============================================================================

USE ecom;

-- ----------------------------------------------------------------------------
-- 1. Single-column ASC (the default)
-- ----------------------------------------------------------------------------
SELECT name, price
FROM products
ORDER BY price;

SELECT name, price
FROM products
ORDER BY price ASC;     -- explicit, identical to above

-- ----------------------------------------------------------------------------
-- 2. Single-column DESC
-- ----------------------------------------------------------------------------
SELECT name, price
FROM products
ORDER BY price DESC;

-- ----------------------------------------------------------------------------
-- 3. Multi-column sort
-- ----------------------------------------------------------------------------
-- Sort by country ascending, then by last_name ascending within each country.
SELECT first_name, last_name, country
FROM customers
ORDER BY country ASC, last_name ASC;

-- Mixed direction: country ASC, created_at DESC (newest first per country).
SELECT first_name, country, created_at
FROM customers
ORDER BY country ASC, created_at DESC;

-- ----------------------------------------------------------------------------
-- 4. Sort by column not in SELECT list
-- ----------------------------------------------------------------------------
SELECT first_name, last_name
FROM customers
ORDER BY created_at DESC;

-- ----------------------------------------------------------------------------
-- 5. Sort by alias defined in SELECT
-- ----------------------------------------------------------------------------
SELECT
    sku,
    name,
    price,
    (price - cost) AS gross_margin
FROM products
ORDER BY gross_margin DESC;

-- ----------------------------------------------------------------------------
-- 6. Sort by expression
-- ----------------------------------------------------------------------------
SELECT first_name, last_name, email
FROM customers
ORDER BY LENGTH(email) DESC, last_name ASC;

SELECT name, price
FROM products
ORDER BY price * stock_qty DESC;     -- total inventory value

-- ----------------------------------------------------------------------------
-- 7. NULL ordering
-- ----------------------------------------------------------------------------
-- In MySQL ASC: NULLs come FIRST. In DESC: NULLs come LAST.
-- This is the OPPOSITE of PostgreSQL (NULLs sort last in ASC by default).
SELECT first_name, last_name, phone
FROM customers
ORDER BY phone;                      -- NULLs first

SELECT first_name, last_name, phone
FROM customers
ORDER BY phone DESC;                 -- NULLs last

-- Force NULLs last regardless of direction using ISNULL/IS NULL:
SELECT first_name, phone
FROM customers
ORDER BY phone IS NULL, phone;       -- non-NULLs sorted first, NULLs at the end

-- ----------------------------------------------------------------------------
-- 8. Custom sort order with FIELD()
-- ----------------------------------------------------------------------------
-- FIELD(value, list) returns the 1-based position of value in list, or 0 if
-- not found. Use it to define a custom priority order.
SELECT id, status, total
FROM orders
ORDER BY FIELD(status, 'pending', 'paid', 'shipped', 'delivered', 'cancelled', 'refunded');
-- pending first, then paid, then shipped, ... cancelled/refunded last.

-- ----------------------------------------------------------------------------
-- 9. Case-sensitive sort with COLLATE
-- ----------------------------------------------------------------------------
SELECT first_name, last_name
FROM customers
ORDER BY last_name COLLATE utf8mb4_0900_as_cs;
-- `_as_cs` = accent-sensitive, case-sensitive.

-- ----------------------------------------------------------------------------
-- 10. Natural sort using +0 trick or CAST
-- ----------------------------------------------------------------------------
-- Sort SKUs like LAP-001, LAP-002, ..., LAP-010 in numeric order rather than
-- lexicographic (where LAP-010 would come before LAP-002).
SELECT sku, name
FROM products
ORDER BY
    SUBSTRING_INDEX(sku, '-', 1),                         -- category prefix
    CAST(SUBSTRING_INDEX(sku, '-', -1) AS UNSIGNED);      -- numeric suffix

-- ----------------------------------------------------------------------------
-- 11. ORDER BY with LIMIT — TOP N queries
-- ----------------------------------------------------------------------------
-- Three most expensive products.
SELECT name, price
FROM products
ORDER BY price DESC
LIMIT 3;

-- Second, third, fourth most expensive — use OFFSET.
SELECT name, price
FROM products
ORDER BY price DESC
LIMIT 3 OFFSET 1;

-- MySQL 8.0+ (SQL:2023 compatible where noted) supports the cleaner `LIMIT .. OFFSET ..` syntax:
SELECT name, price
FROM products
ORDER BY price DESC
LIMIT 3 OFFSET 1;

-- ----------------------------------------------------------------------------
-- 12. Stable sort
-- ----------------------------------------------------------------------------
-- SQL does not guarantee stable sort. If you need a tiebreaker, add a
-- unique column (usually the primary key) as the final sort key.
SELECT id, total, customer_id
FROM orders
ORDER BY total DESC, id ASC;

-- ----------------------------------------------------------------------------
-- 13. EXERCISES
-- ----------------------------------------------------------------------------
-- EASY
-- E1.  Return all products sorted by name (A → Z).
-- E2.  Return the 5 customers with the highest `id` (a proxy for newest).
--
-- MEDIUM
-- E3.  Return orders sorted by status using this custom priority:
--      cancelled → refunded → pending → paid → shipped → delivered.
-- E4.  Return customers sorted by country ASC, then by created_at DESC
--      within each country. Show first_name, last_name, country, created_at.
--
-- HARD
-- E5.  For every product, return name, price, and gross_margin_pct
--      (computed), sorted by gross_margin_pct DESC. Round the pct to 1 dp.
-- E6.  Find the top 3 customers by total spend across their orders.
--      (Hint: SUM(total) per customer, ORDER BY that DESC, LIMIT 3.)
--
-- EXPERT
-- E7.  Sort customers so that those with a NULL `phone` appear LAST, and
--      among non-NULL phones the sort is alphabetical by last_name. Write a
--      single ORDER BY clause.
-- ============================================================================

-- End of file 05_order_by.sql
