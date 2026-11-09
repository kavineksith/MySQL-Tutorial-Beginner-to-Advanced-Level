-- ============================================================================
-- 01_window_functions.sql — Window Functions (Modern SQL)
-- ============================================================================
-- SKILL LEVEL : Advanced
-- TOPICS      : OVER(), PARTITION BY, ORDER BY in OVER, window frames
--               (ROWS/RANGE PRECEDING/FOLLOWING), ROW_NUMBER, RANK,
--               DENSE_RANK, LAG, LEAD, FIRST_VALUE, LAST_VALUE, NTH_VALUE,
--               SUM/AVG/COUNT OVER, NTILE, CUME_DIST, PERCENT_RANK.
-- ----------------------------------------------------------------------------
-- TEXTBOOK DEPTH
--   Window functions are the most important SQL feature added since CTEs.
--   They compute a value OVER a "window" of rows related to the current
--   row, WITHOUT collapsing rows (unlike GROUP BY).
--
--   Key difference vs GROUP BY:
--     * GROUP BY  : aggregates many rows into one row per group.
--     * OVER()    : aggregates many rows but keeps each original row.
--
--   Anatomy:
--     function(args) OVER (
--         [PARTITION BY col1, col2]              -- grouping
--         [ORDER BY col3 [ASC|DESC]]             -- ordering within partition
--         [frame_clause]                         -- which rows to include
--     )
--
--   Frame clause defines the "window" of rows used by the function:
--     {ROWS | RANGE} BETWEEN frame_start AND frame_end
--     frame_start: UNBOUNDED PRECEDING | n PRECEDING | CURRENT ROW
--     frame_end  : CURRENT ROW | n FOLLOWING | UNBOUNDED FOLLOWING
--
--   Default frame:
--     * If ORDER BY is present: RANGE BETWEEN UNBOUNDED PRECEDING AND
--       CURRENT ROW (running aggregate up to the current row).
--     * If ORDER BY is absent: ENTIRE partition (whole-group aggregate).
--
--   MySQL 8.0+ (SQL:2023 compatible where noted) supports window functions natively.
-- ============================================================================

USE ecom;

-- ----------------------------------------------------------------------------
-- 1. ROW_NUMBER — sequential integer per row within a partition
-- ----------------------------------------------------------------------------
SELECT
    sku,
    name,
    category_id,
    price,
    ROW_NUMBER() OVER (PARTITION BY category_id ORDER BY price DESC) AS rn_in_cat
FROM products
ORDER BY category_id, rn_in_cat;

-- ----------------------------------------------------------------------------
-- 2. RANK — same as ROW_NUMBER but ties get the same rank
-- ----------------------------------------------------------------------------
-- If two rows tie for rank 2, the next rank is 4 (gaps).
SELECT
    sku,
    name,
    price,
    RANK() OVER (ORDER BY price DESC) AS rank_by_price
FROM products
ORDER BY rank_by_price;

-- ----------------------------------------------------------------------------
-- 3. DENSE_RANK — no gaps after ties
-- ----------------------------------------------------------------------------
-- If two rows tie for rank 2, the next rank is 3 (no gap).
SELECT
    sku,
    name,
    price,
    DENSE_RANK() OVER (ORDER BY price DESC) AS dense_rank
FROM products
ORDER BY dense_rank;

-- ----------------------------------------------------------------------------
-- 4. LAG / LEAD — access previous/next row's value
-- ----------------------------------------------------------------------------
-- For each order, show the previous order's total (per customer).
SELECT
    customer_id,
    id AS order_id,
    order_date,
    total,
    LAG(total) OVER (PARTITION BY customer_id ORDER BY order_date) AS prev_order_total,
    LEAD(total) OVER (PARTITION BY customer_id ORDER BY order_date) AS next_order_total,
    total - LAG(total) OVER (PARTITION BY customer_id ORDER BY order_date) AS delta_from_prev
FROM orders
ORDER BY customer_id, order_date;

-- ----------------------------------------------------------------------------
-- 5. FIRST_VALUE / LAST_VALUE — window edges
-- ----------------------------------------------------------------------------
-- CAUTION: LAST_VALUE returns the last value of the FRAME, not the
-- partition. To get the partition's last value, you must change the frame
-- to ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING.
SELECT
    customer_id,
    id AS order_id,
    total,
    FIRST_VALUE(total) OVER w AS first_order_total,
    LAST_VALUE(total) OVER (
        PARTITION BY customer_id
        ORDER BY order_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS last_order_total
FROM orders
WINDOW w AS (
    PARTITION BY customer_id
    ORDER BY order_date
    ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
)
ORDER BY customer_id, order_date;

-- ----------------------------------------------------------------------------
-- 6. NTH_VALUE — value of the Nth row in the frame
-- ----------------------------------------------------------------------------
SELECT
    customer_id,
    id AS order_id,
    total,
    NTH_VALUE(total, 2) OVER (
        PARTITION BY customer_id
        ORDER BY order_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS second_order_total
FROM orders
ORDER BY customer_id, order_date;

-- ----------------------------------------------------------------------------
-- 7. SUM / AVG / COUNT OVER — running totals and partition aggregates
-- ----------------------------------------------------------------------------
-- Running total per customer (cumulative revenue over time):
SELECT
    customer_id,
    order_date,
    total,
    SUM(total) OVER (PARTITION BY customer_id ORDER BY order_date) AS running_total
FROM orders
WHERE status NOT IN ('cancelled', 'refunded')
ORDER BY customer_id, order_date;

-- Each order's total as a percentage of all that customer's spend:
SELECT
    customer_id,
    id AS order_id,
    total,
    SUM(total) OVER (PARTITION BY customer_id) AS total_customer_spend,
    ROUND(total / SUM(total) OVER (PARTITION BY customer_id) * 100, 2) AS pct_of_customer_spend
FROM orders
WHERE status NOT IN ('cancelled', 'refunded');

-- Average price of products in same category:
SELECT
    sku,
    name,
    category_id,
    price,
    AVG(price) OVER (PARTITION BY category_id) AS avg_cat_price,
    ROUND(price - AVG(price) OVER (PARTITION BY category_id), 2) AS price_vs_avg
FROM products
ORDER BY category_id, price;

-- ----------------------------------------------------------------------------
-- 8. NTILE — bucket rows into N equal groups
-- ----------------------------------------------------------------------------
-- Divide products into 4 quartiles by price:
SELECT
    sku,
    name,
    price,
    NTILE(4) OVER (ORDER BY price) AS price_quartile
FROM products
ORDER BY price_quartile, price;

-- ----------------------------------------------------------------------------
-- 9. CUME_DIST and PERCENT_RANK — statistical distribution
-- ----------------------------------------------------------------------------
SELECT
    sku,
    name,
    price,
    CUME_DIST() OVER (ORDER BY price) AS cumulative_dist,
    PERCENT_RANK() OVER (ORDER BY price) AS percent_rank
FROM products
ORDER BY price;

-- ----------------------------------------------------------------------------
-- 10. WINDOW clause — define a named window, reuse it
-- ----------------------------------------------------------------------------
SELECT
    sku,
    name,
    category_id,
    price,
    ROW_NUMBER() OVER w AS rn,
    RANK()       OVER w AS rk,
    DENSE_RANK() OVER w AS drk,
    AVG(price)   OVER w AS avg_price_in_cat
FROM products
WINDOW w AS (PARTITION BY category_id ORDER BY price DESC)
ORDER BY category_id, rn;

-- ----------------------------------------------------------------------------
-- 11. Top-N per group — the canonical window function use case
-- ----------------------------------------------------------------------------
-- Top 2 products by price per category.
WITH ranked AS (
    SELECT
        sku,
        name,
        category_id,
        price,
        ROW_NUMBER() OVER (PARTITION BY category_id ORDER BY price DESC) AS rn
    FROM products
)
SELECT sku, name, category_id, price
FROM ranked
WHERE rn <= 2
ORDER BY category_id, rn;

-- ----------------------------------------------------------------------------
-- 12. EXERCISES
-- ----------------------------------------------------------------------------
-- EASY
-- E1.  Add a row_number column to products, ordered by price DESC.
-- E2.  Add a column showing each product's rank within its category by price.
--
-- MEDIUM
-- E3.  For each order, show the previous order's total (per customer) and
--      the delta.
-- E4.  Add a running_total column to the orders table (per customer, ordered
--      by date).
--
-- HARD
-- E5.  Find the top 2 products by price per category (use ROW_NUMBER in a
--      CTE and filter rn <= 2).
-- E6.  For each customer, compute their first_order_total and last_order_total.
--      (Be careful with LAST_VALUE's default frame — use ROWS BETWEEN
--      UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING.)
--
-- EXPERT
-- E7.  Compute each customer's cumulative revenue over time AND their
--      total revenue, then express each order as a percentage of the
--      cumulative. Compare with the percentage of total.
-- ============================================================================

-- End of file 01_window_functions.sql
