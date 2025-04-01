/*1. Create a table called employees with the following structure?
: emp_id (integer, should not be NULL and should be a primary key)Q
: emp_name (text, should not be NULL)Q
: age (integer, should have a check constraint to ensure the age is at least 18)Q
: email (text, should be unique for each employee)Q
: salary (decimal, with a default value of 30,000).

Write the SQL query to create the above table with all constraints.*/
CREATE TABLE employees (
    emp_id INT PRIMARY KEY NOT NULL,
    emp_name TEXT NOT NULL,
    age INT CHECK (age >= 18),
    email TEXT UNIQUE,
    salary DECIMAL DEFAULT 30000
);

/*2.Explain the purpose of constraints and how they help maintain data integrity in a database. Provide
examples of common types of constraints.*/
/* Ans: Purpose of constraints: Constraints ensure data integrity by restricting invalid entries. Examples include:
--   - NOT NULL: Prevents missing values.
--   - UNIQUE: Ensures no duplicate values.
--   - PRIMARY KEY: Uniquely identifies records.
--   - FOREIGN KEY: Enforces relationships.
--   - CHECK: Restricts value ranges.
--   - DEFAULT: Provides default values.*/

/*3. Why would you apply the NOT NULL constraint to a column? Can a primary key contain NULL values? Justify
your answer.*/
/*Ans:NOT NULL prevents null values to ensure essential data is provided. PRIMARY KEY cannot contain NULLs because it uniquely identifies records.*/

/*4.  Explain the steps and SQL commands used to add or remove constraints on an existing table. Provide an
example for both adding and removing a constraint.*/
ALTER TABLE employees ADD CONSTRAINT unique_email UNIQUE(email);
ALTER TABLE employees DROP CONSTRAINT unique_email; 

/* 5. Explain the consequences of attempting to insert, update, or delete data in a way that violates constraints.
Provide an example of an error message that might occur when violating a constraint.
Ans:Constraint violations cause errors:
-- Example: Trying to insert NULL in emp_id:
-- INSERT INTO employees (emp_id, emp_name, age, email, salary) VALUES (NULL, 'John Doe', 25, 'john@example.com', 40000);
-- Error: 'Column emp_id cannot be NULL' */

/*6. You created a products table without constraints as follows:

CREATE TABLE products (

    product_id INT,

    product_name VARCHAR(50),

    price DECIMAL(10, 2));
    Now, you realise that?
: The product_id should be a primary keyQ
: The price should have a default value of 50.00 */
ALTER TABLE products ADD PRIMARY KEY (product_id);
ALTER TABLE products ALTER COLUMN price SET DEFAULT 50.00;

-- 7. Ans:
SELECT students.student_name, classes.class_name
FROM students
INNER JOIN classes ON students.class_id = classes.class_id;

/*8. Write a query that shows all order_id, customer_name, and product_name, ensuring that all products are
listed even if they are not associated with an order */
SELECT orders.order_id, customers.customer_name, products.product_name
FROM orders
LEFT JOIN order_details ON orders.order_id = order_details.order_id
LEFT JOIN products ON order_details.product_id = products.product_id
LEFT JOIN customers ON orders.customer_id = customers.customer_id;

-- 9.Write a query to find the total sales amount for each product using an INNER JOIN and the SUM() function.
SELECT products.product_name, SUM(order_details.quantity * products.price) AS total_sales
FROM order_details
INNER JOIN products ON order_details.product_id = products.product_id
GROUP BY products.product_name;

/*10. You are given three tables:
Write a query to display the order_id, customer_name, and the quantity of products ordered by each
customer using an INNER JOIN between all three tables.*/
SELECT orders.order_id, customers.customer_name, SUM(order_details.quantity) AS total_quantity
FROM orders
INNER JOIN customers ON orders.customer_id = customers.customer_id
INNER JOIN order_details ON orders.order_id = order_details.order_id
GROUP BY orders.order_id, customers.customer_name;


