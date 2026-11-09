-- ============================================================================
-- 07_security_solutions.sql — Solutions for 07_security
-- ============================================================================

USE ecom;

-- ============================================================================
-- 01_sql_injection.sql
-- ============================================================================

-- E1. SQL injection is...
-- When user-supplied input is concatenated into a SQL string and the user
-- injects SQL syntax (quotes, semicolons, comments) that breaks out of
-- the developer's intended structure. Cause: string concatenation.

-- E2. parameterized SELECT by email
PREPARE stmt FROM 'SELECT id, first_name, email FROM customers WHERE email = ?';
SET @e := 'alice.johnson@example.com';
EXECUTE stmt USING @e;
DEALLOCATE PREPARE stmt;

-- E3. UNION-based SQLi (vulnerable)
-- Vulnerable form (string concat in PREPARE):
SET @evil := 'x'' UNION SELECT id, first_name, name FROM customers -- ';
SET @sql := CONCAT('SELECT id, first_name, email FROM customers WHERE email = ''', @evil, '''');
SELECT @sql;
-- PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;
-- (MySQL PREPARE doesn't allow multi-statement; the UNION would still fire.)

-- Safe parameterized version:
PREPARE safe FROM 'SELECT id, first_name, email FROM customers WHERE email = ?';
EXECUTE safe USING @evil;   -- returns 0 rows; @evil is just data
DEALLOCATE PREPARE safe;

-- E4. App user privileges
-- SHOULD have: SELECT, INSERT, UPDATE, DELETE on the application DB.
-- SHOULD NOT have: DROP, ALTER, CREATE, GRANT OPTION, FILE, SUPER, RELOAD,
-- SHUTDOWN, PROCESS, REPLICATION CLIENT/SUPER.
-- This bounds the blast radius if SQLi succeeds.

-- E5. Time-based blind SQLi
-- Payload: ' OR IF((SELECT ASCII(SUBSTRING(email,1,1)) FROM customers WHERE id=1) = 97, SLEEP(5), 0) -- '
-- If response takes 5 seconds, the first char of customer 1's email has
-- ASCII 97 (i.e. 'a'). Iterate to extract any data one bit at a time.

-- E6. Why escaping is not a complete defense
-- Escaping single quotes (replace ' with '' or \') handles most cases
-- but fails in subtle ways:
--   * Numeric contexts: WHERE id = <user_input> — no quotes, escaping
--     doesn't apply.
--   * Different charsets: GBK / Big5 multi-byte sequences can swallow
--     the escape backslash (the classic "GBK injection").
--   * Second-order injection: stored data is later concatenated.
-- Parameterized queries treat input as binary data, NEVER as SQL syntax,
-- so they sidestep ALL of these. Use them always.

-- ============================================================================
-- 02_parameterized_queries.sql
-- ============================================================================

-- E1. parameterized SELECT price <= ?
PREPARE s FROM 'SELECT name, price FROM products WHERE price <= ? ORDER BY price';
SET @p := 200;
EXECUTE s USING @p;
DEALLOCATE PREPARE s;

-- E2. INSERT into temp with two placeholders
DROP TABLE IF EXISTS tmp_safe;
CREATE TABLE tmp_safe (id INT AUTO_INCREMENT PRIMARY KEY, a VARCHAR(20), b INT);
PREPARE ins FROM 'INSERT INTO tmp_safe (a, b) VALUES (?, ?)';
SET @a := 'hello'; SET @b := 42;
EXECUTE ins USING @a, @b;
SELECT * FROM tmp_safe;
DEALLOCATE PREPARE ins;
DROP TABLE tmp_safe;

-- E3. insert 3 customers with single-quote emails
DROP TABLE IF EXISTS tmp_q;
CREATE TABLE tmp_q (id INT AUTO_INCREMENT PRIMARY KEY, email VARCHAR(100));
PREPARE ins FROM 'INSERT INTO tmp_q (email) VALUES (?)';
SET @e1 := 'o''brien@x.com';
SET @e2 := 'alice''s@x.com';
SET @e3 := 'normal@x.com';
EXECUTE ins USING @e1;
EXECUTE ins USING @e2;
EXECUTE ins USING @e3;
SELECT * FROM tmp_q;
DEALLOCATE PREPARE ins;
DROP TABLE tmp_q;

-- E4. parameterized UPDATE
PREPARE upd FROM 'UPDATE customers SET is_active = ? WHERE country = ?';
SET @a := 0; SET @c := 'Japan';
EXECUTE upd USING @a, @c;
SELECT first_name, country, is_active FROM customers WHERE country = 'Japan';
DEALLOCATE PREPARE upd;
-- Restore
UPDATE customers SET is_active = 1 WHERE country = 'Japan';

-- E5. Why PREPARE doesn't accept ? for identifiers
-- SQL syntax is parsed at PREPARE time. The parser needs to know whether
-- `?` is a table name, column name, or value. Placeholders are only valid
-- where VALUES go — after =, IN (limited), VALUES (...), SET col = ?.
-- Safe alternative: validate table/column name against an allowlist on
-- the app side, then interpolate the validated name.

-- E6. Why parameterization defeats SQLi (protocol-level)
-- COM_STMT_PREPARE sends the SQL with `?` placeholders. The server parses
-- ONCE and stores an execution plan.
-- COM_STMT_EXECUTE sends only the parameter VALUES (binary-encoded). The
-- server binds each value to a placeholder in the already-parsed plan.
-- The values NEVER become SQL text — they are typed binary data. So
-- `'; DROP TABLE x; --` is just a string value, not SQL syntax.

-- ============================================================================
-- 03_prepared_statements.sql
-- ============================================================================

-- E1.
PREPARE s FROM 'SELECT first_name, last_name FROM customers WHERE country = ?';
SET @c := 'United States'; EXECUTE s USING @c;
SET @c := 'Japan';         EXECUTE s USING @c;
DEALLOCATE PREPARE s;

-- E2.
DROP TABLE IF EXISTS tmp_p;
CREATE TABLE tmp_p (id INT AUTO_INCREMENT PRIMARY KEY, a VARCHAR(20), b INT);
PREPARE ins FROM 'INSERT INTO tmp_p (a, b) VALUES (?, ?)';
SET @a := 'x'; SET @b := 1; EXECUTE ins USING @a, @b;
SET @a := 'y'; SET @b := 2; EXECUTE ins USING @a, @b;
SET @a := 'z'; SET @b := 3; EXECUTE ins USING @a, @b;
SELECT * FROM tmp_p;
DEALLOCATE PREPARE ins;
DROP TABLE tmp_p;

-- E3. dynamic SQL procedure (see source file for full implementation)
-- The pattern is: validate input against allowlist; build @sql via
-- CONCAT; PREPARE FROM @sql; EXECUTE USING @param; DEALLOCATE.

-- E4. Compare prepared vs ad-hoc (5 times each)
-- Run each 5 times; in our small dataset the difference is invisible.
-- On large data sets with parse-heavy queries, prepared should be faster.

-- E5. Limitation demo (these fail):
-- PREPARE s FROM 'SELECT * FROM ?';        -- ERROR: ? is a table name
-- PREPARE s FROM 'SELECT ? FROM tbl';      -- ERROR: ? is a column name
-- Safe alternative: allowlist + CONCAT the identifier on the app side.

-- E6. When NOT to use prepared statements
-- * One-off ad-hoc queries — parsing cost > execution savings.
-- * When you need dynamic table/column names (use allowlist + concat).
-- * Statement cache thrash: if every query is unique, the cache adds
--   overhead with no benefit.

-- ============================================================================
-- 04_user_management.sql
-- ============================================================================

-- E1. create test_user
CREATE USER IF NOT EXISTS 'test_user'@'localhost' IDENTIFIED BY 'TestP@ss!';

-- E2. GRANT SELECT on ecom
GRANT SELECT ON ecom.* TO 'test_user'@'localhost';
SHOW GRANTS FOR 'test_user'@'localhost';

-- E3. role 'reporting' + grant to new user + default role
CREATE ROLE IF NOT EXISTS 'reporting';
GRANT SELECT ON ecom.* TO 'reporting';
CREATE USER IF NOT EXISTS 'rep1'@'localhost' IDENTIFIED BY 'RepP@ss!';
GRANT 'reporting' TO 'rep1'@'localhost';
ALTER USER 'rep1'@'localhost' DEFAULT ROLE 'reporting';
SHOW GRANTS FOR 'rep1'@'localhost';

-- E4. column-level grant
CREATE USER IF NOT EXISTS 'col_user'@'localhost' IDENTIFIED BY 'ColP@ss!';
GRANT SELECT (id, first_name, last_name) ON ecom.customers TO 'col_user'@'localhost';
SHOW GRANTS FOR 'col_user'@'localhost';

-- E5. resource limits
ALTER USER 'test_user'@'localhost'
    WITH MAX_QUERIES_PER_HOUR 100
         MAX_USER_CONNECTIONS 5;

-- E6. Why app user should NEVER have DROP, ALTER, GRANT, FILE, SUPER:
-- DROP — attacker can destroy tables.
-- ALTER — attacker can add columns, drop constraints, or change schema
--         in ways that corrupt data.
-- GRANT OPTION — attacker can grant privileges to themselves or others,
--         escalating persistence.
-- FILE — attacker can read or write files on the DB server (e.g. read
--         /etc/passwd, write a webshell).
-- SUPER — attacker can kill connections, set GLOBAL variables, override
--         read-only mode, access replication.

-- Cleanup
DROP USER IF EXISTS 'test_user'@'localhost';
DROP USER IF EXISTS 'rep1'@'localhost';
DROP USER IF EXISTS 'col_user'@'localhost';
DROP ROLE IF EXISTS 'reporting';

-- End of file 07_security_solutions.sql
