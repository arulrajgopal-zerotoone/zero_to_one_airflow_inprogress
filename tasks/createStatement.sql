CREATE TABLE IF NOT EXISTS customer (
    customer_id INTEGER PRIMARY KEY, 
    name VARCHAR(255) NOT NULL,      
    city VARCHAR(255),               
    state VARCHAR(255),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS product (
    product_id INTEGER PRIMARY KEY,    
    product_name VARCHAR(255) NOT NULL,
    category VARCHAR(100) ,           
    unit_price DECIMAL(10, 2) NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE IF NOT EXISTS orders (
    order_id INTEGER PRIMARY KEY,      
    customer_id INT NOT NULL,        
    order_date DATE NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id)
);

CREATE TABLE IF NOT EXISTS order_items (
    order_id INT NOT NULL,             
    product_id INT NOT NULL,         
    qty INT NOT NULL,      
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,           
    PRIMARY KEY (order_id, product_id),  
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,  
    FOREIGN KEY (product_id) REFERENCES product(product_id) ON DELETE CASCADE 
);


CREATE TABLE IF NOT EXISTS order_details (
    order_id INT NOT NULL,             
    product_id INT NOT NULL,  
    customer_id INT NOT NULL,         
    qty INT NOT NULL,    
    order_date DATE NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,           
    PRIMARY KEY (order_id, product_id),  
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,  
    FOREIGN KEY (product_id) REFERENCES product(product_id) ON DELETE CASCADE 
);


CREATE TABLE IF NOT EXISTS monthly_summary (
    year_month INT NOT NULL,
    customer_id INT NOT NULL,  
    name VARCHAR(255) NOT NULL,      
    sale_total INT NOT NULL,    
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE OR REPLACE PROCEDURE load_order_details()
LANGUAGE plpgsql
AS $$
BEGIN
    TRUNCATE TABLE order_details;


    INSERT INTO order_details (order_id, product_id, customer_id, qty,order_date)
    SELECT 
    A.order_id,
    B.product_id,
    A.customer_id,
    B.qty,
    A.order_date
    FROM orders A
    JOIN order_items B ON A.order_id = B.order_id;


    RAISE NOTICE 'order details loaded successfully.';
END;
$$;


CREATE OR REPLACE PROCEDURE load_monthly_summary()
LANGUAGE plpgsql
AS $$
BEGIN
    TRUNCATE TABLE monthly_summary;

    INSERT INTO monthly_summary (year_month, customer_id, name, sale_total)
    select 
        CAST(TO_CHAR(A.order_date, 'YYYYMM') AS INTEGER) AS year_month,
        A.customer_id,
        C.name,
        sum(A.qty * B.unit_price) as sale_total
    from order_details A 
    join product B on A.product_id = B.product_id 
    join customer C on A.customer_id = C.customer_id
    group by year_month, A.customer_id, C.name
    order by year_month desc, customer_id;

    RAISE NOTICE 'monthly_summary loaded successfully.';
END;
$$;
