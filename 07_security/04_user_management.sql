-- ============================================================================
-- 04_user_management.sql — User Accounts, Privileges, Roles
-- ============================================================================
-- SKILL LEVEL : Intermediate→Advanced
-- TOPICS      : CREATE USER, ALTER USER, DROP USER, GRANT, REVOKE, roles,
--               SET ROLE, password policies, resource limits, SSL/TLS,
--               auditing.
-- ----------------------------------------------------------------------------
-- TEXTBOOK DEPTH
--   User management in MySQL covers authentication, authorization, and
--   resource limits. Three layers:
--     1. AUTHENTICATION — who is the user? Verified by password, auth
--        plugin, SSL cert, etc.
--     2. AUTHORIZATION  — what can the user do? Controlled by GRANT/REVOKE
--        on databases, tables, columns, routines.
--     3. RESOURCE LIMITS — how much can the user do? Per-hour query count,
--        connection count, etc.
--
--   MySQL 8.0 added ROLES — named bundles of privileges that can be
--   granted to users. Much cleaner than managing privileges per user.
--
--   Privilege levels (most to least restrictive):
--     * Column-level: GRANT SELECT (col1, col2) ON db.tbl TO user;
--     * Table-level: GRANT SELECT ON db.tbl TO user;
--     * Database-level: GRANT SELECT ON db.* TO user;
--     * Global: GRANT SELECT ON *.* TO user;
--
--   Best practices:
--     * One DB user per application, with only the privileges it needs.
--     * Application user should NEVER have DROP, ALTER, GRANT, FILE, SUPER.
--     * Use roles for grouping privileges (dev_readonly, prod_app, etc.).
--     * Force TLS for non-localhost connections.
--     * Rotate passwords; never store them in code.
--     * Audit GRANTs regularly.
-- ============================================================================

-- NOTE: Most statements in this file require SUPER or CREATE USER privilege.
-- Run as root or a user with the necessary grants.

USE ecom;

-- ============================================================================
-- 1. CREATE USER — basic
-- ============================================================================
-- In MySQL 8, CREATE USER is the preferred way to make accounts. (Older
-- GRANT ... IDENTIFIED BY also worked but is deprecated.)

-- Create a local app user (only connects from localhost):
CREATE USER IF NOT EXISTS 'app_user'@'localhost'
    IDENTIFIED BY 'StrongP@ssw0rd!2024';

-- Create a remote app user (connects from any host):
CREATE USER IF NOT EXISTS 'app_user'@'%'
    IDENTIFIED BY 'StrongP@ssw0rd!2024';

-- ============================================================================
-- 2. Inspect users
-- ============================================================================
SELECT User, Host, account_locked, password_expired
FROM mysql.user
WHERE User IN ('app_user');

-- ============================================================================
-- 3. GRANT privileges
-- ============================================================================
-- Common DML privileges for an application user:
GRANT SELECT, INSERT, UPDATE, DELETE ON ecom.* TO 'app_user'@'localhost';

-- Read-only reporting user:
CREATE USER IF NOT EXISTS 'reporting_user'@'localhost' IDENTIFIED BY 'Rep0rtP@ss!';
GRANT SELECT ON ecom.* TO 'reporting_user'@'localhost';

-- DBA user (do NOT use for app connections):
CREATE USER IF NOT EXISTS 'dev_dba'@'localhost' IDENTIFIED BY 'DevDbaP@ss!';
GRANT ALL PRIVILEGES ON *.* TO 'dev_dba'@'localhost' WITH GRANT OPTION;

-- ============================================================================
-- 4. Show grants for a user
-- ============================================================================
SHOW GRANTS FOR 'app_user'@'localhost';
SHOW GRANTS FOR 'reporting_user'@'localhost';

-- ============================================================================
-- 5. REVOKE privileges
-- ============================================================================
REVOKE DELETE ON ecom.* FROM 'app_user'@'localhost';
SHOW GRANTS FOR 'app_user'@'localhost';

-- Re-grant to restore (just for the demo):
GRANT DELETE ON ecom.* TO 'app_user'@'localhost';

-- ============================================================================
-- 6. Column-level privileges
-- ============================================================================
-- Grant SELECT on only some columns of customers (hide sensitive ones).
CREATE USER IF NOT EXISTS 'public_api'@'localhost' IDENTIFIED BY 'ApiP@ss!';
GRANT SELECT (id, first_name, last_name, country, is_active)
    ON ecom.customers TO 'public_api'@'localhost';

SHOW GRANTS FOR 'public_api'@'localhost';

-- ============================================================================
-- 7. ROLES (MySQL 8.0+ (SQL:2023 compatible where noted)) — named bundles of privileges
-- ============================================================================
-- Create a role for read-only access:
CREATE ROLE IF NOT EXISTS 'read_only';
GRANT SELECT ON ecom.* TO 'read_only';

-- Create a role for write access:
CREATE ROLE IF NOT EXISTS 'app_writer';
GRANT SELECT, INSERT, UPDATE, DELETE ON ecom.* TO 'app_writer';

-- Grant roles to users:
CREATE USER IF NOT EXISTS 'analyst1'@'localhost' IDENTIFIED BY 'AnalystP@ss!';
CREATE USER IF NOT EXISTS 'analyst2'@'localhost' IDENTIFIED BY 'AnalystP@ss!';
GRANT 'read_only' TO 'analyst1'@'localhost';
GRANT 'read_only' TO 'analyst2'@'localhost';

CREATE USER IF NOT EXISTS 'service_x'@'localhost' IDENTIFIED BY 'SvcXP@ss!';
GRANT 'app_writer' TO 'service_x'@'localhost';

-- ============================================================================
-- 8. Set default roles — auto-enabled on login
-- ============================================================================
ALTER USER 'analyst1'@'localhost' DEFAULT ROLE 'read_only';
ALTER USER 'service_x'@'localhost' DEFAULT ROLE 'app_writer';

-- Manually enable a role for the current session:
-- SET ROLE 'read_only';
-- SET ROLE NONE;   -- disable all roles

-- See currently active roles:
SELECT CURRENT_ROLE();

-- ============================================================================
-- 9. ALTER USER — change password, expire, lock
-- ============================================================================
ALTER USER 'app_user'@'localhost' IDENTIFIED BY 'NewP@ssw0rd!2025';

-- Lock an account (e.g. ex-employee, suspected compromise):
ALTER USER 'app_user'@'%' ACCOUNT LOCK;
-- Unlock:
ALTER USER 'app_user'@'%' ACCOUNT UNLOCK;

-- Expire password (forces change on next login):
ALTER USER 'app_user'@'localhost' PASSWORD EXPIRE;

-- ============================================================================
-- 10. Resource limits — per-hour quotas
-- ============================================================================
ALTER USER 'app_user'@'localhost'
    WITH MAX_QUERIES_PER_HOUR 1000
         MAX_UPDATES_PER_HOUR 500
         MAX_CONNECTIONS_PER_HOUR 50
         MAX_USER_CONNECTIONS 10;

-- ============================================================================
-- 11. Require SSL/TLS
-- ============================================================================
-- Force TLS for a user connecting over the network:
-- ALTER USER 'app_user'@'%' REQUIRE SSL;
-- Require a specific X.509 certificate:
-- ALTER USER 'app_user'@'%' REQUIRE SUBJECT '/CN=app.example.com';

-- ============================================================================
-- 12. Password policy plugin (validate_password)
-- ============================================================================
-- If the validate_password plugin is loaded, passwords must meet policy:
SHOW VARIABLES LIKE 'validate_password%';
-- validate_password.length       8
-- validate_password.policy       MEDIUM  (LOW/MEDIUM/STRONG)
-- validate_password.mixed_case_count   1
-- validate_password.number_count       1
-- validate_password.special_char_count 1

-- ============================================================================
-- 13. DROP USER and REVOKE ALL
-- ============================================================================
-- Remove a user entirely:
DROP USER IF EXISTS 'public_api'@'localhost';
DROP USER IF EXISTS 'analyst1'@'localhost';
DROP USER IF EXISTS 'analyst2'@'localhost';
DROP USER IF EXISTS 'service_x'@'localhost';
DROP USER IF EXISTS 'reporting_user'@'localhost';
DROP USER IF EXISTS 'dev_dba'@'localhost';
DROP USER IF EXISTS 'app_user'@'localhost';
DROP USER IF EXISTS 'app_user'@'%';

-- Drop roles:
DROP ROLE IF EXISTS 'read_only';
DROP ROLE IF EXISTS 'app_writer';

-- ============================================================================
-- 14. Audit log (MySQL Enterprise Audit / community alternatives)
-- ============================================================================
-- Enterprise Audit logs all connection events and statements to a file.
-- SHOW VARIABLES LIKE 'audit_log%';

-- ============================================================================
-- 15. EXERCISES
-- ============================================================================
-- EASY
-- E1.  Create a user 'test_user'@'localhost' with password 'TestP@ss!'.
-- E2.  GRANT SELECT on the ecom database to test_user.
--
-- MEDIUM
-- E3.  Create a role 'reporting' that has SELECT on ecom.* and GRANT it
--      to a new user. Set it as the default role.
-- E4.  Create a column-level GRANT that exposes only id, first_name, and
--      last_name of customers (hiding email, phone, etc.).
--
-- HARD
-- E5.  Configure resource limits on a user: max 100 queries/hour, max 5
--      concurrent connections.
--
-- EXPERT
-- E6.  Explain in a comment why an application DB user should NEVER have
--      DROP, ALTER, GRANT OPTION, FILE, or SUPER privileges. Provide a
--      concrete attack scenario for each.
-- ============================================================================

-- End of file 04_user_management.sql
