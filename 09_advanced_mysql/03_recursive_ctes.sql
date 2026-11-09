-- ============================================================================
-- 03_recursive_ctes.sql — Recursive CTEs for Hierarchies
-- ============================================================================
-- SKILL LEVEL : Advanced
-- TOPICS      : WITH RECURSIVE, anchor + recursive member, termination
--               condition, hierarchy traversal (org chart, category tree),
--               generating series, cycle detection.
-- ----------------------------------------------------------------------------
-- TEXTBOOK DEPTH
--   A recursive CTE references ITSELF in its definition. It runs in rounds:
--     1. Anchor member runs ONCE — produces seed rows.
--     2. Recursive member runs, joining against the previous round's output.
--     3. Repeat until the recursive member returns no new rows.
--
--   Syntax:
--     WITH RECURSIVE cte_name AS (
--         SELECT ...          -- anchor (non-recursive)
--         UNION [ALL]
--         SELECT ... FROM cte_name WHERE ...   -- recursive member
--     )
--     SELECT ... FROM cte_name;
--
--   Common use cases:
--     * Org chart traversal (employees → manager → grand-manager → ...).
--     * Category tree (children → parent → grandparent).
--     * Generate a series (numbers, dates) without a numbers table.
--     * Bill-of-materials explosion.
--     * Graph traversal.
--
--   Safety:
--     * MySQL caps recursion depth with cte_max_recursion_depth (default 1000).
--     * Set it higher for deep hierarchies: SET cte_max_recursion_depth = 10000;
--     * Beware cycles in graphs — use a visited-path list in a column to
--       detect them.
-- ============================================================================

USE ecom;

-- ----------------------------------------------------------------------------
-- 1. Generate a series of numbers 1..10
-- ----------------------------------------------------------------------------
WITH RECURSIVE nums(n) AS (
    SELECT 1
    UNION ALL
    SELECT n + 1 FROM nums WHERE n < 10
)
SELECT n FROM nums;

-- ----------------------------------------------------------------------------
-- 2. Generate a series of dates (e.g., every day in January 2024)
-- ----------------------------------------------------------------------------
WITH RECURSIVE calendar(d) AS (
    SELECT DATE '2024-01-01'
    UNION ALL
    SELECT d + INTERVAL 1 DAY FROM calendar WHERE d < '2024-01-31'
)
SELECT d AS day FROM calendar;

-- ----------------------------------------------------------------------------
-- 3. Org chart traversal — bottom-up (employee → manager → grand-manager)
-- ----------------------------------------------------------------------------
-- For employee 9 (Olivia Chen), show her management chain to the top.
WITH RECURSIVE management_chain AS (
    -- Anchor: the starting employee
    SELECT id, first_name, last_name, manager_id, title, 1 AS depth
    FROM employees
    WHERE id = 9

    UNION ALL

    -- Recursive: walk up to the manager
    SELECT e.id, e.first_name, e.last_name, e.manager_id, e.title, mc.depth + 1
    FROM employees e
    JOIN management_chain mc ON mc.manager_id = e.id
)
SELECT depth, id, first_name, last_name, title
FROM management_chain
ORDER BY depth;

-- ----------------------------------------------------------------------------
-- 4. Org chart traversal — top-down (CEO → all reports recursively)
-- ----------------------------------------------------------------------------
WITH RECURSIVE org_tree AS (
    -- Anchor: the CEO (no manager)
    SELECT id, first_name, last_name, manager_id, title, 1 AS depth,
           CAST(CONCAT(first_name, ' ', last_name) AS CHAR(500)) AS path
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    -- Recursive: each direct report of the previous level
    SELECT e.id, e.first_name, e.last_name, e.manager_id, e.title, ot.depth + 1,
           CONCAT(ot.path, ' > ', e.first_name, ' ', e.last_name)
    FROM employees e
    JOIN org_tree ot ON e.manager_id = ot.id
)
SELECT depth, id, first_name, last_name, title, path
FROM org_tree
ORDER BY path;

-- ----------------------------------------------------------------------------
-- 5. Category tree traversal — top-down
-- ----------------------------------------------------------------------------
-- Starting from Electronics (id=1), walk down to all subcategories.
WITH RECURSIVE category_tree AS (
    SELECT id, parent_id, name, 0 AS depth,
           CAST(name AS CHAR(500)) AS path
    FROM categories
    WHERE id = 1     -- Electronics

    UNION ALL

    SELECT c.id, c.parent_id, c.name, ct.depth + 1,
           CONCAT(ct.path, ' > ', c.name)
    FROM categories c
    JOIN category_tree ct ON c.parent_id = ct.id
)
SELECT depth, id, name, path
FROM category_tree
ORDER BY path;

-- ----------------------------------------------------------------------------
-- 6. Category tree traversal — bottom-up
-- ----------------------------------------------------------------------------
-- For Laptops (id=8), show the chain of parent categories up to the root.
WITH RECURSIVE parent_chain AS (
    SELECT id, parent_id, name, 1 AS depth
    FROM categories WHERE id = 8

    UNION ALL

    SELECT c.id, c.parent_id, c.name, pc.depth + 1
    FROM categories c
    JOIN parent_chain pc ON pc.parent_id = c.id
)
SELECT depth, id, name FROM parent_chain ORDER BY depth;

-- ----------------------------------------------------------------------------
-- 7. Bill-of-materials style aggregation — count of all subcategories
-- ----------------------------------------------------------------------------
-- For each root category, count the total number of descendants.
WITH RECURSIVE descendants AS (
    -- Anchor: each category
    SELECT id AS root_id, id AS descendant_id
    FROM categories

    UNION ALL

    -- Recursive: child of descendant belongs to root
    SELECT d.root_id, c.id
    FROM descendants d
    JOIN categories c ON c.parent_id = d.descendant_id
)
SELECT
    r.name AS root_category,
    COUNT(DISTINCT d.descendant_id) - 1 AS descendant_count   -- exclude self
FROM descendants d
JOIN categories r ON r.id = d.root_id
GROUP BY r.id, r.name
ORDER BY descendant_count DESC;

-- ----------------------------------------------------------------------------
-- 8. Cycle detection — graph traversal safety
-- ----------------------------------------------------------------------------
-- If your data has a cycle (e.g. A manages B manages A), naive recursion
-- loops forever. Detect cycles by tracking visited ids in a path column.
CREATE TEMPORARY TABLE tmp_cyclic (id INT, parent_id INT);
INSERT INTO tmp_cyclic VALUES (1, 2), (2, 3), (3, 1);  -- cycle 1→2→3→1

WITH RECURSIVE walk AS (
    SELECT id, parent_id, CAST(CONCAT(',', id, ',') AS CHAR(500)) AS visited
    FROM tmp_cyclic WHERE id = 1

    UNION ALL

    SELECT c.id, c.parent_id, CONCAT(w.visited, c.id, ',')
    FROM tmp_cyclic c
    JOIN walk w ON c.id = w.parent_id
    WHERE FIND_IN_SET(c.id, REPLACE(SUBSTRING(w.visited, 2), ',', ',')) = 0
      -- Stop if we'd revisit a node already in visited
      AND w.visited NOT LIKE CONCAT('%,', c.id, ',%')
)
SELECT id, parent_id, visited FROM walk;

DROP TEMPORARY TABLE tmp_cyclic;

-- ----------------------------------------------------------------------------
-- 9. Adjusting cte_max_recursion_depth
-- ----------------------------------------------------------------------------
SHOW VARIABLES LIKE 'cte_max_recursion_depth';
-- SET SESSION cte_max_recursion_depth = 10000;

-- ----------------------------------------------------------------------------
-- 10. EXERCISES
-- ----------------------------------------------------------------------------
-- EASY
-- E1.  Use a recursive CTE to generate numbers 1 through 20.
-- E2.  Use a recursive CTE to generate every day of February 2024.
--
-- MEDIUM
-- E3.  Traverse the employee org chart from the CEO (id=1) down to all
--      descendants, with depth and path columns.
-- E4.  For employee 9 (Olivia Chen), show her full management chain up to
--      the CEO.
--
-- HARD
-- E5.  For each root category, count the total number of descendant
--      subcategories at any depth.
-- E6.  Generate a date series for 2024 and LEFT JOIN it to orders so you
--      can see days with zero orders too.
--
-- EXPERT
-- E7.  Create a temp table with a cycle (A→B→C→A) and write a recursive
--      CTE that detects and stops at the cycle. Explain in a comment why
--      naive recursion would loop forever.
-- ============================================================================

-- End of file 03_recursive_ctes.sql
