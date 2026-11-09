-- ============================================================================
-- 02_medium_challenges.sql — Progressive Challenges (MEDIUM)
-- ============================================================================
-- SKILL LEVEL : Beginner→Intermediate
-- Each challenge combines 2-3 concepts. Solutions in
-- solutions/12_medium_challenges_solutions.sql
-- ============================================================================

USE ecom;

-- ============================================================================
-- M1. For each customer, return first_name, last_name, total number of
--     orders, and total spend. Use LEFT JOIN so customers without orders
--     appear with 0. Sort by total spend DESC.
-- ============================================================================

-- M2. Find the top 3 customers by total spend (excluding cancelled orders).
--     Show customer_id, first_name, last_name, total_spend.

-- M3. For each order, return order_id, customer_name, product_name,
--     quantity, and line_total. Join all 4 tables (customers, orders,
--     order_items, products). Limit to 10 rows.

-- M4. Find products that have been ordered at least 2 times. Show sku,
--     name, times_ordered. Sort by times_ordered DESC.

-- M5. Find customers who have placed an order but have NOT placed a
--     delivered order. Use EXISTS + NOT EXISTS.

-- M6. Use a CTE to compute per-category average price, then return
--     products whose price exceeds their category average. Show product
--     name, price, category average.

-- M7. Compute the running total of revenue per month for 2024. Show
--     month, monthly_revenue, cumulative_revenue.

-- M8. Find the most expensive product in each category. Show category_id,
--     product name, price. Use ROW_NUMBER() OVER (...).

-- M9. For each customer, return the date of their FIRST order and the
--     date of their LAST order. Use MIN() and MAX(). Customers without
--     orders should appear with NULLs.

-- M10. Find orders whose total is greater than the customer's average
--      order total. Use a correlated subquery.

-- M11. Use GROUP_CONCAT to return each customer's order_ids as a
--      comma-separated list.

-- M12. Build a pivot table: rows are countries, columns are 2024 revenue
--      and 2025 revenue. Use SUM(CASE WHEN YEAR=... THEN total ELSE 0 END).

-- M13. Find duplicate emails in the customers table (should be empty but
--      write the query). Use SELF JOIN with a.id < b.id.

-- M14. Use a recursive CTE to generate all days in 2024 and LEFT JOIN
--      to orders. Show days with zero orders too.

-- M15. Find the second-highest price in each product category. Use a
--      CTE with ROW_NUMBER() and filter rn = 2.

-- M16. Compute each product's gross margin percentage (price - cost) /
--      price * 100. Round to 2 decimals. Avoid division by zero. Sort DESC.

-- M17. Use JSON_EXTRACT to return each customer's loyalty_points from
--      their metadata, with 0 as the default.

-- M18. Find customers whose first_name appears in another table
--      (employees). Use INTERSECT-like pattern with IN.

-- M19. Use NTILE(4) to bucket products into 4 quartiles by price. Show
--      name, price, quartile.

-- M20. Find the employee with the most direct reports. Show manager's
--      name and the count of reports. Use SELF JOIN + GROUP BY.

-- End of file 02_medium_challenges.sql
