-- ============================================================================
-- 05_indexes.sql — CREATE INDEX & Indexing Strategy
-- ============================================================================
-- SKILL LEVEL : Intermediate
-- TOPICS      : CREATE INDEX, INDEX vs UNIQUE vs FULLTEXT vs SPATIAL,
--               composite indexes, index order (leftmost prefix), EXPLAIN,
--               invisible indexes, functional indexes, when to index.
-- ----------------------------------------------------------------------------
-- TEXTBOOK DEPTH
--   An index is a separate data structure that lets MySQL find rows without
--   scanning the whole table. The default InnoDB index is a B+tree.
--
--   Cost/benefit of an index:
--     + Speeds up WHERE, JOIN, ORDER BY, GROUP BY on indexed columns.
--     + Enforces UNIQUE constraint.
--     − Slows INSERT/UPDATE/DELETE (index must be maintained).
--     − Consumes disk space.
--
--   Index types in MySQL:
--     INDEX (BTREE)   — default; sorted range lookups
--     UNIQUE          — BTREE + uniqueness
--     FULLTEXT        — inverted index for MATCH AGAINST
--     SPATIAL         — for GEOMETRY columns (R-tree)
--     HASH            — only in MEMORY engine; not for InnoDB
--
--   Critical rules for COMPOSITE indexes:
--     * Column order matters: an index on (a, b, c) speeds queries that
--       filter on `a`, `a AND b`, or `a AND b AND c`. It does NOT speed
--       queries on just `b` or `c` alone — the leftmost-prefix rule.
--     * Equality predicates on early columns + range on the next column
--       is the optimal pattern.
--
--   MySQL 8.0+ (SQL:2023 compatible where noted) supports invisible indexes (the optimizer ignores them).
--   Use this to safely test removing an index before dropping it.
-- ============================================================================

USE ecom;

-- ----------------------------------------------------------------------------
-- 1. CREATE INDEX (basic)
-- ----------------------------------------------------------------------------
-- (Products already has idx_products_name; let's add another to demo.)
DROP TABLE IF EXISTS tmp_idx_demo;
CREATE TABLE tmp_idx_demo (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50),
    email VARCHAR(100),
    age INT
);
INSERT INTO tmp_idx_demo (name, email, age)
SELECT
    CONCAT('User', LPAD(seq, 4, '0')),
    CONCAT('user', LPAD(seq, 4, '0'), '@x.com'),
    FLOOR(20 + RAND() * 60)
FROM (
    SELECT @i := @i + 1 AS seq FROM
        (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4) a,
        (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4) b,
        (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4) c,
        (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4) d,
        (SELECT @i := 0) init
) nums
LIMIT 200;

CREATE INDEX idx_email ON tmp_idx_demo (email);
CREATE INDEX idx_age   ON tmp_idx_demo (age);
SHOW INDEX FROM tmp_idx_demo;

-- ----------------------------------------------------------------------------
-- 2. EXPLAIN — see if the optimizer uses the index
-- ----------------------------------------------------------------------------
EXPLAIN SELECT * FROM tmp_idx_demo WHERE email = 'user0042@x.com';
-- Look at the `key` column: should be `idx_email`, and `rows` should be
-- small (1 or a few).

EXPLAIN SELECT * FROM tmp_idx_demo WHERE age = 30;
-- `key` should be `idx_age`.

EXPLAIN SELECT * FROM tmp_idx_demo WHERE name = 'User0042';
-- `key` should be NULL — no index on name. `rows` will be the full table.

-- ----------------------------------------------------------------------------
-- 3. Composite index — leftmost-prefix rule
-- ----------------------------------------------------------------------------
DROP INDEX idx_email ON tmp_idx_demo;
DROP INDEX idx_age ON tmp_idx_demo;

CREATE INDEX idx_email_age ON tmp_idx_demo (email, age);

-- Uses index (leftmost prefix matches email):
EXPLAIN SELECT * FROM tmp_idx_demo WHERE email = 'user0042@x.com';

-- Uses index (full match on email + range on age):
EXPLAIN SELECT * FROM tmp_idx_demo
WHERE email = 'user0042@x.com' AND age > 25;

-- Does NOT use index (leftmost prefix is age, but index starts with email):
EXPLAIN SELECT * FROM tmp_idx_demo WHERE age = 30;
-- `key` will be NULL.

-- ----------------------------------------------------------------------------
-- 4. UNIQUE INDEX
-- ----------------------------------------------------------------------------
CREATE UNIQUE INDEX uq_email_unique ON tmp_idx_demo (email);
-- Inserting a duplicate email now fails:
-- INSERT INTO tmp_idx_demo (name, email, age) VALUES ('Dup', 'user0042@x.com', 30);
-- ERROR 1062 (23000): Duplicate entry

DROP INDEX uq_email_unique ON tmp_idx_demo;

-- ----------------------------------------------------------------------------
-- 5. FULLTEXT INDEX — for MATCH AGAINST search
-- ----------------------------------------------------------------------------
CREATE FULLTEXT INDEX ft_name ON tmp_idx_demo (name);

SELECT * FROM tmp_idx_demo WHERE MATCH(name) AGAINST('User0042' IN NATURAL LANGUAGE MODE);

DROP INDEX ft_name ON tmp_idx_demo;

-- ----------------------------------------------------------------------------
-- 6. Functional index on an expression (MySQL 8.0.13+)
-- ----------------------------------------------------------------------------
CREATE INDEX idx_lower_email ON tmp_idx_demo ((LOWER(email)));
EXPLAIN SELECT * FROM tmp_idx_demo WHERE LOWER(email) = 'user0042@x.com';
-- Should use idx_lower_email.

DROP INDEX idx_lower_email ON tmp_idx_demo;

-- ----------------------------------------------------------------------------
-- 7. Invisible indexes — test removal safely
-- ----------------------------------------------------------------------------
CREATE INDEX idx_age_invisible ON tmp_idx_demo (age) INVISIBLE;

EXPLAIN SELECT * FROM tmp_idx_demo WHERE age = 30;
-- `key` should be NULL because the index is invisible.

ALTER TABLE tmp_idx_demo ALTER INDEX idx_age_invisible VISIBLE;
EXPLAIN SELECT * FROM tmp_idx_demo WHERE age = 30;
-- Now uses idx_age_invisible.

DROP INDEX idx_age_invisible ON tmp_idx_demo;

-- ----------------------------------------------------------------------------
-- 8. Index on a prefix of a long string column
-- ----------------------------------------------------------------------------
-- Indexing the full VARCHAR(255) is wasteful; index the first N chars.
CREATE INDEX idx_email_prefix ON tmp_idx_demo (email(10));
SHOW INDEX FROM tmp_idx_demo;
DROP INDEX idx_email_prefix ON tmp_idx_demo;

-- ----------------------------------------------------------------------------
-- 9. DROP INDEX
-- ----------------------------------------------------------------------------
DROP INDEX idx_email_age ON tmp_idx_demo;
DROP TABLE tmp_idx_demo;

-- ----------------------------------------------------------------------------
-- 10. Inspecting existing indexes on a real table
-- ----------------------------------------------------------------------------
SHOW INDEX FROM products;
SHOW INDEX FROM customers;

-- ----------------------------------------------------------------------------
-- 11. EXERCISES
-- ----------------------------------------------------------------------------
-- EASY
-- E1.  Create an index on `customers.last_name`.
-- E2.  Use EXPLAIN to verify a query on `customers.last_name` uses the new
--      index.
--
-- MEDIUM
-- E3.  Create a composite index on (country, is_active) on customers. Use
--      EXPLAIN to verify queries that filter on country alone AND on
--      country + is_active both use the index.
-- E4.  Use EXPLAIN to demonstrate the leftmost-prefix rule: a query on
--      `is_active` alone should NOT use the (country, is_active) index.
--
-- HARD
-- E5.  Create an invisible index on `orders.status`. Verify with EXPLAIN
--      that queries on status do NOT use it while invisible, then make it
--      visible and verify usage.
--
-- EXPERT
-- E6.  Explain in a comment why adding an index can slow down INSERTs.
--      Provide a rough rule of thumb for how many indexes are "too many"
--      on a write-heavy table.
-- ============================================================================

-- End of file 05_indexes.sql
