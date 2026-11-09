-- ============================================================================
-- 05_triggers.sql — Triggers: Automated Row-Level Actions
-- ============================================================================
-- SKILL LEVEL : Advanced
-- TOPICS      : CREATE TRIGGER, BEFORE/AFTER INSERT/UPDATE/DELETE, NEW and
--               OLD pseudo-rows, FOLLOWS/PRECEDES ordering, multi-trigger
--               tables, audit log pattern, restrictions.
-- ----------------------------------------------------------------------------
-- TEXTBOOK DEPTH
--   A trigger is SQL code that runs automatically BEFORE or AFTER an
--   INSERT, UPDATE, or DELETE on a table. Use cases:
--     * Audit logging (record who changed what and when).
--     * Enforcing complex constraints CHECK can't express.
--     * Auto-populating derived columns (though generated columns are often
--       better for this).
--     * Synchronizing a summary table.
--
--   Trigger firing order:
--     BEFORE INSERT  → INSERT executes → AFTER INSERT
--     BEFORE UPDATE  → UPDATE executes → AFTER UPDATE
--     BEFORE DELETE  → DELETE executes → AFTER DELETE
--
--   Pseudo-rows:
--     NEW  — the row about to be inserted/updated. Modifiable in BEFORE.
--     OLD  — the row being replaced/deleted. Read-only.
--
--   Restrictions:
--     * A trigger cannot use START TRANSACTION, COMMIT, ROLLBACK.
--     * A trigger cannot return a result set (no SELECT without INTO).
--     * A trigger cannot recursively modify its OWN table.
--     * Each table can have up to 6 triggers (BEFORE/AFTER × 3 events).
--     * Use FOLLOWS/PRECEDES to order multiple triggers on the same event.
--
--   Caution: triggers fire per ROW, so bulk updates run trigger N times.
--   This can be slow. Test on production-sized data.
-- ============================================================================

USE ecom;

-- ----------------------------------------------------------------------------
-- 1. Set up an audit table for the test
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS tmp_customer_audit;
CREATE TABLE tmp_customer_audit (
    audit_id   BIGINT AUTO_INCREMENT PRIMARY KEY,
    action     VARCHAR(10),
    customer_id BIGINT,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    changed_by VARCHAR(80),
    before_row JSON,
    after_row  JSON
);

-- ----------------------------------------------------------------------------
-- 2. BEFORE INSERT trigger — set is_active default if not provided
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS tmp_demo_with_trigger;
CREATE TABLE tmp_demo_with_trigger (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50),
    is_active TINYINT(1)
);

DELIMITER //
DROP TRIGGER IF EXISTS tmp_demo_before_insert //
CREATE TRIGGER tmp_demo_before_insert
BEFORE INSERT ON tmp_demo_with_trigger
FOR EACH ROW
BEGIN
    IF NEW.is_active IS NULL THEN
        SET NEW.is_active = 1;
    END IF;
    IF NEW.name IS NULL OR NEW.name = '' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'name cannot be NULL or empty';
    END IF;
END //

-- ----------------------------------------------------------------------------
-- 3. AFTER INSERT trigger — audit log
-- ----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS tmp_demo_after_insert //
CREATE TRIGGER tmp_demo_after_insert
AFTER INSERT ON tmp_demo_with_trigger
FOR EACH ROW
BEGIN
    INSERT INTO tmp_customer_audit (action, customer_id, after_row)
    VALUES ('INSERT', NEW.id,
        JSON_OBJECT('id', NEW.id, 'name', NEW.name, 'is_active', NEW.is_active));
END //

-- ----------------------------------------------------------------------------
-- 4. AFTER UPDATE trigger — audit log with before/after
-- ----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS tmp_demo_after_update //
CREATE TRIGGER tmp_demo_after_update
AFTER UPDATE ON tmp_demo_with_trigger
FOR EACH ROW
BEGIN
    INSERT INTO tmp_customer_audit (action, customer_id, before_row, after_row)
    VALUES ('UPDATE', NEW.id,
        JSON_OBJECT('id', OLD.id, 'name', OLD.name, 'is_active', OLD.is_active),
        JSON_OBJECT('id', NEW.id, 'name', NEW.name, 'is_active', NEW.is_active));
END //

-- ----------------------------------------------------------------------------
-- 5. BEFORE DELETE trigger — capture the row before deletion
-- ----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS tmp_demo_before_delete //
CREATE TRIGGER tmp_demo_before_delete
BEFORE DELETE ON tmp_demo_with_trigger
FOR EACH ROW
BEGIN
    INSERT INTO tmp_customer_audit (action, customer_id, before_row)
    VALUES ('DELETE', OLD.id,
        JSON_OBJECT('id', OLD.id, 'name', OLD.name, 'is_active', OLD.is_active));
END //

DELIMITER ;

-- ----------------------------------------------------------------------------
-- 6. Test the triggers
-- ----------------------------------------------------------------------------
INSERT INTO tmp_demo_with_trigger (name, is_active) VALUES ('Alice', NULL);
SELECT * FROM tmp_demo_with_trigger;
-- is_active should be 1 (set by the BEFORE INSERT trigger).

-- Insert with empty name — should fail
-- INSERT INTO tmp_demo_with_trigger (name) VALUES ('');   -- SIGNAL error

INSERT INTO tmp_demo_with_trigger (name, is_active) VALUES ('Bob', 0);

-- Update
UPDATE tmp_demo_with_trigger SET is_active = 1 WHERE name = 'Bob';

-- Delete
DELETE FROM tmp_demo_with_trigger WHERE name = 'Bob';

-- Inspect the audit log
SELECT * FROM tmp_customer_audit ORDER BY audit_id;

-- ----------------------------------------------------------------------------
-- 7. SHOW TRIGGERS
-- ----------------------------------------------------------------------------
SHOW TRIGGERS LIKE 'tmp_demo_%';

-- ----------------------------------------------------------------------------
-- 8. Inspect via information_schema
-- ----------------------------------------------------------------------------
SELECT
    TRIGGER_NAME,
    EVENT_MANIPULATION,
    EVENT_OBJECT_TABLE,
    ACTION_TIMING,
    ACTION_STATEMENT
FROM information_schema.TRIGGERS
WHERE TRIGGER_SCHEMA = 'ecom';

-- ----------------------------------------------------------------------------
-- 9. DROP TRIGGER
-- ----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS tmp_demo_before_insert;
DROP TRIGGER IF EXISTS tmp_demo_after_insert;
DROP TRIGGER IF EXISTS tmp_demo_after_update;
DROP TRIGGER IF EXISTS tmp_demo_before_delete;

DROP TABLE tmp_demo_with_trigger;
DROP TABLE tmp_customer_audit;

-- ----------------------------------------------------------------------------
-- 10. Realistic trigger — enforce a complex business rule
-- ----------------------------------------------------------------------------
-- Prevent cancellation of an order that has already been shipped.
-- (CHECK constraints can't reference the OLD row to compare.)

DROP TABLE IF EXISTS tmp_orders_trig;
CREATE TABLE tmp_orders_trig LIKE orders;

DELIMITER //
DROP TRIGGER IF EXISTS tmp_orders_trig_before_update //
CREATE TRIGGER tmp_orders_trig_before_update
BEFORE UPDATE ON tmp_orders_trig
FOR EACH ROW
BEGIN
    IF OLD.status = 'shipped' AND NEW.status = 'cancelled' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot cancel an order that has already been shipped';
    END IF;
END //
DELIMITER ;

-- Test:
INSERT INTO tmp_orders_trig
SELECT * FROM orders WHERE id = 7;   -- status = 'shipped'

UPDATE tmp_orders_trig SET status = 'delivered' WHERE id = 7;   -- OK
UPDATE tmp_orders_trig SET status = 'cancelled' WHERE id = 7;   -- ERROR 45000

DROP TRIGGER tmp_orders_trig_before_update;
DROP TABLE tmp_orders_trig;

-- ----------------------------------------------------------------------------
-- 11. EXERCISES
-- ----------------------------------------------------------------------------
-- EASY
-- E1.  Create a BEFORE INSERT trigger on a temp table that sets a
--      created_at column to NOW() if NULL.
-- E2.  Create an AFTER INSERT trigger that logs the inserted row to an
--      audit table.
--
-- MEDIUM
-- E3.  Create BEFORE INSERT and AFTER UPDATE triggers that maintain an
--      audit log with the full OLD and NEW row as JSON.
-- E4.  Use a trigger to enforce a business rule: an order's status cannot
--      go backwards (e.g. delivered → shipped is forbidden).
--
-- HARD
-- E5.  Build a "soft delete" trigger: BEFORE DELETE captures the deleted
--      row into an audit table; AFTER DELETE updates a "deletion_count"
--      summary table.
--
-- EXPERT
-- E6.  Explain in a comment the performance implications of triggers on
--      bulk UPDATE/DELETE operations. When would you disable triggers
--      temporarily, and how?
-- ============================================================================

-- End of file 05_triggers.sql
