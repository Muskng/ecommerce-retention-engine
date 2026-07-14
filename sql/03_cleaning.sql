-- ==========================================
-- File: 03_cleaning.sql
-- Purpose: Run Data Integrity and Validation checks
-- Author: Mohit Pratap Singh
-- Date: 2026
-- ==========================================

USE EcomCohortAnalytics;
GO

-- QC Check 1: Check for any NULL values in critical analytical columns
SELECT 
    SUM(CASE WHEN CustomerSK IS NULL THEN 1 ELSE 0 END) AS MissingCustomers,
    SUM(CASE WHEN ProductSK IS NULL THEN 1 ELSE 0 END) AS MissingProducts,
    SUM(CASE WHEN OrderDateKey IS NULL THEN 1 ELSE 0 END) AS MissingDates,
    SUM(CASE WHEN Quantity IS NULL OR UnitPrice IS NULL THEN 1 ELSE 0 END) AS MissingFinancials
FROM FactRetailOrders;

-- QC Check 2: Check for duplicate transactional line entries
SELECT OrderID, CustomerSK, ProductSK, OrderDateKey, COUNT(*) as DuplicateCount
FROM FactRetailOrders
GROUP BY OrderID, CustomerSK, ProductSK, OrderDateKey
HAVING COUNT(*) > 1;

-- QC Check 3: Check for referential integrity leaks (Orphan Records)
-- This ensures every order points to an existing customer in our dimension
SELECT COUNT(*) AS OrphanOrdersCount
FROM FactRetailOrders o
LEFT JOIN DimCustomers c ON o.CustomerSK = c.CustomerSK
WHERE c.CustomerSK IS NULL;

-- QC Check 4: Check for negative financial data (Anomalies)
SELECT COUNT(*) AS AnomalousTransactionCount
FROM FactRetailOrders
WHERE Quantity <= 0 OR UnitPrice < 0;