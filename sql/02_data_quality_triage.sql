-- Phase 2: Data Quality Audit & Ingestion Triage
USE dataco_supply_chain;

-- 1. Recursive sequence CTE to isolate the 3 missing/rejected records
SET SESSION cte_max_recursion_depth = 200000;

WITH RECURSIVE numbers AS (
    SELECT 1 AS id
    UNION ALL
    SELECT id + 1
    FROM numbers
    WHERE id < 180519
)
SELECT numbers.id AS missing_order_item_id
FROM numbers
LEFT JOIN raw_dataco_orders r
    ON r.`Order Item Id` = numbers.id
WHERE r.`Order Item Id` IS NULL;

-- 2. Validate misplaced zipcodes across remaining records
SELECT 
    `Order Item Id`,
    `Customer City`,
    `Customer State`,
    `Customer Street`,
    `Customer Zipcode`
FROM raw_dataco_orders
WHERE `Customer State` REGEXP '^[0-9]{5}$';