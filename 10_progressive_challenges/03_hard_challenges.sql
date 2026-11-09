-- ============================================================================
-- 03_hard_challenges.sql — Progressive Challenges (HARD)
-- ============================================================================
-- SKILL LEVEL : Intermediate→Advanced
-- Combines joins, window functions, CTEs, subqueries, aggregations.
-- Solutions in solutions/13_hard_challenges_solutions.sql
-- ============================================================================

USE ecom;

-- ============================================================================
-- H1. Find the top spender per country (one row per country). Use
--     ROW_NUMBER() OVER (PARTITION BY country ORDER BY spend DESC).
-- ============================================================================

-- H2. For each product, return its name, price, category name, and a
--     computed column 'is_top_seller' that is TRUE if the product appears
--     in the top 10 order_items by quantity sold.

-- H3. Compute the month-over-month revenue growth rate for 2024.
--     Show month, revenue, prev_month_revenue, growth_pct.

-- H4. Find customers who placed an order in 2024 AND 2025 (if 2025 exists).
--     Use INTERSECT pattern (or two EXISTS subqueries).

-- H5. Use a recursive CTE to traverse the employee org chart top-down.
--     Return each employee with their depth from the CEO and a path
--     column showing the management chain (e.g. "Sofia > Daniel > Lucas > Elena").

-- H6. Compute a customer retention cohort: for each customer who placed
--     their first order in 2024-Q1, what % placed at least one order in
--     2024-Q2, 2024-Q3, 2024-Q4?

-- H7. Find the product whose removal would most reduce total inventory
--     value (price * stock_qty). Return product name and the inventory
--     value it represents.

-- H8. Build a "Top 5 + Other" report: top 5 products by revenue, plus a
--     single "Other" row rolling up the rest. Use UNION ALL.

-- H9. For each order, compute:
--       - items_count (number of line items)
--       - total_quantity (sum of quantities)
--       - avg_unit_price
--       - max_unit_price
--       - min_unit_price
--     Use a single GROUP BY query.

-- H10. Find orders whose total differs from the sum of their line items
--      by more than $1 (data quality check). Show order_id, order total,
--      sum of line totals, difference.

-- H11. Use JSON_TABLE to flatten the metadata.tags array of each customer
--      into one row per tag. Return customer_id, first_name, tag.

-- H12. Compute the moving average of order totals over a 3-order window
--      (current + 2 previous) per customer. Use SUM/AVG OVER with
--      ROWS BETWEEN 2 PRECEDING AND CURRENT ROW.

-- H13. For each category, find:
--       - product_count
--       - avg_price
--       - max_price
--       - min_price
--       - price_range (max - min)
--     Use a single GROUP BY query.

-- H14. Identify customers whose metadata.tags contain 'vip' AND whose
--      total spend exceeds the average spend of ALL customers. Use
--      JSON_CONTAINS and a HAVING with a subquery.

-- H15. Use a CTE with ROW_NUMBER() to find the latest order per customer.
--     Then return customer_name, latest_order_date, latest_order_status,
--     latest_order_total.

-- H16. Compute the percentage of revenue each order_status contributed
--      in 2024. Show status, revenue, pct_of_total. Round to 2 decimals.

-- H17. Find products that have been reviewed but never ordered. Use
--      NOT EXISTS with two subqueries.

-- H18. Use the WITH ROLLUP modifier to produce a hierarchical report:
--     per country → per city → customer count, with subtotals at each
--     level and a grand total.

-- H19. For each employee, compute the salary as a percentage of their
--     manager's salary. Use SELF JOIN. Sort by pct_of_manager_salary DESC.

-- H20. Use EXPLAIN to compare two query plans:
--        (a) SELECT * FROM orders WHERE DATE(order_date) = '2024-02-20';
--        (b) SELECT * FROM orders WHERE order_date >= '2024-02-20' AND
--            order_date < '2024-02-21';
--      Note which uses the index and which doesn't.

-- End of file 03_hard_challenges.sql
