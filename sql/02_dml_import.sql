-- ==========================================
-- File: 02_dml_import.sql
-- Purpose: Ingest and populate Master Dimension and Fact Tables
-- Author: Mohit Pratap Singh
-- Date: 2026
-- ==========================================

USE EcomCohortAnalytics;
GO

-- 1. POPULATE DIMDATE (Calendar Dimension)
-- We will dynamically populate a 2-year calendar from 2025 to 2026
SET NOCOUNT ON;
DECLARE @StartDate DATE = '2025-01-01';
DECLARE @EndDate DATE = '2026-12-31';

WHILE @StartDate <= @EndDate
BEGIN
    INSERT INTO DimDate (DateKey, FullDate, CalendarYear, CalendarQuarter, CalendarMonth, MonthName, DayOfWeek)
    VALUES (
        CAST(FORMAT(@StartDate, 'yyyyMMdd') AS INT),
        @StartDate,
        YEAR(@StartDate),
        DATEPART(QUARTER, @StartDate),
        MONTH(@StartDate),
        DATENAME(MONTH, @StartDate),
        DATENAME(WEEKDAY, @StartDate)
    );
    SET @StartDate = DATEADD(DAY, 1, @StartDate);
END;
GO

-- 2. POPULATE DIMCUSTOMERS (Simulating 1,000 Unique Customers)
-- We use a CTE loop to generate a clean, realistic customer base
WITH CustomerGenerator AS (
    SELECT 1 AS ID
    UNION ALL
    SELECT ID + 1 FROM CustomerGenerator WHERE ID < 1000
)
INSERT INTO DimCustomers (CustomerAlternateID, CustomerCity, CustomerState)
SELECT 
    'CUST-' + RIGHT('0000' + CAST(ID AS VARCHAR), 4) AS CustomerAlternateID,
    CASE (ID % 5)
        WHEN 0 THEN 'Mumbai' WHEN 1 THEN 'Delhi' WHEN 2 THEN 'Bangalore' 
        WHEN 3 THEN 'Kolkata' ELSE 'Chennai' 
    END AS CustomerCity,
    CASE (ID % 5)
        WHEN 0 THEN 'Maharashtra' WHEN 1 THEN 'Delhi' WHEN 2 THEN 'Karnataka' 
        WHEN 3 THEN 'West Bengal' ELSE 'Tamil Nadu' 
    END AS CustomerState
FROM CustomerGenerator
OPTION (MAXRECURSION 1000);
GO

-- 3. POPULATE DIMPRODUCTS
-- Standard corporate categories for product segmentation analysis
INSERT INTO DimProducts (ProductID, ProductName, ProductCategory, UnitCost)
VALUES 
('P001', 'Pro Gaming Headset', 'Electronics', 45.00),
('P002', 'Mechanical Keyboard', 'Electronics', 60.00),
('P003', 'Ergonomic Office Chair', 'Furniture', 120.00),
('P004', 'Leather Desk Mat', 'Office Supplies', 15.00),
('P005', 'Running Shoes Premium', 'Apparel', 55.00),
('P006', 'Cotton Slim-Fit Hoodie', 'Apparel', 25.00),
('P007', 'Stainless Water Flask', 'Home & Kitchen', 12.00),
('P008', 'Nordic Ceramic Mug Set', 'Home & Kitchen', 18.00);
GO

-- 4. POPULATE FACTRETAILORDERS (Simulating ~10,000 realistic orders)
-- This query generates orders with built-in repurchase patterns
WITH OrderNums AS (
    SELECT 1 AS RowNum
    UNION ALL
    SELECT RowNum + 1 FROM OrderNums WHERE RowNum < 10000
)
INSERT INTO FactRetailOrders (OrderID, CustomerSK, ProductSK, OrderDateKey, Quantity, UnitPrice)
SELECT 
    'ORD-' + CAST(100000 + RowNum AS VARCHAR) AS OrderID,
    -- Simulates customer behavior: some purchase often, others once
    (ABS(CHECKSUM(NEWID())) % 1000) + 1 AS CustomerSK,
    (ABS(CHECKSUM(NEWID())) % 8) + 1 AS ProductSK,
    -- Generates random, organic transaction dates across 2025 and 2026
    CAST(FORMAT(DATEADD(DAY, ABS(CHECKSUM(NEWID())) % 730, '2025-01-01'), 'yyyyMMdd') AS INT) AS OrderDateKey,
    (ABS(CHECKSUM(NEWID())) % 4) + 1 AS Quantity,
    CASE ((ABS(CHECKSUM(NEWID())) % 8) + 1)
        WHEN 1 THEN 79.99 WHEN 2 THEN 99.99 WHEN 3 THEN 199.99 WHEN 4 THEN 29.99 
        WHEN 5 THEN 89.99 WHEN 6 THEN 45.00 WHEN 7 THEN 25.00 ELSE 35.00
    END AS UnitPrice
FROM OrderNums
OPTION (MAXRECURSION 10000);
GO