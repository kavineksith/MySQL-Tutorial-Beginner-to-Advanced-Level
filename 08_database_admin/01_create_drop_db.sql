-- ============================================================================
-- 01_create_drop_db.sql — CREATE / DROP DATABASE
-- ============================================================================
-- SKILL LEVEL : Beginner→Intermediate
-- TOPICS      : CREATE DATABASE, IF NOT EXISTS, CHARACTER SET, COLLATE,
--               ALTER DATABASE, DROP DATABASE, SHOW DATABASES, schema
--               migration patterns.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. CREATE DATABASE — basic
-- ----------------------------------------------------------------------------
-- Already done in 00_setup/00_schema.sql — review:
--   CREATE DATABASE ecom CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;

CREATE DATABASE IF NOT EXISTS tmp_demo_db;
SHOW DATABASES LIKE 'tmp_demo_%';

-- ----------------------------------------------------------------------------
-- 2. CHARACTER SET and COLLATE
-- ----------------------------------------------------------------------------
-- CHARACTER SET = how characters are encoded in storage.
-- COLLATE      = how strings are compared/sorted.
--
-- MySQL 8 default: utf8mb4_0900_ai_ci
--   utf8mb4  — full Unicode including 4-byte chars (emojis)
--   0900     — Unicode Collation Algorithm 9.0
--   _ai      — accent-insensitive (café == cafe)
--   _ci      — case-insensitive (Alice == alice)
-- Use utf8mb4_0900_as_cs for case-sensitive, accent-sensitive comparisons.

DROP DATABASE IF EXISTS tmp_demo_db;
CREATE DATABASE tmp_demo_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_0900_ai_ci;

SHOW CREATE DATABASE tmp_demo_db;

-- ----------------------------------------------------------------------------
-- 3. ALTER DATABASE — change character set / collation
-- ----------------------------------------------------------------------------
ALTER DATABASE tmp_demo_db CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_as_cs;
SHOW CREATE DATABASE tmp_demo_db;

-- ----------------------------------------------------------------------------
-- 4. CREATE DATABASE with IF NOT EXISTS — idempotent
-- ----------------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS tmp_demo_db;
-- No error if it already exists.

-- ----------------------------------------------------------------------------
-- 5. USE — select the current database
-- ----------------------------------------------------------------------------
USE tmp_demo_db;
SELECT DATABASE() AS current_db;

-- ----------------------------------------------------------------------------
-- 6. SHOW DATABASES — list all databases
-- ----------------------------------------------------------------------------
SHOW DATABASES;

-- ----------------------------------------------------------------------------
-- 7. DROP DATABASE — destructive!
-- ----------------------------------------------------------------------------
DROP DATABASE IF EXISTS tmp_demo_db;
SHOW DATABASES LIKE 'tmp_demo_%';   -- should be empty

-- ----------------------------------------------------------------------------
-- 8. Schema migration pattern
-- ----------------------------------------------------------------------------
-- Drop and recreate is common during dev. In prod, use migrations.

-- Drop and recreate ecom (DO NOT RUN — would destroy your seed data)
-- DROP DATABASE IF EXISTS ecom;
-- CREATE DATABASE ecom CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;

-- ----------------------------------------------------------------------------
-- 9. Inspecting schema info via information_schema
-- ----------------------------------------------------------------------------
USE ecom;
SELECT
    TABLE_NAME,
    ENGINE,
    TABLE_COLLATION,
    TABLE_ROWS,
    DATA_LENGTH,
    CREATE_TIME
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'ecom'
ORDER BY TABLE_NAME;

-- ----------------------------------------------------------------------------
-- 10. EXERCISES
-- ----------------------------------------------------------------------------
-- EASY
-- E1.  Create a database called `tmp_practice` with the default character
--      set and collation. Then drop it.
-- E2.  List all databases you can see. Identify the `ecom` database.
--
-- MEDIUM
-- E3.  Create a database with case-sensitive collation. Insert two rows
--      that differ only in case, then verify a WHERE clause treats them as
--      distinct.
--
-- HARD
-- E4.  Write a script that drops and recreates the `ecom` database IF a
--      flag variable is set to 1, otherwise leaves it alone. (Hint: use
--      a prepared statement.)
--
-- EXPERT
-- E5.  Explain in a comment the difference between utf8mb4_0900_ai_ci and
--      utf8mb4_0900_as_cs. When would you choose each?
-- ============================================================================

-- End of file 01_create_drop_db.sql
