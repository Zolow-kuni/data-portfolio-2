-- ============================================================
-- Project 5 — SQL Retail Analysis
-- Dataset: Online Retail II (UK-based retailer, 2009-2011)
-- Database: retail.db (SQLite)
-- Run: python run_analysis.py
-- ============================================================


-- ============================================================
-- BASIC QUERIES
-- ============================================================

-- Query 1: Total revenue by country, ordered by revenue DESC
-- Shows which markets generate the most value
SELECT
    Country,
    ROUND(SUM(TotalValue), 2)   AS TotalRevenue,
    COUNT(DISTINCT Invoice)     AS TotalOrders,
    COUNT(DISTINCT CustomerID)  AS UniqueCustomers
FROM transactions
GROUP BY Country
ORDER BY TotalRevenue DESC;


-- Query 2: Top 20 best-selling products by quantity sold
-- Identifies highest-volume SKUs for inventory prioritisation
SELECT
    StockCode,
    Description,
    SUM(Quantity)               AS TotalQuantitySold,
    COUNT(DISTINCT CustomerID)  AS CustomersBought,
    ROUND(SUM(TotalValue), 2)   AS TotalRevenue
FROM transactions
GROUP BY StockCode, Description
ORDER BY TotalQuantitySold DESC
LIMIT 20;


-- Query 3: Monthly revenue trend across all months
-- Used for time-series analysis and seasonality detection
SELECT
    SUBSTR(InvoiceDate, 1, 7)   AS YearMonth,
    ROUND(SUM(TotalValue), 2)   AS Revenue,
    COUNT(DISTINCT Invoice)     AS Orders,
    COUNT(DISTINCT CustomerID)  AS ActiveCustomers
FROM transactions
GROUP BY YearMonth
ORDER BY YearMonth;


-- Query 4: Count of unique customers per country
-- Shows geographic distribution of customer base
SELECT
    Country,
    COUNT(DISTINCT CustomerID)  AS UniqueCustomers,
    ROUND(
        100.0 * COUNT(DISTINCT CustomerID) / SUM(COUNT(DISTINCT CustomerID)) OVER (),
        2
    )                           AS PctOfTotalCustomers
FROM transactions
GROUP BY Country
ORDER BY UniqueCustomers DESC;


-- ============================================================
-- INTERMEDIATE QUERIES — JOINs and GROUP BY
-- ============================================================

-- Query 5: Average order value per customer (joined with customers table)
-- Helps segment customers by purchasing behaviour
SELECT
    t.CustomerID,
    c.Country,
    COUNT(DISTINCT t.Invoice)                       AS OrderCount,
    ROUND(SUM(t.TotalValue), 2)                     AS TotalSpend,
    ROUND(SUM(t.TotalValue) / COUNT(DISTINCT t.Invoice), 2) AS AvgOrderValue
FROM transactions t
JOIN customers c ON t.CustomerID = c.CustomerID
GROUP BY t.CustomerID, c.Country
ORDER BY AvgOrderValue DESC
LIMIT 50;


-- Query 6: Top 10 customers by total spend
-- Key accounts for retention and VIP treatment
SELECT
    t.CustomerID,
    c.Country,
    COUNT(DISTINCT t.Invoice)       AS Orders,
    SUM(t.Quantity)                 AS ItemsBought,
    ROUND(SUM(t.TotalValue), 2)     AS TotalSpend
FROM transactions t
JOIN customers c ON t.CustomerID = c.CustomerID
GROUP BY t.CustomerID, c.Country
ORDER BY TotalSpend DESC
LIMIT 10;


-- Query 7: Revenue contribution % by country using window functions
-- Shows share of wallet by market
SELECT
    Country,
    ROUND(SUM(TotalValue), 2)   AS Revenue,
    ROUND(
        100.0 * SUM(TotalValue) / SUM(SUM(TotalValue)) OVER (),
        2
    )                           AS RevenuePct,
    ROUND(
        100.0 * SUM(SUM(TotalValue)) OVER (ORDER BY SUM(TotalValue) DESC) / SUM(SUM(TotalValue)) OVER (),
        2
    )                           AS CumulativePct
FROM transactions
GROUP BY Country
ORDER BY Revenue DESC;


-- Query 8: Products bought by only one unique customer (single-purchase products)
-- Identifies niche or slow-moving items
SELECT
    StockCode,
    Description,
    COUNT(DISTINCT CustomerID)  AS UniqueBuyers,
    SUM(Quantity)               AS TotalQtySold,
    ROUND(SUM(TotalValue), 2)   AS TotalRevenue
FROM transactions
GROUP BY StockCode, Description
HAVING COUNT(DISTINCT CustomerID) = 1
ORDER BY TotalRevenue DESC
LIMIT 30;


-- ============================================================
-- ADVANCED QUERIES — CTEs and Window Functions
-- ============================================================

-- Query 9: Month-over-month revenue growth rate using LAG()
-- Detects acceleration or deceleration in sales
WITH monthly AS (
    SELECT
        SUBSTR(InvoiceDate, 1, 7)   AS YearMonth,
        ROUND(SUM(TotalValue), 2)   AS Revenue
    FROM transactions
    GROUP BY YearMonth
)
SELECT
    YearMonth,
    Revenue,
    LAG(Revenue) OVER (ORDER BY YearMonth)  AS PrevMonthRevenue,
    ROUND(
        100.0 * (Revenue - LAG(Revenue) OVER (ORDER BY YearMonth))
        / LAG(Revenue) OVER (ORDER BY YearMonth),
        2
    )                                        AS MoMGrowthPct
FROM monthly
ORDER BY YearMonth;


-- Query 10: Customer ranking by total spend using RANK() OVER
-- Full ranking table for tiering customers
WITH customer_spend AS (
    SELECT
        CustomerID,
        ROUND(SUM(TotalValue), 2) AS TotalSpend
    FROM transactions
    GROUP BY CustomerID
)
SELECT
    CustomerID,
    TotalSpend,
    RANK()       OVER (ORDER BY TotalSpend DESC) AS SpendRank,
    DENSE_RANK() OVER (ORDER BY TotalSpend DESC) AS DenseRank,
    NTILE(4)     OVER (ORDER BY TotalSpend DESC) AS SpendQuartile
FROM customer_spend
ORDER BY TotalSpend DESC
LIMIT 50;


-- Query 11: Rolling 3-month revenue average
-- Smooths seasonality for trend identification
WITH monthly AS (
    SELECT
        SUBSTR(InvoiceDate, 1, 7)   AS YearMonth,
        ROUND(SUM(TotalValue), 2)   AS Revenue
    FROM transactions
    GROUP BY YearMonth
)
SELECT
    YearMonth,
    Revenue,
    ROUND(
        AVG(Revenue) OVER (
            ORDER BY YearMonth
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS Rolling3MonthAvg
FROM monthly
ORDER BY YearMonth;


-- Query 12: Cohort analysis — customers by first purchase month
-- Tracks how many customers from each cohort made repeat purchases
WITH first_purchase AS (
    SELECT
        CustomerID,
        SUBSTR(MIN(InvoiceDate), 1, 7) AS CohortMonth
    FROM transactions
    GROUP BY CustomerID
),
customer_activity AS (
    SELECT
        t.CustomerID,
        f.CohortMonth,
        SUBSTR(t.InvoiceDate, 1, 7) AS ActivityMonth
    FROM transactions t
    JOIN first_purchase f ON t.CustomerID = f.CustomerID
)
SELECT
    CohortMonth,
    COUNT(DISTINCT CustomerID)                          AS CohortSize,
    COUNT(DISTINCT CASE WHEN ActivityMonth > CohortMonth THEN CustomerID END) AS ReturnedCustomers,
    ROUND(
        100.0 * COUNT(DISTINCT CASE WHEN ActivityMonth > CohortMonth THEN CustomerID END)
        / COUNT(DISTINCT CustomerID),
        1
    )                                                   AS RetentionPct
FROM customer_activity
GROUP BY CohortMonth
ORDER BY CohortMonth;


-- Query 13: RFM Segmentation — Recency, Frequency, Monetary
-- Classifies each customer as High / Medium / Low value
WITH rfm_base AS (
    SELECT
        CustomerID,
        JULIANDAY('2011-12-31') - JULIANDAY(MAX(InvoiceDate)) AS Recency,
        COUNT(DISTINCT Invoice)                                AS Frequency,
        ROUND(SUM(TotalValue), 2)                             AS Monetary
    FROM transactions
    GROUP BY CustomerID
),
rfm_scored AS (
    SELECT
        CustomerID,
        Recency,
        Frequency,
        Monetary,
        NTILE(5) OVER (ORDER BY Recency ASC)    AS R_Score,
        NTILE(5) OVER (ORDER BY Frequency DESC) AS F_Score,
        NTILE(5) OVER (ORDER BY Monetary DESC)  AS M_Score
    FROM rfm_base
)
SELECT
    CustomerID,
    ROUND(Recency, 0)   AS RecencyDays,
    Frequency,
    Monetary,
    R_Score,
    F_Score,
    M_Score,
    (R_Score + F_Score + M_Score) AS RFM_Total,
    CASE
        WHEN (R_Score + F_Score + M_Score) >= 12 THEN 'High Value'
        WHEN (R_Score + F_Score + M_Score) >= 7  THEN 'Medium Value'
        ELSE 'Low Value'
    END AS CustomerSegment
FROM rfm_scored
ORDER BY RFM_Total DESC;


-- Query 14: Top 3 products per country using RANK() OVER PARTITION BY
-- Shows best sellers in each market for localised merchandising
WITH product_country AS (
    SELECT
        Country,
        StockCode,
        Description,
        SUM(Quantity)              AS TotalQty,
        ROUND(SUM(TotalValue), 2)  AS Revenue
    FROM transactions
    GROUP BY Country, StockCode, Description
),
ranked AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY Country ORDER BY TotalQty DESC) AS RankInCountry
    FROM product_country
)
SELECT
    Country,
    RankInCountry,
    StockCode,
    Description,
    TotalQty,
    Revenue
FROM ranked
WHERE RankInCountry <= 3
ORDER BY Country, RankInCountry;


-- Query 15: Customers who increased spend MoM for 3+ consecutive months
-- Identifies accelerating / growing customers for upsell campaigns
WITH monthly_spend AS (
    SELECT
        CustomerID,
        SUBSTR(InvoiceDate, 1, 7)   AS YearMonth,
        ROUND(SUM(TotalValue), 2)   AS MonthlySpend
    FROM transactions
    GROUP BY CustomerID, YearMonth
),
with_growth AS (
    SELECT
        CustomerID,
        YearMonth,
        MonthlySpend,
        LAG(MonthlySpend) OVER (PARTITION BY CustomerID ORDER BY YearMonth) AS PrevSpend
    FROM monthly_spend
),
growth_flag AS (
    SELECT
        CustomerID,
        YearMonth,
        MonthlySpend,
        PrevSpend,
        CASE WHEN MonthlySpend > PrevSpend THEN 1 ELSE 0 END AS GrowthFlag
    FROM with_growth
    WHERE PrevSpend IS NOT NULL
),
streaks AS (
    SELECT
        CustomerID,
        YearMonth,
        MonthlySpend,
        GrowthFlag,
        SUM(CASE WHEN GrowthFlag = 0 THEN 1 ELSE 0 END)
            OVER (PARTITION BY CustomerID ORDER BY YearMonth) AS BreakCount
    FROM growth_flag
),
streak_lengths AS (
    SELECT
        CustomerID,
        BreakCount,
        COUNT(*)            AS ConsecutiveGrowthMonths,
        MIN(YearMonth)      AS StreakStart,
        MAX(YearMonth)      AS StreakEnd,
        ROUND(SUM(MonthlySpend), 2) AS SpendInStreak
    FROM streaks
    WHERE GrowthFlag = 1
    GROUP BY CustomerID, BreakCount
)
SELECT
    CustomerID,
    StreakStart,
    StreakEnd,
    ConsecutiveGrowthMonths,
    SpendInStreak
FROM streak_lengths
WHERE ConsecutiveGrowthMonths >= 3
ORDER BY ConsecutiveGrowthMonths DESC, SpendInStreak DESC;
