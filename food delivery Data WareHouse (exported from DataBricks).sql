-- Databricks notebook source
CREATE DATABASE food_delivery_dw;

-- COMMAND ----------

use database food_delivery_dw;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Dim_Customer
-- MAGIC

-- COMMAND ----------

CREATE TABLE Dim_Customer (
    CustomerKey INT,
    CustomerID STRING,
    Name STRING,
    City STRING,
    SignupDate DATE,
    StartDate DATE,
    EndDate DATE,
    IsCurrent STRING
)
USING DELTA;

-- COMMAND ----------

INSERT INTO Dim_Customer VALUES
(1, 'C101', 'Rahul', 'Bangalore', '2023-01-01', '2023-01-01', NULL, 'Y'),
(2, 'C102', 'Ananya', 'Hyderabad', '2023-02-01', '2023-02-01', NULL, 'Y'),
(3, 'C103', 'Vikram', 'Delhi', '2023-03-01', '2023-03-01', NULL, 'Y'),
(4, 'C104', 'Priya', 'Mumbai', '2023-04-01', '2023-04-01', NULL, 'Y'),
(5, 'C105', 'Arjun', 'Kochi', '2023-05-01', '2023-05-01', NULL, 'Y');

-- COMMAND ----------

select * from dim_customer;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Dim_Restuarant
-- MAGIC

-- COMMAND ----------

CREATE TABLE Dim_Restaurant (
    RestaurantKey INT,
    RestaurantID STRING,
    Name STRING,
    City STRING,
    Cuisine STRING,
    Rating DOUBLE
)
USING DELTA;

-- COMMAND ----------

INSERT INTO Dim_Restaurant VALUES
(201, 'R101', 'Spicy Hub', 'Bangalore', 'Indian', 4.2),
(202, 'R102', 'Pizza World', 'Hyderabad', 'Italian', 4.5),
(203, 'R103', 'Burger Town', 'Delhi', 'Fast Food', 4.0),
(204, 'R104', 'Curry Palace', 'Mumbai', 'Indian', 4.3),
(205, 'R105', 'SeaFood Bay', 'Kochi', 'Seafood', 4.6);

-- COMMAND ----------

select * from dim_restaurant;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Dim_Dates

-- COMMAND ----------

CREATE TABLE Dim_Date (
    DateKey INT,
    FullDate DATE,
    Day INT,
    Month INT,
    Year INT,
    Weekday STRING
)
USING DELTA;

-- COMMAND ----------

INSERT INTO Dim_Date VALUES
(20240101, '2024-01-01', 1, 1, 2024, 'Monday'),
(20240102, '2024-01-02', 2, 1, 2024, 'Tuesday'),
(20240103, '2024-01-03', 3, 1, 2024, 'Wednesday'),
(20240104, '2024-01-04', 4, 1, 2024, 'Thursday'),
(20240105, '2024-01-05', 5, 1, 2024, 'Friday');

-- COMMAND ----------

select * from dim_date;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Fact_Table

-- COMMAND ----------

CREATE TABLE Fact_Orders (
    OrderKey INT,
    OrderID STRING,
    CustomerKey INT,
    RestaurantKey INT,
    DateKey INT,
    Quantity INT,
    UnitPrice DOUBLE,
    TotalAmount DOUBLE
)
USING DELTA;

-- COMMAND ----------

INSERT INTO Fact_Orders VALUES
(1, 'O1001', 1, 201, 20240101, 2, 250, 500),
(2, 'O1002', 2, 202, 20240102, 1, 300, 300),
(3, 'O1003', 3, 203, 20240103, 3, 150, 450),
(4, 'O1004', 4, 204, 20240104, 2, 200, 400),
(5, 'O1005', 5, 205, 20240105, 4, 100, 400);

-- COMMAND ----------

select * from fact_orders

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Analytical Queries

-- COMMAND ----------

-- Total revenue per city

select c.city, sum(f.TotalAmount) as Total_Revenue
from fact_orders f
join dim_customer c on f.CustomerKey = c.CustomerKey
group by c.city;

-- COMMAND ----------

-- Top Resto

select r.name, sum(f.TotalAmount) as Total_Revenue
from fact_orders f
join dim_restaurant r
on f.RestaurantKey = r.RestaurantKey
group by r.Name
order by total_revenue desc;

-- COMMAND ----------

SELECT d.Weekday, COUNT(*) AS Orders
FROM Fact_Orders f
JOIN Dim_Date d ON f.DateKey = d.DateKey
GROUP BY d.Weekday;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## SCD

-- COMMAND ----------

CREATE TABLE stg_customer (
    CustomerID STRING,
    Name STRING,
    City STRING
)
USING DELTA;

-- COMMAND ----------

INSERT INTO stg_customer VALUES
('C101', 'Rahul', 'Hyderabad'),  -- changed city
('C102', 'Ananya', 'Hyderabad'), -- no change
('C106', 'New User', 'Chennai'); -- new customer

-- COMMAND ----------

MERGE INTO Dim_Customer target
USING stg_customer source
ON target.CustomerID = source.CustomerID
AND target.IsCurrent = 'Y'

WHEN MATCHED AND (
    target.Name <> source.Name OR
    target.City <> source.City
)
THEN UPDATE SET
    target.EndDate = current_date(),
    target.IsCurrent = 'N';

-- COMMAND ----------

-- DBTITLE 1,Cell 27
INSERT INTO food_delivery_dw.Dim_Customer
SELECT
    monotonically_increasing_id() AS CustomerKey,
    s.CustomerID,
    s.Name,
    s.City,
    current_date() AS SignupDate,
    current_date() AS StartDate,
    NULL AS EndDate,
    'Y' AS IsCurrent
FROM food_delivery_dw.stg_customer s
LEFT JOIN food_delivery_dw.Dim_Customer d
ON s.CustomerID = d.CustomerID
AND d.IsCurrent = 'Y'
WHERE d.CustomerID IS NULL
   OR s.Name <> d.Name
   OR s.City <> d.City;