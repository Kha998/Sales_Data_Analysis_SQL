/* Explolarity Data Analysis */


SELECT * from superstore_sales_staging;


-- now when we are doing exploratory data analysis we usually follow a few steps
-- 1. Understand the dataset
-- 2. Examine numerical data
-- 3. Analyze categories
-- 4. Analyze the time dimension
-- 5. Identify outliers or unusual values
 
 
SELECT
    COUNT(*)                                 AS order_lines,
    COUNT(DISTINCT order_id)                 AS orders,
    COUNT(DISTINCT customer_id)              AS customers,
    ROUND(SUM(sales), 2)                     AS total_sales,
    ROUND(SUM(profit), 2)                    AS total_profit,
    SUM(profit < 0)                          AS loss_making_lines
FROM superstore_sales_staging;
-- 9693	4931	793	2272168.48	282869.81	1807
 
 
-- 1. Understand the dataset

 
-- What are we even looking at? Get oriented before you go looking for anything.
 
DESCRIBE superstore_sales_staging;
 
SELECT * FROM superstore_sales_staging LIMIT 10;
 
 
SELECT
    COUNT(*)                                        AS order_lines,
    COUNT(DISTINCT order_id)                        AS orders,
    COUNT(DISTINCT customer_id)                     AS customers,
    COUNT(DISTINCT product_id, product_name)        AS products,
    COUNT(DISTINCT state)                           AS states,
    MIN(order_date)                                 AS first_order,
    MAX(order_date)                                 AS last_order,
    ROUND(SUM(sales), 2)                            AS total_sales,
    ROUND(SUM(profit), 2)                           AS total_profit,
    ROUND(100 * SUM(profit) / SUM(sales), 2)        AS profit_margin_pct,
    ROUND(SUM(sales) / COUNT(DISTINCT order_id), 2) AS avg_order_value,
    ROUND(AVG(discount) * 100, 2)                   AS avg_discount_pct,
    ROUND(100 * SUM(profit < 0) / COUNT(*), 2)      AS pct_lines_sold_at_a_loss
FROM superstore_sales_staging;

WITH per_order AS (
    SELECT order_id, COUNT(*) AS lines_per_order, SUM(sales) AS order_value
    FROM superstore_sales_staging
    GROUP BY order_id
)
SELECT
    lines_per_order,
    COUNT(*)                                         AS orders,
    ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_orders,
    ROUND(AVG(order_value), 2)                       AS avg_order_value
FROM per_order
GROUP BY lines_per_order
ORDER BY lines_per_order;
 

-- 2. Examine numerical data
 
-- Min, mean, max and spread of every measure. This is where you find out whether
-- "average" is even a meaningful word for this data.
 
SELECT
    'sales'     AS measure,
    ROUND(MIN(sales), 2)      AS min_value,
    ROUND(AVG(sales), 2)      AS mean_value,
    ROUND(MAX(sales), 2)      AS max_value,
    ROUND(STDDEV(sales), 2)   AS std_dev
FROM superstore_sales_staging
UNION ALL
SELECT 'profit',    ROUND(MIN(profit),2),   ROUND(AVG(profit),2),   ROUND(MAX(profit),2),   ROUND(STDDEV(profit),2)   FROM superstore_sales_staging
UNION ALL
SELECT 'quantity',  MIN(quantity),          ROUND(AVG(quantity),2), MAX(quantity),          ROUND(STDDEV(quantity),2) FROM superstore_sales_staging
UNION ALL
SELECT 'discount',  ROUND(MIN(discount),2), ROUND(AVG(discount),2), ROUND(MAX(discount),2), ROUND(STDDEV(discount),2) FROM superstore_sales_staging
UNION ALL
SELECT 'ship_days', MIN(ship_days),         ROUND(AVG(ship_days),2),MAX(ship_days),         ROUND(STDDEV(ship_days),2) FROM superstore_sales_staging;
 
-- sales     min $0.44        mean $229.85     max $22,638.48
-- profit    min -$6,599.98   mean $28.66      max $8,399.98
-- discount  0.00 to 0.80
--
-- Look at profit's MINIMUM: someone lost SIX AND A HALF THOUSAND DOLLARS on a
-- single sale. We'll come back to that in step 5.
 

 
WITH ordered AS (
    SELECT
        sales,
        ROW_NUMBER() OVER (ORDER BY sales) AS rn,
        COUNT(*)    OVER ()                AS n
    FROM superstore_sales_staging
)
SELECT ROUND(AVG(sales), 2) AS median_line_sales
FROM ordered
WHERE rn IN (FLOOR((n + 1) / 2), CEIL((n + 1) / 2));    -- handles odd AND even n
 
-- MEDIAN = $55.92.    

-- transaction that almost never happens. HALF of all sales are under $55.
 
 
-- How is profit distributed? Bucket it.
 
SELECT
    CASE
        WHEN profit <  -100 THEN '1. Big loss   (< -$100)'
        WHEN profit <     0 THEN '2. Small loss (-$100 to $0)'
        WHEN profit <   100 THEN '3. Small win  ($0 to $100)'
        WHEN profit <  1000 THEN '4. Good win   ($100 to $1000)'
        ELSE                     '5. Big win    (> $1000)'
    END                                              AS profit_band,
    COUNT(*)                                         AS order_lines,
    ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_lines,
    ROUND(SUM(profit), 2)                            AS total_profit
FROM superstore_sales_staging
GROUP BY profit_band
ORDER BY profit_band;
 
-- Nearly one line in five is a loss. That is not a rounding error — it's a pattern.
 
 
-- 3. Analyze categories 
-- How many distinct values does each dimension have? Understand the grain of a
-- column BEFORE you group by it.
 
SELECT 'region'          AS attribute, COUNT(DISTINCT region)       AS distinct_values FROM superstore_sales_staging
UNION ALL SELECT 'state',           COUNT(DISTINCT state)        FROM superstore_sales_staging
UNION ALL SELECT 'city',            COUNT(DISTINCT city)         FROM superstore_sales_staging
UNION ALL SELECT 'segment',         COUNT(DISTINCT segment)      FROM superstore_sales_staging
UNION ALL SELECT 'category',        COUNT(DISTINCT category)     FROM superstore_sales_staging
UNION ALL SELECT 'sub_category',    COUNT(DISTINCT sub_category) FROM superstore_sales_staging
UNION ALL SELECT 'ship_mode',       COUNT(DISTINCT ship_mode)    FROM superstore_sales_staging
UNION ALL SELECT 'discount_levels', COUNT(DISTINCT discount)     FROM superstore_sales_staging
ORDER BY distinct_values DESC;
 -- 4 regions, 49 states, 3 categories, 17 sub-categories, city 529...

-- WHERE DOES THE MONEY COME FROM? Every top-level slice, side by side.
 SELECT 'Segment' AS dimension, segment AS value,
       ROUND(SUM(sales), 2)                     AS sales,
       ROUND(SUM(profit), 2)                    AS profit,
       ROUND(100 * SUM(profit) / SUM(sales), 2) AS margin_pct
FROM superstore_sales_staging GROUP BY segment
UNION ALL
SELECT 'Category', category, ROUND(SUM(sales),2), ROUND(SUM(profit),2),
       ROUND(100*SUM(profit)/SUM(sales),2)
FROM superstore_sales_staging GROUP BY category
UNION ALL
SELECT 'Region', region, ROUND(SUM(sales),2), ROUND(SUM(profit),2),
       ROUND(100*SUM(profit)/SUM(sales),2)
FROM superstore_sales_staging GROUP BY region
UNION ALL
SELECT 'Ship mode', ship_mode, ROUND(SUM(sales),2), ROUND(SUM(profit),2),
       ROUND(100*SUM(profit)/SUM(sales),2)
FROM superstore_sales_staging GROUP BY ship_mode
ORDER BY dimension, sales DESC;
 
-- Now SCAN THE margin_pct COLUMN. Two things stick out like sore thumbs:
--   Furniture   2.32%   
--   Central     8.06%   ...
-- Those are threads worth pulling. They become Q1, Q2 and Q3 in the analysis.
 
 
-- All 17 sub-categories. Which ones actually lose money?
 SELECT
    category,
    sub_category,
    ROUND(SUM(sales), 2)                     AS sales,
    ROUND(SUM(profit), 2)                    AS profit,
    ROUND(100 * SUM(profit) / SUM(sales), 2) AS margin_pct,
    ROUND(AVG(discount) * 100, 1)            AS avg_discount_pct
FROM superstore_sales_staging
GROUP BY category, sub_category
ORDER BY profit ASC;
 
-- Tables -$17,725 | Bookcases -$3,473 | Supplies -$1,348.57


-- Discount is a category (only 12 values), so just group by it and look at profit.
 SELECT
    ROUND(discount * 100)                            AS discount_pct,
    COUNT(*)                                         AS order_lines,
    ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_all_lines,
    ROUND(SUM(sales), 2)                             AS sales,
    ROUND(SUM(profit), 2)                            AS profit
FROM superstore_sales_staging
GROUP BY discount
ORDER BY discount;
 
--   0%  ->  +317184.04
--  10%  ->    +9,029.18
--  15%  ->    +1,418.99
--  20%  ->   +89379.30
--  30%  ->   -10357.22   <---- flips NEGATIVE here
--  32%  ->    -2391.14
--  40%  ->   -23065.44
--  45%  ->    -2493.11
--  50%  ->   -20506.43
--  60%  ->    -5548.40
--  70%  ->   -39643.72
--  80%  ->   -30136.24
--
-- EVERY discount level of 30% and above has NEGATIVE total profit.
-- Every single one. Not one exception in four years of data.
-- That is not a coincidence. This becomes Q4 in the business analysis — and it
-- turns out to be the headline of the entire project.
 
 

-- SHIPPING — and this one is about RULING SOMETHING OUT.
 SELECT
    ship_mode,
    COUNT(*)                                 AS order_lines,
    ROUND(AVG(ship_days), 1)                 AS avg_ship_days,
    ROUND(SUM(sales), 2)                     AS sales,
    ROUND(SUM(profit), 2)                    AS profit,
    ROUND(100 * SUM(profit) / SUM(sales), 2) AS margin_pct
FROM superstore_sales_staging
GROUP BY ship_mode
ORDER BY sales DESC;
 
-- Standard Class  5.0 days  12.08%
-- Second Class    3.2 days  12.51%
-- First Class     2.2 days  13.93%
-- Same Day        0.0 days  12.38%
-- RULING THINGS OUT IS HALF OF GOOD ANALYSIS. It's how you know the discount
-- finding is the real story, and not just the first thing you happened to look at.
 
 
-- 4. Analyze the time dimension 
-- First: is the series COMPLETE? Check for gaps before you analyse any trend.
 
SELECT
    DATE_FORMAT(order_date, '%Y-%m') AS month,
    COUNT(DISTINCT order_id)         AS orders,
    COUNT(*)                         AS order_lines,
    ROUND(SUM(sales), 2)             AS sales,
    ROUND(SUM(profit), 2)            AS profit
FROM superstore_sales_staging
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY month;
 
-- 48 rows = 48 months = 2014-01 through 2017-12. No gaps. The series can be trusted.

-- Yearly. Is the business growing, and is it getting BETTER at making money?
SELECT
    YEAR(order_date)                         AS year,
    COUNT(DISTINCT order_id)                 AS orders,
    ROUND(SUM(sales), 2)                     AS sales,
    ROUND(SUM(profit), 2)                    AS profit,
    ROUND(100 * SUM(profit) / SUM(sales), 2) AS margin_pct
FROM superstore_sales_staging
GROUP BY YEAR(order_date)
ORDER BY year;
 
-- 2014  $483,966  |  10.19%
-- 2015  $470,533  |  13.11%
-- 2016  $609,206  |  13.33%
-- 2017  $733,215  |  12.80%

-- Seasonality. Which months carry the year?
 SELECT
    MONTH(order_date)                                   AS month_no,
    DATE_FORMAT(order_date, '%b')                       AS month_name,
    ROUND(SUM(sales), 2)                                AS sales_all_years,
    ROUND(SUM(sales) / COUNT(DISTINCT YEAR(order_date)), 2) AS avg_sales_per_year,
    ROUND(100 * SUM(sales) / SUM(SUM(sales)) OVER (), 1)    AS pct_of_all_sales
FROM superstore_sales_staging
GROUP BY MONTH(order_date), DATE_FORMAT(order_date, '%b')
ORDER BY month_no;
 


 
 
 

-- 5. Identify outliers or unusual values
 

-- Top 10 biggest wins and top 10 biggest losses, side by side — WITH the
-- discount column visible.
 
(SELECT 'BIGGEST WIN' AS type, order_id, product_name, sub_category,
        sales, ROUND(discount * 100) AS discount_pct, profit
 FROM superstore_sales_staging ORDER BY profit DESC LIMIT 10)
UNION ALL
(SELECT 'BIGGEST LOSS', order_id, product_name, sub_category,
        sales, ROUND(discount * 100), profit
 FROM superstore_sales_staging ORDER BY profit ASC LIMIT 10);
 
-- NOW LOOK AT THE discount_pct COLUMN. It sorts itself:
--
--   Top 10 WINS   -> every single one at 0% or 20% discount
--                    (Copiers, Binders, Machines)
--   Top 10 LOSSES -> every single one at 40%, 50%, 70% or 80%
--                    (Machines, Binders, Tables)
 
 

 
-- Products that are sold OFTEN and still never make money. The fix-it-first list.
 
SELECT
    product_name,
    sub_category,
    COUNT(*)                      AS times_sold,
    SUM(quantity)                 AS units,
    ROUND(SUM(sales), 2)          AS sales,
    ROUND(SUM(profit), 2)         AS profit,
    ROUND(AVG(discount) * 100, 1) AS avg_discount_pct
FROM superstore_sales_staging
GROUP BY product_name, sub_category
HAVING SUM(profit) < 0 AND COUNT(*) >= 5
ORDER BY profit ASC
LIMIT 15;
 
-- 15 products, sold 5+ times each, that have NEVER made money.
-- Worst: Chromcraft Bull-Nose Conference Table — sold 5 times, lost $2,876,
-- at a 28% average discount.
 
 
-- Customers who cost more than they bring in.
 WITH per_customer AS (
    SELECT
        customer_id,
        customer_name,
        COUNT(DISTINCT order_id) AS orders,
        SUM(sales)               AS lifetime_sales,
        SUM(profit)              AS lifetime_profit
    FROM superstore_sales_staging
    GROUP BY customer_id, customer_name
)
SELECT
    COUNT(*)                                   AS total_customers,
    SUM(lifetime_profit < 0)                   AS loss_making_customers,
    ROUND(100 * SUM(lifetime_profit < 0) / COUNT(*), 1) AS pct_of_customers
FROM per_customer;
 
-- 157 of 793 customers are net loss-making across their
 
 
--  AND THE MOST IMPORTANT "OUTLIER" OF ALL:
 
SELECT
    SUM(profit < 0)                                     AS loss_making_lines,
    ROUND(100 * SUM(profit < 0) / COUNT(*), 2)          AS pct_of_all_lines,
    ROUND(SUM(CASE WHEN profit < 0 THEN profit END), 2) AS total_profit_burned,
    ROUND(AVG(CASE WHEN profit < 0 THEN discount END) * 100, 1) AS avg_discount_on_them
FROM superstore_sales_staging;
 
-- 1,870 lines | 18.64% of everything sold | -154499.09 burned | 47.7% avg discount
 
 
-- NEXT: Business_Analysis/analysis.sql
-- ---------------------------------------------------------------------------