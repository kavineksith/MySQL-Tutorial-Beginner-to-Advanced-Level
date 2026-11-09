-- ============================================================================
-- 01_sql_injection.sql — SQL Injection: Concepts and Defense
-- ============================================================================
-- SKILL LEVEL : Intermediate
-- TOPICS      : What SQL injection is, classic attack patterns, blind SQLi,
--               second-order SQLi, defense in depth, NEVER concatenate.
-- ----------------------------------------------------------------------------
-- TEXTBOOK DEPTH
--   SQL injection (SQLi) is the #1 web application security risk for
--   databases (OWASP Top 10 perennial). It occurs when user input is
--   concatenated into a SQL string and the user injects SQL syntax that
--   the developer never intended.
--
--   Classic example — a login form:
--     sql = "SELECT * FROM users WHERE email = '" + email + "' AND password = '" + password + "'"
--
--   Attacker enters email = "admin' --"  → resulting SQL:
--     SELECT * FROM users WHERE email = 'admin' --' AND password = '...'
--   The `--` comments out the rest. Authenticated as admin without a
--   password.
--
--   Attack vectors:
--     1. Classic SQLi — error messages reveal schema.
--     2. UNION-based — attacker appends UNION SELECT to exfiltrate other
--        tables' data.
--     3. Blind boolean — app returns TRUE/FALSE signal; attacker asks
--        yes/no questions to extract data bit by bit.
--     4. Time-based blind — attacker uses SLEEP() and measures response
--        time to extract one bit at a time.
--     5. Second-order SQLi — input is stored safely, then concatenated
--        into a query later (e.g., admin dashboard).
--
--   DEFENSE (in order of effectiveness):
--     1. Use PARAMETERIZED QUERIES / PREPARED STATEMENTS — the ONLY
--        complete defense. User input never becomes SQL syntax.
--     2. Use an ORM (Hibernate, SQLAlchemy, Eloquent) which parameterizes
--        by default.
--     3. Validate input (allowlist, not denylist).
--     4. Least-privilege DB user: app user can't DROP tables or read
--        other schemas.
--     5. Disable error messages in production (they leak schema info).
--     6. WAF as defense-in-depth (not a primary defense).
--
--   This file demonstrates attack patterns INSIDE MySQL for education.
--   NEVER run any of these patterns in production code.
-- ============================================================================

USE ecom;

-- ============================================================================
-- 1. NAIVE (VULNERABLE) PATTERN — string concatenation
-- ============================================================================
-- This is what NOT to do. We simulate it with PREPARE/EXECUTE using
-- string concatenation so you can SEE the attack working.

SET @user_input := 'alice.johnson@example.com'' -- ';

-- Vulnerable constructed query:
SET @vuln_sql := CONCAT(
    'SELECT id, first_name, email FROM customers WHERE email = ''',
    @user_input,
    ''''
);

SELECT @vuln_sql AS constructed_query;
-- Prints:
-- SELECT id, first_name, email FROM customers WHERE email = 'alice.johnson@example.com' -- '

-- The `-- ` comments out the trailing single quote, so the query is
-- syntactically valid. Let's execute it:
PREPARE stmt FROM @vuln_sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
-- Returns Alice's row even though we provided "malicious" input.

-- ============================================================================
-- 2. UNION-BASED EXFILTRATION
-- ============================================================================
-- Attacker enters an email that appends a UNION to dump other tables.
SET @attacker_email := 'x'' UNION SELECT id, username, password FROM mysql.user -- ';

SET @vuln_sql := CONCAT(
    'SELECT id, first_name, email FROM customers WHERE email = ''',
    @attacker_email,
    ''''
);

SELECT @vuln_sql AS constructed_query;
-- SELECT id, first_name, email FROM customers WHERE email = 'x' UNION SELECT id, username, password FROM mysql.user -- '

-- (We don't EXECUTE this because we'd need access to mysql.user. The
-- pattern is what matters: an attacker can read ANY table the connection
-- user has SELECT on.)

-- ============================================================================
-- 3. BLIND BOOLEAN — app signals TRUE/FALSE
-- ============================================================================
-- Attacker probes with: ' OR (SELECT SUBSTRING(email,1,1) FROM customers WHERE id=1) = 'a' -- '
-- If the page loads normally → TRUE → first char is 'a'. If it errors or
-- shows "no user" → FALSE. Iterate to extract any data character by
-- character.

-- ============================================================================
-- 4. TIME-BASED BLIND — when no error/visual signal is available
-- ============================================================================
-- Attacker uses SLEEP() to extract a bit at a time:
--   ' OR IF((SELECT ASCII(SUBSTRING(email,1,1)) FROM customers WHERE id=1) = 97, SLEEP(5), 0) -- '
-- If response takes 5s → first char's ASCII is 97 ('a'). Iterate.

-- ============================================================================
-- 5. SECOND-ORDER SQLi
-- ============================================================================
-- Input is stored safely via parameterized INSERT (so the dangerous chars
-- are not escaped — they're just data). Later, an admin report query
-- concatenates that stored value into a new SQL string, and the injection
-- fires.

-- Demo:
CREATE TEMPORARY TABLE tmp_usernames (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(80));
INSERT INTO tmp_usernames (name) VALUES ('alice'), ('bob''; DROP TABLE reviews; -- ');

-- Later, an admin runs:
SET @admin_sql := CONCAT('SELECT * FROM tmp_usernames WHERE name = ''',
                        (SELECT name FROM tmp_usernames WHERE id = 2), '''');
SELECT @admin_sql AS admin_query;
-- The stored name contained a single quote that breaks out of the string
-- literal. If executed, this would inject `; DROP TABLE reviews; --`.
-- (MySQL's PREPARE doesn't allow multi-statement, so this exact attack
-- fails in MySQL CLI — but PDO/mysqli_multi_query do allow it.)

DROP TEMPORARY TABLE tmp_usernames;

-- ============================================================================
-- 6. SAFE PATTERN — parameterized query (PREPARE with placeholders)
-- ============================================================================
-- Placeholders (?) keep user input as DATA, never as SQL syntax.
SET @user_input := 'alice.johnson@example.com'' OR 1=1 -- ';

PREPARE safe_stmt FROM
    'SELECT id, first_name, email FROM customers WHERE email = ?';
EXECUTE safe_stmt USING @user_input;
DEALLOCATE PREPARE safe_stmt;
-- Returns ZERO rows because no customer has the literal email
-- "alice.johnson@example.com' OR 1=1 -- " — that's just data now.

-- ============================================================================
-- 7. LEAST-PRIVILEGE defense
-- ============================================================================
-- Even if SQLi succeeds, damage is bounded by what the DB user can do.
-- NEVER use root for the application connection.

-- Application user should have only what it needs:
--   GRANT SELECT, INSERT, UPDATE, DELETE ON ecom.* TO 'app_user'@'web-host';
-- NO DROP, ALTER, GRANT, FILE, SUPER, etc.

-- Read-only reporting user:
--   GRANT SELECT ON ecom.* TO 'reporting_user'@'reporting-host';

-- ============================================================================
-- 8. Error message suppression
-- ============================================================================
-- In production, set:
--   SHOW VARIABLES LIKE 'log_error';
-- Don't expose raw MySQL errors to end users. Catch them server-side and
-- return generic messages.

-- ============================================================================
-- 9. EXERCISES
-- ============================================================================
-- EASY
-- E1.  Explain in a comment what SQL injection is and why string
--      concatenation is the cause.
-- E2.  Write a parameterized SELECT (PREPARE ... USING) that safely looks
--      up a customer by email.
--
-- MEDIUM
-- E3.  Demonstrate a UNION-based SQLi attack using string concatenation
--      in a PREPARE statement. Then show the parameterized version that
--      defeats it.
-- E4.  List the privileges an application DB user should have, and the
--      privileges it should NOT have.
--
-- HARD
-- E5.  Explain in a comment how time-based blind SQLi works. Provide an
--      example payload that would SLEEP(5) when the first character of a
--      secret column equals 'a'.
--
-- EXPERT
-- E6.  Explain in a comment why input validation (escaping quotes) is NOT
--      a complete defense against SQLi, and why parameterized queries are.
--      Provide a concrete example where escaping fails.
-- ============================================================================

-- End of file 01_sql_injection.sql
