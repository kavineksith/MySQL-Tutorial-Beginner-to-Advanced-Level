-- ============================================================================
-- 04_constraints.sql — Constraints Overview
-- ============================================================================
-- SKILL LEVEL : Intermediate
-- TOPICS      : NOT NULL, UNIQUE, PRIMARY KEY, FOREIGN KEY, CHECK, DEFAULT,
--               when to use each, enforcement in MySQL 8.
-- ----------------------------------------------------------------------------
-- TEXTBOOK DEPTH
--   Constraints are declarative rules the database enforces on data. They
--   protect integrity WITHOUT application code. Constraints are checked at
--   INSERT/UPDATE time and ABORT the statement if violated.
--
--   Constraint types (in order of enforcement strictness):
--     NOT NULL      — column cannot be NULL.
--     UNIQUE        — column (or combo) value must be unique across rows.
--     PRIMARY KEY   — NOT NULL + UNIQUE + clustered index. One per table.
--     FOREIGN KEY   — value must exist in the referenced parent column.
--     CHECK         — arbitrary predicate must be TRUE (or NULL).
--     DEFAULT       — value used when INSERT omits the column.
--
--   MySQL 8.0.16+ ENFORCES CHECK constraints. Before that, they were parsed
--   but ignored.
--
--   General principle: prefer constraints over triggers or app validation.
--   Constraints are atomic, can't be bypassed (e.g., by direct table edits),
--   and document the schema.
-- ============================================================================

USE ecom;

-- ----------------------------------------------------------------------------
-- 1. Demonstrate all constraint types in one table
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS tmp_constraint_demo;
DROP TABLE IF EXISTS tmp_constraint_parent;

CREATE TABLE tmp_constraint_parent (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(40) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE tmp_constraint_demo (
    -- NOT NULL + AUTO_INCREMENT + PRIMARY KEY (the canonical PK pattern)
    id             INT          NOT NULL AUTO_INCREMENT,
    -- UNIQUE constraint (column-level)
    email          VARCHAR(255) NOT NULL,
    -- DEFAULT constraint
    is_active      TINYINT(1)   NOT NULL DEFAULT 1,
    -- FOREIGN KEY reference
    parent_id      INT          NULL,
    -- CHECK constraint on a single column
    age            INT          NULL,
    -- Composite UNIQUE (multi-column) declared at table level
    region_code    VARCHAR(10)  NULL,
    customer_no    INT          NULL,
    -- Multi-column CHECK
    start_date     DATE         NULL,
    end_date       DATE         NULL,

    PRIMARY KEY (id),
    UNIQUE KEY uq_demo_email (email),
    UNIQUE KEY uq_demo_region_custno (region_code, customer_no),
    KEY idx_demo_parent (parent_id),
    CONSTRAINT fk_demo_parent
        FOREIGN KEY (parent_id) REFERENCES tmp_constraint_parent(id)
        ON DELETE SET NULL,
    CONSTRAINT chk_demo_age CHECK (age IS NULL OR (age >= 0 AND age <= 150)),
    CONSTRAINT chk_demo_dates CHECK (end_date IS NULL OR start_date IS NULL OR end_date >= start_date)
) ENGINE=InnoDB;

DESCRIBE tmp_constraint_demo;
SHOW CREATE TABLE tmp_constraint_demo\G

-- ----------------------------------------------------------------------------
-- 2. NOT NULL violation — error 1048
-- ----------------------------------------------------------------------------
-- INSERT INTO tmp_constraint_demo (email) VALUES (NULL);
-- ERROR 1048 (23000): Column 'email' cannot be null

-- ----------------------------------------------------------------------------
-- 3. UNIQUE violation — error 1062
-- ----------------------------------------------------------------------------
INSERT INTO tmp_constraint_demo (email) VALUES ('unique1@x.com');
-- INSERT INTO tmp_constraint_demo (email) VALUES ('unique1@x.com');
-- ERROR 1062 (23000): Duplicate entry 'unique1@x.com' for key 'uq_demo_email'

-- ----------------------------------------------------------------------------
-- 4. FOREIGN KEY violation — error 1452
-- ----------------------------------------------------------------------------
-- INSERT INTO tmp_constraint_demo (email, parent_id) VALUES ('fk@x.com', 999);
-- ERROR 1452 (23000): Cannot add or update a child row: a foreign key constraint fails

INSERT INTO tmp_constraint_parent (name) VALUES ('Parent X');
INSERT INTO tmp_constraint_demo (email, parent_id) VALUES ('fk@x.com', 1);

-- ----------------------------------------------------------------------------
-- 5. FOREIGN KEY ON DELETE behavior
-- ----------------------------------------------------------------------------
DELETE FROM tmp_constraint_parent WHERE id = 1;
-- The FK is declared ON DELETE SET NULL, so the child's parent_id becomes NULL.
SELECT id, email, parent_id FROM tmp_constraint_demo WHERE email = 'fk@x.com';

-- ----------------------------------------------------------------------------
-- 6. CHECK violation — error 3819 (MySQL 8.0.16+)
-- ----------------------------------------------------------------------------
-- INSERT INTO tmp_constraint_demo (email, age) VALUES ('check@x.com', 200);
-- ERROR 3819 (23000): Check constraint 'chk_demo_age' is violated.

INSERT INTO tmp_constraint_demo (email, age) VALUES ('ok@x.com', 42);   -- OK

-- ----------------------------------------------------------------------------
-- 7. Composite UNIQUE — only the combo must be unique
-- ----------------------------------------------------------------------------
INSERT INTO tmp_constraint_demo (email, region_code, customer_no)
VALUES ('r1@x.com', 'US', 1), ('r2@x.com', 'US', 2);   -- both OK (same region, diff cust)

-- INSERT INTO tmp_constraint_demo (email, region_code, customer_no)
-- VALUES ('r3@x.com', 'US', 1);   -- ERROR 1062: violates uq_demo_region_custno

-- ----------------------------------------------------------------------------
-- 8. Multi-column CHECK (date range)
-- ----------------------------------------------------------------------------
INSERT INTO tmp_constraint_demo (email, start_date, end_date)
VALUES ('d1@x.com', '2024-01-01', '2024-12-31');   -- OK (end >= start)

-- INSERT INTO tmp_constraint_demo (email, start_date, end_date)
-- VALUES ('d2@x.com', '2024-12-31', '2024-01-01');
-- ERROR 3819: chk_demo_dates violated

-- ----------------------------------------------------------------------------
-- 9. DEFAULT — when INSERT omits the column
-- ----------------------------------------------------------------------------
INSERT INTO tmp_constraint_demo (email) VALUES ('default@x.com');
SELECT id, email, is_active FROM tmp_constraint_demo WHERE email = 'default@x.com';
-- is_active = 1 (from DEFAULT)

-- ----------------------------------------------------------------------------
-- 10. Inspecting constraints via information_schema
-- ----------------------------------------------------------------------------
SELECT
    CONSTRAINT_NAME,
    CONSTRAINT_TYPE
FROM information_schema.TABLE_CONSTRAINTS
WHERE TABLE_SCHEMA = 'ecom' AND TABLE_NAME = 'tmp_constraint_demo';

SELECT
    CONSTRAINT_NAME,
    CHECK_CLAUSE
FROM information_schema.CHECK_CONSTRAINTS
WHERE CONSTRAINT_SCHEMA = 'ecom' AND TABLE_NAME = 'tmp_constraint_demo';

-- ----------------------------------------------------------------------------
-- 11. Drop constraint patterns
-- ----------------------------------------------------------------------------
-- Drop a CHECK constraint:
ALTER TABLE tmp_constraint_demo DROP CONSTRAINT chk_demo_age;

-- Drop a UNIQUE constraint (drops the underlying index too):
ALTER TABLE tmp_constraint_demo DROP INDEX uq_demo_email;

-- Drop a FOREIGN KEY (drop the constraint, not the column):
-- ALTER TABLE tmp_constraint_demo DROP FOREIGN KEY fk_demo_parent;

DROP TABLE tmp_constraint_demo;
DROP TABLE tmp_constraint_parent;

-- ----------------------------------------------------------------------------
-- 12. EXERCISES
-- ----------------------------------------------------------------------------
-- EASY
-- E1.  Create a table `tmp_accounts` with a NOT NULL `email` column. Try
--      inserting NULL to see the error.
-- E2.  Create a table with a UNIQUE constraint on `username`. Insert two
--      rows with the same username to see the error.
--
-- MEDIUM
-- E3.  Create a parent and child table with a FOREIGN KEY relationship.
--      Try inserting a child with a non-existent parent_id to see the
--      error.
-- E4.  Create a CHECK constraint ensuring `price >= 0` on a products-like
--      table. Try inserting a negative price to see the error.
--
-- HARD
-- E5.  Create a composite UNIQUE constraint on (region_code, customer_no).
--      Demonstrate that the same customer_no is allowed in different
--      regions but not in the same region.
--
-- EXPERT
-- E6.  Explain in a comment why CHECK constraints were a "fake" feature
--      before MySQL 8.0.16, and what changed in 8.0.16+. Verify the
--      current version with SELECT VERSION().
-- ============================================================================

-- End of file 04_constraints.sql
