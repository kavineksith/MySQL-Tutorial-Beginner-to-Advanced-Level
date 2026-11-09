# Comprehensive SQL Tutorial — Beginner to Advanced (MySQL 8.0+, SQL:2023)

A complete, textbook-depth SQL course covering core SQL concepts plus
advanced MySQL features (window functions, CTEs, JSON, triggers, transactions,
performance, security). All examples use a single realistic e-commerce
database so every query is runnable.

> **Target audience**: developers and DBAs who want to master SQL end-to-end.
> **MySQL version**: 8.0+ (uses window functions, CTEs, JSON, CHECK constraints).
> **SQL standard**: Compatible with SQL:2023 where supported.
> **Sample database**: `ecom` — customers, products, orders, order_items,
> categories, reviews, employees.

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Directory Structure](#directory-structure)
3. [Learning Path & Roadmap](#learning-path--roadmap)
4. [Setup Instructions](#setup-instructions)
5. [Cheat Sheet](#cheat-sheet)
6. [MySQL Keywords Glossary](#mysql-keywords-glossary)
7. [MySQL Functions Reference](#mysql-functions-reference)
8. [Common Errors & Fixes](#common-errors--fixes)
9. [Interview Questions](#interview-questions)
10. [How to Use This Course](#how-to-use-this-course)

---

## Quick Start

```bash
# 1. Install MySQL 8.0+ (if not already installed)
#    macOS:  brew install mysql
#    Ubuntu: sudo apt install mysql-server
#    Windows: download from https://dev.mysql.com/downloads/

# 2. Start MySQL server
sudo systemctl start mysql   # Linux
brew services start mysql    # macOS

# 3. Load the schema and seed data
mysql -u root -p < 00_setup/00_schema.sql
mysql -u root -p < 00_setup/01_seed_data.sql

# 4. Verify the load
mysql -u root -p -e "USE ecom; SELECT COUNT(*) FROM customers;"

# 5. Start learning! Open the first file in your editor:
#    01_foundations/01_intro_and_syntax.sql
```

---

## Directory Structure

```
sql-course/
├── README.md                              ← You are here
│
├── 00_setup/                              ← Run these FIRST
│   ├── 00_schema.sql                      ← Creates the `ecom` database
│   └── 01_seed_data.sql                   ← Inserts realistic sample data
│
├── 01_foundations/                        ← Beginner: SQL basics
│   ├── 01_intro_and_syntax.sql
│   ├── 02_select.sql
│   ├── 03_select_distinct.sql
│   ├── 04_where.sql
│   ├── 05_order_by.sql
│   ├── 06_and_or_not.sql
│   ├── 07_insert.sql
│   ├── 08_null_values.sql
│   ├── 09_update.sql
│   └── 10_delete.sql
│
├── 02_joins/                              ← Intermediate: relational queries
│   ├── 01_joins_intro.sql
│   ├── 02_inner_join.sql
│   ├── 03_left_join.sql
│   ├── 04_right_join.sql
│   ├── 05_full_join.sql
│   └── 06_self_join.sql
│
├── 03_subqueries/                         ← Intermediate: nested queries
│   ├── 01_subqueries_basics.sql
│   ├── 02_exists.sql
│   ├── 03_any_all.sql
│   └── 04_select_into_select_into.sql
│
├── 04_set_operations/                     ← Intermediate: combining results
│   ├── 01_union.sql
│   ├── 02_union_all.sql
│   └── 03_case.sql
│
├── 05_aggregates_and_grouping/            ← Intermediate: summary queries
│   ├── 01_aggregate_functions.sql
│   ├── 02_min_max_count_sum_avg.sql
│   ├── 03_group_by.sql
│   └── 04_having.sql
│
├── 06_filtering_and_operators/            ← Beginner→Intermediate
│   ├── 01_select_top_limit.sql
│   ├── 02_like.sql
│   ├── 03_wildcards.sql
│   ├── 04_in_operator.sql
│   ├── 05_between.sql
│   ├── 06_aliases.sql
│   ├── 07_null_functions.sql
│   ├── 08_operators.sql
│   └── 09_comments.sql
│
├── 07_security/                           ← Intermediate→Advanced
│   ├── 01_sql_injection.sql
│   ├── 02_parameterized_queries.sql
│   ├── 03_prepared_statements.sql
│   └── 04_user_management.sql
│
├── 08_database_admin/                     ← Intermediate→Advanced
│   ├── 01_create_drop_db.sql
│   ├── 02_create_table.sql
│   ├── 03_alter_table.sql
│   ├── 04_constraints.sql
│   ├── 05_indexes.sql
│   ├── 06_auto_increment_dates.sql
│   ├── 07_views.sql
│   ├── 08_stored_procedures.sql
│   └── 09_backup_hosting.sql
│
├── 09_advanced_mysql/                     ← Advanced
│   ├── 01_window_functions.sql
│   ├── 02_ctes.sql
│   ├── 03_recursive_ctes.sql
│   ├── 04_json_functions.sql
│   ├── 05_triggers.sql
│   ├── 06_events.sql
│   ├── 07_transactions.sql
│   ├── 08_locks_isolation.sql
│   ├── 09_fulltext_search.sql
│   ├── 10_explain_performance.sql
│   └── 11_indexing_strategies.sql
│
├── 10_progressive_challenges/             ← Practice
│   ├── 01_easy_challenges.sql             ← 20 exercises
│   ├── 02_medium_challenges.sql           ← 20 exercises
│   ├── 03_hard_challenges.sql             ← 20 exercises
│   └── 04_expert_challenges.sql           ← 20 exercises
│
└── solutions/                             ← ALL solutions live here
    ├── 01_foundations_solutions.sql
    ├── 02_joins_solutions.sql
    ├── 03_subqueries_solutions.sql
    ├── 04_set_operations_solutions.sql
    ├── 05_aggregates_solutions.sql
    ├── 06_filtering_solutions.sql
    ├── 07_security_solutions.sql
    ├── 08_database_admin_solutions.sql
    ├── 09_advanced_mysql_solutions.sql
    ├── 10_easy_challenges_solutions.sql
    ├── 11_medium_challenges_solutions.sql
    ├── 12_hard_challenges_solutions.sql
    └── 13_expert_challenges_solutions.sql
```

**Total**: ~45 SQL files, 80 exercises with solutions, fully runnable against
the included e-commerce schema.

---

## Learning Path & Roadmap

### Phase 1 — Foundations (1–2 weeks, ~10 hours)

| Order | File | Concepts | Time |
|-------|------|----------|------|
| 1 | `00_setup/00_schema.sql` + `01_seed_data.sql` | Set up the database | 30 min |
| 2 | `01_foundations/01_intro_and_syntax.sql` | SQL anatomy, identifiers, literals | 1 hr |
| 3 | `01_foundations/02_select.sql` | SELECT, projection, computed columns | 1 hr |
| 4 | `01_foundations/03_select_distinct.sql` | DISTINCT, NULL handling in DISTINCT | 45 min |
| 5 | `01_foundations/04_where.sql` | WHERE, comparison operators, NULLs | 1.5 hr |
| 6 | `01_foundations/05_order_by.sql` | ORDER BY, ASC/DESC, multi-column, NULL ordering | 1 hr |
| 7 | `01_foundations/06_and_or_not.sql` | AND, OR, NOT, three-valued logic | 1 hr |
| 8 | `01_foundations/07_insert.sql` | INSERT, multi-row, ON DUPLICATE KEY UPDATE | 1.5 hr |
| 9 | `01_foundations/08_null_values.sql` | NULL semantics, three-valued logic, COALESCE | 1.5 hr |
| 10 | `01_foundations/09_update.sql` | UPDATE, multi-table, conditional | 1 hr |
| 11 | `01_foundations/10_delete.sql` | DELETE, TRUNCATE, soft delete | 1 hr |

**Milestone**: You can query, insert, update, and delete rows; understand NULL
semantics; write basic filtering and sorting.

### Phase 2 — Relational Queries (2 weeks, ~15 hours)

| Order | File | Concepts | Time |
|-------|------|----------|------|
| 12 | `02_joins/01_joins_intro.sql` | All join types overview | 1.5 hr |
| 13 | `02_joins/02_inner_join.sql` | INNER JOIN, multi-table | 2 hr |
| 14 | `02_joins/03_left_join.sql` | LEFT JOIN, anti-join pattern | 2 hr |
| 15 | `02_joins/04_right_join.sql` | RIGHT JOIN, when to rewrite | 45 min |
| 16 | `02_joins/05_full_join.sql` | FULL JOIN emulation in MySQL | 1 hr |
| 17 | `02_joins/06_self_join.sql` | Self-joins for hierarchies | 1.5 hr |
| 18 | `03_subqueries/01_subqueries_basics.sql` | Scalar, row, table subqueries | 2 hr |
| 19 | `03_subqueries/02_exists.sql` | EXISTS, NOT EXISTS, NULL safety | 1.5 hr |
| 20 | `03_subqueries/03_any_all.sql` | ANY, ALL, equivalences | 1 hr |
| 21 | `03_subqueries/04_select_into_select_into.sql` | CREATE TABLE AS SELECT, INSERT SELECT | 1 hr |
| 22 | `04_set_operations/01_union.sql` + `02_union_all.sql` | UNION, UNION ALL, performance | 1.5 hr |
| 23 | `04_set_operations/03_case.sql` | CASE expression | 1.5 hr |

**Milestone**: You can write complex queries with joins, subqueries, and set
operations. You understand relational data retrieval thoroughly.

### Phase 3 — Aggregation & Filtering (1 week, ~10 hours)

| Order | File | Concepts | Time |
|-------|------|----------|------|
| 24 | `05_aggregates_and_grouping/01_aggregate_functions.sql` | COUNT, SUM, AVG, MIN, MAX, GROUP_CONCAT | 1.5 hr |
| 25 | `05_aggregates_and_grouping/02_min_max_count_sum_avg.sql` | Detailed aggregate behavior | 1.5 hr |
| 26 | `05_aggregates_and_grouping/03_group_by.sql` | GROUP BY, multi-column, WITH ROLLUP | 2 hr |
| 27 | `05_aggregates_and_grouping/04_having.sql` | HAVING vs WHERE, group filtering | 1.5 hr |
| 28 | `06_filtering_and_operators/01_select_top_limit.sql` | LIMIT, OFFSET, keyset pagination | 1 hr |
| 29 | `06_filtering_and_operators/02_like.sql` | LIKE, %, _, case sensitivity | 1 hr |
| 30 | `06_filtering_and_operators/03_wildcards.sql` | Wildcards, REGEXP | 1 hr |
| 31 | `06_filtering_and_operators/04_in_operator.sql` | IN, NOT IN, NULL trap | 1 hr |
| 32 | `06_filtering_and_operators/05_between.sql` | BETWEEN, date boundary trap | 45 min |
| 33 | `06_filtering_and_operators/06_aliases.sql` | Column & table aliases, scope rules | 45 min |
| 34 | `06_filtering_and_operators/07_null_functions.sql` | IFNULL, COALESCE, NULLIF, IF | 1 hr |
| 35 | `06_filtering_and_operators/08_operators.sql` | All operators, precedence | 1 hr |
| 36 | `06_filtering_and_operators/09_comments.sql` | Comment styles, executable comments | 30 min |

**Milestone**: You can write summary queries with aggregations and grouping,
and use all filtering operators fluently.

### Phase 4 — Security (3 days, ~5 hours)

| Order | File | Concepts | Time |
|-------|------|----------|------|
| 37 | `07_security/01_sql_injection.sql` | SQLi patterns, defense in depth | 1.5 hr |
| 38 | `07_security/02_parameterized_queries.sql` | PREPARE/EXECUTE, placeholders | 1.5 hr |
| 39 | `07_security/03_prepared_statements.sql` | Statement caching, dynamic SQL | 1 hr |
| 40 | `07_security/04_user_management.sql` | CREATE USER, GRANT/REVOKE, roles | 1.5 hr |

**Milestone**: You can secure database access, parameterize queries, manage
users and roles safely.

### Phase 5 — Database Administration (1 week, ~10 hours)

| Order | File | Concepts | Time |
|-------|------|----------|------|
| 41 | `08_database_admin/01_create_drop_db.sql` | CREATE/DROP DATABASE, charsets | 45 min |
| 42 | `08_database_admin/02_create_table.sql` | All column types, constraints, generated columns | 2 hr |
| 43 | `08_database_admin/03_alter_table.sql` | ALTER TABLE operations, online DDL | 1.5 hr |
| 44 | `08_database_admin/04_constraints.sql` | NOT NULL, UNIQUE, PK, FK, CHECK, DEFAULT | 2 hr |
| 45 | `08_database_admin/05_indexes.sql` | Index types, composite indexes, EXPLAIN | 2 hr |
| 46 | `08_database_admin/06_auto_increment_dates.sql` | AUTO_INCREMENT, date functions | 1.5 hr |
| 47 | `08_database_admin/07_views.sql` | CREATE VIEW, updatable views, security | 1.5 hr |
| 48 | `08_database_admin/08_stored_procedures.sql` | Procedures, functions, control flow, cursors | 2.5 hr |
| 49 | `08_database_admin/09_backup_hosting.sql` | mysqldump, replication, hosting | 1 hr |

**Milestone**: You can design schemas, write DDL, create views and stored
procedures, perform backups.

### Phase 6 — Advanced MySQL (2 weeks, ~20 hours)

| Order | File | Concepts | Time |
|-------|------|----------|------|
| 50 | `09_advanced_mysql/01_window_functions.sql` | ROW_NUMBER, RANK, LAG, LEAD, OVER | 3 hr |
| 51 | `09_advanced_mysql/02_ctes.sql` | WITH clause, named subqueries | 1.5 hr |
| 52 | `09_advanced_mysql/03_recursive_ctes.sql` | Hierarchies, graph traversal | 2 hr |
| 53 | `09_advanced_mysql/04_json_functions.sql` | JSON columns, JSON_EXTRACT, JSON_TABLE | 2 hr |
| 54 | `09_advanced_mysql/05_triggers.sql` | BEFORE/AFTER triggers, audit logs | 2 hr |
| 55 | `09_advanced_mysql/06_events.sql` | Scheduled events, cron-like tasks | 1 hr |
| 56 | `09_advanced_mysql/07_transactions.sql` | ACID, BEGIN/COMMIT/ROLLBACK, SAVEPOINT | 2 hr |
| 57 | `09_advanced_mysql/08_locks_isolation.sql` | Shared/exclusive locks, deadlocks | 2 hr |
| 58 | `09_advanced_mysql/09_fulltext_search.sql` | FULLTEXT, MATCH AGAINST | 1.5 hr |
| 59 | `09_advanced_mysql/10_explain_performance.sql` | EXPLAIN, query plans | 2 hr |
| 60 | `09_advanced_mysql/11_indexing_strategies.sql` | Index design, leftmost prefix | 2 hr |

**Milestone**: You can write modern SQL (window functions, CTEs, JSON),
maintain data integrity (triggers, transactions), and optimize queries.

### Phase 7 — Progressive Challenges (1 week, ~10 hours)

Work through these exercises in order. Try each problem before peeking at the
solution file.

| Order | File | # Exercises | Difficulty |
|-------|------|-------------|-----------|
| 61 | `10_progressive_challenges/01_easy_challenges.sql` | 20 | Beginner |
| 62 | `10_progressive_challenges/02_medium_challenges.sql` | 20 | Intermediate |
| 63 | `10_progressive_challenges/03_hard_challenges.sql` | 20 | Advanced |
| 64 | `10_progressive_challenges/04_expert_challenges.sql` | 20 | Expert |

**Milestone**: You can solve realistic data problems independently.

---

## Setup Instructions

### Step 1 — Install MySQL 8.0+

**macOS (Homebrew)**:
```bash
brew install mysql
brew services start mysql
mysql_secure_installation
```

**Ubuntu/Debian**:
```bash
sudo apt update
sudo apt install mysql-server
sudo systemctl start mysql
sudo mysql_secure_installation
```

**Windows**: Download the installer from
https://dev.mysql.com/downloads/installer/ and follow the wizard.

**Docker** (any OS):
```bash
docker run --name mysql8 -e MYSQL_ROOT_PASSWORD=yourpassword -p 3306:3306 -d mysql:8.0
docker exec -it mysql8 mysql -u root -pyourpassword
```

### Step 2 — Verify Installation

```bash
mysql --version
# mysql  Ver 8.0.xx for Linux on x86_64 (MySQL Community Server - GPL)
```

```bash
mysql -u root -p -e "SELECT VERSION();"
# +-----------+
# | VERSION() |
# +-----------+
# | 8.0.xx    |
# +-----------+
```

### Step 3 — Load the Course Database

```bash
cd /path/to/sql-course

# Create schema
mysql -u root -p < 00_setup/00_schema.sql

# Load sample data
mysql -u root -p < 00_setup/01_seed_data.sql

# Verify
mysql -u root -p -e "USE ecom; SHOW TABLES;"
```

Expected output:
```
+----------------+
| Tables_in_ecom |
+----------------+
| categories     |
| customers      |
| employees      |
| order_items    |
| orders         |
| products       |
| reviews        |
+----------------+
```

### Step 4 — Try Your First Query

```bash
mysql -u root -p ecom
```

```sql
SELECT first_name, last_name, country
FROM customers
WHERE is_active = 1
ORDER BY country, last_name;
```

### Step 5 — Use MySQL Workbench (optional GUI)

1. Download MySQL Workbench from https://dev.mysql.com/downloads/workbench/
2. Connect to localhost, user root, your password.
3. Open any `.sql` file from this course and execute with `Ctrl+Shift+Enter`.

### Step 6 — Recommended CLI Settings

Add to `~/.my.cnf`:
```ini
[client]
user=root
password=yourpassword
database=ecom

[mysql]
pager=less -S
safe-updates
auto-vertical-output
```

Then `mysql` connects automatically to the `ecom` database.

---

## Cheat Sheet

### SELECT Statement Skeleton

```sql
SELECT   col1, col2, expr AS alias
FROM     table1 [AS t1]
[JOIN    table2 [AS t2] ON t1.id = t2.t1_id]
WHERE    predicate
GROUP BY col1, col2
HAVING   aggregate_predicate
ORDER BY col1 [ASC|DESC], col2 [ASC|DESC]
LIMIT    n [OFFSET m];
```

**Logical evaluation order**:
```
FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY → LIMIT
```

### Comparison Operators

| Operator | Meaning |
|----------|---------|
| `=` | Equal |
| `<>` or `!=` | Not equal |
| `<`, `<=`, `>`, `>=` | Comparison |
| `<=>` | NULL-safe equal (NULL = NULL returns TRUE) |
| `IS NULL` / `IS NOT NULL` | NULL test |
| `BETWEEN a AND b` | Inclusive range |
| `IN (a, b, c)` | Equals any of |
| `NOT IN (a, b, c)` | Equals none of (NULL trap!) |
| `LIKE 'pat%'` | Pattern match (`%` = any chars, `_` = one char) |
| `REGEXP 'pat'` | Regular expression match |
| `EXISTS (subquery)` | Subquery returns ≥ 1 row |

### Logical Operators

| Operator | Meaning |
|----------|---------|
| `AND` | Both true |
| `OR` | Either true |
| `NOT` | Negation |
| `XOR` | Exactly one true |

**Precedence**: NOT > AND > OR (use parentheses liberally).

### Aggregate Functions

| Function | Behavior |
|----------|---------|
| `COUNT(*)` | Count all rows (including NULLs) |
| `COUNT(col)` | Count non-NULL col values |
| `COUNT(DISTINCT col)` | Count unique non-NULL values |
| `SUM(col)` | Sum of non-NULL values |
| `AVG(col)` | Average of non-NULL values (NULLs ignored) |
| `MIN(col)` / `MAX(col)` | Minimum / Maximum of non-NULL values |
| `GROUP_CONCAT(col SEPARATOR ',')` | Concatenate values (MySQL) |

### JOIN Types

| Join | Result |
|------|--------|
| `INNER JOIN` | Only matching rows |
| `LEFT [OUTER] JOIN` | All left rows; NULL right when no match |
| `RIGHT [OUTER] JOIN` | All right rows; NULL left when no match |
| `FULL [OUTER] JOIN` | All rows from both; MySQL emulates via UNION |
| `CROSS JOIN` | Cartesian product (every left × every right) |
| `SELF JOIN` | Table joined to itself (use aliases) |

### Data Types Quick Reference

| Type | Use for | Size |
|------|---------|------|
| `TINYINT(1)` | Boolean (0/1) | 1 byte |
| `INT` / `BIGINT` | Integer IDs | 4 / 8 bytes |
| `DECIMAL(10,2)` | Money (exact) | variable |
| `FLOAT` / `DOUBLE` | Approximate numbers (avoid for money) | 4 / 8 bytes |
| `VARCHAR(n)` | Variable string | n bytes |
| `TEXT` | Long text (up to 64KB) | length + 2 |
| `DATE` | YYYY-MM-DD | 3 bytes |
| `TIME` | HH:MM:SS | 3 bytes |
| `DATETIME` | Date+time, no TZ | 8 bytes |
| `TIMESTAMP` | Date+time, UTC-stored | 4 bytes (Y2038 limit) |
| `JSON` | JSON document | variable |
| `ENUM(...)` | One of listed values | 1-2 bytes |
| `BLOB` | Binary data | variable |

### Common Date Functions

| Function | Returns |
|----------|---------|
| `NOW()` / `CURRENT_TIMESTAMP` | Current date+time |
| `CURDATE()` | Current date |
| `CURTIME()` | Current time |
| `YEAR(d)` / `MONTH(d)` / `DAY(d)` | Extract part |
| `DATE_ADD(d, INTERVAL n DAY)` | Add interval |
| `DATE_SUB(d, INTERVAL n DAY)` | Subtract interval |
| `DATEDIFF(d1, d2)` | Days between |
| `DATE_FORMAT(d, '%Y-%m-%d')` | Format |
| `UNIX_TIMESTAMP()` | Epoch seconds |

### Common String Functions

| Function | Returns |
|----------|---------|
| `CONCAT(a, b, c)` | Concatenated string (NULL-propagating) |
| `CONCAT_WS(sep, a, b, c)` | Concat with separator (NULL-skipping) |
| `LENGTH(s)` | Byte length |
| `CHAR_LENGTH(s)` | Character length |
| `UPPER(s)` / `LOWER(s)` | Case conversion |
| `SUBSTRING(s, pos, len)` | Substring |
| `SUBSTRING_INDEX(s, delim, n)` | Substring before nth delim |
| `TRIM(s)` / `LTRIM` / `RTRIM` | Trim whitespace |
| `REPLACE(s, from, to)` | Replace all occurrences |
| `LEFT(s, n)` / `RIGHT(s, n)` | First/last n chars |
| `LOCATE(sub, s)` | Position of sub in s (1-indexed) |
| `REVERSE(s)` | Reverse |
| `LPAD(s, n, pad)` / `RPAD` | Pad to length n |

### NULL-Handling Functions

| Function | Returns |
|----------|---------|
| `IFNULL(a, b)` | `a` if not NULL, else `b` |
| `COALESCE(a, b, c, ...)` | First non-NULL value (ANSI standard) |
| `NULLIF(a, b)` | NULL if `a = b`, else `a` |
| `ISNULL(a)` | 1 if NULL, else 0 |
| `IF(cond, x, y)` | `x` if cond TRUE, else `y` |

### Window Function Syntax

```sql
function(args) OVER (
    [PARTITION BY col1, col2]
    [ORDER BY col3 [ASC|DESC]]
    [ROWS BETWEEN frame_start AND frame_end]
)
```

| Function | Returns |
|----------|---------|
| `ROW_NUMBER()` | Sequential integer per row in partition |
| `RANK()` | Rank with gaps after ties |
| `DENSE_RANK()` | Rank without gaps |
| `LAG(col, n)` | Value n rows before current |
| `LEAD(col, n)` | Value n rows after current |
| `FIRST_VALUE(col)` | First value in window |
| `LAST_VALUE(col)` | Last value in window (watch frame!) |
| `NTH_VALUE(col, n)` | Nth value in window |
| `NTILE(n)` | Bucket rows into n groups |
| `SUM/AVG/COUNT/MIN/MAX(col) OVER (...)` | Aggregate over window |
| `CUME_DIST()` / `PERCENT_RANK()` | Statistical distribution |

---

## MySQL Keywords Glossary

A non-exhaustive list of MySQL reserved words. Full list:
https://dev.mysql.com/doc/refman/8.0/en/keywords.html

| Keyword | Meaning |
|---------|---------|
| `ADD` | Add column/index in ALTER TABLE |
| `ALL` | Quantifier for subqueries |
| `ALTER` | Modify schema |
| `AND` | Logical AND |
| `AS` | Alias keyword (optional) |
| `ASC` | Ascending sort (default) |
| `AUTO_INCREMENT` | Auto-assigned sequential value |
| `BEGIN` | Start a transaction |
| `BETWEEN` | Inclusive range test |
| `BY` | Used in GROUP BY / ORDER BY |
| `CASCADE` | FK action: propagate to children |
| `CASE` | Conditional expression |
| `CHECK` | Constraint predicate |
| `COLLATE` | Specify collation |
| `COLUMN` | Column reference (optional) |
| `COMMIT` | Persist transaction |
| `CONSTRAINT` | Named rule |
| `CREATE` | Create database/table/index/etc. |
| `CROSS` | Cross join (Cartesian) |
| `CURRENT_TIMESTAMP` | Now |
| `DATABASE` | Schema reference |
| `DEFAULT` | Default value |
| `DELETE` | Remove rows |
| `DESC` | Descending sort |
| `DISTINCT` | Remove duplicates |
| `DROP` | Remove object |
| `ELSE` | CASE branch |
| `END` | End of block/CASE |
| `EXISTS` | Subquery returns rows |
| `FETCH` | Standard SQL alternative to LIMIT |
| `FOREIGN` | FK reference |
| `FROM` | Source table |
| `FULL` | Full outer join (emulated in MySQL) |
| `GROUP` | Group rows |
| `HAVING` | Filter groups |
| `IF` | Conditional (MySQL extension) |
| `IN` | Equals any of |
| `INDEX` | Create/show index |
| `INNER` | Inner join |
| `INSERT` | Add rows |
| `INTERVAL` | Date arithmetic |
| `INTO` | INSERT target / SELECT INTO variable |
| `IS` | NULL test (IS NULL) |
| `JOIN` | Combine tables |
| `KEY` | Synonym for INDEX |
| `LEFT` | Left outer join |
| `LIKE` | Pattern match |
| `LIMIT` | Restrict row count |
| `LOCK` | Acquire lock |
| `MOD` | Modulo |
| `NATURAL` | Join on matching column names |
| `NOT` | Negation |
| `NULL` | Missing value marker |
| `OFFSET` | Skip rows in LIMIT |
| `ON` | Join predicate or UPDATE target |
| `OR` | Logical OR |
| `ORDER` | Sort |
| `OUTER` | Outer join qualifier (optional) |
| `PARTITION` | Partition clause |
| `PRIMARY` | Primary key |
| `REFERENCES` | FK target |
| `REGEXP` / `RLIKE` | Regular expression match |
| `REPLACE` | DELETE+INSERT on conflict |
| `RESTRICT` | FK action: refuse delete |
| `RIGHT` | Right outer join |
| `ROLLBACK` | Undo transaction |
| `SAVEPOINT` | Mark within transaction |
| `SELECT` | Read rows |
| `SET` | Assign value (UPDATE or variable) |
| `SHOW` | Inspect metadata |
| `SOME` | Synonym for ANY |
| `TABLE` | Table reference |
| `TEMPORARY` | Session-scoped table |
| `THEN` | CASE branch |
| `TO` | RENAME target |
| `TRANSACTION` | Atomic unit of work |
| `TRIGGER` | Auto-firing code |
| `TRUNCATE` | Empty table fast |
| `UNION` | Combine result sets (dedup) |
| `UNIQUE` | Distinct values |
| `UPDATE` | Modify rows |
| `USE` | Select database |
| `USING` | Join by column name |
| `VALUES` | INSERT row values |
| `VIEW` | Virtual table |
| `WHEN` | CASE branch |
| `WHERE` | Row filter |
| `WITH` | CTE introduction |
| `XOR` | Exactly one true |

---

## MySQL Functions Reference

### String Functions

| Function | Syntax | Description |
|----------|--------|-------------|
| `ASCII` | `ASCII(s)` | ASCII code of first char |
| `CHAR_LENGTH` | `CHAR_LENGTH(s)` | Character count |
| `CHARACTER_LENGTH` | `CHARACTER_LENGTH(s)` | Synonym for CHAR_LENGTH |
| `CONCAT` | `CONCAT(s1, s2, ...)` | Concatenate (NULL-propagating) |
| `CONCAT_WS` | `CONCAT_WS(sep, s1, s2, ...)` | Concat with separator (NULL-skipping) |
| `ELT` | `ELT(n, s1, s2, ...)` | Nth string from list |
| `FIELD` | `FIELD(s, s1, s2, ...)` | Position of s in list |
| `FIND_IN_SET` | `FIND_IN_SET(s, list)` | Position of s in comma-separated list |
| `FORMAT` | `FORMAT(num, dec)` | Format number with thousands sep |
| `FROM_BASE64` | `FROM_BASE64(s)` | Decode base64 |
| `HEX` | `HEX(s)` | Hex representation |
| `INSERT` | `INSERT(s, pos, len, new)` | Replace substring |
| `INSTR` | `INSTR(s, sub)` | Position of sub in s |
| `LCASE` | `LCASE(s)` | Synonym for LOWER |
| `LEFT` | `LEFT(s, n)` | First n chars |
| `LENGTH` | `LENGTH(s)` | Byte length |
| `LOAD_FILE` | `LOAD_FILE(path)` | Read file content |
| `LOCATE` | `LOCATE(sub, s[, pos])` | Position of sub in s |
| `LOWER` | `LOWER(s)` | Lowercase |
| `LPAD` | `LPAD(s, n, pad)` | Left-pad to length n |
| `LTRIM` | `LTRIM(s)` | Trim leading whitespace |
| `MAKE_SET` | `MAKE_SET(bits, s1, s2, ...)` | Build set from bits |
| `MID` | `MID(s, pos, len)` | Synonym for SUBSTRING |
| `OCTET_LENGTH` | `OCTET_LENGTH(s)` | Synonym for LENGTH |
| `ORD` | `ORD(s)` | Numeric code of first char |
| `POSITION` | `POSITION(sub IN s)` | Synonym for LOCATE |
| `QUOTE` | `QUOTE(s)` | Escape for SQL literal |
| `REGEXP` | `s REGEXP pat` | Regex match |
| `REPEAT` | `REPEAT(s, n)` | Repeat string n times |
| `REPLACE` | `REPLACE(s, from, to)` | Replace all occurrences |
| `REVERSE` | `REVERSE(s)` | Reverse string |
| `RIGHT` | `RIGHT(s, n)` | Last n chars |
| `RPAD` | `RPAD(s, n, pad)` | Right-pad to length n |
| `RTRIM` | `RTRIM(s)` | Trim trailing whitespace |
| `SPACE` | `SPACE(n)` | String of n spaces |
| `STRCMP` | `STRCMP(s1, s2)` | Compare strings (-1/0/1) |
| `SUBSTR` | `SUBSTR(s, pos[, len])` | Synonym for SUBSTRING |
| `SUBSTRING` | `SUBSTRING(s, pos[, len])` | Extract substring |
| `SUBSTRING_INDEX` | `SUBSTRING_INDEX(s, delim, n)` | Substring before nth delim |
| `TO_BASE64` | `TO_BASE64(s)` | Encode base64 |
| `TRIM` | `TRIM([{BOTH\|LEADING\|TRAILING} [rem] FROM] s)` | Trim |
| `UCASE` | `UCASE(s)` | Synonym for UPPER |
| `UNHEX` | `UNHEX(s)` | Decode hex |
| `UPPER` | `UPPER(s)` | Uppercase |
| `WEIGHT_STRING` | `WEIGHT_STRING(s AS level)` | Sort weight |

### Numeric Functions

| Function | Syntax | Description |
|----------|--------|-------------|
| `ABS` | `ABS(n)` | Absolute value |
| `ACOS` | `ACOS(n)` | Arc cosine |
| `ASIN` | `ASIN(n)` | Arc sine |
| `ATAN` | `ATAN(n)` / `ATAN2(y, x)` | Arc tangent |
| `CEIL` / `CEILING` | `CEIL(n)` | Round up |
| `CONV` | `CONV(n, from_base, to_base)` | Convert base |
| `COS` | `COS(n)` | Cosine |
| `COT` | `COT(n)` | Cotangent |
| `CRC32` | `CRC32(s)` | CRC32 checksum |
| `DEGREES` | `DEGREES(n)` | Radians to degrees |
| `EXP` | `EXP(n)` | e^n |
| `FLOOR` | `FLOOR(n)` | Round down |
| `GREATEST` | `GREATEST(a, b, ...)` | Largest value |
| `LEAST` | `LEAST(a, b, ...)` | Smallest value |
| `LN` | `LN(n)` | Natural log |
| `LOG` | `LOG(n)` / `LOG(b, n)` | Logarithm |
| `LOG2` / `LOG10` | `LOG2(n)` / `LOG10(n)` | Log base 2 / 10 |
| `MOD` | `MOD(n, m)` | Modulo (n % m) |
| `PI` | `PI()` | Value of π |
| `POW` / `POWER` | `POW(x, y)` | x^y |
| `RADIANS` | `RADIANS(n)` | Degrees to radians |
| `RAND` | `RAND([seed])` | Random float 0..1 |
| `ROUND` | `ROUND(n[, dec])` | Round to dec places |
| `SIGN` | `SIGN(n)` | -1, 0, or 1 |
| `SIN` | `SIN(n)` | Sine |
| `SQRT` | `SQRT(n)` | Square root |
| `TAN` | `TAN(n)` | Tangent |
| `TRUNCATE` | `TRUNCATE(n, dec)` | Truncate to dec places |

### Date & Time Functions

| Function | Syntax | Description |
|----------|--------|-------------|
| `ADDDATE` | `ADDDATE(d, INTERVAL expr unit)` | Add interval |
| `ADDTIME` | `ADDTIME(t1, t2)` | Add time |
| `CONVERT_TZ` | `CONVERT_TZ(d, from_tz, to_tz)` | Convert time zone |
| `CURDATE` / `CURRENT_DATE` | `CURDATE()` | Today's date |
| `CURTIME` / `CURRENT_TIME` | `CURTIME()` | Current time |
| `CURRENT_TIMESTAMP` / `NOW` | `NOW()` | Current date+time |
| `DATE` | `DATE(d)` | Extract date part |
| `DATE_ADD` / `DATE_SUB` | `DATE_ADD(d, INTERVAL ...)` | Add/subtract |
| `DATE_FORMAT` | `DATE_FORMAT(d, fmt)` | Format |
| `DATEDIFF` | `DATEDIFF(d1, d2)` | Days between |
| `DAY` | `DAY(d)` | Day of month |
| `DAYNAME` | `DAYNAME(d)` | Name of weekday |
| `DAYOFMONTH` | `DAYOFMONTH(d)` | Synonym for DAY |
| `DAYOFWEEK` | `DAYOFWEEK(d)` | Day of week (1=Sun) |
| `DAYOFYEAR` | `DAYOFYEAR(d)` | Day of year (1-366) |
| `EXTRACT` | `EXTRACT(unit FROM d)` | Extract part |
| `FROM_DAYS` | `FROM_DAYS(n)` | Day number to date |
| `FROM_UNIXTIME` | `FROM_UNIXTIME(epoch)` | Epoch to date |
| `GET_FORMAT` | `GET_FORMAT(DATE, 'USA')` | Format string |
| `HOUR` | `HOUR(t)` | Hour |
| `LAST_DAY` | `LAST_DAY(d)` | Last day of month |
| `LOCALTIME` / `LOCALTIMESTAMP` | `LOCALTIMESTAMP()` | Synonym for NOW |
| `MAKEDATE` | `MAKEDATE(y, doy)` | Build date |
| `MAKETIME` | `MAKETIME(h, m, s)` | Build time |
| `MICROSECOND` | `MICROSECOND(t)` | Microsecond part |
| `MINUTE` | `MINUTE(t)` | Minute |
| `MONTH` | `MONTH(d)` | Month number |
| `MONTHNAME` | `MONTHNAME(d)` | Month name |
| `PERIOD_ADD` | `PERIOD_ADD(p, n)` | Add months to YYYYMM |
| `PERIOD_DIFF` | `PERIOD_DIFF(p1, p2)` | Months between YYYYMM |
| `QUARTER` | `QUARTER(d)` | Quarter (1-4) |
| `SECOND` | `SECOND(t)` | Second |
| `SEC_TO_TIME` | `SEC_TO_TIME(s)` | Seconds to time |
| `STR_TO_DATE` | `STR_TO_DATE(s, fmt)` | Parse date |
| `SUBDATE` | `SUBDATE(d, INTERVAL ...)` | Subtract |
| `SUBTIME` | `SUBTIME(t1, t2)` | Subtract time |
| `SYSDATE` | `SYSDATE()` | Current date+time (real-time) |
| `TIME` | `TIME(d)` | Extract time part |
| `TIME_FORMAT` | `TIME_FORMAT(t, fmt)` | Format time |
| `TIME_TO_SEC` | `TIME_TO_SEC(t)` | Time to seconds |
| `TIMEDIFF` | `TIMEDIFF(t1, t2)` | Time between |
| `TIMESTAMP` | `TIMESTAMP(d[, t])` | Date+time |
| `TIMESTAMPADD` | `TIMESTAMPADD(unit, n, d)` | Add interval |
| `TIMESTAMPDIFF` | `TIMESTAMPDIFF(unit, d1, d2)` | Difference |
| `TO_DAYS` | `TO_DAYS(d)` | Date to day number |
| `TO_SECONDS` | `TO_SECONDS(d)` | Date to seconds |
| `UNIX_TIMESTAMP` | `UNIX_TIMESTAMP([d])` | Date to epoch |
| `UTC_DATE` / `UTC_TIME` / `UTC_TIMESTAMP` | `UTC_TIMESTAMP()` | UTC values |
| `WEEK` | `WEEK(d[, mode])` | Week number |
| `WEEKDAY` | `WEEKDAY(d)` | Day of week (0=Mon) |
| `WEEKOFYEAR` | `WEEKOFYEAR(d)` | Week number |
| `YEAR` | `YEAR(d)` | Year |
| `YEARWEEK` | `YEARWEEK(d[, mode])` | Year+week |

### Aggregate Functions

| Function | Syntax | Description |
|----------|--------|-------------|
| `AVG` | `AVG(col)` | Average |
| `BIT_AND` / `BIT_OR` / `BIT_XOR` | `BIT_AND(col)` | Bitwise aggregate |
| `COUNT` | `COUNT(*)` / `COUNT(col)` / `COUNT(DISTINCT col)` | Count |
| `GROUP_CONCAT` | `GROUP_CONCAT(col [ORDER BY ...] [SEPARATOR sep])` | Concatenate |
| `JSON_ARRAYAGG` | `JSON_ARRAYAGG(col)` | Aggregate to JSON array |
| `JSON_OBJECTAGG` | `JSON_OBJECTAGG(key, value)` | Aggregate to JSON object |
| `MAX` / `MIN` | `MAX(col)` / `MIN(col)` | Maximum / minimum |
| `STD` / `STDDEV` / `STDDEV_POP` / `STDDEV_SAMP` | `STDDEV(col)` | Standard deviation |
| `SUM` | `SUM(col)` | Sum |
| `VAR_POP` / `VAR_SAMP` / `VARIANCE` | `VARIANCE(col)` | Variance |

### Window Functions (MySQL 8.0+)

| Function | Syntax | Description |
|----------|--------|-------------|
| `CUME_DIST` | `CUME_DIST() OVER w` | Cumulative distribution |
| `DENSE_RANK` | `DENSE_RANK() OVER w` | Rank without gaps |
| `FIRST_VALUE` | `FIRST_VALUE(col) OVER w` | First value in window |
| `LAG` | `LAG(col[, n[, default]]) OVER w` | Previous row's value |
| `LAST_VALUE` | `LAST_VALUE(col) OVER w` | Last value in window |
| `LEAD` | `LEAD(col[, n[, default]]) OVER w` | Next row's value |
| `NTH_VALUE` | `NTH_VALUE(col, n) OVER w` | Nth value in window |
| `NTILE` | `NTILE(n) OVER w` | Bucket into n groups |
| `PERCENT_RANK` | `PERCENT_RANK() OVER w` | Percentile rank |
| `RANK` | `RANK() OVER w` | Rank with gaps |
| `ROW_NUMBER` | `ROW_NUMBER() OVER w` | Sequential number |

Plus: `SUM`, `AVG`, `COUNT`, `MIN`, `MAX` can be used with `OVER()`.

### JSON Functions (MySQL 8.0+)

| Function | Syntax | Description |
|----------|--------|-------------|
| `JSON_ARRAY` | `JSON_ARRAY(a, b, c)` | Build array |
| `JSON_ARRAY_APPEND` | `JSON_ARRAY_APPEND(doc, path, val)` | Append to array |
| `JSON_ARRAY_INSERT` | `JSON_ARRAY_INSERT(doc, path, val)` | Insert into array |
| `JSON_CONTAINS` | `JSON_CONTAINS(doc, cand)` | Does doc contain cand |
| `JSON_CONTAINS_PATH` | `JSON_CONTAINS_PATH(doc, mode, paths...)` | Path exists |
| `JSON_DEPTH` | `JSON_DEPTH(doc)` | Max nesting depth |
| `JSON_EXTRACT` | `JSON_EXTRACT(doc, path)` | Extract value (JSON-typed) |
| `JSON_INSERT` | `JSON_INSERT(doc, path, val)` | Insert if missing |
| `JSON_KEYS` | `JSON_KEYS(doc)` | Object keys as array |
| `JSON_LENGTH` | `JSON_LENGTH(doc)` | Number of elements |
| `JSON_MERGE_PATCH` | `JSON_MERGE_PATCH(doc, patch)` | RFC 7396 merge |
| `JSON_MERGE_PRESERVE` | `JSON_MERGE_PRESERVE(doc, patch)` | Merge preserving arrays |
| `JSON_OBJECT` | `JSON_OBJECT('k1', v1, ...)` | Build object |
| `JSON_PRETTY` | `JSON_PRETTY(doc)` | Pretty-print |
| `JSON_QUOTE` | `JSON_QUOTE(s)` | Quote as JSON string |
| `JSON_REMOVE` | `JSON_REMOVE(doc, path)` | Remove elements |
| `JSON_REPLACE` | `JSON_REPLACE(doc, path, val)` | Replace existing |
| `JSON_SCHEMA_VALID` | `JSON_SCHEMA_VALID(schema, doc)` | Validate against schema |
| `JSON_SEARCH` | `JSON_SEARCH(doc, mode, str)` | Search for value |
| `JSON_SET` | `JSON_SET(doc, path, val)` | Insert or update |
| `JSON_STORAGE_FREE` / `JSON_STORAGE_SIZE` | `JSON_STORAGE_SIZE(doc)` | Storage info |
| `JSON_TABLE` | `JSON_TABLE(doc, path COLUMNS(...))` | Flatten JSON to rows |
| `JSON_TYPE` | `JSON_TYPE(doc)` | Type string |
| `JSON_UNQUOTE` | `JSON_UNQUOTE(json_str)` | Unquote JSON string |
| `JSON_VALID` | `JSON_VALID(s)` | Is valid JSON |
| `JSON_VALUE` | `JSON_VALUE(doc, path)` | Extract scalar |
| `MEMBER OF` | `val MEMBER OF (json_array)` | Is value in array |

### Other Functions

| Function | Syntax | Description |
|----------|--------|-------------|
| `CAST` / `CONVERT` | `CAST(x AS type)` | Type conversion |
| `COALESCE` | `COALESCE(a, b, ...)` | First non-NULL |
| `CONNECTION_ID` | `CONNECTION_ID()` | Current connection id |
| `CURRENT_USER` / `USER` | `CURRENT_USER()` | Authenticated user |
| `DATABASE` / `SCHEMA` | `DATABASE()` | Current database |
| `DEFAULT` | `DEFAULT(col)` | Column default value |
| `FOUND_ROWS` | `FOUND_ROWS()` | Rows last SELECT would have returned without LIMIT |
| `IF` | `IF(cond, x, y)` | Ternary |
| `IFNULL` | `IFNULL(a, b)` | a if not NULL, else b |
| `ISNULL` | `ISNULL(a)` | 1 if NULL |
| `LAST_INSERT_ID` | `LAST_INSERT_ID()` | AUTO_INC id of last INSERT |
| `NULLIF` | `NULLIF(a, b)` | NULL if a=b, else a |
| `ROW_COUNT` | `ROW_COUNT()` | Rows affected by last statement |
| `UUID` | `UUID()` | Generate UUID |
| `VERSION` | `VERSION()` | MySQL version string |

---

## Common Errors & Fixes

### Error 1048 (23000) — Column cannot be null
**Cause**: INSERT or UPDATE tried to set a NOT NULL column to NULL.
**Fix**: Provide a value, or use `DEFAULT`, or alter the column to allow NULL.

### Error 1054 (42S22) — Unknown column
**Cause**: Referencing a column that doesn't exist (typo, wrong table).
**Fix**: Check `DESCRIBE table;` to verify column names. Remember aliases
cannot be used in WHERE.

### Error 1062 (23000) — Duplicate entry
**Cause**: UNIQUE or PRIMARY KEY constraint violated.
**Fix**: Use `INSERT ... ON DUPLICATE KEY UPDATE` for upserts, or
`INSERT IGNORE` to skip duplicates, or remove the duplicate first.

### Error 1064 (42000) — Syntax error
**Cause**: Malformed SQL (missing comma, parenthesis mismatch).
**Fix**: Read the error position. Check for reserved words used as
identifiers (quote them with backticks).

### Error 1140 (42000) — Mixing grouped and non-grouped columns
**Cause**: ONLY_FULL_GROUP_BY mode rejects SELECT with non-aggregated columns
not in GROUP BY.
**Fix**: Add columns to GROUP BY, wrap in ANY_VALUE(), or rewrite the query.

### Error 1146 (42S02) — Table doesn't exist
**Cause**: Misspelled table name, wrong database, or forgot to run schema setup.
**Fix**: `USE ecom; SHOW TABLES;` to verify. Run `00_setup/00_schema.sql`.

### Error 1215 (HY000) — Cannot add foreign key constraint
**Cause**: Parent column not indexed, type mismatch, or parent column
doesn't exist.
**Fix**: Ensure parent column is indexed (typically PK). Verify types match
exactly. Check parent table exists.

### Error 1213 (40001) — Deadlock found
**Cause**: Two transactions waited on each other's locks.
**Fix**: Acquire locks in consistent order. Keep transactions short. Retry
the rolled-back transaction.

### Error 1235 (42000) — This version of MySQL doesn't yet support
**Cause**: Using a feature not in your MySQL version (e.g. FULL OUTER JOIN).
**Fix**: Emulate with UNION of LEFT and RIGHT joins (see 02_joins/05_full_join.sql).

### Error 1364 (HY000) — Field doesn't have a default value
**Cause**: INSERT omitted a NOT NULL column with no DEFAULT.
**Fix**: Provide the value explicitly, or add a DEFAULT to the column.

### Error 1369 (HY000) — CHECK OPTION failed
**Cause**: INSERT or UPDATE would make a row invisible through a WITH CHECK
OPTION view.
**Fix**: Ensure the row satisfies the view's WHERE clause.

### Error 1451 (23000) — Cannot delete or update a parent row
**Cause**: FK constraint prevents deleting a parent with children.
**Fix**: Delete children first, or change FK to ON DELETE CASCADE / SET NULL.

### Error 1452 (23000) — Cannot add or update a child row
**Cause**: FK constraint: parent_id doesn't exist in parent table.
**Fix**: Insert the parent first, or use a valid parent_id.

### Error 3819 (23000) — Check constraint violated
**Cause**: CHECK constraint predicate failed (MySQL 8.0.16+).
**Fix**: Ensure the value satisfies the constraint, or alter the constraint.

### Error 3572 (HY000) — Statement aborted (lock wait)
**Cause**: `NOWAIT` was used and a row was already locked.
**Fix**: Retry, or use `SKIP LOCKED` to skip locked rows.

### Error 1205 (HY000) — Lock wait timeout exceeded
**Cause**: Waited longer than `innodb_lock_wait_timeout` (default 50s) for a lock.
**Fix**: Identify the blocking transaction with
`SELECT * FROM performance_schema.data_lock_waits;`. Kill it with `KILL <pid>`.

---

## Interview Questions

### Beginner

**Q1**: What's the difference between `DELETE` and `TRUNCATE`?
**A**: DELETE is DML, fires triggers, can be in a transaction, can use WHERE.
TRUNCATE is DDL, drops and recreates the table, fires no triggers, cannot
be rolled back inside a transaction, resets AUTO_INCREMENT. TRUNCATE is
much faster on large tables.

**Q2**: What is a primary key? Can it be NULL?
**A**: A primary key uniquely identifies each row. It's NOT NULL + UNIQUE
plus a clustered index. Cannot be NULL.

**Q3**: What's the difference between `CHAR` and `VARCHAR`?
**A**: CHAR(n) is fixed-length (always n bytes, padded). VARCHAR(n) is
variable (1-2 byte length prefix + actual bytes). Use CHAR for short
fixed codes (country codes, status flags); VARCHAR for most text.

**Q4**: Why does `WHERE col = NULL` return no rows?
**A**: NULL = NULL evaluates to NULL (not TRUE), and a row passes WHERE
only if the predicate is TRUE. Use `WHERE col IS NULL`.

**Q5**: What's the difference between `INNER JOIN` and `LEFT JOIN`?
**A**: INNER JOIN returns only matching rows. LEFT JOIN returns all left
rows, with NULL right columns when there's no match.

### Intermediate

**Q6**: Explain three-valued logic in SQL.
**A**: Predicates evaluate to TRUE, FALSE, or NULL (UNKNOWN). NULL = NULL
is NULL. AND/OR/NOT follow 3VL truth tables. A row passes WHERE only if
the predicate is TRUE — FALSE and NULL both exclude.

**Q7**: What is normalization? Name three normal forms.
**A**: Normalization is the process of organizing tables to reduce
redundancy and improve integrity.
- 1NF: atomic values, no repeating groups.
- 2NF: 1NF + no partial dependency on a composite key.
- 3NF: 2NF + no transitive dependency (non-key attributes depend only on the key).

**Q8**: What's the difference between `WHERE` and `HAVING`?
**A**: WHERE filters rows BEFORE grouping and cannot use aggregates.
HAVING filters GROUPS AFTER grouping and can use aggregates.

**Q9**: Why use an index? What's the cost?
**A**: Indexes speed up WHERE, JOIN, ORDER BY, GROUP BY on indexed columns.
Cost: slower INSERT/UPDATE/DELETE (index must be maintained), disk space.
Aim for 5-7 indexes per write-heavy table.

**Q10**: Explain the leftmost-prefix rule.
**A**: A composite index on (a, b, c) can be used for queries filtering on
`a`, `a AND b`, or `a AND b AND c` — but NOT on `b` alone or `c` alone.
The index is sorted by a, then b within equal a, then c within equal (a,b).

**Q11**: What is SQL injection and how do you prevent it?
**A**: SQL injection occurs when user input is concatenated into a SQL
string and the user injects SQL syntax. Prevention: use parameterized
queries (PREPARE with `?` placeholders) — input becomes binary data,
never SQL syntax.

**Q12**: What's the difference between `UNION` and `UNION ALL`?
**A**: UNION removes duplicates (forces a sort/hash). UNION ALL preserves
duplicates (faster). Use UNION ALL when you know inputs are mutually
exclusive or want duplicates preserved.

### Advanced

**Q13**: Explain ACID properties.
**A**: Atomicity (all-or-nothing), Consistency (valid state transitions),
Isolation (concurrent transactions appear sequential), Durability (committed
data survives crashes). InnoDB provides full ACID.

**Q14**: What are the four isolation levels? Which anomalies does each prevent?
**A**:
- READ UNCOMMITTED: dirty reads possible.
- READ COMMITTED: no dirty reads; non-repeatable reads possible.
- REPEATABLE READ (MySQL default): no non-repeatable reads; phantoms possible
  in standard SQL, but InnoDB prevents phantoms via next-key locking.
- SERIALIZABLE: strongest, prevents all anomalies; may serialize.

**Q15**: What's a window function? How does it differ from GROUP BY?
**A**: A window function computes a value OVER a related set of rows
WITHOUT collapsing them — each row keeps its identity and gets an
additional computed value. GROUP BY collapses N rows into one per group.

**Q16**: What's a CTE? When would you use one?
**A**: A Common Table Expression is a named temporary result set for the
duration of one statement. Use when:
- A complex subquery is referenced multiple times.
- A query benefits from being broken into named steps.
- You need recursion (WITH RECURSIVE).

**Q17**: Explain optimistic vs pessimistic locking.
**A**: Pessimistic assumes conflicts will happen; locks rows with FOR UPDATE.
Use when contention is high. Optimistic assumes conflicts rare; reads a
version, checks at commit time. Use when contention is low and reads
outnumber writes.

**Q18**: What's a deadlock? How does MySQL detect it?
**A**: A deadlock is when two transactions hold locks the other needs.
MySQL's InnoDB has a deadlock detector that picks the transaction with
the smaller undo log as the victim and rolls it back (error 1213). The
other transaction proceeds.

**Q19**: How would you optimize a slow query?
**A**:
1. Run `EXPLAIN` to see the plan.
2. Look for `type=ALL` (full scan) or `Using filesort`/`Using temporary`.
3. Add indexes on filter/join/sort columns.
4. Rewrite to use index-friendly predicates (no functions on indexed columns).
5. Use covering indexes for hot queries.
6. Consider denormalization or materialized views for reports.

**Q20**: Explain the difference between `DATETIME` and `TIMESTAMP`.
**A**: DATETIME is 8 bytes, stores literal date/time, no timezone
conversion, range 1000-9999. TIMESTAMP is 4 bytes, stored as UTC epoch,
converted to session time_zone on read, range 1970-2038 (Y2038 problem).
Use DATETIME for distant past/future events; TIMESTAMP for recent
events with timezone awareness.

### Scenario-Based

**Q21**: How would you find the second-highest salary in a table?
**A**:
```sql
SELECT MAX(salary) FROM employees WHERE salary < (SELECT MAX(salary) FROM employees);
-- Modern way using window functions:
WITH ranked AS (
    SELECT salary, DENSE_RANK() OVER (ORDER BY salary DESC) AS rk
    FROM employees
)
SELECT salary FROM ranked WHERE rk = 2;
```

**Q22**: How would you find duplicate emails in a customers table?
**A**:
```sql
SELECT email, COUNT(*) AS cnt
FROM customers
GROUP BY email
HAVING COUNT(*) > 1;
```

**Q23**: How would you delete duplicates, keeping only the row with the
lowest id?
**A**:
```sql
DELETE c1 FROM customers c1
JOIN customers c2 ON c1.email = c2.email AND c1.id > c2.id;
```

**Q24**: How would you find customers who have never placed an order?
**A**:
```sql
-- LEFT JOIN approach:
SELECT c.* FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
WHERE o.id IS NULL;

-- NOT EXISTS approach (often faster):
SELECT c.* FROM customers c
WHERE NOT EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.id);
```

**Q25**: How would you implement pagination that's efficient for deep pages?
**A**: Use keyset (seek) pagination instead of OFFSET. Remember the last
seen value of the sort key and ask for rows strictly greater than it.
This is O(log n) lookup vs O(n) scan with OFFSET.

**Q26**: How would you find the top 3 customers per country by spend?
**A**:
```sql
WITH ranked AS (
    SELECT c.country, c.first_name, c.last_name, SUM(o.total) AS spend,
        ROW_NUMBER() OVER (PARTITION BY c.country ORDER BY SUM(o.total) DESC) AS rn
    FROM customers c JOIN orders o ON o.customer_id = c.id
    GROUP BY c.country, c.first_name, c.last_name
)
SELECT country, first_name, last_name, spend
FROM ranked WHERE rn <= 3;
```

**Q27**: How would you design a backup strategy?
**A**: Follow the 3-2-1 rule (3 copies, 2 media, 1 offsite). Combine:
- Daily logical backup with `mysqldump --single-transaction`.
- Continuous binary log retention for point-in-time recovery.
- Periodic physical backup (Percona XtraBackup) for fast restore.
- Replication to a hot standby for failover.
- Quarterly restore drills.

**Q28**: A query is slow. Walk me through your debugging process.
**A**:
1. `EXPLAIN` the query — check `type`, `key`, `rows`, `Extra`.
2. Identify full table scans (`type=ALL`) and bad indicators
   (`Using filesort`, `Using temporary`).
3. Check whether indexes exist on filter/join columns.
4. Check whether the query applies functions to indexed columns
   (defeats the index).
5. Run `EXPLAIN ANALYZE` (MySQL 8.0.18+) for actual timings.
6. Add or modify indexes; verify the plan improves.
7. Consider rewriting (e.g. NOT EXISTS instead of NOT IN, keyset
   pagination instead of OFFSET).
8. Check `slow_query_log` for systemic patterns.

**Q29**: How would you secure a production database?
**A**:
- Application DB user has only SELECT/INSERT/UPDATE/DELETE; never DROP/ALTER/SUPER/FILE.
- All queries use parameterized prepared statements (no SQLi).
- TLS for non-localhost connections.
- Encryption at rest (TDE).
- Network firewall restricts 3306 to app servers only.
- Auditing enabled (Enterprise Audit or MariaDB Audit Plugin).
- Regular GRANT reviews.
- Backups encrypted and offsite.
- Strong password policy; rotate periodically.

**Q30**: How would you handle a schema migration with zero downtime?
**A**: Use the "expand-contract" pattern:
1. **Expand**: add new column(s) alongside the old. Dual-write to both.
2. **Migrate**: backfill the new column from the old in batches.
3. **Switch**: read code switches to the new column.
4. **Verify**: monitor for discrepancies.
5. **Contract**: stop writing to old column, then drop it.
Each step is independently deployable and reversible.

---

## How to Use This Course

### Study Workflow

1. **Read** the SQL file linearly from top to bottom. Don't skip the
   textbook-depth comments at the top — they explain the WHY, not just
   the WHAT.
2. **Run** every example query against the `ecom` database. Modify the
   examples and observe the changes.
3. **Attempt** each exercise before looking at the solution.
4. **Compare** your solution with the one in `solutions/`. There's usually
   more than one way to solve a problem — both can be correct.
5. **Take notes** in a personal notebook or markdown file. Writing
   explanations in your own words cements understanding.

### Running Files

You can run an entire file:
```bash
mysql -u root -p ecom < 01_foundations/02_select.sql
```

Or interactively inside the mysql client:
```bash
mysql -u root -p ecom
mysql> SOURCE 01_foundations/02_select.sql;
```

For files with stored procedures (which use `DELIMITER`), use `SOURCE` or
pipe the file — GUI tools may split on semicolons incorrectly.

### Tips

- **Enable safe-updates mode** while learning:
  ```bash
  mysql --safe-updates -u root -p
  ```
  This prevents UPDATE/DELETE without a key in WHERE.

- **Use `\G` instead of `;`** to display wide rows vertically:
  ```sql
  SELECT * FROM customers\G
  ```

- **Use `pager less -S`** to page through wide results without wrapping.

- **Reset the database anytime**:
  ```bash
  mysql -u root -p < 00_setup/00_schema.sql
  mysql -u root -p < 00_setup/01_seed_data.sql
  ```

### Going Further

After completing this course:

1. **Read the MySQL 8.0 Reference Manual** end-to-end:
   https://dev.mysql.com/doc/refman/8.0/en/

2. **Read "High Performance MySQL"** by Vadim Tkachenko et al. (O'Reilly).

3. **Practice on LeetCode Database problems**:
   https://leetcode.com/studyplan/top-sql-50/

4. **Contribute to a real open-source project** that uses MySQL (WordPress,
   Drupal, Magento).

5. **Set up replication** on your local machine — master + slave. Practice
   failover.

6. **Explore MySQL's competitors**: PostgreSQL (richer types, stricter
   SQL), SQLite (embedded), SQL Server (T-SQL), Oracle (PL/SQL). Knowing
   the differences makes you a better engineer.

---

## License

This course is provided for educational use. The SQL examples are original
content. Sample data is synthetic.

Schema inspired by typical e-commerce patterns. No real customer data.

---

**Happy learning!** Work through the files in order, attempt every
exercise, and you'll have a deep, durable understanding of SQL and MySQL.
