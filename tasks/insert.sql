DELETE FROM order_items;
DELETE FROM orders;
DELETE FROM customer;
DELETE FROM product;


INSERT INTO customer (customer_id, name, city, state) VALUES
(1, 'John Doe', 'New York', 'NY'),
(2, 'Jane Smith', 'Los Angeles', 'CA'),
(3, 'Michael Johnson', 'Chicago', 'IL'),
(4, 'Emily Davis', 'Houston', 'TX'),
(5, 'David Wilson', 'Phoenix', 'AZ');

INSERT INTO product (product_id, product_name, category, unit_price) VALUES
(1, 'Laptop', 'Electronics', 1200.00),
(2, 'Smartphone', 'Electronics', 800.00),
(3, 'Tablet', 'Electronics', 400.00),
(4, 'Headphones', 'Accessories', 150.00),
(5, 'Keyboard', 'Accessories', 50.00),
(6, 'Mouse', 'Accessories', 25.00),
(7, 'Desk Chair', 'Furniture', 200.00),
(8, 'Monitor', 'Electronics', 300.00),
(9, 'Printer', 'Electronics', 150.00),
(10, 'Smartwatch', 'Wearables', 250.00);



INSERT INTO orders (order_id, customer_id, order_date) VALUES
(1, 1, '2025-01-03'),
(2, 2, '2025-01-10'),
(3, 3, '2025-01-17'),
(4, 4, '2025-01-24'),
(5, 5, '2025-01-31'),
(6, 1, '2025-02-05'),
(7, 2, '2025-02-10'),
(8, 3, '2025-02-22'),
(9, 4, '2025-02-24'),
(10, 5, '2025-02-28');

INSERT INTO order_items (order_id, product_id, qty) VALUES
-- Week 1 - Order 1
(1, 1, 7), (1, 2, 2), (1, 3, 9), (1, 4, 5), (1, 5, 1),
(1, 6, 6), (1, 7, 10), (1, 8, 3), (1, 9, 4), (1,10,8),

-- Week 2 - Order 2
(2, 1, 3), (2, 2, 6), (2, 3, 1), (2, 4, 9), (2, 5, 4),
(2, 6, 2), (2, 7, 8), (2, 8, 5), (2, 9, 10), (2,10,7),

-- Week 3 - Order 3
(3, 1, 2), (3, 2, 10), (3, 3, 7), (3, 4, 1), (3, 5, 6),
(3, 6, 3), (3, 7, 5), (3, 8, 4), (3, 9, 9), (3,10,8),

-- Week 4 - Order 4
(4, 1, 8), (4, 2, 4), (4, 3, 6), (4, 4, 1), (4, 5, 10),
(4, 6, 5), (4, 7, 2), (4, 8, 3), (4, 9, 7), (4,10,9),

-- Week 5 - Order 5
(5, 1, 9), (5, 2, 2), (5, 3, 4), (5, 4, 8), (5, 5, 6),
(5, 6, 1), (5, 7, 10), (5, 8, 5), (5, 9, 3), (5,10,7),

-- Week 6 - Order 6
(6, 1, 6), (6, 2, 3), (6, 3, 7), (6, 4, 5), (6, 5, 2),
(6, 6, 10), (6, 7, 1), (6, 8, 9), (6, 9, 8), (6,10,4),

-- Week 7 - Order 7
(7, 1, 1), (7, 2, 7), (7, 3, 5), (7, 4, 3), (7, 5, 9),
(7, 6, 6), (7, 7, 2), (7, 8, 10), (7, 9, 8), (7,10,4),

-- Week 8 - Order 8
(8, 1, 5), (8, 2, 10), (8, 3, 4), (8, 4, 6), (8, 5, 3),
(8, 6, 8), (8, 7, 1), (8, 8, 2), (8, 9, 9), (8,10,7),

-- Week 9 - Order 9
(9, 1, 2), (9, 2, 8), (9, 3, 5), (9, 4, 10), (9, 5, 3),
(9, 6, 7), (9, 7, 6), (9, 8, 4), (9, 9, 1), (9,10,9),

-- Week 10 - Order 10
(10,1, 4), (10,2, 6), (10,3, 1), (10,4, 9), (10,5, 8),
(10,6, 3), (10,7, 5), (10,8, 2), (10,9, 7), (10,10,10);

