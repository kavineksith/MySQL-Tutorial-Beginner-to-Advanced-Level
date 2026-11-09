-- ============================================================================
-- 03_prepared_statements.sql — Prepared Statements Deep Dive
-- ============================================================================
-- SKILL LEVEL : Intermediate
-- TOPICS      : PREPARE / EXECUTE / DEALLOCATE PREPARE, SQL syntax vs.
--               binary protocol, statement caching, performance benefits,
--               limitations, when NOT to use prepared statements.
-- ----------------------------------------------------------------------------
-- TEXTBOOK DEPTH
--   Prepared statements exist at TWO levels in MySQL:
--     1. SQL-level prepared statements — PREPARE stmt FROM '...?' inside
--        the mysql client or stored programs. Use SQL text + EXECUTE.
--     2. Binary-protocol prepared statements — used by drivers (PDO,
--        mysql2, JDBC). Use COM_STMT_PREPARE / COM_STMT_EXECUTE wire
--        commands. More efficient (no SQL text on each execution).
--
--   Benefits:
--     * SECURITY — parameters are data, never SQL syntax (no SQLi).
--     * PERFORMANCE — server parses the SQL ONCE, then executes N times
--       with different params. Reuse saves parsing and (often) planning.
--     * MEMORY — statement cache avoids re-preparing the same SQL.
--
--   Limitations:
--     * Placeholders only for VALUES, not identifiers (table/column names).
--     * Placeholders cannot replace SQL keywords or whole clauses.
--     * MySQL's prepared statement cache has a fixed size
--       (stmt_cache_size). Too many unique prepared statements can thrash.
--     * Some complex queries (certain JOINs with subqueries) had bugs in
--       older MySQL versions.
--
--   When NOT to use prepared statements:
--     * One-off ad-hoc queries (parsing cost > execution savings).
--     * When you need dynamic table/column names (use allowlist + concat).
-- ============================================================================

USE ecom;

-- ----------------------------------------------------------------------------
-- 1. SQL-level PREPARE / EXECUTE / DEALLOCATE
-- ----------------------------------------------------------------------------
PREPARE stmt FROM
    'SELECT id, first_name, last_name FROM customers WHERE country = ? AND is_active = ?';

SET @country := 'United States';
SET @active  := 1;
EXECUTE stmt USING @country, @active;

-- Re-execute with different params — parse cost is paid only ONCE:
SET @country := 'Japan';
SET @active  := 1;
EXECUTE stmt USING @country, @active;

DEALLOCATE PREPARE stmt;

-- ----------------------------------------------------------------------------
-- 2. PREPARE from a variable (dynamic SQL)
-- ----------------------------------------------------------------------------
SET @sql := CONCAT(
    'SELECT id, name, price FROM products WHERE category_id = ',
    (SELECT id FROM categories WHERE slug = 'laptops')
);

PREPARE dyn_stmt FROM @sql;
EXECUTE dyn_stmt;
DEALLOCATE PREPARE dyn_stmt;

-- ----------------------------------------------------------------------------
-- 3. PREPARE inside a stored procedure (dynamic SQL pattern)
-- ----------------------------------------------------------------------------
-- Useful when the WHERE clause or ORDER BY column is dynamic and you've
-- validated the input against an allowlist.

DROP PROCEDURE IF EXISTS sp_dynamic_lookup;
DELIMITER //
CREATE PROCEDURE sp_dynamic_lookup(IN p_country VARCHAR(60))
BEGIN
    -- Validate input against known set (allowlist)
    IF p_country NOT IN ('United States', 'United Kingdom', 'Canada',
                          'Australia', 'France', 'Japan') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Invalid country';
    END IF;

    SET @sql := CONCAT(
        'SELECT id, first_name, last_name, country FROM customers ',
        'WHERE country = ?'
    );
    PREPARE dyn FROM @sql;
    SET @c := p_country;
    EXECUTE dyn USING @c;
    DEALLOCATE PREPARE dyn;
END //
DELIMITER ;

CALL sp_dynamic_lookup('Japan');
-- CALL sp_dynamic_lookup('Narnia');   -- raises SIGNAL error

DROP PROCEDURE sp_dynamic_lookup;

-- ----------------------------------------------------------------------------
-- 4. Statement cache settings
-- ----------------------------------------------------------------------------
-- MySQL maintains a prepared statement cache. Inspect settings:
SHOW VARIABLES LIKE 'stmt_cache_size';
SHOW GLOBAL STATUS LIKE 'Com_stmt_prepare';
SHOW GLOBAL STATUS LIKE 'Com_stmt_execute';

-- ----------------------------------------------------------------------------
-- 5. Performance comparison — prepared vs. ad-hoc (illustrative)
-- ----------------------------------------------------------------------------
-- For N executions of the same query, prepared should be faster because
-- parsing happens once. For ONE execution, prepared has slight overhead.

DROP TABLE IF EXISTS tmp_perf;
CREATE TABLE tmp_perf (id INT AUTO_INCREMENT PRIMARY KEY, val INT);
INSERT INTO tmp_perf (val)
SELECT FLOOR(RAND() * 1000) FROM
    (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4) a,
    (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4) b,
    (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4) c,
    (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4) d;

-- Run a query 3 different ways
PREPARE s FROM 'SELECT COUNT(*) FROM tmp_perf WHERE val > ?';
SET @v := 500;
EXECUTE s USING @v;
EXECUTE s USING @v;
EXECUTE s USING @v;
DEALLOCATE PREPARE s;

SELECT COUNT(*) FROM tmp_perf WHERE val > 500;   -- ad-hoc — parses each time

DROP TABLE tmp_perf;

-- ----------------------------------------------------------------------------
-- 6. DEALLOCATE PREPARE — release server resources
-- ----------------------------------------------------------------------------
-- Always DEALLOCATE when done. Or the statement is freed automatically
-- when the session ends.

-- ----------------------------------------------------------------------------
-- 7. PREPARE limitations — what placeholders CANNOT do
-- ----------------------------------------------------------------------------
-- Cannot replace table name:
--   PREPARE s FROM 'SELECT * FROM ?';   -- ERROR 1064

-- Cannot replace column name:
--   PREPARE s FROM 'SELECT ? FROM customers';   -- ERROR 1064

-- Cannot replace ORDER BY direction:
--   PREPARE s FROM 'SELECT * FROM customers ORDER BY last_name ?';   -- ERROR

-- Cannot replace a whole IN list:
--   PREPARE s FROM 'SELECT * FROM customers WHERE id IN (?)';   -- only ONE id
--   -- Workaround: build the IN list as a string and interpolate (with care).

-- ----------------------------------------------------------------------------
-- 8. EXERCISES
-- ----------------------------------------------------------------------------
-- EASY
-- E1.  PREPARE a statement that selects customers WHERE country = ?.
--      Execute twice with different countries. DEALLOCATE.
-- E2.  PREPARE an INSERT with two placeholders. Execute 3 times with
--      different values.
--
-- MEDIUM
-- E3.  Write a stored procedure that uses dynamic SQL (PREPARE from @sql)
--      to filter customers by a validated country input.
-- E4.  Compare prepared vs ad-hoc execution of the same query 5 times.
--      Note any difference (subtle in our small dataset).
--
-- HARD
-- E5.  Demonstrate that PREPARE cannot use placeholders for table names
--      or column names. Provide the safe alternative (allowlist on app
--      side).
--
-- EXPERT
-- E6.  Explain in a comment when you should NOT use prepared statements
--      (e.g. one-off ad-hoc queries). Discuss the trade-offs of
--      statement caching.
-- ============================================================================

-- End of file 03_prepared_statements.sql
