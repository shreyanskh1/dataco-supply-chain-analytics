-- Phase 3: Analytical SQL Logic (CTEs, Window Functions, Risk)
USE dataco_supply_chain;

-- Query 1: CTE & Lead Time Delivery Variance Analysis
WITH Shipping_Performance AS (
    SELECT 
        `Order Id`,
        `Market`,
        `Order Region`,
        `Shipping Mode`,
        `Days for shipping (real)` AS Actual_Days,
        `Days for shipment (scheduled)` AS Scheduled_Days,
        (`Days for shipping (real)` - `Days for shipment (scheduled)`) AS Delivery_Variance_Days,
        CASE 
            WHEN `Days for shipping (real)` > `Days for shipment (scheduled)` THEN 1
            ELSE 0
        END AS Is_Late_Delivery
    FROM raw_dataco_orders
)
SELECT 
    Market,
    `Shipping Mode`,
    COUNT(`Order Id`) AS Total_Orders,
    SUM(Is_Late_Delivery) AS Total_Late_Orders,
    ROUND(AVG(Delivery_Variance_Days), 2) AS Avg_Delay_Days,
    ROUND((SUM(Is_Late_Delivery) / COUNT(`Order Id`)) * 100, 2) AS Late_Delivery_Rate_Pct
FROM Shipping_Performance
GROUP BY Market, `Shipping Mode`
HAVING Total_Orders > 50
ORDER BY Late_Delivery_Rate_Pct DESC;

-- Query 2: Product Profit Margin Ranking with DENSE_RANK()
WITH Category_Financials AS (
    SELECT 
        `Market`,
        `Category Name`,
        ROUND(SUM(`Sales`), 2) AS Total_Category_Sales,
        ROUND(SUM(`Order Profit Per Order`), 2) AS Total_Category_Profit,
        ROUND((SUM(`Order Profit Per Order`) / SUM(`Sales`)) * 100, 2) AS Profit_Margin_Pct
    FROM raw_dataco_orders
    GROUP BY `Market`, `Category Name`
)
SELECT 
    Market,
    `Category Name`,
    Total_Category_Sales,
    Total_Category_Profit,
    Profit_Margin_Pct,
    DENSE_RANK() OVER(
        PARTITION BY Market 
        ORDER BY Profit_Margin_Pct ASC
    ) AS Margin_Rank_Ascending
FROM Category_Financials
WHERE Total_Category_Sales > 1000
ORDER BY Market, Margin_Rank_Ascending;

-- Query 3: Conditional Country Risk & Fraud Exposure Tiers
SELECT 
    `Order Country`,
    `Type` AS Payment_Type,
    COUNT(`Order Id`) AS Total_Transactions,
    SUM(CASE WHEN `Order Status` = 'SUSPECTED_FRAUD' THEN 1 ELSE 0 END) AS Suspected_Fraud_Count,
    ROUND(SUM(CASE WHEN `Order Status` = 'SUSPECTED_FRAUD' THEN `Sales` ELSE 0 END), 2) AS Fraudulent_Sales_Exposure,
    ROUND((SUM(CASE WHEN `Order Status` = 'SUSPECTED_FRAUD' THEN 1 ELSE 0 END) / COUNT(`Order Id`)) * 100, 2) AS Fraud_Rate_Pct,
    CASE 
        WHEN (SUM(CASE WHEN `Order Status` = 'SUSPECTED_FRAUD' THEN 1 ELSE 0 END) / COUNT(`Order Id`)) * 100 >= 5.0 THEN 'CRITICAL RISK ZONE'
        WHEN (SUM(CASE WHEN `Order Status` = 'SUSPECTED_FRAUD' THEN 1 ELSE 0 END) / COUNT(`Order Id`)) * 100 BETWEEN 2.0 AND 4.99 THEN 'MODERATE RISK ZONE'
        ELSE 'LOW RISK ZONE'
    END AS Country_Risk_Tier
FROM raw_dataco_orders
GROUP BY `Order Country`, Payment_Type
HAVING Total_Transactions >= 20
ORDER BY Fraud_Rate_Pct DESC;