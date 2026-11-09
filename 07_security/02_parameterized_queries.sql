-- ============================================================================
-- 02_parameterized_queries.sql — Parameterized Queries (the SQLi defense)
-- ============================================================================
-- SKILL LEVEL : Intermediate
-- TOPICS      : PREPARE / EXECUTE / USING / DEALLOCATE, placeholders,
--               why parameterization defeats SQLi, application-side
--               examples (PHP PDO, Python, Node mysql2).
-- ----------------------------------------------------------------------------
-- TEXTBOOK DEPTH
--   A parameterized query separates SQL STRUCTURE from user-supplied DATA.
--   The structure (with `?` placeholders) is sent to MySQL first and
--   parsed ONCE. The data values are then sent SEPARATELY — they never
--   become part of the SQL syntax, so injection is impossible.
--
--   MySQL protocol flow:
--     1. Client: COM_STMT_PREPARE  "SELECT * FROM customers WHERE email = ?"
--     2. Server: parses, returns a statement ID and parameter metadata.
--     3. Client: COM_STMT_EXECUTE  stmt_id=42, params=['alice@x.com']
--     4. Server: substitutes the binary-encoded value into the already-
--        parsed execution plan. Runs it. Returns rows.
--
--   Key points:
--     * You CANNOT inject SQL through a parameter. The server treats it
--       as a binary value, not as SQL text.
--     * Placeholders can only appear where a VALUE is allowed: WHERE, SET,
--       VALUES, LIMIT (with caveats), etc. They CANNOT replace table or
--       column names — those are part of the SQL structure.
--     * A PREPAREd statement can be EXECUTEd many times with different
--       params — the parse cost is paid once.
-- ============================================================================

USE ecom;

-- ----------------------------------------------------------------------------
-- 1. Basic PREPARE / EXECUTE / DEALLOCATE
-- ----------------------------------------------------------------------------
PREPARE stmt FROM
    'SELECT id, first_name, last_name, email FROM customers WHERE country = ?';
SET @country := 'United States';
EXECUTE stmt USING @country;
DEALLOCATE PREPARE stmt;

-- ----------------------------------------------------------------------------
-- 2. Multiple placeholders
-- ----------------------------------------------------------------------------
PREPARE stmt FROM
    'SELECT id, name, price FROM products WHERE category_id = ? AND price <= ? ORDER BY price';
SET @cat := 9;
SET @max_price := 600;
EXECUTE stmt USING @cat, @max_price;
DEALLOCATE PREPARE stmt;

-- ----------------------------------------------------------------------------
-- 3. Re-execute with different params (pay parse cost once)
-- ----------------------------------------------------------------------------
PREPARE stmt FROM
    'SELECT id, name, price FROM products WHERE category_id = ?';

SET @c := 8;       EXECUTE stmt USING @c;
SET @c := 9;       EXECUTE stmt USING @c;
SET @c := 12;      EXECUTE stmt USING @c;

DEALLOCATE PREPARE stmt;

-- ----------------------------------------------------------------------------
-- 4. INSERT with placeholders
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS tmp_safe_insert;
CREATE TABLE tmp_safe_insert (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(50), email VARCHAR(100));

PREPARE ins FROM 'INSERT INTO tmp_safe_insert (name, email) VALUES (?, ?)';

-- Even though these inputs contain single quotes, they're DATA, not SQL:
SET @n := 'O''Brien';        -- contains a single quote
SET @e := 'obrien@example.com';
EXECUTE ins USING @n, @e;

-- Attack attempt — stored as data, not executed:
SET @n := 'alice; DROP TABLE tmp_safe_insert; --';
SET @e := 'evil@example.com';
EXECUTE ins USING @n, @e;

SELECT * FROM tmp_safe_insert;
-- Two rows, both safely inserted. No table was dropped. The `; DROP TABLE`
-- is just text in the name column.

DEALLOCATE PREPARE ins;
DROP TABLE tmp_safe_insert;

-- ----------------------------------------------------------------------------
-- 5. UPDATE with placeholders
-- ----------------------------------------------------------------------------
PREPARE upd FROM
    'UPDATE customers SET is_active = ? WHERE country = ?';
SET @a := 1; SET @c := 'Japan';
EXECUTE upd USING @a, @c;
DEALLOCATE PREPARE upd;

-- ----------------------------------------------------------------------------
-- 6. LIMIT with placeholder — historically tricky
-- ----------------------------------------------------------------------------
-- In MySQL 5.7, LIMIT ? worked but required integer params.
-- In MySQL 8.0+ (SQL:2023 compatible where noted), LIMIT works with placeholders directly.
PREPARE stmt FROM 'SELECT id, name FROM products ORDER BY price DESC LIMIT ?';
SET @n := 3;
EXECUTE stmt USING @n;
DEALLOCATE PREPARE stmt;

-- ----------------------------------------------------------------------------
-- 7. Placeholders CANNOT replace identifiers (table/column names)
-- ----------------------------------------------------------------------------
-- This FAILS:
-- PREPARE stmt FROM 'SELECT * FROM ?';
-- ERROR 1064 (42000): ... syntax error near '?'
--
-- Identifiers must be string-interpolated. If you must parameterize a
-- table name, do it on the application side AFTER validating against an
-- allowlist:
--   allowed_tables = {'customers', 'products', 'orders'}
--   if user_input not in allowed_tables: raise error
--   sql = f"SELECT * FROM {user_input}"

-- ----------------------------------------------------------------------------
-- 8. Application-side examples (NOT run — for reference)
-- ----------------------------------------------------------------------------
-- PHP PDO:
--   $stmt = $pdo->prepare('SELECT * FROM customers WHERE email = :email');
--   $stmt->execute([':email' => $user_input]);
--   $row = $stmt->fetch();

-- Python (mysql-connector or PyMySQL):
--   cur = conn.cursor()
--   cur.execute('SELECT * FROM customers WHERE email = %s', (user_input,))
--   row = cur.fetchone()

-- Node.js (mysql2):
--   const [rows] = await pool.execute(
--       'SELECT * FROM customers WHERE email = ?',
--       [userInput]
--   );

-- Java (JDBC):
--   PreparedStatement ps = conn.prepareStatement(
--       "SELECT * FROM customers WHERE email = ?");
--   ps.setString(1, userInput);
--   ResultSet rs = ps.executeQuery();

-- ============================================================================
-- 9. EXERCISES
-- ============================================================================
-- EASY
-- E1.  Write a parameterized SELECT for products WHERE price <= ?.
-- E2.  Write a parameterized INSERT into a temp table with two columns.
--
-- MEDIUM
-- E3.  Use PREPARE/EXECUTE to insert 3 customers with email values
--      containing single quotes. Verify they're stored as data, not
--      executed.
-- E4.  Write a parameterized UPDATE that sets is_active to ? for
--      customers WHERE country = ?.
--
-- HARD
-- E5.  Try PREPARE with `?` as a table name. Explain in a comment why
--      this fails and what the safe alternative is (allowlist on the app
--      side).
--
-- EXPERT
-- E6.  Explain in a comment why a parameterized query defeats SQL
--      injection even when the user input contains characters like
--      single quotes, semicolons, or SQL keywords. Reference the
--      COM_STMT_PREPARE / COM_STMT_EXECUTE protocol flow.
-- ============================================================================

-- End of file 02_parameterized_queries.sql
