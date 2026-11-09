-- ============================================================================
-- 00_schema.sql — E-Commerce Sample Database Schema
-- ============================================================================
-- Course       : Comprehensive SQL Tutorial (Beginner → Advanced)
-- Target DB    : MySQL 8.0+ (SQL:2023 compatible where noted)
-- Purpose      : Create the `ecom` database used by every example in this
--                course. Run this file FIRST, then run 01_seed_data.sql.
-- How to run   : mysql -u root -p < 00_schema.sql
--            or : SOURCE 00_schema.sql;   (inside the mysql client)
-- ----------------------------------------------------------------------------
-- DESIGN NOTES (textbook depth)
-- ----------------------------------------------------------------------------
-- 1. We use InnoDB as the storage engine because it is the only MySQL engine
--    that supports foreign keys, transactions, and row-level locking — the
--    three features you need for any realistic e-commerce workload.
--
-- 2. Every table has a surrogate BIGINT PRIMARY KEY named `id` with
--    AUTO_INCREMENT. This is a deliberate convention:
--      * BIGINT  → avoids overflow on high-volume tables (vs INT)
--      * Surrogate keys → business rules (e.g. email) can change without
--        forcing cascading primary-key updates across child tables.
--
-- 3. All money columns use DECIMAL(10,2), never FLOAT. Floating-point math
--    is non-deterministic and silently corrupts financial totals. DECIMAL is
--    exact, fixed-point arithmetic.
--
-- 4. TIMESTAMP columns use `DEFAULT CURRENT_TIMESTAMP` and
--    `ON UPDATE CURRENT_TIMESTAMP` so MySQL maintains audit timestamps
--    automatically — you never need to write `updated_at = NOW()` in
--    application code.
--
-- 5. Foreign keys include `ON DELETE RESTRICT` for parent tables (you cannot
--    delete a customer who has orders) and `ON DELETE CASCADE` only for true
--    child rows (order_items vanish when an order is deleted).
--
-- 6. UNIQUE constraints on natural keys (email, sku) prevent duplicate
--    business entities — the database enforces integrity, not the app.
--
-- 7. We add CHECK constraints (MySQL 8.0.16+ enforces them) to prevent
--    impossible values (negative prices, future birth dates, etc.).
-- ============================================================================

DROP DATABASE IF EXISTS ecom;
CREATE DATABASE ecom
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_0900_ai_ci;

USE ecom;

-- ============================================================================
-- TABLE: categories
--   Self-referencing tree of product categories (parent_id → categories.id).
--   Used to demonstrate recursive CTEs later in the course.
-- ============================================================================
CREATE TABLE categories (
    id          BIGINT       NOT NULL AUTO_INCREMENT,
    parent_id   BIGINT       NULL,
    name        VARCHAR(80)  NOT NULL,
    slug        VARCHAR(80)  NOT NULL,
    description TEXT         NULL,
    created_at  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
                                ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_categories_slug (slug),
    KEY idx_categories_parent (parent_id),
    CONSTRAINT fk_categories_parent
        FOREIGN KEY (parent_id) REFERENCES categories(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_categories_name
        CHECK (CHAR_LENGTH(name) BETWEEN 1 AND 80)
) ENGINE=InnoDB;

-- ============================================================================
-- TABLE: customers
--   People who place orders. `email` is the natural unique key.
-- ============================================================================
CREATE TABLE customers (
    id           BIGINT       NOT NULL AUTO_INCREMENT,
    first_name   VARCHAR(60)  NOT NULL,
    last_name    VARCHAR(60)  NOT NULL,
    email        VARCHAR(255) NOT NULL,
    phone        VARCHAR(30)  NULL,
    birth_date   DATE         NULL,
    street       VARCHAR(120) NULL,
    city         VARCHAR(80)  NULL,
    state        VARCHAR(40)  NULL,
    postal_code  VARCHAR(20)  NULL,
    country      VARCHAR(60)  NOT NULL DEFAULT 'United States',
    is_active    TINYINT(1)   NOT NULL DEFAULT 1,
    metadata     JSON         NULL,           -- flexible attribute storage
    created_at   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
                                 ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_customers_email (email),
    KEY idx_customers_name (last_name, first_name),
    KEY idx_customers_country (country),
    CONSTRAINT chk_customers_email
        CHECK (email LIKE '%_@_%._%'),
    CONSTRAINT chk_customers_birth
        CHECK (birth_date IS NULL OR birth_date >= '1900-01-01')
) ENGINE=InnoDB;

-- ============================================================================
-- TABLE: products
--   Sellable items. `sku` is the natural unique key. Price must be positive.
-- ============================================================================
CREATE TABLE products (
    id            BIGINT         NOT NULL AUTO_INCREMENT,
    category_id   BIGINT         NOT NULL,
    sku           VARCHAR(40)    NOT NULL,
    name          VARCHAR(120)   NOT NULL,
    description   TEXT           NULL,
    price         DECIMAL(10,2)  NOT NULL,
    cost          DECIMAL(10,2)  NOT NULL DEFAULT 0.00,
    stock_qty     INT            NOT NULL DEFAULT 0,
    weight_kg     DECIMAL(6,3)   NULL,
    is_active     TINYINT(1)     NOT NULL DEFAULT 1,
    created_at    TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP
                                  ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_products_sku (sku),
    KEY idx_products_category (category_id),
    KEY idx_products_price (price),
    KEY idx_products_name (name),
    FULLTEXT KEY ft_products_name_desc (name, description),
    CONSTRAINT fk_products_category
        FOREIGN KEY (category_id) REFERENCES categories(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_products_price
        CHECK (price > 0),
    CONSTRAINT chk_products_cost
        CHECK (cost >= 0),
    CONSTRAINT chk_products_stock
        CHECK (stock_qty >= 0)
) ENGINE=InnoDB;

-- ============================================================================
-- TABLE: orders
--   A cart that has been checked out. Status tracks the lifecycle.
-- ============================================================================
CREATE TABLE orders (
    id              BIGINT         NOT NULL AUTO_INCREMENT,
    customer_id     BIGINT         NOT NULL,
    order_date      TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status          ENUM('pending','paid','shipped','delivered',
                         'cancelled','refunded')
                                 NOT NULL DEFAULT 'pending',
    subtotal        DECIMAL(10,2)  NOT NULL DEFAULT 0.00,
    discount        DECIMAL(10,2)  NOT NULL DEFAULT 0.00,
    tax             DECIMAL(10,2)  NOT NULL DEFAULT 0.00,
    shipping        DECIMAL(10,2)  NOT NULL DEFAULT 0.00,
    total           DECIMAL(10,2)  NOT NULL DEFAULT 0.00,
    shipping_address VARCHAR(255)  NULL,
    notes           TEXT           NULL,
    created_at      TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP
                                    ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_orders_customer (customer_id),
    KEY idx_orders_date (order_date),
    KEY idx_orders_status (status),
    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id) REFERENCES customers(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_orders_total
        CHECK (total >= 0)
) ENGINE=InnoDB;

-- ============================================================================
-- TABLE: order_items
--   Each row is one product line on one order. CASCADE on parent delete
--   because order_items have no meaning without their order.
-- ============================================================================
CREATE TABLE order_items (
    id           BIGINT         NOT NULL AUTO_INCREMENT,
    order_id     BIGINT         NOT NULL,
    product_id   BIGINT         NOT NULL,
    quantity     INT            NOT NULL,
    unit_price   DECIMAL(10,2)  NOT NULL,    -- snapshot of price at order time
    line_total   DECIMAL(10,2)  AS (quantity * unit_price) STORED,
    created_at   TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_order_items (order_id, product_id),
    KEY idx_oi_product (product_id),
    CONSTRAINT fk_oi_order
        FOREIGN KEY (order_id) REFERENCES orders(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_oi_product
        FOREIGN KEY (product_id) REFERENCES products(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_oi_qty
        CHECK (quantity > 0),
    CONSTRAINT chk_oi_price
        CHECK (unit_price >= 0)
) ENGINE=InnoDB;

-- ============================================================================
-- TABLE: reviews
--   Customer product reviews. One review per (customer, product) pair.
-- ============================================================================
CREATE TABLE reviews (
    id           BIGINT         NOT NULL AUTO_INCREMENT,
    customer_id  BIGINT         NOT NULL,
    product_id   BIGINT         NOT NULL,
    rating       TINYINT        NOT NULL,    -- 1..5
    title        VARCHAR(120)   NULL,
    body         TEXT           NULL,
    created_at   TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_reviews (customer_id, product_id),
    KEY idx_reviews_product (product_id),
    KEY idx_reviews_rating (rating),
    FULLTEXT KEY ft_reviews_body (title, body),
    CONSTRAINT fk_reviews_customer
        FOREIGN KEY (customer_id) REFERENCES customers(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_reviews_product
        FOREIGN KEY (product_id) REFERENCES products(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_reviews_rating
        CHECK (rating BETWEEN 1 AND 5)
) ENGINE=InnoDB;

-- ============================================================================
-- TABLE: employees
--   Self-referencing org chart (manager_id → employees.id).
-- ============================================================================
CREATE TABLE employees (
    id           BIGINT         NOT NULL AUTO_INCREMENT,
    manager_id   BIGINT         NULL,
    first_name   VARCHAR(60)   NOT NULL,
    last_name    VARCHAR(60)   NOT NULL,
    email        VARCHAR(255)  NOT NULL,
    title        VARCHAR(80)   NULL,
    salary       DECIMAL(10,2) NOT NULL,
    hire_date    DATE          NOT NULL,
    is_active    TINYINT(1)    NOT NULL DEFAULT 1,
    PRIMARY KEY (id),
    UNIQUE KEY uq_employees_email (email),
    KEY idx_employees_manager (manager_id),
    CONSTRAINT fk_employees_manager
        FOREIGN KEY (manager_id) REFERENCES employees(id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT chk_employees_salary
        CHECK (salary > 0)
) ENGINE=InnoDB;

-- ============================================================================
-- VERIFICATION
--   Confirm the schema loaded correctly.
-- ============================================================================
SELECT
    TABLE_NAME,
    ENGINE,
    TABLE_ROWS,
    TABLE_COLLATION
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'ecom'
ORDER BY TABLE_NAME;

-- Expected output: 7 tables — categories, customers, employees, order_items,
-- orders, products, reviews — all using the InnoDB engine and the
-- utf8mb4_0900_ai_ci collation.
