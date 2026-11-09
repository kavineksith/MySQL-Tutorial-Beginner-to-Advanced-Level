-- ============================================================================
-- 01_seed_data.sql — Sample Data for the `ecom` Database
-- ============================================================================
-- Run AFTER 00_schema.sql. Inserts realistic e-commerce data you can use to
-- practice every query in this course: customers, categories (nested),
-- products, orders with line items, reviews, and employees (org chart).
-- ============================================================================
-- HOW TO USE
--   * Reload any time:  mysql -u root -p ecom < 01_seed_data.sql
--   * The script first wipes existing rows so re-runs are idempotent.
-- ============================================================================

USE ecom;

SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE order_items;
TRUNCATE TABLE orders;
TRUNCATE TABLE reviews;
TRUNCATE TABLE products;
TRUNCATE TABLE categories;
TRUNCATE TABLE customers;
TRUNCATE TABLE employees;
SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================================
-- 1. CATEGORIES — nested tree (root → subcategory → sub-subcategory)
-- ============================================================================
INSERT INTO categories (id, parent_id, name, slug, description) VALUES
-- Root categories (parent_id IS NULL)
( 1, NULL, 'Electronics',     'electronics',     'Gadgets and devices'),
( 2, NULL, 'Books',           'books',           'Printed and digital books'),
( 3, NULL, 'Home & Kitchen',  'home-kitchen',    'Everything for your home'),
( 4, NULL, 'Apparel',         'apparel',         'Clothing and accessories'),
-- Electronics children
( 5, 1, 'Computers',          'computers',       'Laptops, desktops, parts'),
( 6, 1, 'Phones',             'phones',          'Smartphones and accessories'),
( 7, 1, 'Audio',              'audio',           'Headphones and speakers'),
-- Computers children (depth = 3)
( 8, 5, 'Laptops',            'laptops',         'Portable computers'),
( 9, 5, 'Components',         'components',      'CPUs, GPUs, RAM, storage'),
-- Books children
(10, 2, 'Fiction',            'fiction',         'Novels and stories'),
(11, 2, 'Non-Fiction',        'non-fiction',     'Biography, history, science'),
-- Home & Kitchen children
(12, 3, 'Furniture',          'furniture',       'Tables, chairs, shelving'),
(13, 3, 'Cookware',           'cookware',        'Pots, pans, utensils'),
-- Apparel children
(14, 4, 'Men',                'men',             "Men's clothing"),
(15, 4, 'Women',              'women',           "Women's clothing");

-- ============================================================================
-- 2. CUSTOMERS — 12 across 5 countries
-- ============================================================================
INSERT INTO customers
    (id, first_name, last_name, email, phone, birth_date,
     street, city, state, postal_code, country, is_active, metadata)
VALUES
(1, 'Alice',   'Johnson', 'alice.johnson@example.com',   '555-0101', '1990-04-12',
    '123 Maple St',     'Springfield', 'IL', '62704', 'United States', 1,
    '{"tags":["vip"],"loyalty_points":1250}'),
(2, 'Bob',     'Smith',   'bob.smith@example.com',       '555-0102', '1985-09-23',
    '456 Oak Ave',      'Austin',      'TX', '73301', 'United States', 1,
    '{"tags":["new"],"loyalty_points":50}'),
(3, 'Carol',   'Williams','carol.williams@example.com',  '555-0103', '1978-12-01',
    '789 Pine Rd',      'Seattle',     'WA', '98101', 'United States', 1,
    '{"tags":["vip"],"loyalty_points":3400}'),
(4, 'David',   'Brown',   'david.brown@example.com',     '555-0104', '1992-06-15',
    '321 Cedar Blvd',   'Denver',      'CO', '80201', 'United States', 0,
    '{"tags":[],"loyalty_points":0}'),
(5, 'Eve',     'Davis',   'eve.davis@example.com',       '555-0105', '1995-02-28',
    '654 Birch Ln',     'Miami',       'FL', '33101', 'United States', 1,
    '{"tags":["newsletter"],"loyalty_points":320}'),
(6, 'Frank',   'Miller',  'frank.miller@example.com',    '555-0106', '1980-11-09',
    '987 Spruce Way',   'Boston',      'MA', '02108', 'United States', 1,
    '{"tags":["vip","newsletter"],"loyalty_points":890}'),
(7, 'Grace',   'Wilson',  'grace.wilson@example.com',    '555-0107', '1988-07-30',
    '159 Elm Ct',       'Chicago',     'IL', '60601', 'United States', 1,
    NULL),
(8, 'Henry',   'Taylor',  'henry.taylor@example.com',    '+44 20 7946 0958', '1975-03-17',
    '10 Downing St',    'London',      'ENG', 'SW1A 2AA', 'United Kingdom', 1,
    '{"tags":["vip"],"loyalty_points":5100}'),
(9, 'Ivy',     'Anderson','ivy.anderson@example.com',    '+61 2 9876 5432', '1993-10-05',
    '42 Sydney Rd',     'Sydney',      'NSW', '2000', 'Australia', 1,
    '{"tags":["new"],"loyalty_points":10}'),
(10,'Jack',    'Thomas',  'jack.thomas@example.com',     '+33 1 4234 5678', '1987-05-22',
    '5 Rue de la Paix', 'Paris',       'IDF', '75002', 'France', 1,
    '{"tags":["newsletter"],"loyalty_points":780}'),
(11,'Karen',   'Jackson', 'karen.jackson@example.com',   '+81 3 1234 5678', '1996-08-14',
    '1-2 Shibuya',      'Tokyo',       'TKY', '150-0002', 'Japan', 1,
    '{"tags":["vip"],"loyalty_points":2100}'),
(12,'Liam',    'White',   'liam.white@example.com',      '555-0108', '1983-01-19',
    '742 Evergreen Tce','Springfield', 'OR', '97477', 'United States', 0,
    NULL);

-- ============================================================================
-- 3. PRODUCTS — 16 across multiple categories
-- ============================================================================
INSERT INTO products
    (id, category_id, sku, name, description, price, cost, stock_qty, weight_kg, is_active)
VALUES
(1,  8, 'LAP-001', 'Aurora 14 Ultrabook',
     '14-inch ultrabook with 16GB RAM and 1TB SSD, 18-hour battery life.',
     1299.00, 920.00, 25, 1.20, 1),
(2,  8, 'LAP-002', 'Vector Pro 16 Workstation',
     '16-inch workstation, 32GB RAM, RTX 4070, 2TB NVMe.',
     2499.00, 1850.00, 12, 2.10, 1),
(3,  9, 'CPU-001', 'Ryzen 9 7950X',
     '16-core, 32-thread desktop processor, 5.7GHz boost.',
     599.00, 410.00, 40, 0.08, 1),
(4,  9, 'GPU-001', 'GeForce RTX 4080',
     '16GB GDDR6X, ray tracing, DLSS 3.',
     1099.00, 780.00, 18, 1.40, 1),
(5,  9, 'RAM-001', 'Vengeance 32GB DDR5-6000',
     '32GB (2x16) DDR5-6000 CL30 kit.',
     149.00, 95.00, 60, 0.20, 1),
(6,  6, 'PHN-001', 'Helios S24',
     '6.2-inch Android flagship, 50MP triple camera, 5000mAh.',
     799.00, 480.00, 35, 0.18, 1),
(7,  6, 'PHN-002', 'Helios A14',
     'Budget Android, 6.5-inch, 48MP dual camera.',
     249.00, 140.00, 80, 0.20, 1),
(8,  7, 'AUD-001', 'Studio Pro Wireless Headphones',
     'Over-ear ANC headphones, 40-hour battery, spatial audio.',
     349.00, 180.00, 50, 0.28, 1),
(9,  7, 'AUD-002', 'Pulse Buds Pro',
     'In-ear true wireless earbuds, ANC, IPX5.',
     129.00, 60.00, 120, 0.05, 1),
(10, 7, 'AUD-003', 'BoomBox Mini',
     'Portable Bluetooth speaker, 20W, waterproof.',
     79.00, 35.00, 90, 0.45, 1),
(11, 10,'BK-001', 'The Silent Patient',
     'Psychological thriller by Alex Michaelides.',
     14.99, 4.20, 200, 0.40, 1),
(12, 11,'BK-002', 'Sapiens: A Brief History of Humankind',
     'Yuval Noah Harari on the history of our species.',
     19.99, 5.80, 150, 0.55, 1),
(13, 12,'FRN-001', 'Hemnes Bookshelf',
     'Solid wood 5-shelf bookcase, walnut finish.',
     249.00, 130.00, 8, 22.00, 1),
(14, 13,'CW-001',  'Stainless Steel Chef Knife 8"',
     'High-carbon Japanese steel blade.',
     59.99, 22.00, 75, 0.20, 1),
(15, 14,'AP-001', 'Men Classic Denim Jacket',
     '100% cotton indigo denim jacket, sizes S-XXL.',
     89.99, 38.00, 45, 0.70, 1),
(16, 15,'AP-002', 'Women Linen Summer Dress',
     'Breathable linen-blend midi dress, sizes XS-XL.',
     69.99, 28.00, 60, 0.30, 1);

-- ============================================================================
-- 4. EMPLOYEES — 9 people in a 3-level org chart
-- ============================================================================
INSERT INTO employees
    (id, manager_id, first_name, last_name, email, title, salary, hire_date, is_active)
VALUES
(1, NULL, 'Sofia',  'Romano',  'sofia.romano@example.com',   'CEO',                  250000, '2015-01-05', 1),
(2, 1,    'Daniel', 'Cohen',   'daniel.cohen@example.com',   'CTO',                  210000, '2015-03-12', 1),
(3, 1,    'Maya',   'Patel',   'maya.patel@example.com',     'CFO',                  205000, '2016-07-01', 1),
(4, 2,    'Lucas',  'Nguyen',  'lucas.nguyen@example.com',   'VP Engineering',       180000, '2017-02-20', 1),
(5, 2,    'Aria',   'Kim',     'aria.kim@example.com',       'VP Product',           175000, '2017-08-15', 1),
(6, 3,    'Noah',   'Schmidt', 'noah.schmidt@example.com',   'Controller',           140000, '2018-11-10', 1),
(7, 4,    'Elena',  'Rossi',   'elena.rossi@example.com',    'Engineering Manager',  155000, '2019-04-01', 1),
(8, 7,    'Ethan',  'Walker',  'ethan.walker@example.com',   'Senior Engineer',      130000, '2020-06-15', 1),
(9, 7,    'Olivia', 'Chen',    'olivia.chen@example.com',    'Software Engineer',    110000, '2021-09-20', 1);

-- ============================================================================
-- 5. ORDERS + ORDER_ITEMS — 10 orders spanning 2024–2025
-- ============================================================================
INSERT INTO orders
    (id, customer_id, order_date, status, subtotal, discount, tax, shipping, total, shipping_address)
VALUES
(1, 1, '2024-01-15 10:23:00', 'delivered', 1299.00, 0.00,   103.92, 0.00,  1402.92, '123 Maple St, Springfield, IL 62704'),
(2, 3, '2024-02-20 14:11:00', 'delivered', 1598.99, 50.00,  123.92, 12.00, 1684.91, '789 Pine Rd, Seattle, WA 98101'),
(3, 6, '2024-03-05 09:45:00', 'delivered', 478.99,  0.00,   38.32,  10.00, 527.31,  '987 Spruce Way, Boston, MA 02108'),
(4, 8, '2024-04-12 16:30:00', 'delivered', 2499.00, 100.00, 191.92, 0.00,  2590.92, '10 Downing St, London SW1A 2AA, UK'),
(5, 1, '2024-05-18 11:00:00', 'delivered', 499.99,  25.00,  38.00,  15.00, 527.99,  '123 Maple St, Springfield, IL 62704'),
(6, 5, '2024-06-22 13:50:00', 'delivered', 79.00,   0.00,   6.32,   8.00,  93.32,   '654 Birch Ln, Miami, FL 33101'),
(7, 11,'2024-07-30 18:15:00', 'shipped',   799.00,  40.00,  60.72,  0.00,  819.72,  '1-2 Shibuya, Tokyo 150-0002, Japan'),
(8, 2, '2024-09-10 08:00:00', 'paid',      1648.99, 80.00,  125.52, 0.00,  1694.51, '456 Oak Ave, Austin, TX 73301'),
(9, 10,'2024-11-25 20:30:00', 'pending',   89.99,   0.00,   7.20,   5.00,  102.19,  '5 Rue de la Paix, Paris 75002, France'),
(10,3, '2025-01-08 12:00:00', 'cancelled', 249.00,  0.00,   19.92,  10.00, 278.92,  '789 Pine Rd, Seattle, WA 98101');

INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
-- Order 1
(1, 1, 1, 1299.00),
-- Order 2
(2, 8, 1, 349.00),  (2, 9, 1, 129.00),  (2, 10, 1, 79.00), (2, 11, 8, 14.99),
-- Order 3
(3, 6, 1, 799.00),  (3, 7, 0, 249.00),
-- Order 4
(4, 2, 1, 2499.00),
-- Order 5
(5, 8, 1, 349.00),  (5, 10, 1, 79.00), (5, 11, 5, 14.99),
-- Order 6
(6, 10, 1, 79.00),
-- Order 7
(7, 6, 1, 799.00),
-- Order 8
(8, 1, 1, 1299.00), (8, 9, 1, 129.00), (8, 11, 16, 14.99),
-- Order 9
(9, 15, 1, 89.99),
-- Order 10 (cancelled)
(10, 13, 1, 249.00);

-- Fix: Order 3 has zero qty for product 7 — correct the seed to a sensible qty.
UPDATE order_items SET quantity = 1 WHERE order_id = 3 AND product_id = 7;
-- Recompute order 3 subtotal via the snapshot line items
UPDATE orders SET subtotal = 1048.00, tax = 83.84, total = 1131.84
WHERE id = 3;

-- ============================================================================
-- 6. REVIEWS — 14 reviews across products
-- ============================================================================
INSERT INTO reviews (customer_id, product_id, rating, title, body) VALUES
(1, 1, 5, 'Best laptop I have owned', 'Battery life is incredible and the screen is gorgeous.'),
(3, 1, 4, 'Great but pricey',         'Performance is top-notch, but I wish it had more ports.'),
(5, 1, 5, 'Perfect for travel',       'Lightweight and fast. Highly recommend for remote workers.'),
(2, 6, 5, 'Flagship quality',         'Camera and screen are amazing for the price.'),
(6, 6, 4, 'Good phone, software buggy','Hardware is excellent but the OS needs polish.'),
(8, 8, 5, 'Best headphones ever',     'Noise cancellation is magical. Worth every penny.'),
(3, 8, 4, 'Excellent ANC',            'Sound is rich and the ANC rivals more expensive brands.'),
(5, 9, 3, 'Decent for the price',     'Sound is okay but the fit is uncomfortable after an hour.'),
(6, 11,5, 'Could not put it down',    'Twists kept me guessing until the last page.'),
(10,12,5, 'Mind-expanding',           'Harari makes 100,000 years of history feel personal.'),
(11,4, 4, 'Powerhouse GPU',           'Runs everything at 4K ultra. Runs hot though.'),
(1, 14,5, 'Sharp and well balanced',  'Cuts through anything. Great value for Japanese steel.'),
(8, 13,4, 'Sturdy and beautiful',     'Assembly took an hour but the result is solid.'),
(11,6, 2, 'Overheats fast',           'Lovely phone but it gets uncomfortably hot when gaming.');

-- ============================================================================
-- VERIFICATION — quick counts so you can confirm the seed worked
-- ============================================================================
SELECT 'categories'  AS table_name, COUNT(*) AS rows FROM categories
UNION ALL SELECT 'customers',  COUNT(*) FROM customers
UNION ALL SELECT 'products',   COUNT(*) FROM products
UNION ALL SELECT 'orders',     COUNT(*) FROM orders
UNION ALL SELECT 'order_items',COUNT(*) FROM order_items
UNION ALL SELECT 'reviews',    COUNT(*) FROM reviews
UNION ALL SELECT 'employees',  COUNT(*) FROM employees;

-- Expected counts:
--   categories = 15, customers = 12, products = 16, orders = 10,
--   order_items = 21, reviews = 14, employees = 9
