-- ============================================================================
-- 09_comments.sql — SQL Comments
-- ============================================================================
-- SKILL LEVEL : Beginner
-- TOPICS      : Single-line `--`, single-line `#` (MySQL), multi-line
--               `/* */`, conditional comments `/*! ... */`, executable
--               comments `/*!VERSION ... */`, when to use each.
-- ----------------------------------------------------------------------------
-- TEXTBOOK DEPTH
--   SQL supports three comment styles:
--     --          single-line, requires a space after the dashes
--     #           single-line, MySQL-specific
--     /* ... */   multi-line, can span many lines
--
--   MySQL adds two extensions:
--     /*! ... */             "executable comment" — code runs only in MySQL
--                            (other RDBMSs see it as a comment). Useful
--                            for MySQL-specific syntax in portable scripts.
--     /*!50100 ... */        version-gated executable comment. The code runs
--                            only if MySQL version >= 5.1.0. (50100 = 5.01.00)
--                            Useful for feature-gated DDL.
--
--   Best practices:
--     * Use -- for short inline notes (portable to PostgreSQL/SQLite).
--     * Use /* */ for multi-line documentation blocks (portable).
--     * Avoid # in production SQL — it's MySQL-specific and surprising.
--     * Use /*! ... */ when you must embed MySQL-specific syntax in a
--       script that other RDBMSs might run.
-- ============================================================================

USE ecom;

-- ----------------------------------------------------------------------------
-- 1. Single-line `-- ` comments (NOTE the space after the dashes!)
-- ----------------------------------------------------------------------------
-- In MySQL, `-- ` (two dashes plus a space) starts a comment.
-- Without the space, MySQL interprets `--` as part of an expression
-- (5 -- 3 = 2, double-negative).
SELECT 5 -- 3 AS double_negative;     -- This is NOT a comment, it's arithmetic!
-- Output: 2

-- With the space:
SELECT 5 AS five; -- this IS a comment, ignored by MySQL

-- ----------------------------------------------------------------------------
-- 2. Single-line `#` comments (MySQL extension, avoid in portable code)
-- ----------------------------------------------------------------------------
# This is a MySQL-style single-line comment
SELECT 'hello' AS greeting; # to end of line

-- ----------------------------------------------------------------------------
-- 3. Multi-line `/* ... */` comments
-- ----------------------------------------------------------------------------
/*
 * Multi-line comment.
 * Useful for header documentation, license text, or explaining complex
 * query logic that needs multiple paragraphs.
 *
 * Can span any number of lines.
 */
SELECT
    first_name,
    last_name,
    /* inline comment */ email
FROM customers
LIMIT 3;

-- ----------------------------------------------------------------------------
-- 4. Inline comments within a statement
-- ----------------------------------------------------------------------------
SELECT
    first_name,   -- customer's first name
    last_name,    -- customer's last name
    email         -- contact email (UNIQUE)
FROM customers
WHERE is_active = 1   -- only active customers
LIMIT 10;

-- ----------------------------------------------------------------------------
-- 5. MySQL executable comments /*! ... */
-- ----------------------------------------------------------------------------
-- The code inside /*! ... */ is executed by MySQL but treated as a comment
-- by other RDBMSs. Use this for MySQL-specific syntax in portable scripts.

-- Example: SQL_CALC_FOUND_ROWS was a MySQL-only modifier (deprecated in 8.0).
-- /*!SQL_CALC_FOUND_ROWS */ SELECT * FROM customers LIMIT 3;

-- ENGINE=InnoDB is MySQL-specific DDL. Wrap it so portable scripts don't
-- break on PostgreSQL:
CREATE TEMPORARY TABLE tmp_portable (
    id INT PRIMARY KEY,
    name VARCHAR(20)
) /*!ENGINE=MEMORY */;
DROP TEMPORARY TABLE tmp_portable;

-- ----------------------------------------------------------------------------
-- 6. Version-gated executable comments /*!50100 ... */
-- ----------------------------------------------------------------------------
-- The number after /*! is interpreted as MMmm00 (major*100 + minor).
-- The code runs only if MySQL version >= that value. Useful for
-- feature-gated DDL in replication setups where the master and slave
-- run different versions.

-- Create table only if MySQL >= 8.0.0 (80000):
/*!80000 CREATE TEMPORARY TABLE IF NOT EXISTS tmp_mysql8_only (id INT); */
/*!80000 DROP TEMPORARY TABLE IF EXISTS tmp_mysql8_only; */

-- ----------------------------------------------------------------------------
-- 7. Nested comments — NOT supported
-- ----------------------------------------------------------------------------
-- MySQL does NOT support /* /* nested */ */ comments. The inner `*/` closes
-- the outer block and the rest of the line produces a syntax error.

-- ----------------------------------------------------------------------------
-- 8. Comments vs hint syntax
-- ----------------------------------------------------------------------------
-- Optimizer hints (MySQL 8.0+ (SQL:2023 compatible where noted)) look like comments but are interpreted:
SELECT /*+ NO_RANGE_OPTIMIZATION(c PRIMARY) */ first_name
FROM customers c
WHERE c.id BETWEEN 1 AND 5;
-- The `/*+ ... */` form is an optimizer hint, not a comment.

-- ----------------------------------------------------------------------------
-- 9. Comment style guide (recommended for this course)
-- ----------------------------------------------------------------------------
-- Header block for each file:           /* ... */
-- Section dividers:                     -- ===== lines
-- Per-line explanations:                -- at end of line
-- Commenting out a line of code:        -- prefix the line
-- Multi-line temporary disable:         /* ... */

-- ----------------------------------------------------------------------------
-- 10. EXERCISES
-- ----------------------------------------------------------------------------
-- EASY
-- E1.  Write a SELECT with a single-line `-- ` comment explaining each
--      column.
-- E2.  Write a SELECT with a multi-line `/* */` header comment.
--
-- MEDIUM
-- E3.  Explain in a comment why `SELECT 5 -- 3;` returns 2 in MySQL.
-- E4.  Write a query using an inline comment to mark which WHERE condition
--      is a "business rule" vs. a "performance filter".
--
-- HARD
-- E5.  Write a CREATE TABLE statement that uses /*!ENGINE=InnoDB */ so it
--      runs on MySQL (creating an InnoDB table) and is ignored on PostgreSQL.
--
-- EXPERT
-- E6.  Explain in a comment the difference between a regular comment, an
--      executable comment /*! ... */, and an optimizer hint /*+ ... */.
--      When would you use each?
-- ============================================================================

-- End of file 09_comments.sql
