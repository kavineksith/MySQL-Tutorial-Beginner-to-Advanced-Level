# Contributing to the SQL Course

First off: **thank you for considering a contribution!** 🗄️

This course exists to help people learn SQL end-to-end. Every contribution —
typo fixes, new examples, clearer explanations, additional exercises — makes
the material better for everyone.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Ways to Contribute](#ways-to-contribute)
- [Getting Started](#getting-started)
- [Contribution Workflow](#contribution-workflow)
- [Style Guidelines](#style-guidelines)
- [Practice with Real Open-Source Projects](#practice-with-real-open-source-projects)
- [Using This Course to Teach](#using-this-course-to-teach)
- [Questions?](#questions)

---

## Code of Conduct

Please be kind, patient, and welcoming. We are all here to learn.

---

## Ways to Contribute

### 🐛 Report Bugs or Broken Examples

If a SQL example doesn't run or the notes have incorrect information:

1. Check [existing issues](../../issues) to avoid duplicates.
2. Open a new issue with:
   - Chapter folder and file name (e.g. `02_joins/03_left_join.sql`)
   - What you expected vs. what happened
   - The exact error message
   - Your MySQL version (`SELECT VERSION();`)

### 💡 Suggest New Chapters or Improvements

Have an idea for a new topic, a better explanation, or additional exercises?
Open an issue with the `enhancement` label and describe:

- What topic you want to add or improve
- Why it's valuable
- A rough outline (if you have one)

### ✏️ Fix Typos and Clarify Explanations

Spotted a typo? An unclear comment? A confusing example? PRs are very
welcome — small fixes are just as valuable as big ones.

### 📝 Add Practice Problems

The `10_progressive_challenges/` folder has 80 exercises across four
difficulty levels. We'd love more! Open an issue to propose new problems
before writing them up.

### 🌍 Translate Notes to Other Languages

If you'd like to translate the SQL comments into another language, open an
issue first to coordinate so we don't duplicate work.

---

## Getting Started

### Prerequisites

- MySQL 8.0+ (or MariaDB 10.5+)
- Git
- A text editor with SQL syntax highlighting

### Setup

```bash
# Fork the repo on GitHub, then:
git clone https://github.com/YOUR-USERNAME/sql-course.git
cd sql-course

# Add the upstream remote:
git remote add upstream https://github.com/ORIGINAL-OWNER/sql-course.git

# Load the database:
mysql -u root -p < 00_setup/00_schema.sql
mysql -u root -p < 00_setup/01_seed_data.sql

# Verify the load:
mysql -u root -p -e "USE ecom; SELECT COUNT(*) FROM customers;"

# Test a file:
mysql -u root -p ecom < 01_foundations/01_intro_and_syntax.sql
```

### File Structure

Each chapter is a folder containing self-contained `.sql` files:

```
02_joins/
├── 01_joins_intro.sql       — concept explanation + runnable examples
├── 02_inner_join.sql
├── 03_left_join.sql
└── ...
```

Solutions live in the `solutions/` folder, with filenames matching the
chapter (e.g. `02_joins_solutions.sql`).

---

## Contribution Workflow

1. **Fork** the repository on GitHub.
2. **Clone** your fork locally.
3. **Create a branch** for your change:
   ```bash
   git checkout -b fix/typo-in-joins
   ```
4. **Make your changes**. Follow the [style guidelines](#style-guidelines).
5. **Verify** that your SQL runs without errors:
   ```bash
   mysql -u root -p ecom < 02_joins/03_left_join.sql
   ```
6. **Commit** with a clear message:
   ```bash
   git commit -m "Fix typo in left join examples"
   ```
7. **Push** to your fork:
   ```bash
   git push origin fix/typo-in-joins
   ```
8. **Open a Pull Request** on GitHub. Reference any related issues.

### Commit Message Conventions

- `Fix typo in chapter 02 joins notes`
- `Add example demonstrating LATERAL join in chapter 02`
- `Clarify NULL handling explanation in chapter 01`
- `Add 5 new medium-difficulty exercises`

---

## Style Guidelines

### For `.sql` Files

- Start each file with a banner comment:
  ```sql
  -- ============================================================================
  -- NN_file_name.sql — Short Title
  -- ============================================================================
  -- SKILL LEVEL : Beginner | Intermediate | Advanced
  -- PREREQUISITE: Previous files that must be read first
  -- TOPICS      : Comma-separated list of concepts
  -- ----------------------------------------------------------------------------
  ```
- Use **rich inline comments** explaining every concept.
- Every SQL statement should be preceded by a comment explaining what it does.
- Use the `ecom` sample database for all examples.
- End every statement with a semicolon `;`.
- Use lowercase for SQL keywords by convention (or uppercase — just be consistent).
- Test that the file runs without errors: `mysql -u root -p ecom < file.sql`

### For `README.md`

- Keep the table of contents up to date when adding chapters.
- Use Markdown tables for comparisons and reference material.

---

## Practice with Real Open-Source Projects

The best way to solidify your SQL skills is to **contribute to real
projects** that involve databases. Many open-source projects welcome
help with database schemas, migrations, query optimization, and
documentation.

### How to Find Database-Focused Projects

1. **Browse GitHub** for projects with SQL/database tags:
   - [github.com/topics/sql](https://github.com/topics/sql)
   - [github.com/topics/database](https://github.com/topics/database)
   - [github.com/topics/mysql](https://github.com/topics/mysql)

2. **Look for `good-first-issue` labels** in database projects.

3. **Contribute to database tools**:
   - [DBeaver](https://github.com/dbeaver/dbeaver) — universal database tool
   - [Flyway](https://github.com/flyway/flyway) — database migration tool
   - [Liquibase](https://github.com/liquibase/liquibase) — database version control
   - [PostgreSQL](https://github.com/postgres/postgres) — the database itself
   - [MariaDB](https://github.com/MariaDB/server) — MySQL fork
   - [SQLite](https://github.com/sqlite/sqlite) — embedded database
   - [Vitess](https://github.com/vitessio/vitess) — database clustering system
   - [PgAdmin](https://github.com/pgadmin-org/pgadmin4) — PostgreSQL admin tool
   - [Adminer](https://github.com/vrana/adminer) — single-file database manager

4. **Contribute to projects that USE databases**:
   - Most web applications need database help — look for issues labeled
     `database`, `sql`, `query-optimization`, or `performance`.

### Tips for Your First Database Contribution

1. **Read the project's `CONTRIBUTING.md`** before anything else.
2. **Set up the project locally** — including its database.
3. **Run the existing test suite** to make sure your environment works.
4. **Start small** — a documentation fix, a missing index, or a query
   optimization is a great first PR.
5. **Write tests** for your change if applicable.
6. **Explain your SQL changes** in the PR description — why does this
   query need changing? What does this new index improve?
7. **Be patient** — maintainers are often volunteers.
8. **Be kind** — even if your PR is rejected, thank the maintainer for
   their time.

### Specific SQL Contribution Ideas

| Type of contribution | Where to look |
|----------------------|---------------|
| Add a missing database index | Any project with slow queries |
| Fix a SQL injection vulnerability | Security-focused issues |
| Write a database migration | Projects adding new features |
| Optimize a slow query | Issues tagged `performance` |
| Improve database documentation | Any project with sparse DB docs |
| Add a stored procedure or view | Projects with complex reporting |
| Write database tests | Projects with low DB test coverage |

---

## Using This Course to Teach

You're welcome to use this material in classrooms, workshops, meetups,
and bootcamps under the MIT license. Some suggestions:

- **Load the sample database** on a shared server so students can follow along.
- **Project the `.sql` files** on a screen and walk through the comments.
- **Have students modify the queries** — change WHERE clauses, add JOINs,
  experiment with aggregates.
- **Use the progressive challenges** as homework.
- **Pair students up** — one writes a query, the other reviews it.

If you use this material in a course, we'd love to hear about it! Open an
issue with the `teaching` label and let us know.

---

## Questions?

- **Issues**: [open an issue](../../issues) for bugs, suggestions, or questions
- **Discussions**: [start a discussion](../../discussions) for general questions
- **MySQL community**: [forums.mysql.com](https://forums.mysql.com/)
- **Stack Overflow**: [stackoverflow.com/questions/tagged/sql](https://stackoverflow.com/questions/tagged/sql) or [mysql](https://stackoverflow.com/questions/tagged/mysql)

---

<p align="center">
  <sub>Thank you for helping make SQL more accessible to everyone. 🗄️</sub>
</p>
