-- ============================================================================
-- 06_auto_increment_dates.sql — AUTO_INCREMENT & Working with Dates
-- ============================================================================
-- SKILL LEVEL : Intermediate
-- TOPICS      : AUTO_INCREMENT, LAST_INSERT_ID, start value, gap behavior,
--               DATE/DATETIME/TIMESTAMP types, date functions, date
--               arithmetic, time zones, UNIX timestamps.
-- ============================================================================

USE ecom;

-- ============================================================================
-- AUTO_INCREMENT
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. AUTO_INCREMENT basics
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS tmp_autoinc;
CREATE TABLE tmp_autoinc (
    id  BIGINT NOT NULL AUTO_INCREMENT,
    val VARCHAR(20),
    PRIMARY KEY (id)
) ENGINE=InnoDB;

INSERT INTO tmp_autoinc (val) VALUES ('a'), ('b'), ('c');
SELECT * FROM tmp_autoinc;
-- ids 1, 2, 3.

-- ----------------------------------------------------------------------------
-- 2. LAST_INSERT_ID() — get the auto id of the last INSERT
-- ----------------------------------------------------------------------------
INSERT INTO tmp_autoinc (val) VALUES ('d');
SELECT LAST_INSERT_ID() AS last_id;
-- Returns 4 (per-connection, last INSERT only).

-- Multiple-row INSERT returns the FIRST generated id:
INSERT INTO tmp_autoinc (val) VALUES ('e'), ('f'), ('g');
SELECT LAST_INSERT_ID() AS first_id_of_batch;
-- Returns 5 (first of the batch). Use LAST_INSERT_ID() + n to compute others.

-- ----------------------------------------------------------------------------
-- 3. AUTO_INCREMENT start value
-- ----------------------------------------------------------------------------
DROP TABLE tmp_autoinc;
CREATE TABLE tmp_autoinc (
    id BIGINT NOT NULL AUTO_INCREMENT,
    val VARCHAR(20),
    PRIMARY KEY (id)
) AUTO_INCREMENT = 1000;

INSERT INTO tmp_autoinc (val) VALUES ('a'), ('b');
SELECT * FROM tmp_autoinc;   -- ids 1000, 1001

-- ----------------------------------------------------------------------------
-- 4. Gaps in AUTO_INCREMENT — they happen and are normal
-- ----------------------------------------------------------------------------
-- Gaps can occur from:
--   * Failed INSERTs (constraint violation, deadlock)
--   * Explicit DELETE of a row
--   * INSERT IGNORE that skips a duplicate
--   * ROLLBACK
-- InnoDB does NOT reuse gaps. This is by design — concurrent INSERTs
-- shouldn't block on the AUTO_INC lock.

INSERT INTO tmp_autoinc (val) VALUES ('c');   -- id 1002
INSERT IGNORE INTO tmp_autoinc (val) VALUES ('c');   -- skipped (no constraint though)
DELETE FROM tmp_autoinc WHERE id = 1002;
INSERT INTO tmp_autoinc (val) VALUES ('d');   -- id 1003 (not 1002 — gap left)

SELECT * FROM tmp_autoinc;

-- ----------------------------------------------------------------------------
-- 5. Resetting AUTO_INCREMENT
-- ----------------------------------------------------------------------------
ALTER TABLE tmp_autoinc AUTO_INCREMENT = 5000;
INSERT INTO tmp_autoinc (val) VALUES ('e');
SELECT * FROM tmp_autoinc ORDER BY id DESC LIMIT 1;
-- id = 5000

DROP TABLE tmp_autoinc;

-- ============================================================================
-- DATES — DATE, DATETIME, TIMESTAMP, TIME, YEAR
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 6. Date/time data types
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS tmp_dates;
CREATE TABLE tmp_dates (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    d_date      DATE,                       -- '2024-01-15' (3 bytes)
    t_time      TIME,                       -- '14:30:00'   (3 bytes)
    dt_datetime DATETIME,                   -- '2024-01-15 14:30:00' (8 bytes)
    ts_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- epoch-based, 4 bytes
    y_year      YEAR                        -- 2024 (1 byte)
);

INSERT INTO tmp_dates (d_date, t_time, dt_datetime, y_year)
VALUES
    ('2024-01-15', '14:30:00', '2024-01-15 14:30:00', 2024),
    ('2024-06-30', '09:15:30', '2024-06-30 09:15:30', 2024);

SELECT * FROM tmp_dates;

-- ----------------------------------------------------------------------------
-- 7. TIMESTAMP vs DATETIME — critical differences
-- ----------------------------------------------------------------------------
-- DATETIME:  stores a literal date/time, no zone conversion. 8 bytes. Range
--            1000-01-01 to 9999-12-31.
-- TIMESTAMP: stored as Unix epoch UTC, converted to current session's
--            time_zone on read. 4 bytes. Range 1970-01-01 to 2038-01-19
--            (the "Y2038 problem").

-- Show current session time zone
SELECT @@session.time_zone AS session_tz;

-- ----------------------------------------------------------------------------
-- 8. Date functions
-- ----------------------------------------------------------------------------
SELECT
    NOW()              AS now_datetime,         -- 2024-MM-DD HH:MM:SS
    CURRENT_TIMESTAMP  AS current_ts,           -- same as NOW()
    CURDATE()          AS today_date,           -- YYYY-MM-DD
    CURTIME()          AS current_time,         -- HH:MM:SS
    UNIX_TIMESTAMP()   AS unix_epoch_seconds,   -- 17xxxxxxxx
    FROM_UNIXTIME(1700000000) AS from_epoch,
    UTC_TIMESTAMP()    AS utc_now;

-- ----------------------------------------------------------------------------
-- 9. Extracting parts of a date
-- ----------------------------------------------------------------------------
SELECT
    order_date,
    YEAR(order_date)      AS yr,
    MONTH(order_date)     AS mon,
    DAY(order_date)       AS dy,
    HOUR(order_date)      AS hr,
    MINUTE(order_date)    AS mn,
    SECOND(order_date)    AS sec,
    DAYOFWEEK(order_date) AS dow,        -- 1=Sunday, 7=Saturday
    DAYNAME(order_date)   AS day_name,
    MONTHNAME(order_date) AS month_name,
    QUARTER(order_date)   AS qtr,
    WEEK(order_date, 0)   AS week_num
FROM orders
LIMIT 3;

-- ----------------------------------------------------------------------------
-- 10. Date arithmetic
-- ----------------------------------------------------------------------------
SELECT
    order_date,
    DATE_ADD(order_date, INTERVAL 7 DAY)    AS plus_7_days,
    DATE_SUB(order_date, INTERVAL 1 MONTH)  AS minus_1_month,
    order_date + INTERVAL 1 YEAR            AS plus_1_year_alt,
    DATEDIFF(order_date, '2024-01-01')      AS days_since_jan1,
    TIMESTAMPDIFF(DAY, '2024-01-01', order_date) AS days_diff_alt,
    DATE_FORMAT(order_date, '%Y-%m-%d %H:%i') AS formatted
FROM orders
LIMIT 3;

-- ----------------------------------------------------------------------------
-- 11. Date comparison patterns
-- ----------------------------------------------------------------------------
-- "Orders placed in January 2024" — boundary-safe (handles TIMESTAMP).
SELECT id, order_date
FROM orders
WHERE order_date >= '2024-01-01' AND order_date < '2024-02-01';

-- "Orders placed today"
SELECT id, order_date FROM orders
WHERE order_date >= CURDATE() AND order_date < CURDATE() + INTERVAL 1 DAY;

-- "Orders placed in the last 30 days"
SELECT id, order_date FROM orders
WHERE order_date >= NOW() - INTERVAL 30 DAY;

-- ----------------------------------------------------------------------------
-- 12. DATE_FORMAT — custom formatting
-- ----------------------------------------------------------------------------
SELECT
    order_date,
    DATE_FORMAT(order_date, '%W, %M %e, %Y at %r') AS pretty_date,
    DATE_FORMAT(order_date, '%Y%m%d') AS compact_date,
    DATE_FORMAT(order_date, '%H:%i:%s') AS time_only
FROM orders LIMIT 3;

-- ----------------------------------------------------------------------------
-- 13. STR_TO_DATE — parse a string into a date
-- ----------------------------------------------------------------------------
SELECT STR_TO_DATE('15-01-2024', '%d-%m-%Y') AS parsed_eu_date;
SELECT STR_TO_DATE('Jan 15, 2024', '%b %e, %Y') AS parsed_us_date;

-- ----------------------------------------------------------------------------
-- 14. Grouping by date parts
-- ----------------------------------------------------------------------------
SELECT
    YEAR(order_date) AS yr, MONTH(order_date) AS mo,
    COUNT(*) AS order_count, SUM(total) AS revenue
FROM orders
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY yr, mo;

-- ----------------------------------------------------------------------------
-- 15. EXTRACT
-- ----------------------------------------------------------------------------
SELECT
    order_date,
    EXTRACT(YEAR_MONTH FROM order_date) AS year_month,
    EXTRACT(DAY FROM order_date)        AS day_only
FROM orders LIMIT 3;

-- ----------------------------------------------------------------------------
-- 16. Time zone conversion
-- ----------------------------------------------------------------------------
-- CONVERT_TZ(dt, from_tz, to_tz) — requires time zone data loaded.
SELECT CONVERT_TZ('2024-01-15 14:30:00', 'UTC', 'America/New_York') AS utc_to_ny;

DROP TABLE tmp_dates;

-- ----------------------------------------------------------------------------
-- 17. EXERCISES
-- ----------------------------------------------------------------------------
-- EASY
-- E1.  Create a table with an AUTO_INCREMENT id starting at 1000. Insert
--      three rows and verify the ids.
-- E2.  Write a query that returns orders placed in 2024.
--
-- MEDIUM
-- E3.  Find the day of the week for each order. Return order_id, day_name.
-- E4.  Compute the number of days between each order and the previous
--      order (by date) for the same customer. Use DATEDIFF.
--
-- HARD
-- E5.  Group orders by year-month and compute total revenue per month.
-- E6.  Use DATE_FORMAT to display each order_date as "Mon DD, YYYY - HH:MM AM".
--
-- EXPERT
-- E7.  Explain in a comment the difference between DATETIME and TIMESTAMP.
--      When would you choose each? What is the Y2038 problem?
-- ============================================================================

-- End of file 06_auto_increment_dates.sql
