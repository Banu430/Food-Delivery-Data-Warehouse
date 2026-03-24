# 🍔 Food Delivery Data Warehouse (Databricks Project)

## 📌 Project Overview
This project demonstrates the design and implementation of a Data Warehouse using a Star Schema model. It simulates a food delivery platform to generate business insights.

## 🧠 Key Concepts Used
- Star Schema
- Fact and Dimension Tables
- SCD Type 2 (Slowly Changing Dimensions)
- Degenerate Dimension
- Transaction Fact Table

## 🏗️ Architecture
Raw Data → ETL → Dimension Tables → Fact Table → Analytics

## ⭐ Schema Design

![Star Schema](images/star_schema.png)

## 🧾 Fact Table
Fact_Orders:
- OrderKey
- CustomerKey
- RestaurantKey
- DateKey
- Quantity
- TotalAmount

## 🧩 Dimension Tables

### Dim_Customer (SCD Type 2)
Tracks customer history.

### Dim_Restaurant
Stores restaurant details.

### Dim_Date
Stores calendar data.

## 🔄 SCD Type 2 Implementation
Implemented using MERGE in Databricks Delta Lake:
- Old records expired
- New records inserted
- History maintained

