-- ============================================================================
-- 06_self_join.sql — SELF JOIN
-- ============================================================================
-- SKILL LEVEL : Intermediate
-- TOPICS      : Self-join for hierarchical data, manager-employee, parent-
--               child categories, finding pairs (e.g. customers in same
--               city), comparing adjacent rows, performance.
-- ----------------------------------------------------------------------------
-- TEXTBOOK DEPTH
--   A self-join is any join where the same table appears on both sides.
--   You MUST use aliases to distinguish the two instances. Self-joins are
--   the SQL way to answer:
--     * "Who is this person's manager?"          (employees × employees)
--     * "What is this category's parent?"        (categories × categories)
--     * "Which customers live in the same city?" (customers × customers)
--     * "Compare today's row to yesterday's row" (sales × sales, on date-1)
--
--   Performance note: self-joins on a 100k-row table produce up to 10^10
--   row pairs in the worst case. Always include a tight join predicate
--   (typically equality on a key like manager_id) and an index on that key.
-- ============================================================================

USE ecom;

-- ----------------------------------------------------------------------------
-- 1. Manager-employee self-join
-- ----------------------------------------------------------------------------
SELECT
    e.id           AS employee_id,
    e.first_name   AS employee,
    e.title        AS emp_title,
    m.id           AS manager_id,
    m.first_name   AS manager,
    m.title        AS mgr_title
FROM employees e
LEFT JOIN employees m ON m.id = e.manager_id
ORDER BY e.id;

-- ----------------------------------------------------------------------------
-- 2. Find direct reports of a specific manager
-- ----------------------------------------------------------------------------
SELECT
    e.id, e.first_name, e.last_name, e.title
FROM employees e
JOIN employees m ON m.id = e.manager_id
WHERE m.first_name = 'Lucas' AND m.last_name = 'Nguyen';
-- All employees whose manager is Lucas Nguyen (VP Engineering).

-- ----------------------------------------------------------------------------
-- 3. Category parent-child self-join
-- ----------------------------------------------------------------------------
SELECT
    c.id,
    c.name AS category,
    p.name AS parent_category
FROM categories c
LEFT JOIN categories p ON p.id = c.parent_id
ORDER BY c.id;

-- ----------------------------------------------------------------------------
-- 4. Find sibling categories (same parent)
-- ----------------------------------------------------------------------------
SELECT
    a.name AS category_a,
    b.name AS category_b,
    a.parent_id AS shared_parent
FROM categories a
JOIN categories b ON a.parent_id = b.parent_id AND a.id < b.id
WHERE a.parent_id IS NOT NULL
ORDER BY a.parent_id, a.id, b.id;
-- a.id < b.id avoids pairing each row with itself and avoids duplicates.

-- ----------------------------------------------------------------------------
-- 5. Find customers who live in the same city
-- ----------------------------------------------------------------------------
SELECT
    a.first_name AS cust_a,
    a.last_name  AS cust_a_last,
    b.first_name AS cust_b,
    b.last_name  AS cust_b_last,
    a.city
FROM customers a
JOIN customers b ON a.city = b.city AND a.id < b.id
WHERE a.city IS NOT NULL
ORDER BY a.city, a.id, b.id;

-- ----------------------------------------------------------------------------
-- 6. Compare adjacent rows (LAG-like query without window functions)
-- ----------------------------------------------------------------------------
-- Find orders placed by the same customer on consecutive order ids.
SELECT
    a.id           AS order_a,
    a.order_date   AS date_a,
    b.id           AS order_b,
    b.order_date   AS date_b,
    a.customer_id
FROM orders a
JOIN orders b ON a.customer_id = b.customer_id AND a.id < b.id
ORDER BY a.customer_id, a.id, b.id;

-- ----------------------------------------------------------------------------
-- 7. Self-join with aggregation — manager's team size and budget
-- ----------------------------------------------------------------------------
SELECT
    m.id           AS manager_id,
    m.first_name   AS manager,
    COUNT(e.id)    AS direct_reports,
    SUM(e.salary)  AS team_salary_budget
FROM employees m
LEFT JOIN employees e ON e.manager_id = m.id
GROUP BY m.id, m.first_name
HAVING COUNT(e.id) > 0
ORDER BY team_salary_budget DESC;

-- ----------------------------------------------------------------------------
-- 8. Multi-level hierarchy via chained self-joins
-- ----------------------------------------------------------------------------
-- CEO → VP → Manager → IC, by chaining three self-joins.
SELECT
    ceo.first_name  AS ceo,
    vp.first_name   AS vp,
    mgr.first_name  AS manager,
    ic.first_name   AS engineer
FROM employees ic
LEFT JOIN employees mgr ON mgr.id = ic.manager_id
LEFT JOIN employees vp  ON vp.id  = mgr.manager_id
LEFT JOIN employees ceo ON ceo.id = vp.manager_id
WHERE ic.title = 'Software Engineer'
ORDER BY ic.id;
-- This works for fixed-depth hierarchies. For arbitrary depth, use a
-- recursive CTE (see 09_advanced_mysql/03_recursive_ctes.sql).

-- ----------------------------------------------------------------------------
-- 9. Self-join to find duplicates by email
-- ----------------------------------------------------------------------------
-- Data quality check — find customers sharing the same email.
SELECT
    a.id AS id_a,
    b.id AS id_b,
    a.email
FROM customers a
JOIN customers b ON a.email = b.email AND a.id < b.id;
-- Empty in our seed data, but the pattern is the canonical duplicate
-- detector.

-- ----------------------------------------------------------------------------
-- 10. Self-join vs window function — when to use which
-- ----------------------------------------------------------------------------
-- For "previous row" / "next row" calculations, window functions
-- (LAG, LEAD) are clearer and faster than self-joins. See
-- 09_advanced_mysql/01_window_functions.sql.

-- Old way (self-join):
SELECT a.order_date, a.total, b.total AS prev_total
FROM orders a
LEFT JOIN orders b ON b.id = (
    SELECT MAX(id) FROM orders WHERE customer_id = a.customer_id AND id < a.id
)
WHERE a.customer_id = 1
ORDER BY a.id;

-- Modern way (window function):
SELECT order_date, total,
       LAG(total) OVER (PARTITION BY customer_id ORDER BY id) AS prev_total
FROM orders
WHERE customer_id = 1
ORDER BY id;

-- ----------------------------------------------------------------------------
-- 11. EXERCISES
-- ----------------------------------------------------------------------------
-- EASY
-- E1.  List every category with its parent category name.
-- E2.  List every employee with their manager's first name.
--
-- MEDIUM
-- E3.  Find pairs of customers who share the same `country` (use a.id < b.id
--      to avoid duplicates and self-pairs).
-- E4.  Find employees whose salary is greater than their manager's salary.
--
-- HARD
-- E5.  For each manager, list direct reports, count them, and compute the
--      total team salary budget.
-- E6.  Chain three self-joins to traverse the employee hierarchy 3 levels
--      deep (CEO → VP → IC). Return rows where the bottom level is a
--      'Software Engineer'.
--
-- EXPERT
-- E7.  Compare the self-join approach to LAG() OVER (...) for "previous
--      row" queries. Explain in a comment which you'd prefer and why.
-- ============================================================================

-- End of file 06_self_join.sql
