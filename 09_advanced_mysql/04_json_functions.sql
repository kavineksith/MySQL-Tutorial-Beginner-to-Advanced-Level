-- ============================================================================
-- 04_json_functions.sql — MySQL JSON Functions
-- ============================================================================
-- SKILL LEVEL : Advanced
-- TOPICS      : JSON columns, JSON_VALID, JSON_EXTRACT, ->, ->>, JSON_SET,
--               JSON_INSERT, JSON_REPLACE, JSON_REMOVE, JSON_ARRAY,
--               JSON_OBJECT, JSON_MERGE_PATCH, JSON_TABLE, JSON indexes.
-- ----------------------------------------------------------------------------
-- TEXTBOOK DEPTH
--   MySQL 8 stores JSON in a binary format (not as text). The JSON column
--   type validates on write and provides fast element access via path
--   expressions.
--
--   Path syntax:
--     '$'           — the root document
--     '$.key'       — value of object member `key`
--     '$[0]'        — first element of an array
--     '$.tags[1]'   — second element of `tags` array
--     '$.**.price'  — any descendant `price`
--
--   Extraction operators:
--     JSON_EXTRACT(json, path)  — returns the value at path (still JSON-typed)
--     json->path                — shorthand for JSON_EXTRACT
--     json->>path               — shorthand for JSON_UNQUOTE(JSON_EXTRACT(...))
--                                  returns plain text (string values unquoted)
--
--   Modification functions (each returns a NEW JSON document — JSON is
--   immutable in MySQL):
--     JSON_SET(doc, path, val, ...)     — insert or update
--     JSON_INSERT(doc, path, val, ...)  — insert only if path does not exist
--     JSON_REPLACE(doc, path, val, ...) — replace only if path exists
--     JSON_REMOVE(doc, path, ...)       — remove elements
--
--   Construction:
--     JSON_ARRAY(a, b, c)               — build array
--     JSON_OBJECT('k1', v1, 'k2', v2)   — build object
--     JSON_MERGE_PATCH(doc, patch)      — RFC 7396 merge
--
--   Inspection:
--     JSON_VALID(str)                   — is the string valid JSON?
--     JSON_TYPE(json)                   — 'OBJECT', 'ARRAY', 'STRING', etc.
--     JSON_LENGTH(json)                 — number of elements
--     JSON_CONTAINS(doc, candidate)     — does doc contain candidate?
--     JSON_CONTAINS_PATH(doc, mode, paths...)
--     JSON_KEYS(doc)                    — object keys as array
--
--   JSON_TABLE — flatten a JSON array into rows (MySQL 8.0.4+).
--
--   Multi-valued indexes — index values inside a JSON array (8.0.17+).
-- ============================================================================

USE ecom;

-- ----------------------------------------------------------------------------
-- 1. Inspect the JSON column in customers
-- ----------------------------------------------------------------------------
SELECT id, first_name, metadata FROM customers WHERE metadata IS NOT NULL LIMIT 3;

-- ----------------------------------------------------------------------------
-- 2. JSON_VALID — check if a string is valid JSON
-- ----------------------------------------------------------------------------
SELECT
    JSON_VALID('{"a": 1}')        AS valid1,
    JSON_VALID('{a: 1}')           AS invalid,
    JSON_VALID('[1, 2, 3]')        AS valid_array,
    JSON_VALID('"hello"')          AS valid_string,
    JSON_VALID('42')               AS valid_number;

-- ----------------------------------------------------------------------------
-- 3. JSON_EXTRACT and -> operator
-- ----------------------------------------------------------------------------
SELECT
    first_name,
    metadata,
    JSON_EXTRACT(metadata, '$.loyalty_points') AS loyalty_extracted,
    metadata->'$.loyalty_points'                AS loyalty_arrow,
    metadata->>'$.loyalty_points'               AS loyalty_unquoted
FROM customers
WHERE metadata IS NOT NULL;

-- ----------------------------------------------------------------------------
-- 4. JSON_EXTRACT nested paths and arrays
-- ----------------------------------------------------------------------------
SELECT
    first_name,
    metadata->'$.tags'           AS tags_array,
    metadata->'$.tags[0]'        AS first_tag,
    metadata->>'$.tags[0]'       AS first_tag_unquoted,
    JSON_LENGTH(metadata->'$.tags') AS tag_count
FROM customers
WHERE metadata IS NOT NULL;

-- ----------------------------------------------------------------------------
-- 5. JSON_CONTAINS — search inside a JSON array
-- ----------------------------------------------------------------------------
-- Find customers whose tags array contains 'vip'.
SELECT first_name, metadata
FROM customers
WHERE metadata IS NOT NULL
  AND JSON_CONTAINS(metadata->'$.tags', '"vip"');
-- Note: '"vip"' is a JSON string (with quotes) because JSON_CONTAINS
-- expects JSON-formatted values.

-- ----------------------------------------------------------------------------
-- 6. JSON_CONTAINS_PATH — does a path exist?
-- ----------------------------------------------------------------------------
SELECT first_name,
       JSON_CONTAINS_PATH(metadata, 'one', '$.loyalty_points') AS has_loyalty,
       JSON_CONTAINS_PATH(metadata, 'one', '$.tags') AS has_tags,
       JSON_CONTAINS_PATH(metadata, 'all', '$.loyalty_points', '$.tags') AS has_both
FROM customers
WHERE metadata IS NOT NULL;

-- ----------------------------------------------------------------------------
-- 7. JSON_KEYS — get object keys
-- ----------------------------------------------------------------------------
SELECT first_name, JSON_KEYS(metadata) AS keys
FROM customers
WHERE metadata IS NOT NULL;

-- ----------------------------------------------------------------------------
-- 8. JSON_TYPE — type of value at a path
-- ----------------------------------------------------------------------------
SELECT
    JSON_TYPE(metadata)              AS doc_type,
    JSON_TYPE(metadata->'$.tags')    AS tags_type,
    JSON_TYPE(metadata->'$.loyalty_points') AS loyalty_type
FROM customers
WHERE id = 1;

-- ----------------------------------------------------------------------------
-- 9. JSON_SET — insert or update a path (returns new document)
-- ----------------------------------------------------------------------------
SELECT
    metadata AS before_set,
    JSON_SET(metadata,
        '$.loyalty_points', 5000,
        '$.last_login', '2024-06-15'
    ) AS after_set
FROM customers WHERE id = 1;

-- Actually UPDATE the row:
UPDATE customers
SET metadata = JSON_SET(metadata, '$.loyalty_points', 5000, '$.last_login', '2024-06-15')
WHERE id = 1;

SELECT metadata FROM customers WHERE id = 1;

-- Restore: remove the last_login path
UPDATE customers
SET metadata = JSON_REMOVE(metadata, '$.last_login'),
    metadata = JSON_SET(metadata, '$.loyalty_points', 1250)
WHERE id = 1;

SELECT metadata FROM customers WHERE id = 1;

-- ----------------------------------------------------------------------------
-- 10. JSON_INSERT vs JSON_REPLACE vs JSON_SET
-- ----------------------------------------------------------------------------
SET @doc := '{"a": 1, "b": 2}';

SELECT
    @doc                                                AS original,
    JSON_INSERT(@doc, '$.a', 99, '$.c', 3)              AS after_insert,
    -- Insert does NOT change existing paths: a stays 1, c added.

    JSON_REPLACE(@doc, '$.a', 99, '$.c', 3)             AS after_replace,
    -- Replace only changes EXISTING paths: a→99, c NOT added.

    JSON_SET(@doc, '$.a', 99, '$.c', 3)                 AS after_set;
    -- Set is upsert: existing → update, missing → insert.

-- ----------------------------------------------------------------------------
-- 11. JSON_ARRAY and JSON_OBJECT — construct
-- ----------------------------------------------------------------------------
SELECT JSON_ARRAY(1, 'two', TRUE, NULL) AS arr;
SELECT JSON_OBJECT('name', 'Alice', 'age', 30, 'tags', JSON_ARRAY('vip', 'newsletter')) AS obj;

-- ----------------------------------------------------------------------------
-- 12. JSON_ARRAYAGG and JSON_OBJECTAGG — aggregate to JSON
-- ----------------------------------------------------------------------------
SELECT
    c.id,
    c.first_name,
    JSON_ARRAYAGG(o.id) AS order_ids
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
GROUP BY c.id, c.first_name
LIMIT 5;

SELECT JSON_OBJECTAGG(sku, price) AS sku_to_price FROM products;

-- ----------------------------------------------------------------------------
-- 13. JSON_TABLE — flatten a JSON array into rows
-- ----------------------------------------------------------------------------
SET @json := '[
    {"id": 1, "name": "Alice", "tags": ["vip", "newsletter"]},
    {"id": 2, "name": "Bob",   "tags": ["new"]},
    {"id": 3, "name": "Carol", "tags": []}
]';

SELECT *
FROM JSON_TABLE(
    @json,
    '$[*]' COLUMNS (
        id   INT PATH '$.id',
        name VARCHAR(50) PATH '$.name',
        tag_count INT PATH '$.tags' DEFAULT 0 ON EMPTY,
        tag_count_err INT PATH '$.tags' DEFAULT 0 ON ERROR
    )
) AS jt;

-- ----------------------------------------------------------------------------
-- 14. Multi-valued index — index values inside a JSON array
-- ----------------------------------------------------------------------------
-- Create an index on the elements of `metadata->'$.tags`:
CREATE TABLE tmp_json_indexed (
    id INT AUTO_INCREMENT PRIMARY KEY,
    data JSON,
    INDEX idx_tags ((CAST(data->'$.tags' AS CHAR(20) ARRAY)))
);

INSERT INTO tmp_json_indexed (data) VALUES
    ('{"tags":["vip","newsletter"]}'),
    ('{"tags":["new"]}'),
    ('{"tags":["vip","early-adopter"]}');

-- Member-of query that uses the multi-valued index:
SELECT id, data FROM tmp_json_indexed
WHERE 'vip' MEMBER OF (data->'$.tags');

EXPLAIN SELECT id, data FROM tmp_json_indexed
WHERE 'vip' MEMBER OF (data->'$.tags');

DROP TABLE tmp_json_indexed;

-- ----------------------------------------------------------------------------
-- 15. EXERCISES
-- ----------------------------------------------------------------------------
-- EASY
-- E1.  Select first_name and loyalty_points from each customer's metadata
--      (use the ->> operator).
-- E2.  Use JSON_CONTAINS to find customers whose tags include 'newsletter'.
--
-- MEDIUM
-- E3.  Update customer 1's metadata: add a new path $.signup_source = 'web'.
--      Then remove it.
-- E4.  Use JSON_ARRAYAGG to return each customer's order ids as a JSON array.
--
-- HARD
-- E5.  Use JSON_TABLE to flatten this JSON array into rows:
--        '[{"id":1,"name":"A"},{"id":2,"name":"B"},{"id":3,"name":"C"}]'
-- E6.  Create a multi-valued index on customers.metadata->'$.tags' and use
--      a MEMBER OF query to find VIPs.
--
-- EXPERT
-- E7.  Explain in a comment when JSON columns are the right choice vs when
--      they should be normalized into regular columns. Provide a concrete
--      example of each.
-- ============================================================================

-- End of file 04_json_functions.sql
