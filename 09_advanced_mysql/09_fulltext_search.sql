-- ============================================================================
-- 09_fulltext_search.sql — FULLTEXT Indexes & MATCH AGAINST
-- ============================================================================
-- SKILL LEVEL : Advanced
-- TOPICS      : FULLTEXT index, MATCH AGAINST in natural language / boolean
--               / query expansion mode, IN BOOLEAN MODE operators,
--               stopwords, ngram parser for CJK.
-- ----------------------------------------------------------------------------
-- TEXTBOOK DEPTH
--   A FULLTEXT index is an inverted index optimized for natural-language
--   search. It builds a list of (word → list of rows containing it).
--
--   Create a FULLTEXT index on CHAR/VARCHAR/TEXT columns:
--     CREATE FULLTEXT INDEX idx_ft ON tbl (col1, col2);
--     -- Or in CREATE TABLE: FULLTEXT KEY ft_x (col1, col2)
--
--   Query modes:
--     1. NATURAL LANGUAGE MODE (default):
--          MATCH(col) AGAINST('search terms')
--          Returns rows ranked by relevance; uses stopwords.
--
--     2. IN BOOLEAN MODE:
--          MATCH(col) AGAINST('+mysql -oracle partial*' IN BOOLEAN MODE)
--          Operators:
--            +word   required
--            -word   prohibited
--            word    optional (boosts ranking)
--            word*   prefix wildcard
--            "phrase"  exact phrase
--            (a b)   grouping
--            ~word   fuzzy (synonyms)
--            <word   decrease contribution
--            >word   increase contribution
--
--     3. WITH QUERY EXPANSION:
--          MATCH(col) AGAINST('search' WITH QUERY EXPANSION)
--          Runs the query twice; second pass uses words from first pass's
--          top results to broaden the search. Useful when the user's
--          query is short.
--
--   Configuration:
--     * ft_min_word_len (default 4 for MyISAM, innodb_ft_min_token_size=3
--       for InnoDB) — words shorter than this are ignored.
--     * Stopwords list — common words like 'the', 'and' are ignored.
--     * For CJK (Chinese/Japanese/Korean) use the ngram parser.
--
--   When to use FULLTEXT vs LIKE:
--     * LIKE '%word%' — scans every row, slow on large tables.
--     * FULLTEXT — uses the inverted index, scales well, returns relevance
--       ranking.
-- ============================================================================

USE ecom;

-- ----------------------------------------------------------------------------
-- 1. Inspect existing FULLTEXT indexes (defined in 00_schema.sql)
-- ----------------------------------------------------------------------------
SHOW INDEX FROM products WHERE Index_type = 'FULLTEXT';
-- ft_products_name_desc on (name, description)

SHOW INDEX FROM reviews WHERE Index_type = 'FULLTEXT';
-- ft_reviews_body on (title, body)

-- ----------------------------------------------------------------------------
-- 2. Natural language mode (default) — ranked search
-- ----------------------------------------------------------------------------
SELECT
    id,
    name,
    MATCH(name, description) AGAINST('laptop') AS relevance
FROM products
WHERE MATCH(name, description) AGAINST('laptop')
ORDER BY relevance DESC;

-- ----------------------------------------------------------------------------
-- 3. Multiple search terms — natural language ranks by combined relevance
-- ----------------------------------------------------------------------------
SELECT
    id, name,
    MATCH(name, description) AGAINST('headphones noise cancellation') AS relevance
FROM products
WHERE MATCH(name, description) AGAINST('headphones noise cancellation')
ORDER BY relevance DESC;

-- ----------------------------------------------------------------------------
-- 4. IN BOOLEAN MODE — required (+), prohibited (-), prefix (*)
-- ----------------------------------------------------------------------------
-- Must contain 'pro', must NOT contain 'phone'.
SELECT id, name
FROM products
WHERE MATCH(name, description) AGAINST('+pro -phone' IN BOOLEAN MODE)
ORDER BY name;

-- Prefix search 'head*'
SELECT id, name
FROM products
WHERE MATCH(name, description) AGAINST('head*' IN BOOLEAN MODE)
ORDER BY name;

-- Exact phrase (quoted)
SELECT id, name
FROM products
WHERE MATCH(name, description) AGAINST('"ray tracing"' IN BOOLEAN MODE);

-- Optional terms — boost rows that contain both
SELECT id, name,
    MATCH(name, description) AGAINST('>laptop <tablet' IN BOOLEAN MODE) AS relevance
FROM products
WHERE MATCH(name, description) AGAINST('>laptop <tablet' IN BOOLEAN MODE)
ORDER BY relevance DESC;

-- ----------------------------------------------------------------------------
-- 5. Search the reviews body
-- ----------------------------------------------------------------------------
SELECT
    id,
    customer_id,
    product_id,
    title,
    body,
    MATCH(title, body) AGAINST('noise cancellation') AS relevance
FROM reviews
WHERE MATCH(title, body) AGAINST('noise cancellation')
ORDER BY relevance DESC;

-- ----------------------------------------------------------------------------
-- 6. WITH QUERY EXPANSION — broadens a short query
-- ----------------------------------------------------------------------------
-- First pass returns rows matching 'laptop'. Second pass uses words from
-- those rows to find related rows (like 'ultrabook', 'notebook').
SELECT id, name
FROM products
WHERE MATCH(name, description) AGAINST('laptop' WITH QUERY EXPANSION)
ORDER BY id;

-- ----------------------------------------------------------------------------
-- 7. Combining MATCH AGAINST with normal WHERE
-- ----------------------------------------------------------------------------
SELECT id, name, price
FROM products
WHERE MATCH(name, description) AGAINST('wireless' IN BOOLEAN MODE)
  AND price < 200
ORDER BY price;

-- ----------------------------------------------------------------------------
-- 8. Inspecting the relevance score
-- ----------------------------------------------------------------------------
-- The relevance score is a floating-point number based on word frequency,
-- document length, and other factors. Higher = more relevant.
SELECT
    id,
    name,
    MATCH(name, description) AGAINST('pro laptop wireless') AS relevance
FROM products
WHERE MATCH(name, description) AGAINST('pro laptop wireless' IN BOOLEAN MODE)
ORDER BY relevance DESC;

-- ----------------------------------------------------------------------------
-- 9. Adding a FULLTEXT index to an existing table
-- ----------------------------------------------------------------------------
-- ALTER TABLE products ADD FULLTEXT INDEX ft_products_full (name, description, sku);

-- ----------------------------------------------------------------------------
-- 10. Configuration variables
-- ----------------------------------------------------------------------------
SHOW VARIABLES LIKE 'innodb_ft_min_token_size';
SHOW VARIABLES LIKE 'innodb_ft_max_token_size';
SHOW VARIABLES LIKE 'ft_min_word_len';
SHOW VARIABLES LIKE 'innodb_ft_server_stopword_table';
SHOW VARIABLES LIKE 'ngram_token_size';

-- ----------------------------------------------------------------------------
-- 11. ngram parser for CJK (Chinese/Japanese/Korean)
-- ----------------------------------------------------------------------------
-- CREATE FULLTEXT INDEX ft_cjk ON articles (title, body) WITH PARSER ngram;
-- Tokenizes CJK text into N-grams (default n=2) so searches on individual
-- Chinese characters work.

-- ----------------------------------------------------------------------------
-- 12. EXERCISES
-- ----------------------------------------------------------------------------
-- EASY
-- E1.  Use MATCH AGAINST in natural language mode to find products
--      matching 'wireless'.
-- E2.  Use MATCH AGAINST in boolean mode to find products that MUST
--      contain 'audio' but NOT 'phone'.
--
-- MEDIUM
-- E3.  Find reviews mentioning 'battery life' using boolean mode with an
--      exact phrase. Sort by relevance.
-- E4.  Use WITH QUERY EXPANSION to broaden a 'phone' search and observe
--      how related products appear.
--
-- HARD
-- E5.  Build a search query that requires 'pro' AND has 'laptop' as an
--      optional boost term, with relevance > 0. Sort by relevance.
--
-- EXPERT
-- E6.  Explain in a comment why FULLTEXT search is faster than
--      LIKE '%word%' on a million-row table. Reference the data structure
--      (inverted index) and the O(log n) lookup vs O(n) scan.
-- ============================================================================

-- End of file 09_fulltext_search.sql
