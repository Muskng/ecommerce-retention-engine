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

-- ==========================================
-- STEP 2: COHORT RETENTION ANALYTICS ENGINE
-- ==========================================

-- Create a Clean View for Power BI to consume later
IF OBJECT_ID('vw_CohortRetention', 'V') IS NOT NULL
    DROP VIEW vw_CohortRetention;
GO

CREATE VIEW vw_CohortRetention AS
WITH CustomerFirstPurchase AS (
    -- Step 1: Find the first purchase date and cohort month for each customer
    SELECT 
        CustomerSK,
        MIN(d.FullDate) AS FirstPurchaseDate,
        DATEADD(MONTH, DATEDIFF(MONTH, 0, MIN(d.FullDate)), 0) AS CohortMonth
    FROM FactRetailOrders o
    JOIN DimDate d ON o.OrderDateKey = d.DateKey
    GROUP BY CustomerSK
),
OrderMonths AS (
    -- Step 2: Map every order to its calendar month
    SELECT DISTINCT
        o.CustomerSK,
        DATEADD(MONTH, DATEDIFF(MONTH, 0, d.FullDate), 0) AS OrderMonth
    FROM FactRetailOrders o
    JOIN DimDate d ON o.OrderDateKey = d.DateKey
),
CohortGaps AS (
    -- Step 3: Calculate the month index gap between first purchase and subsequent purchases
    SELECT 
        om.CustomerSK,
        cfp.CohortMonth,
        om.OrderMonth,
        DATEDIFF(MONTH, cfp.CohortMonth, om.OrderMonth) AS MonthIndex
    FROM OrderMonths om
    JOIN CustomerFirstPurchase cfp ON om.CustomerSK = cfp.CustomerSK
),
CohortSizes AS (
    -- Step 4: Calculate total starting customers in each cohort (Month Index = 0)
    SELECT 
        CohortMonth,
        COUNT(DISTINCT CustomerSK) AS CohortSize
    FROM CohortGaps
    WHERE MonthIndex = 0
    GROUP BY CohortMonth
)
-- Step 5: Put it all together to calculate active customers and retention percentages
SELECT 
    cg.CohortMonth,
    cs.CohortSize,
    cg.MonthIndex,
    COUNT(DISTINCT cg.CustomerSK) AS ActiveCustomers,
    CAST(COUNT(DISTINCT cg.CustomerSK) AS DECIMAL(10,2)) / cs.CohortSize AS RetentionRate
FROM CohortGaps cg
JOIN CohortSizes cs ON cg.CohortMonth = cs.CohortMonth
GROUP BY cg.CohortMonth, cs.CohortSize, cg.MonthIndex;
GO

-- Test our newly created Cohort view in SSMS
SELECT * FROM vw_CohortRetention
ORDER BY CohortMonth, MonthIndex;


-- ==========================================
-- STEP 3: DYNAMIC CUSTOMER SEGMENTATION ENGINE
-- ==========================================

-- Create a Clean View for Customer Profiling in Power BI
IF OBJECT_ID('vw_CustomerSegments', 'V') IS NOT NULL
    DROP VIEW vw_CustomerSegments;
GO

CREATE VIEW vw_CustomerSegments AS
WITH CustomerStats AS (
    -- Step 1: Calculate lifetime metrics per customer
    SELECT 
        CustomerSK,
        COUNT(DISTINCT OrderID) AS LifetimeOrders,
        SUM(TotalRevenue) AS LifetimeSpend,
        MAX(OrderDateKey) AS LastPurchaseDateKey
    FROM FactRetailOrders
    GROUP BY CustomerSK
)
-- Step 2: Categorize customers dynamically based on their lifetime order counts
SELECT 
    c.CustomerSK,
    c.CustomerAlternateID,
    c.CustomerCity,
    c.CustomerState,
    s.LifetimeOrders,
    s.LifetimeSpend,
    s.LifetimeSpend / s.LifetimeOrders AS AverageOrderValue,
    CASE 
        WHEN s.LifetimeOrders > 12 THEN 'VIP Power User'
        WHEN s.LifetimeOrders BETWEEN 5 AND 12 THEN 'Active Repeat Shopper'
        WHEN s.LifetimeOrders BETWEEN 2 AND 4 THEN 'Slipping Shopper'
        ELSE 'One-Time Buyer'
    END AS CustomerSegment
FROM DimCustomers c
JOIN CustomerStats s ON c.CustomerSK = s.CustomerSK;
GO

-- Test our Customer Segmentation view
SELECT CustomerSegment, COUNT(*) AS TotalCustomers, SUM(LifetimeSpend) AS SegmentRevenue
FROM vw_CustomerSegments
GROUP BY CustomerSegment
ORDER BY SegmentRevenue DESC;