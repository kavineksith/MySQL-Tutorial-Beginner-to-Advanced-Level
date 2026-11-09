-- ============================================================================
-- 06_events.sql — Scheduled Events (MySQL's cron)
-- ============================================================================
-- SKILL LEVEL : Advanced
-- TOPICS      : CREATE EVENT, EVERY / AT schedules, ON COMPLETION PRESERVE,
--               ENABLE / DISABLE, event_scheduler variable, monitoring.
-- ----------------------------------------------------------------------------
-- TEXTBOOK DEPTH
--   The MySQL Event Scheduler runs SQL statements on a schedule, similar to
--   Unix cron. It runs INSIDE the database, so it has full access to all
--   tables and works regardless of whether your app is online.
--
--   Common uses:
--     * Nightly data archival or summarization.
--     * Periodic cleanup of stale sessions or temp tables.
--     * Refreshing materialized-view-style summary tables.
--     * Generating periodic reports.
--     * Sending notifications via a stored procedure (with UDFs).
--
--   Enable the scheduler:
--     SET GLOBAL event_scheduler = ON;
--     (or set in my.cnf: event_scheduler=ON)
--
--   Schedule syntax:
--     EVERY 1 HOUR
--     EVERY 1 DAY STARTS '2024-01-01 03:00:00'
--     EVERY 1 MONTH STARTS '2024-01-01' ENDS '2025-01-01'
--     AT CURRENT_TIMESTAMP + INTERVAL 1 HOUR   (one-shot)
--
--   Notes:
--     * Events fire in the time zone of the server (time_zone system var).
--     * ON COMPLETION NOT PRESERVE drops the event after it has run its
--       last scheduled occurrence. PRESERVE keeps the definition.
--     * Events show up in information_schema.EVENTS.
-- ============================================================================

USE ecom;

-- Enable the scheduler (requires SUPER privilege)
-- SET GLOBAL event_scheduler = ON;
SHOW VARIABLES LIKE 'event_scheduler';

-- ----------------------------------------------------------------------------
-- 1. Create a one-shot event — runs once in the future
-- ----------------------------------------------------------------------------
DROP EVENT IF EXISTS ev_one_shot;

CREATE EVENT ev_one_shot
ON SCHEDULE AT CURRENT_TIMESTAMP + INTERVAL 1 HOUR
ON COMPLETION NOT PRESERVE
DO
    INSERT INTO categories (parent_id, name, slug, description)
    VALUES (NULL, 'Auto-Added By Event', 'auto-event-1', 'Created by ev_one_shot');

-- ----------------------------------------------------------------------------
-- 2. Create a recurring event — runs every hour
-- ----------------------------------------------------------------------------
DROP EVENT IF EXISTS ev_cleanup_temp;

CREATE EVENT ev_cleanup_temp
ON SCHEDULE EVERY 1 HOUR
STARTS CURRENT_TIMESTAMP
ON COMPLETION PRESERVE
ENABLE
COMMENT 'Hourly cleanup of expired temporary data'
DO
    BEGIN
        -- Example: archive orders older than 1 year with status='cancelled'
        -- INSERT INTO orders_archive SELECT * FROM orders WHERE order_date < NOW() - INTERVAL 1 YEAR AND status = 'cancelled';
        -- DELETE FROM orders WHERE order_date < NOW() - INTERVAL 1 YEAR AND status = 'cancelled';

        -- For the demo, just log a row in a temp table
        CREATE TABLE IF NOT EXISTS tmp_event_log (
            id INT AUTO_INCREMENT PRIMARY KEY,
            fired_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            msg VARCHAR(100)
        );
        INSERT INTO tmp_event_log (msg) VALUES (CONCAT('cleanup ran at ', NOW()));
    END;

-- ----------------------------------------------------------------------------
-- 3. Create a daily event at a specific time
-- ----------------------------------------------------------------------------
DROP EVENT IF EXISTS ev_daily_summary;

CREATE EVENT ev_daily_summary
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP + INTERVAL 1 DAY
ON COMPLETION PRESERVE
DO
    INSERT INTO tmp_event_log (msg)
    VALUES (CONCAT('daily summary ran at ', NOW()));

-- ----------------------------------------------------------------------------
-- 4. Create an event with multiple statements (BEGIN ... END)
-- ----------------------------------------------------------------------------
DROP EVENT IF EXISTS ev_complex;

DELIMITER //
CREATE EVENT ev_complex
ON SCHEDULE EVERY 1 WEEK
STARTS '2024-01-07 03:00:00'
ON COMPLETION PRESERVE
DO
BEGIN
    -- Step 1: archive old cancelled orders
    -- INSERT INTO orders_archive
    -- SELECT * FROM orders
    -- WHERE order_date < NOW() - INTERVAL 6 MONTH
    --   AND status = 'cancelled';

    -- Step 2: clean up old session tokens
    -- DELETE FROM sessions WHERE expires_at < NOW();

    -- Step 3: log the run
    INSERT INTO tmp_event_log (msg) VALUES (CONCAT('weekly archive at ', NOW()));
END //
DELIMITER ;

-- ----------------------------------------------------------------------------
-- 5. DISABLE / ENABLE an event
-- ----------------------------------------------------------------------------
ALTER EVENT ev_cleanup_temp DISABLE;
ALTER EVENT ev_cleanup_temp ENABLE;

-- ----------------------------------------------------------------------------
-- 6. Rename an event
-- ----------------------------------------------------------------------------
-- ALTER EVENT ev_complex RENAME TO ev_weekly_archive;

-- ----------------------------------------------------------------------------
-- 7. Inspect events
-- ----------------------------------------------------------------------------
SHOW EVENTS LIKE 'ev_%';

SELECT
    EVENT_NAME,
    EVENT_TYPE,
    EXECUTE_AT,
    INTERVAL_VALUE,
    INTERVAL_FIELD,
    STATUS,
    LAST_EXECUTED
FROM information_schema.EVENTS
WHERE EVENT_SCHEMA = 'ecom';

-- ----------------------------------------------------------------------------
-- 8. Drop events
-- ----------------------------------------------------------------------------
DROP EVENT IF EXISTS ev_one_shot;
DROP EVENT IF EXISTS ev_cleanup_temp;
DROP EVENT IF EXISTS ev_daily_summary;
DROP EVENT IF EXISTS ev_complex;

DROP TABLE IF EXISTS tmp_event_log;

-- ----------------------------------------------------------------------------
-- 9. EXERCISES
-- ----------------------------------------------------------------------------
-- EASY
-- E1.  Create a one-shot event that fires 1 minute from now and inserts a
--      row into a temp log table.
-- E2.  Create an event that fires every 1 minute and logs the current
--      time to a temp table. Disable it after a minute.
--
-- MEDIUM
-- E3.  Create a daily event that fires at 03:00 every day and would
--      archive cancelled orders older than 6 months (just write the SQL,
--      don't actually delete).
-- E4.  Create a weekly event that runs a multi-statement body: archive
--      old data, log the run.
--
-- HARD
-- E5.  Build a "materialized view" refresh job: a daily event that
--      recomputes the per-customer total spend table from orders.
--
-- EXPERT
-- E6.  Explain in a comment when you'd choose MySQL events vs an external
--      scheduler like cron, Airflow, or Sidekiq. What are the trade-offs?
-- ============================================================================

-- End of file 06_events.sql
