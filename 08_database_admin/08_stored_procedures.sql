-- ============================================================================
-- 08_stored_procedures.sql — Stored Procedures & Functions
-- ============================================================================
-- SKILL LEVEL : Intermediate→Advanced
-- TOPICS      : CREATE PROCEDURE, IN/OUT/INOUT parameters, CREATE FUNCTION,
--               DELIMITER, control flow (IF/CASE/LOOP/WHILE/REPEAT),
--               variables, cursors, handlers, DROP.
-- ----------------------------------------------------------------------------
-- TEXTBOOK DEPTH
--   A stored procedure is a named block of SQL statements stored in the
--   database. Pros:
--     * Reduce network round-trips (one call runs many statements).
--     * Centralize business logic close to the data.
--     * Permission boundary: GRANT EXECUTE without GRANT SELECT.
--   Cons:
--     * Hard to version control.
--     * Logic split between app code and DB.
--     * Limited debugging tools.
--     * Doesn't scale out (a sharded DB has them on one node).
--
--   MySQL syntax uses BEGIN ... END blocks. Because statements inside the
--   procedure end with `;`, you must change the statement terminator with
--   DELIMITER while defining the procedure.
--
--   Variables:
--     DECLARE var TYPE [DEFAULT value];  — local, inside BEGIN...END
--     SET var = value;                   — assignment
--     SELECT col INTO var FROM ... LIMIT 1;
--
--   Parameters:
--     IN (default)   — read-only input
--     OUT             — write-only output, initialized to NULL
--     INOUT           — read+write
--
--   Control flow:
--     IF ... THEN ... ELSEIF ... ELSE ... END IF;
--     CASE WHEN ... THEN ... ELSE ... END CASE;
--     WHILE cond DO ... END WHILE;
--     REPEAT ... UNTIL cond END REPEAT;
--     [label:] LOOP ... IF cond THEN LEAVE label; END IF; ... END LOOP;
--
--   Cursors: read row-by-row from a result set inside the procedure.
--   Handlers: catch warnings/errors (CONTINUE or EXIT).
-- ============================================================================

USE ecom;

-- We will use DELIMITER for stored program definitions
-- NOTE: this works in the mysql CLI but NOT in many GUI tools or programs
-- that send one statement at a time. For this lesson, run each block as
-- a single statement.

DELIMITER //

-- ----------------------------------------------------------------------------
-- 1. Simple procedure with no parameters
-- ----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_count_products //
CREATE PROCEDURE sp_count_products()
BEGIN
    SELECT
        category_id,
        COUNT(*) AS product_count,
        AVG(price) AS avg_price
    FROM products
    GROUP BY category_id
    ORDER BY category_id;
END //

-- Call it:
CALL sp_count_products() //

-- ----------------------------------------------------------------------------
-- 2. Procedure with IN parameter
-- ----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_products_in_category //
CREATE PROCEDURE sp_products_in_category(IN p_cat_id BIGINT)
BEGIN
    SELECT p.id, p.sku, p.name, p.price, p.stock_qty
    FROM products p
    WHERE p.category_id = p_cat_id
    ORDER BY p.name;
END //

CALL sp_products_in_category(8) //   -- laptops

-- ----------------------------------------------------------------------------
-- 3. Procedure with OUT parameter
-- ----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_customer_spend //
CREATE PROCEDURE sp_customer_spend(IN p_customer_id BIGINT, OUT p_total DECIMAL(10,2))
BEGIN
    SELECT COALESCE(SUM(o.total), 0) INTO p_total
    FROM orders o
    WHERE o.customer_id = p_customer_id
      AND o.status NOT IN ('cancelled', 'refunded');
END //

SET @spend := 0 //
CALL sp_customer_spend(1, @spend) //
SELECT @spend AS total_spend_for_customer_1 //

-- ----------------------------------------------------------------------------
-- 4. Procedure with INOUT parameter
-- ----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_double_value //
CREATE PROCEDURE sp_double_value(INOUT p_val INT)
BEGIN
    SET p_val = p_val * 2;
END //

SET @x := 21 //
CALL sp_double_value(@x) //
SELECT @x AS doubled //

-- ----------------------------------------------------------------------------
-- 5. Stored FUNCTION — returns a single value, usable in expressions
-- ----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS fn_gross_margin_pct //
CREATE FUNCTION fn_gross_margin_pct(p_price DECIMAL(10,2), p_cost DECIMAL(10,2))
RETURNS DECIMAL(5,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE margin_pct DECIMAL(5,2);
    IF p_price = 0 OR p_price IS NULL THEN
        SET margin_pct := NULL;
    ELSE
        SET margin_pct := ROUND((p_price - p_cost) / p_price * 100, 2);
    END IF;
    RETURN margin_pct;
END //

-- Use the function in a SELECT:
SELECT
    sku,
    name,
    price,
    cost,
    fn_gross_margin_pct(price, cost) AS margin_pct
FROM products
LIMIT 5 //

-- ----------------------------------------------------------------------------
-- 6. Control flow — IF / ELSEIF / ELSE
-- ----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_classify_customer //
CREATE PROCEDURE sp_classify_customer(IN p_customer_id BIGINT)
BEGIN
    DECLARE v_count INT DEFAULT 0;
    DECLARE v_total DECIMAL(10,2) DEFAULT 0;
    DECLARE v_segment VARCHAR(20);

    SELECT COUNT(*), COALESCE(SUM(total), 0)
    INTO v_count, v_total
    FROM orders
    WHERE customer_id = p_customer_id
      AND status NOT IN ('cancelled', 'refunded');

    IF v_count = 0 THEN
        SET v_segment = 'new';
    ELSEIF v_total < 500 THEN
        SET v_segment = 'occasional';
    ELSEIF v_total < 2000 THEN
        SET v_segment = 'regular';
    ELSE
        SET v_segment = 'vip';
    END IF;

    SELECT p_customer_id AS customer_id, v_count AS order_count,
           v_total AS total_spent, v_segment AS segment;
END //

CALL sp_classify_customer(1) //
CALL sp_classify_customer(2) //
CALL sp_classify_customer(12) //

-- ----------------------------------------------------------------------------
-- 7. Loop with WHILE
-- ----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_generate_numbers //
CREATE PROCEDURE sp_generate_numbers(IN n INT)
BEGIN
    DECLARE i INT DEFAULT 1;
    DROP TEMPORARY TABLE IF EXISTS tmp_numbers;
    CREATE TEMPORARY TABLE tmp_numbers (num INT);

    WHILE i <= n DO
        INSERT INTO tmp_numbers VALUES (i);
        SET i := i + 1;
    END WHILE;

    SELECT * FROM tmp_numbers ORDER BY num;
    DROP TEMPORARY TABLE tmp_numbers;
END //

CALL sp_generate_numbers(5) //

-- ----------------------------------------------------------------------------
-- 8. Cursor with handler — iterate over a result set
-- ----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_list_top_customers //
CREATE PROCEDURE sp_list_top_customers(IN limit_n INT)
BEGIN
    DECLARE v_id BIGINT;
    DECLARE v_name VARCHAR(120);
    DECLARE v_spent DECIMAL(10,2);
    DECLARE done INT DEFAULT 0;
    DECLARE cur CURSOR FOR
        SELECT c.id, CONCAT(c.first_name, ' ', c.last_name), SUM(o.total)
        FROM customers c
        JOIN orders o ON o.customer_id = c.id
        WHERE o.status NOT IN ('cancelled', 'refunded')
        GROUP BY c.id, c.first_name, c.last_name
        ORDER BY v_spent DESC
        LIMIT limit_n;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done := 1;

    DROP TEMPORARY TABLE IF EXISTS tmp_top;
    CREATE TEMPORARY TABLE tmp_top (id BIGINT, name VARCHAR(120), spent DECIMAL(10,2));

    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO v_id, v_name, v_spent;
        IF done = 1 THEN
            LEAVE read_loop;
        END IF;
        INSERT INTO tmp_top VALUES (v_id, v_name, v_spent);
    END LOOP;
    CLOSE cur;

    SELECT * FROM tmp_top ORDER BY spent DESC;
    DROP TEMPORARY TABLE tmp_numbers;
    DROP TEMPORARY TABLE tmp_top;
END //

CALL sp_list_top_customers(5) //

-- ----------------------------------------------------------------------------
-- 9. DROP
-- ----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_count_products //
DROP PROCEDURE IF EXISTS sp_products_in_category //
DROP PROCEDURE IF EXISTS sp_customer_spend //
DROP PROCEDURE IF EXISTS sp_double_value //
DROP PROCEDURE IF EXISTS sp_classify_customer //
DROP PROCEDURE IF EXISTS sp_generate_numbers //
DROP PROCEDURE IF EXISTS sp_list_top_customers //
DROP FUNCTION IF EXISTS fn_gross_margin_pct //

DELIMITER ;

-- ----------------------------------------------------------------------------
-- 10. EXERCISES
-- ----------------------------------------------------------------------------
-- EASY
-- E1.  Write a stored procedure sp_product_count() that returns the total
--      number of products.
-- E2.  Write a stored function fn_full_name(p_first, p_last) that returns
--      "first last".
--
-- MEDIUM
-- E3.  Write sp_orders_in_year(p_year INT) that returns all orders in a
--      given year.
-- E4.  Write sp_customer_summary(p_customer_id, OUT order_count,
--      OUT total_spent) returning both values.
--
-- HARD
-- E5.  Write sp_classify_customer(p_customer_id) using IF/ELSEIF that
--      returns a segment label (new, occasional, regular, vip) based on
--      spend thresholds.
--
-- EXPERT
-- E6.  Write a procedure with a cursor that iterates over all customers
--      and inserts each customer's name + total_spent into a temp table.
--      Then return the temp table ordered by spend DESC.
-- ============================================================================

-- End of file 08_stored_procedures.sql
