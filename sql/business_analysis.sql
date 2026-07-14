/* =============================================================================
   Business_Analysis/analysis.sql                                   STEP 6 OF 6
   ---------------------------------------------------------------------------
   THE FIVE BUSINESS QUESTIONS — the reason this project exists.

     Q1  Which categories generate the highest sales and profit?
     Q2  Which sub-categories are the most and least profitable?
     Q3  Which regions perform best?
     Q4  How do discounts affect profit?      <-- THE HEADLINE FINDING
     Q5  How did sales and profit change over time?
     Q6 customer segmentation 

    */
   
   
   /* 
   THE EXECUTIVE SUMMARY.  One row. Start here.
    */
SELECT
    COUNT(*)                                        AS order_lines,
    COUNT(DISTINCT order_id)                        AS orders,
    COUNT(DISTINCT customer_id)                     AS customers,
    ROUND(SUM(sales), 2)                            AS total_sales,
    ROUND(SUM(profit), 2)                           AS total_profit,
    ROUND(100 * SUM(profit) / SUM(sales), 2)        AS profit_margin_pct,
    ROUND(SUM(sales) / COUNT(DISTINCT order_id), 2) AS avg_order_value,
    ROUND(AVG(discount) * 100, 2)                   AS avg_discount_pct,
    ROUND(100 * SUM(profit < 0) / COUNT(*), 2)      AS pct_lines_sold_at_a_loss
FROM superstore_sales_staging;
/* ANSWER: 2272168.48 total sales | 282869.81 profit | 12.45% margin
           …and 18.64% of all order lines are sold AT A LOSS. Hold that thought. */



/* 
   Q1 — WHICH CATEGORIES GENERATE THE HIGHEST SALES AND PROFIT?
 */
SELECT
    category,
    ROUND(SUM(sales), 2)                                    AS sales,
    ROUND(SUM(profit), 2)                                   AS profit,
    ROUND(100 * SUM(profit) / SUM(sales), 2)                AS margin_pct,
    ROUND(100 * SUM(sales)  / SUM(SUM(sales))  OVER (), 2)  AS pct_of_sales,
    ROUND(100 * SUM(profit) / SUM(SUM(profit)) OVER (), 2)  AS pct_of_profit,
    RANK() OVER (ORDER BY SUM(sales)  DESC)                 AS rank_by_sales,
    RANK() OVER (ORDER BY SUM(profit) DESC)                 AS rank_by_profit
FROM superstore_sales_staging
GROUP BY category
ORDER BY sales DESC;

SELECT
    COALESCE(category, 'ALL CATEGORIES') AS category,
    ROUND(SUM(CASE WHEN segment = 'Consumer'    THEN profit END), 2) AS consumer,
    ROUND(SUM(CASE WHEN segment = 'Corporate'   THEN profit END), 2) AS corporate,
    ROUND(SUM(CASE WHEN segment = 'Home Office' THEN profit END), 2) AS home_office,
    ROUND(SUM(profit), 2)                                            AS total_profit
FROM superstore_sales_staging
GROUP BY category WITH ROLLUP;


 -- Q2 — WHICH SUB-CATEGORIES ARE THE MOST AND LEAST PROFITABLE?
  
SELECT
    category,
    sub_category,
    ROUND(SUM(sales), 2)                     AS sales,
    ROUND(SUM(profit), 2)                    AS profit,
    ROUND(100 * SUM(profit) / SUM(sales), 2) AS margin_pct,
    ROUND(AVG(discount) * 100, 1)            AS avg_discount_pct,
    SUM(quantity)                            AS units_sold,
    CASE WHEN SUM(profit) < 0 THEN 'LOSS MAKING' ELSE 'Profitable' END AS status
FROM superstore_sales_staging
GROUP BY category, sub_category
ORDER BY profit DESC;

/* Top 5 and Bottom 5 in ONE result set (RANK both directions). */
WITH sub AS (
    SELECT
        sub_category,
        ROUND(SUM(profit), 2)                   AS profit,
        RANK() OVER (ORDER BY SUM(profit) DESC) AS rank_best,
        RANK() OVER (ORDER BY SUM(profit) ASC)  AS rank_worst
    FROM superstore_sales_staging
    GROUP BY sub_category
)
SELECT
    CASE WHEN rank_best <= 5 THEN 'TOP 5' ELSE 'BOTTOM 5' END AS bucket,
    sub_category,
    profit
FROM sub
WHERE rank_best <= 5 OR rank_worst <= 5
ORDER BY profit DESC;


/* The fix-it-first list: products sold 5+ times that have NEVER made money. */
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

/* 
   Q3 — WHICH REGIONS PERFORM BEST?
*/
SELECT
    region,
    COUNT(DISTINCT order_id)                        AS orders,
    COUNT(DISTINCT customer_id)                     AS customers,
    ROUND(SUM(sales), 2)                            AS sales,
    ROUND(SUM(profit), 2)                           AS profit,
    ROUND(100 * SUM(profit) / SUM(sales), 2)        AS margin_pct,
    ROUND(AVG(discount) * 100, 1)                   AS avg_discount_pct,
    ROUND(SUM(sales) / COUNT(DISTINCT order_id), 2) AS avg_order_value,
    ROUND(AVG(ship_days), 1)                        AS avg_ship_days
FROM superstore_sales_staging
GROUP BY region
ORDER BY profit DESC;


/* Region x Category — where exactly is the money leaking? */
SELECT
    region,
    category,
    ROUND(SUM(sales), 2)                     AS sales,
    ROUND(SUM(profit), 2)                    AS profit,
    ROUND(100 * SUM(profit) / SUM(sales), 2) AS margin_pct
FROM superstore_sales_staging
GROUP BY region, category
ORDER BY margin_pct;


/* The 10 worst states — this is what turns "a bad region" into an action. */
SELECT
    state,
    region,
    ROUND(SUM(sales), 2)                     AS sales,
    ROUND(SUM(profit), 2)                    AS profit,
    ROUND(100 * SUM(profit) / SUM(sales), 2) AS margin_pct,
    ROUND(AVG(discount) * 100, 1)            AS avg_discount_pct
FROM superstore_sales_staging
GROUP BY state, region
ORDER BY profit ASC
LIMIT 10;


/* 
   Q4 — HOW DO DISCOUNTS AFFECT PROFIT?        *** THE HEADLINE FINDING ***
*/

/* 4a. Every discount level actually used, and what it earns.
*/
SELECT
    ROUND(discount * 100)                       AS discount_pct,
    COUNT(*)                                    AS order_lines,
    ROUND(SUM(sales), 2)                        AS sales,
    ROUND(SUM(profit), 2)                       AS profit,
    ROUND(100 * SUM(profit) / SUM(sales), 2)    AS margin_pct,
    ROUND(AVG(profit), 2)                       AS avg_profit_per_line,
    ROUND(100 * SUM(profit < 0) / COUNT(*), 1)  AS pct_lines_losing_money
FROM superstore_sales_staging
GROUP BY discount
ORDER BY discount;
/* ANSWER — the cliff is unmistakable:
     0%  ->  +29.57% margin |   0.0% of lines lose money
    20%  ->  +11.82% margin |  13.7% of lines lose money
    30%  ->  -10.06% margin |  91.6% of lines lose money
    50%+ ->  EVERY SINGLE LINE loses money. No exceptions, in four years.       */


/* 4b. The same thing in bands — the table for your README. */
SELECT
    CASE
        WHEN discount = 0     THEN '0% (none)'
        WHEN discount <= 0.20 THEN '1-20%'
        WHEN discount <= 0.40 THEN '21-40%'
        WHEN discount <= 0.60 THEN '41-60%'
        ELSE                       '60%+'
    END                                         AS discount_band,
    COUNT(*)                                    AS order_lines,
    ROUND(SUM(sales), 2)                        AS sales,
    ROUND(SUM(profit), 2)                       AS profit,
    ROUND(100 * SUM(profit) / SUM(sales), 2)    AS margin_pct,
    ROUND(100 * SUM(profit < 0) / COUNT(*), 1)  AS pct_lines_losing_money,
    ROUND(AVG(quantity), 2)                     AS avg_units_per_line
FROM superstore_sales_staging
GROUP BY discount_band
ORDER BY MIN(discount);


/* 4c. Where is break-even? The first discount level that turns net-negative. */
SELECT
    ROUND(discount * 100) AS first_loss_making_discount_pct,
    ROUND(SUM(profit), 2) AS profit_at_that_level
FROM superstore_sales_staging
GROUP BY discount
HAVING SUM(profit) < 0
ORDER BY discount
LIMIT 1;
/* 30%. Everything at or above 30% is net-negative. 20% is the last safe level. */


/* 4d. Pearson correlation between discount and margin — computed in pure SQL.
*/
SELECT
    ROUND(
      (COUNT(*) * SUM(discount * margin) - SUM(discount) * SUM(margin))
      / SQRT(
          (COUNT(*) * SUM(discount * discount) - POW(SUM(discount), 2)) *
          (COUNT(*) * SUM(margin   * margin)   - POW(SUM(margin),   2))
        )
    , 4) AS pearson_r_discount_vs_margin
FROM (SELECT discount, 100 * profit / sales AS margin FROM superstore_sales_staging) t;



/* 4e. The bill. What is over-discounting actually costing? */
SELECT
    COUNT(*)                      AS loss_making_lines,
    ROUND(SUM(profit), 2)         AS profit_burned,
    ROUND(SUM(sales), 2)          AS sales_on_those_lines,
    ROUND(AVG(discount) * 100, 1) AS avg_discount_on_those_lines
FROM superstore_sales_staging
WHERE profit < 0;




/* 
   Q5 — HOW DID SALES AND PROFIT CHANGE OVER TIME?
*/

/* 5a. Yearly, with year-over-year growth (LAG). */
WITH yearly AS (
    SELECT YEAR(order_date) AS yr, SUM(sales) AS sales, SUM(profit) AS profit
    FROM superstore_sales_staging
    GROUP BY YEAR(order_date)
)
SELECT
    yr                                                       AS year,
    ROUND(sales, 2)                                          AS sales,
    ROUND(profit, 2)                                         AS profit,
    ROUND(100 * profit / sales, 2)                           AS margin_pct,
    ROUND(100 * (sales  - LAG(sales)  OVER (ORDER BY yr))
              / LAG(sales)  OVER (ORDER BY yr), 2)           AS sales_yoy_pct,
    ROUND(100 * (profit - LAG(profit) OVER (ORDER BY yr))
              / LAG(profit) OVER (ORDER BY yr), 2)           AS profit_yoy_pct
FROM yearly
ORDER BY yr;


/* 5b. Monthly, with a 3-month moving average and a running year-to-date total. */
WITH monthly AS (
    SELECT
        DATE_FORMAT(order_date, '%Y-%m') AS ym,
        YEAR(order_date)                 AS yr,
        SUM(sales)                       AS sales,
        SUM(profit)                      AS profit
    FROM superstore_sales_staging
    GROUP BY DATE_FORMAT(order_date, '%Y-%m'), YEAR(order_date)
)
SELECT
    ym                                                                    AS month,
    ROUND(sales, 2)                                                       AS sales,
    ROUND(profit, 2)                                                      AS profit,
    ROUND(AVG(sales) OVER (ORDER BY ym
          ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2)                   AS sales_3mo_moving_avg,
    ROUND(SUM(sales) OVER (PARTITION BY yr ORDER BY ym
          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 2)           AS sales_ytd
FROM monthly
ORDER BY ym;

/* 5c. Seasonality — which months carry the year? */
SELECT
    MONTH(order_date)                                   AS month_no,
    DATE_FORMAT(order_date, '%b')                       AS month_name,
    ROUND(SUM(sales), 2)                                AS sales_all_years,
    ROUND(SUM(sales) / COUNT(DISTINCT YEAR(order_date)), 2) AS avg_sales_per_year,
    ROUND(SUM(profit), 2)                               AS profit_all_years,
    ROUND(100 * SUM(sales) / SUM(SUM(sales)) OVER (), 1) AS pct_of_all_sales
FROM superstore_sales_staging
GROUP BY MONTH(order_date), DATE_FORMAT(order_date, '%b')
ORDER BY month_no;


/* 5d. Quarterly, with quarter-over-quarter growth. */
WITH q AS (
    SELECT YEAR(order_date) AS yr, QUARTER(order_date) AS qtr,
           SUM(sales) AS sales, SUM(profit) AS profit
    FROM superstore_sales_staging
    GROUP BY YEAR(order_date), QUARTER(order_date)
)
SELECT
    CONCAT(yr, ' Q', qtr)                                        AS period,
    ROUND(sales, 2)                                              AS sales,
    ROUND(profit, 2)                                             AS profit,
    ROUND(100 * profit / sales, 2)                               AS margin_pct,
    ROUND(100 * (sales - LAG(sales) OVER (ORDER BY yr, qtr))
              / LAG(sales) OVER (ORDER BY yr, qtr), 1)           AS qoq_sales_pct
FROM q
ORDER BY yr, qtr;




/* CUSTOMER SEGMENTATION
*/
WITH rfm_base AS (
    SELECT
        customer_id,
        customer_name,
        segment,
        DATEDIFF((SELECT MAX(order_date) + INTERVAL 1 DAY FROM superstore_sales_staging),
                 MAX(order_date))     AS recency_days,
        COUNT(DISTINCT order_id)      AS frequency,
        SUM(sales)                    AS monetary,
        SUM(profit)                   AS lifetime_profit
    FROM superstore_sales_staging
    GROUP BY customer_id, customer_name, segment
),
scored AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY recency_days DESC, customer_id) AS r_score,
        NTILE(5) OVER (ORDER BY frequency,         customer_id) AS f_score,
        NTILE(5) OVER (ORDER BY monetary,          customer_id) AS m_score
    FROM rfm_base
),
tagged AS (
    SELECT *,
        CASE
            WHEN r_score >= 4 AND f_score >= 4 THEN 'Champions'
            WHEN r_score >= 3 AND f_score >= 3 THEN 'Loyal'
            WHEN r_score >= 4 AND f_score <= 2 THEN 'New / Promising'
            WHEN r_score <= 2 AND f_score >= 4 THEN 'At Risk (was valuable)'
            WHEN r_score <= 2 AND f_score <= 2 THEN 'Hibernating'
            ELSE                                    'Needs Attention'
        END AS rfm_segment
    FROM scored
)
SELECT
    rfm_segment,
    COUNT(*)                                                   AS customers,
    ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)           AS pct_of_customers,
    ROUND(SUM(monetary), 2)                                    AS sales,
    ROUND(100 * SUM(monetary) / SUM(SUM(monetary)) OVER (), 1) AS pct_of_sales,
    ROUND(AVG(monetary), 2)                                    AS avg_customer_value,
    ROUND(AVG(recency_days), 0)                                AS avg_days_since_last_order,
    ROUND(SUM(lifetime_profit), 2)                             AS profit
FROM tagged
GROUP BY rfm_segment
ORDER BY sales DESC;



