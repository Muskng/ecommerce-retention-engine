-- File: 01_ddl_schema.sql
-- Purpose: To create the database and define our Star Schema tables.
-- ==========================================
-- File: 01_ddl_schema.sql
-- Purpose: Initialize the database and create Star Schema tables
-- Author: Mohit Pratap Singh
-- Date: 2026
-- ==========================================

-- Create Target Database
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'EcomCohortAnalytics')
BEGIN
    CREATE DATABASE EcomCohortAnalytics;
END;
GO

USE EcomCohortAnalytics;
GO

-- 1. Create Customer Dimension Table
CREATE TABLE DimCustomers (
    CustomerSK INT IDENTITY(1,1) PRIMARY KEY, -- Surrogate Key (Auto-incrementing)
    CustomerAlternateID VARCHAR(100) NOT NULL UNIQUE, -- Natural Business Key from Olist CSV
    CustomerCity VARCHAR(100),
    CustomerState VARCHAR(50),
    FirstIngestedDate DATETIME DEFAULT GETDATE()
);

-- 2. Create Product Dimension Table
CREATE TABLE DimProducts (
    ProductSK INT IDENTITY(1,1) PRIMARY KEY, -- Surrogate Key (Auto-incrementing)
    ProductID VARCHAR(100) NOT NULL UNIQUE, -- Natural Business Key from Olist CSV
    ProductName VARCHAR(150),
    ProductCategory VARCHAR(100),
    UnitCost DECIMAL(18,2)
);

-- 3. Create Date Dimension Table
CREATE TABLE DimDate (
    DateKey INT PRIMARY KEY, -- Date formatted as YYYYMMDD (e.g., 20260715)
    FullDate DATE NOT NULL,
    CalendarYear INT NOT NULL,
    CalendarQuarter INT NOT NULL,
    CalendarMonth INT NOT NULL,
    MonthName VARCHAR(20) NOT NULL,
    DayOfWeek VARCHAR(20) NOT NULL
);

-- 4. Create Central Fact Table (linked to all dimensions)
CREATE TABLE FactRetailOrders (
    OrderLineID BIGINT IDENTITY(1,1) PRIMARY KEY,
    OrderID VARCHAR(100) NOT NULL,
    CustomerSK INT FOREIGN KEY REFERENCES DimCustomers(CustomerSK),
    ProductSK INT FOREIGN KEY REFERENCES DimProducts(ProductSK),
    OrderDateKey INT FOREIGN KEY REFERENCES DimDate(DateKey),
    Quantity INT NOT NULL CHECK (Quantity > 0),
    UnitPrice DECIMAL(18,2) NOT NULL,
    TotalRevenue AS (Quantity * UnitPrice) PERSISTED -- Automatically calculated and stored
);

-- Create Non-Clustered Indexes on Foreign Keys for high query performance
CREATE NONCLUSTERED INDEX IX_FactRetailOrders_CustomerSK ON FactRetailOrders(CustomerSK);
CREATE NONCLUSTERED INDEX IX_FactRetailOrders_ProductSK ON FactRetailOrders(ProductSK);
CREATE NONCLUSTERED INDEX IX_FactRetailOrders_OrderDateKey ON FactRetailOrders(OrderDateKey);
GO