-- ==========================================
-- File: 04_analytics.sql
-- Purpose: Exploratory Data Analysis (EDA) & Customer Cohort Analytics
-- Author: Muskan Gour
-- Date: 2026
-- ==========================================

USE EcomCohortAnalytics;
GO

-- ==========================================
-- STEP 1: EXPLORATORY DATA ANALYSIS (EDA)
-- ==========================================

-- Query 1.1: Overall Business KPI Baselines (Revenue, Orders, Customers)
SELECT 
    SUM(TotalRevenue) AS TotalRevenue,
    COUNT(DISTINCT OrderID) AS TotalOrders,
    COUNT(DISTINCT CustomerSK) AS UniqueCustomers,
    SUM(Quantity) AS TotalItemsSold
FROM FactRetailOrders;

-- Query 1.2: Average Order Value (AOV)
-- Business Metric: How much does a customer spend per transaction?
SELECT 
    SUM(TotalRevenue) / COUNT(DISTINCT OrderID) AS AverageOrderValue
FROM FactRetailOrders;

-- Query 1.3: Average Purchases per Customer
-- Business Metric: Are customers buying multiple times?
SELECT 
    CAST(COUNT(DISTINCT OrderID) AS DECIMAL(10,2)) / COUNT(DISTINCT CustomerSK) AS AveragePurchasesPerCustomer
FROM FactRetailOrders;

-- Query 1.4: Category Performance breakdown
-- Business Metric: What categories are driving our business?
SELECT 
    p.ProductCategory,
    COUNT(DISTINCT o.OrderID) AS OrdersCount,
    SUM(o.TotalRevenue) AS TotalRevenue
FROM FactRetailOrders o
JOIN DimProducts p ON o.ProductSK = p.ProductSK
GROUP BY p.ProductCategory
ORDER BY TotalRevenue DESC;