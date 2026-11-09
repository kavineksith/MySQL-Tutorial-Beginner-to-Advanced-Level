-- ============================================================================
-- 03_alter_table.sql — ALTER TABLE: Modifying Schema
-- ============================================================================
-- SKILL LEVEL : Intermediate
-- TOPICS      : ADD/DROP/RENAME/MODIFY column, ADD INDEX, DROP INDEX, ADD
--               constraint, rename table, change ENGINE, partitioning,
--               online DDL notes.
-- ============================================================================

USE ecom;

-- Use a temp table so we don't modify the real schema
CREATE TABLE tmp_alter_demo (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    email VARCHAR(100)
) ENGINE=InnoDB;

INSERT INTO tmp_alter_demo (name, email) VALUES ('Alice', 'a@x.com'), ('Bob', 'b@x.com');

-- ----------------------------------------------------------------------------
-- 1. ADD COLUMN
-- ----------------------------------------------------------------------------
ALTER TABLE tmp_alter_demo ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
DESCRIBE tmp_alter_demo;

-- ADD COLUMN at specific position (FIRST / AFTER col)
ALTER TABLE tmp_alter_demo ADD COLUMN status VARCHAR(20) AFTER name;
DESCRIBE tmp_alter_demo;

-- ----------------------------------------------------------------------------
-- 2. ADD multiple columns in one ALTER
-- ----------------------------------------------------------------------------
ALTER TABLE tmp_alter_demo
    ADD COLUMN updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    ADD COLUMN is_active TINYINT(1) NOT NULL DEFAULT 1;
DESCRIBE tmp_alter_demo;

-- ----------------------------------------------------------------------------
-- 3. DROP COLUMN
-- ----------------------------------------------------------------------------
ALTER TABLE tmp_alter_demo DROP COLUMN status;
DESCRIBE tmp_alter_demo;

-- ----------------------------------------------------------------------------
-- 4. MODIFY COLUMN — change type, default, NULL constraint
-- ----------------------------------------------------------------------------
ALTER TABLE tmp_alter_demo MODIFY COLUMN email VARCHAR(255) NOT NULL;
DESCRIBE tmp_alter_demo;

-- ----------------------------------------------------------------------------
-- 5. CHANGE COLUMN — rename and modify
-- ----------------------------------------------------------------------------
ALTER TABLE tmp_alter_demo CHANGE COLUMN name full_name VARCHAR(100) NOT NULL;
DESCRIBE tmp_alter_demo;

-- ----------------------------------------------------------------------------
-- 6. RENAME COLUMN (MySQL 8.0+ (SQL:2023 compatible where noted))
-- ----------------------------------------------------------------------------
ALTER TABLE tmp_alter_demo RENAME COLUMN email TO contact_email;
DESCRIBE tmp_alter_demo;

-- ----------------------------------------------------------------------------
-- 7. ADD INDEX
-- ----------------------------------------------------------------------------
ALTER TABLE tmp_alter_demo ADD INDEX idx_email (contact_email);
SHOW INDEX FROM tmp_alter_demo;

ALTER TABLE tmp_alter_demo ADD UNIQUE INDEX uq_email (contact_email);

-- ----------------------------------------------------------------------------
-- 8. DROP INDEX
-- ----------------------------------------------------------------------------
ALTER TABLE tmp_alter_demo DROP INDEX idx_email;
SHOW INDEX FROM tmp_alter_demo;

-- ----------------------------------------------------------------------------
-- 9. ADD CONSTRAINT (CHECK)
-- ----------------------------------------------------------------------------
ALTER TABLE tmp_alter_demo ADD CONSTRAINT chk_active CHECK (is_active IN (0, 1));
SHOW CREATE TABLE tmp_alter_demo\G

-- ----------------------------------------------------------------------------
-- 10. RENAME TABLE
-- ----------------------------------------------------------------------------
ALTER TABLE tmp_alter_demo RENAME TO tmp_renamed;
SHOW TABLES LIKE 'tmp_renamed%';
ALTER TABLE tmp_renamed RENAME TO tmp_alter_demo;

-- ----------------------------------------------------------------------------
-- 11. CHANGE ENGINE
-- ----------------------------------------------------------------------------
-- ALTER TABLE tmp_alter_demo ENGINE=MyISAM;   -- would lose FK and TX support
-- InnoDB → InnoDB is a no-op but rebuilds the table (expensive on large tables).

-- ----------------------------------------------------------------------------
-- 12. ADD FOREIGN KEY
-- ----------------------------------------------------------------------------
CREATE TABLE tmp_alter_parent (
    id INT AUTO_INCREMENT PRIMARY KEY,
    label VARCHAR(20)
) ENGINE=InnoDB;

ALTER TABLE tmp_alter_demo
    ADD COLUMN parent_id INT NULL AFTER id,
    ADD CONSTRAINT fk_alter_demo_parent
        FOREIGN KEY (parent_id) REFERENCES tmp_alter_parent(id)
        ON DELETE SET NULL;

SHOW CREATE TABLE tmp_alter_demo\G

-- ----------------------------------------------------------------------------
-- 13. DROP FOREIGN KEY
-- ----------------------------------------------------------------------------
ALTER TABLE tmp_alter_demo DROP FOREIGN KEY fk_alter_demo_parent;
ALTER TABLE tmp_alter_demo DROP COLUMN parent_id;

-- ----------------------------------------------------------------------------
-- 14. ALTER TABLE ... ALGORITHM=INPLACE / LOCK=NONE — online DDL
-- ----------------------------------------------------------------------------
-- MySQL 8 supports online DDL for most operations. Specify explicitly:
-- ALTER TABLE tmp_alter_demo ADD COLUMN test_col INT, ALGORITHM=INPLACE, LOCK=NONE;
-- INPLACE = no copy to a temp table (faster, less locking)
-- NONE    = no writes blocked during the operation
-- COPY    = full table copy (slowest, default for some operations)

-- ----------------------------------------------------------------------------
-- 15. Clean up
-- ----------------------------------------------------------------------------
DROP TABLE tmp_alter_demo;
DROP TABLE tmp_alter_parent;

-- ----------------------------------------------------------------------------
-- 16. EXERCISES
-- ----------------------------------------------------------------------------
-- EASY
-- E1.  Create a temp table with one column, then ALTER it to ADD a second
--      column.
-- E2.  ALTER a table to RENAME a column.
--
-- MEDIUM
-- E3.  Create a table with a CHECK constraint that an `age` column is
--      between 0 and 150. Try inserting an invalid value to see the error.
-- E4.  Use ALTER TABLE to add a UNIQUE index on an existing column.
--
-- HARD
-- E5.  Add a foreign key to an existing table with ALTER. Demonstrate the
--      FK enforcement by inserting an invalid child row.
--
-- EXPERT
-- E6.  Explain in a comment the difference between ALGORITHM=INPLACE and
--      ALGORITHM=COPY. Why does it matter for production DDL on large
--      tables?
-- ============================================================================

-- End of file 03_alter_table.sql
