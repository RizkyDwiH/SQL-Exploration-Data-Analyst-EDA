/*
=============================================================
Create Database and Schemas
=============================================================
Script Purpose:
    This script creates a new database named 'DataWarehouseAnalytics' after checking if it already exists. 
    If the database exists, it is dropped and recreated. Additionally, this script creates a schema called gold
	
WARNING:
    Running this script will drop the entire 'DataWarehouseAnalytics' database if it exists. 
    All data in the database will be permanently deleted. Proceed with caution 
    and ensure you have proper backups before running this script.
*/

USE master;
GO

-- Drop and recreate the 'DataWarehouseAnalytics' database
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouseAnalytics')
BEGIN
    ALTER DATABASE DataWarehouseAnalytics SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DataWarehouseAnalytics;
END;
GO

-- Create the 'DataWarehouseAnalytics' database
CREATE DATABASE DataWarehouseAnalytics;
GO

USE DataWarehouseAnalytics;
GO

-- Create Schemas

CREATE SCHEMA gold;
GO

CREATE TABLE gold.dim_customers(
	customer_key int,
	customer_id int,
	customer_number nvarchar(50),
	first_name nvarchar(50),
	last_name nvarchar(50),
	country nvarchar(50),
	marital_status nvarchar(50),
	gender nvarchar(50),
	birthdate date,
	create_date date
);
GO

CREATE TABLE gold.dim_products(
	product_key int ,
	product_id int ,
	product_number nvarchar(50) ,
	product_name nvarchar(50) ,
	category_id nvarchar(50) ,
	category nvarchar(50) ,
	subcategory nvarchar(50) ,
	maintenance nvarchar(50) ,
	cost int,
	product_line nvarchar(50),
	start_date date 
);
GO

CREATE TABLE gold.fact_sales(
	order_number nvarchar(50),
	product_key int,
	customer_key int,
	order_date date,
	shipping_date date,
	due_date date,
	sales_amount int,
	quantity tinyint,
	price int 
);
GO

TRUNCATE TABLE gold.dim_customers;
GO

BULK INSERT gold.dim_customers
FROM 'C:\Users\userr\OneDrive\Documents\SQL EDA\sql-data-analytics-project\datasets\csv-files\gold.dim_customers.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);
GO

TRUNCATE TABLE gold.dim_products;
GO

BULK INSERT gold.dim_products
FROM 'C:\Users\userr\OneDrive\Documents\SQL EDA\sql-data-analytics-project\datasets\csv-files\gold.dim_products.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);
GO

TRUNCATE TABLE gold.fact_sales;
GO

BULK INSERT gold.fact_sales
FROM 'C:\Users\userr\OneDrive\Documents\SQL EDA\sql-data-analytics-project\datasets\csv-files\gold.fact_sales.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);
GO

-- DIMENSION

-- Explore All Countries Our Customers Come From.
SELECT DISTINCT COUNTRY FROM gold.dim_customers

-- Explore All Countries " The Major Divisions"
SELECT DISTINCT CATEGORY, SUBCATEGORY, PRODUCT_NAME FROM gold.dim_products
ORDER BY 1, 2, 3



-- DATE EXPLORATION

-- Find the date of the first and last order
-- How many years of sales are avaiable
SELECT 
MIN(order_date) AS first_order_date,
MAX(order_date) AS last_order_date,
DATEDIFF(month, MIN(order_date), MAX(order_date)) AS order_range_months
from gold.fact_sales

-- Find the youngest and the oldest customer
SELECT 
MIN(birthdate) AS oldest_birthdate,
DATEDIFF(year, MIN(birthdate), GETDATE()) AS oldest_age,
MAX(birthdate) AS youngest_birthdate,
DATEDIFF(year, MAX(birthdate), GETDATE()) AS youngest_age
from gold.dim_customers



-- MEASURE

-- Find the Total Sales
SELECT SUM(sales_amount) AS total_sales from gold.fact_sales

-- Find how many items are sold
SELECT SUM(quantity) AS total_quantity from gold.fact_sales

-- Find the average selling price
SELECT AVG(price) AS avg_price from gold.fact_sales

-- Find the total number of orders
SELECT COUNT(order_number) AS total_order from gold.fact_sales
SELECT COUNT(DISTINCT order_number) AS total_order from gold.fact_sales

-- Find the total number of products
SELECT COUNT(product_name) AS total_product from gold.dim_products
SELECT COUNT(DISTINCT product_name) AS total_product from gold.dim_products

-- Find the total number of customers
SELECT COUNT(customer_key) AS total_customer from gold.dim_customers

-- Find the total number of customers that has placed an order
SELECT COUNT(DISTINCT customer_key) AS total_customer from gold.fact_sales


--Generate a Report that shows all key metrics of the business

SELECT 'total_sales' AS measure_name, SUM(sales_amount) AS measure_value from gold.fact_sales
UNION ALL
SELECT 'total_quantity' AS measure_name, SUM(quantity) AS measure_value from gold.fact_sales
UNION ALL
SELECT 'average_price', AVG(price) AS avg_price from gold.fact_sales
UNION ALL
SELECT 'total nr. order', COUNT(order_number) AS total_order from gold.fact_sales
UNION ALL
SELECT 'total_nr. product', COUNT(product_name) AS total_product from gold.dim_products
UNION ALL
SELECT 'total_nr. customer', COUNT(DISTINCT customer_key) AS total_customer from gold.fact_sales



-- Magnitude Analysis

-- Find total customers by countries

SELECT
country,
COUNT(customer_key) AS total_customers
from gold.dim_customers
GROUP BY country
ORDER BY total_customers DESC

-- Find total customers by gender

SELECT
gender,
COUNT(customer_key) AS total_customers
from gold.dim_customers
GROUP BY gender
ORDER BY total_customers DESC

-- Find total products by category

SELECT
category,
COUNT(product_key) AS total_products
from gold.dim_products
GROUP BY category
ORDER BY total_products DESC

-- What is the average costs in each category?

SELECT
category,
avg(cost) AS avg_costs
from gold.dim_products
GROUP BY category
ORDER BY avg_costs DESC

-- What is the total revenue generated for each countries?

SELECT
p.category,
sum(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
on p.product_key = f.product_key
GROUP BY p.category
ORDER BY total_revenue DESC

-- Find total revenue is generated by each customer

SELECT
c.customer_key,
c.first_name,
c.last_name,
SUM(F.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
on c.customer_key = f.customer_key
GROUP BY
c.customer_key,
c.first_name,
c.last_name
ORDER BY total_revenue DESC

-- what is the distribution of sold items across countries?

SELECT
c.country,
SUM(F.quantity) AS total_sold_items
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
on c.customer_key = f.customer_key
GROUP BY c.country
ORDER BY total_sold_items DESC


 
-- Ranking Analysis

-- Which 5 products generate the highest revenue?

SELECT TOP 5
p.subcategory,
sum(f.sales_amount) total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
on p.product_key = f.product_key
GROUP BY p.subcategory
ORDER BY total_revenue DESC


-- WINDOW FUNCTION

SELECT *
FROM (
	SELECT
	p.product_name,
	sum(f.sales_amount) total_revenue,
	ROW_NUMBER() OVER(ORDER BY sum(f.sales_amount)DESC) AS rank_products
	FROM gold.fact_sales f
	LEFT JOIN gold.dim_products p
	on p.product_key = f.product_key
	GROUP BY p.product_name) t
WHERE rank_products <= 5


-- What are the 5 worst-performing products in terms of sales?

SELECT TOP 5
p.product_name,
sum(f.sales_amount) total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
on p.product_key = f.product_key
GROUP BY p.product_name
ORDER BY total_revenue ASC

-- Find the top 10 customers who have generated the highest revenue

SELECT TOP 10
c.customer_key,
c.first_name,
c.last_name,
SUM(F.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
on c.customer_key = f.customer_key
GROUP BY
c.customer_key,
c.first_name,
c.last_name
ORDER BY total_revenue DESC

-- Top 3 cutomers the fewest order placed

SELECT TOP 3
c.customer_key,
c.first_name,
c.last_name,
COUNT(DISTINCT order_number) AS total_orders
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
on c.customer_key = f.customer_key
GROUP BY
c.customer_key,
c.first_name,
c.last_name
ORDER BY total_orders ASC