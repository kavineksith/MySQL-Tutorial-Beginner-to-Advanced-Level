-- ============================================================================
-- 04_expert_challenges.sql — Progressive Challenges (EXPERT)
-- ============================================================================
-- SKILL LEVEL : Advanced
-- Requires window functions, recursive CTEs, JSON, transactions, triggers,
-- performance analysis. Solutions in
-- solutions/14_expert_challenges_solutions.sql
-- ============================================================================

USE ecom;

-- ============================================================================
-- X1. Build a customer cohort retention table.
--     Rows: first_order_month (YYYY-MM).
--     Columns: month_0 (count of cohort), month_1 (count active in
--     first_order_month + 1), month_2, ... month_11.
--     Use a CTE to find each customer's first_order_month, then LEFT JOIN
--     to subsequent orders, GROUP BY cohort.
-- ============================================================================

-- X2. Use a recursive CTE to find ALL descendants of the 'Electronics'
--     category (any depth). Return each descendant with its depth and
--     full path from Electronics.

-- X3. Implement optimistic locking on the products table:
--       (a) Add a `version` column to products.
--       (b) Read product 1's version.
--       (c) UPDATE products SET stock_qty = stock_qty - 1, version = version + 1
--           WHERE id = 1 AND version = <read_version>.
--       (d) Verify affected_rows = 1.
--       (e) Demonstrate a conflicting UPDATE that returns affected_rows = 0.

-- X4. Create a trigger that maintains a denormalized `total_spent` column
--     on customers. The trigger fires AFTER INSERT/UPDATE/DELETE on orders
--     and recomputes the affected customer's total_spent from the live
--     orders table.

-- X5. Use JSON_TABLE to extract a multi-level JSON document into rows.
--     Input: '[{"order_id": 1, "items":[{"sku":"A","qty":2},{"sku":"B","qty":1}]},
--              {"order_id": 2, "items":[{"sku":"C","qty":3}]}]'
--     Output: one row per (order_id, sku, qty).

-- X6. Find deadlocks in your application by querying
--     performance_schema.events_errors_summary_global_by_error. List the
--     top 5 error codes by count and explain what each means.

-- X7. Build a window-function query that returns the top product per
--     month (one row per month). Columns: month, product_name, revenue.

-- X8. Use EXPLAIN ANALYZE to compare two JOIN strategies for the same
--     query — one using a hash join (MySQL 8.0.18+) and one forcing a
--     nested-loop join. Measure the actual time difference.

-- X9. Create a stored procedure sp_revenue_report(p_year INT) that:
--       (a) Computes total revenue per month for the given year.
--       (b) Returns the result as a result set with month, revenue,
--           pct_of_year.
--       (c) Logs each run to an audit table.

-- X10. Design a backup verification job:
--        (a) Create a script that takes a logical backup of ecom with
--            mysqldump --single-transaction.
--        (b) Restore it to a scratch database ecom_verify.
--        (c) Run a row-count comparison between ecom and ecom_verify for
--            each table. Fail if any count differs.

-- X11. Use a multi-valued JSON index to find all customers whose
--      metadata.tags array contains 'vip' OR 'newsletter'. Compare
--      performance vs JSON_CONTAINS without the index (use EXPLAIN).

-- X12. Build a slow-query-monitoring query against
--      performance_schema.events_statements_summary_by_digest. Return
--      the top 10 queries by total execution time, with avg latency,
--      call count, and the digest text.

-- X13. Implement row-level security via a VIEW + CURRENT_USER():
--        (a) Add an `owner` column to a temp table.
--        (b) Create a VIEW that filters rows WHERE owner = CURRENT_USER().
--        (c) Demonstrate that a SELECT from the view only returns the
--            caller's own rows.

-- X14. Use a recursive CTE to compute Fibonacci numbers up to F(20).
--      Each row: n, fib_value.

-- X15. Build a materialized-view pattern: a real table `mv_customer_summary`
--      refreshed by an EVENT every hour. The event computes per-customer
--      order_count and total_spent from orders, and TRUNCATE+INSERTs the
--      result into mv_customer_summary. Verify it works.

-- X16. Find queries that produce a filesort or temporary table by
--      querying performance_schema.events_statements_summary_by_digest.
--      Filter on SUM_CREATED_TMP_TABLES > 0 or SORT_SCAN > 0. Suggest
--      an index that would eliminate each.

-- X17. Use the optimizer trace to investigate why MySQL chose a full
--      table scan instead of an index for a query. Document the trace
--      output and the alternative plan considered.

-- X18. Design a write-through cache table pattern:
--        (a) Table `cached_customers` mirrors customers but with denormalized
--            order_count and total_spent.
--        (b) Triggers on customers / orders / order_items keep the cache
--            in sync.
--        (c) Read queries hit the cache; write queries propagate.

-- X19. Use a CTE chained three deep to compute:
--        (a) per-customer spend
--        (b) global quartile boundaries based on spend
--        (c) each customer's quartile (1-4)

-- X20. Write a query that finds the longest consecutive streak of days
--      with at least one order. Use LAG and a difference-of-row-numbers
--      technique to identify consecutive runs.

-- End of file 04_expert_challenges.sql
