-- ============================================================================
-- 02_create_table.sql — CREATE TABLE in Depth
-- ============================================================================
-- SKILL LEVEL : Intermediate
-- TOPICS      : Column definitions, data types, NOT NULL, DEFAULT, AUTO_INC,
--               PRIMARY KEY, UNIQUE, INDEX, FULLTEXT, FOREIGN KEY, CHECK,
--               generated columns, ENUM, SET, JSON, temporary tables.
-- ----------------------------------------------------------------------------
-- TEXTBOOK DEPTH
--   CREATE TABLE defines the schema. Each column has:
--     name  data_type  [constraints]  [DEFAULT ...]  [COMMENT '...']
--
--   Column constraints:
--     NOT NULL                  — column cannot be NULL
--     DEFAULT expr              — value when INSERT omits the column
--     AUTO_INCREMENT            — MySQL assigns 1+N automatically (PK only)
--     PRIMARY KEY               — short for NOT NULL UNIQUE + clustered
--     UNIQUE                    — value must be unique across rows
--     COMMENT 'text'            — inline documentation
--     GENERATED ALWAYS AS expr  — virtual or stored computed column
--     CHECK (predicate)         — MySQL 8.0.16+ enforces
--
--   Table-level options:
--     ENGINE = InnoDB           — only engine that supports FKs/transactions
--     CHARACTER SET / COLLATE   — defaults from database
--     AUTO_INCREMENT = n        — start counter at n
--     ROW_FORMAT = DYNAMIC      — recommended for utf8mb4 + large rows
--     COMMENT 'text'            — table documentation
-- ============================================================================

USE ecom;

-- ----------------------------------------------------------------------------
-- 1. Minimal CREATE TABLE
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS tmp_minimal;
CREATE TABLE tmp_minimal (
    id   INT,
    name VARCHAR(50)
);
DESCRIBE tmp_minimal;
DROP TABLE tmp_minimal;

-- ----------------------------------------------------------------------------
-- 2. CREATE TABLE with all common column constraints
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS tmp_users;
CREATE TABLE tmp_users (
    id           BIGINT       NOT NULL AUTO_INCREMENT,
    username     VARCHAR(40)  NOT NULL,
    email        VARCHAR(255) NOT NULL,
    age          INT          NULL  COMMENT 'may be unknown',
    is_active    TINYINT(1)   NOT NULL DEFAULT 1,
    created_at   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
                                 ON UPDATE CURRENT_TIMESTAMP,
    bio          TEXT         NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_users_username (username),
    UNIQUE KEY uq_users_email    (email),
    KEY idx_users_active (is_active),
    CONSTRAINT chk_users_age CHECK (age IS NULL OR age BETWEEN 0 AND 150)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci
  COMMENT='Demo users table';

DESCRIBE tmp_users;
SHOW CREATE TABLE tmp_users\G
DROP TABLE tmp_users;

-- ----------------------------------------------------------------------------
-- 3. ENUM and SET types
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS tmp_enums;
CREATE TABLE tmp_enums (
    id        INT AUTO_INCREMENT PRIMARY KEY,
    status    ENUM('draft','published','archived') NOT NULL DEFAULT 'draft',
    tags      SET('news','tech','sports','politics') NULL
);
INSERT INTO tmp_enums (status, tags) VALUES
    ('published', 'news,tech'),
    ('archived', 'sports'),
    ('draft', NULL),
    ('published', 'tech,politics');

SELECT * FROM tmp_enums;

-- ENUM limits a column to ONE of the listed values.
-- SET   allows ZERO OR MORE of the listed values (comma-separated).

DROP TABLE tmp_enums;

-- ----------------------------------------------------------------------------
-- 4. JSON column
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS tmp_json;
CREATE TABLE tmp_json (
    id    INT AUTO_INCREMENT PRIMARY KEY,
    data  JSON NOT NULL,
    CHECK (JSON_VALID(data))
);
INSERT INTO tmp_json (data) VALUES
    ('{"name":"Alice","tags":["vip","newsletter"]}'),
    ('{"name":"Bob","tags":[]}');

SELECT id, data, JSON_EXTRACT(data, '$.name') AS name FROM tmp_json;

DROP TABLE tmp_json;

-- ----------------------------------------------------------------------------
-- 5. Generated columns (VIRTUAL vs STORED)
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS tmp_products_demo;
CREATE TABLE tmp_products_demo (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    price       DECIMAL(10,2) NOT NULL,
    cost        DECIMAL(10,2) NOT NULL,
    -- VIRTUAL: computed on read, not stored. No disk cost, no index by default.
    margin_virtual DECIMAL(10,2) AS (price - cost) VIRTUAL,
    -- STORED: computed on write, persisted. Can be indexed.
    margin_stored  DECIMAL(10,2) AS (price - cost) STORED,
    -- STORED computed column with an index
    margin_pct DECIMAL(5,2) AS (ROUND((price - cost) / price * 100, 2)) STORED,
    KEY idx_margin_pct (margin_pct)
);

INSERT INTO tmp_products_demo (price, cost) VALUES (100, 60), (200, 120), (50, 50);

SELECT * FROM tmp_products_demo;

DROP TABLE tmp_products_demo;

-- ----------------------------------------------------------------------------
-- 6. TEMPORARY tables — session-scoped, auto-dropped on disconnect
-- ----------------------------------------------------------------------------
CREATE TEMPORARY TABLE tmp_session (
    id INT AUTO_INCREMENT PRIMARY KEY,
    note VARCHAR(100)
);
INSERT INTO tmp_session (note) VALUES ('scratch data');
SELECT * FROM tmp_session;
-- tmp_session disappears when your connection closes.

-- ----------------------------------------------------------------------------
-- 7. CREATE TABLE LIKE — copy schema only (no data)
-- ----------------------------------------------------------------------------
CREATE TABLE tmp_products_template LIKE products;
DESCRIBE tmp_products_template;
SHOW INDEX FROM tmp_products_template;
DROP TABLE tmp_products_template;

-- ----------------------------------------------------------------------------
-- 8. CREATE TABLE AS SELECT — create + populate
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS tmp_order_summary;
CREATE TABLE tmp_order_summary AS
SELECT
    customer_id,
    COUNT(*) AS order_count,
    SUM(total) AS total_spent
FROM orders
GROUP BY customer_id;
-- No indexes, no PK on the new table.

SELECT * FROM tmp_order_summary ORDER BY total_spent DESC LIMIT 3;
DROP TABLE tmp_order_summary;

-- ----------------------------------------------------------------------------
-- 9. CREATE TABLE with foreign keys
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS tmp_children;
DROP TABLE IF EXISTS tmp_parents;
CREATE TABLE tmp_parents (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE tmp_children (
    id        INT AUTO_INCREMENT PRIMARY KEY,
    parent_id INT NOT NULL,
    name      VARCHAR(50) NOT NULL,
    CONSTRAINT fk_child_parent
        FOREIGN KEY (parent_id) REFERENCES tmp_parents(id)
        ON DELETE CASCADE
        ON UPDATE RESTRICT,
    KEY idx_child_parent (parent_id)
) ENGINE=InnoDB;

-- Test the FK: insert child without parent fails
-- INSERT INTO tmp_children (parent_id, name) VALUES (999, 'orphan');   -- ERROR 1452

INSERT INTO tmp_parents (name) VALUES ('Parent A');
INSERT INTO tmp_children (parent_id, name) VALUES (1, 'Child 1');
-- CASCADE test: deleting the parent deletes the child
DELETE FROM tmp_parents WHERE id = 1;
SELECT * FROM tmp_children;   -- empty

DROP TABLE tmp_children;
DROP TABLE tmp_parents;

-- ----------------------------------------------------------------------------
-- 10. CREATE TABLE IF NOT EXISTS — idempotent
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS tmp_maybe (
    id INT AUTO_INCREMENT PRIMARY KEY,
    val INT
);
-- No error if the table already exists.

DROP TABLE tmp_maybe;

-- ----------------------------------------------------------------------------
-- 11. EXERCISES
-- ----------------------------------------------------------------------------
-- EASY
-- E1.  Create a table `tmp_posts` with columns: id, title, body, created_at.
--      Use sensible types and constraints.
-- E2.  Create a TEMPORARY table with two columns and insert one row.
--
-- MEDIUM
-- E3.  Create a `tmp_events` table with an ENUM column for status
--      (pending/confirmed/cancelled) and a JSON column for metadata.
-- E4.  Create a table with a STORED generated column `margin_pct` from
--      `price` and `cost`, plus an index on `margin_pct`.
--
-- HARD
-- E5.  Create two tables with a foreign key relationship. Demonstrate that
--      inserting a child without a parent fails. Demonstrate that deleting
--      a parent cascades to children.
--
-- EXPERT
-- E6.  Explain in a comment the difference between VIRTUAL and STORED
--      generated columns. When would you choose each? Which one can be
--      indexed?
-- ============================================================================

-- End of file 02_create_table.sql
