-- SQL Project - Data Cleaning
-- Superstore Sales Analysis

-- https://www.kaggle.com/code/hanoya/superstore-sales-analysis/input

SELECT * 
FROM superstore_sales;

-- first thing we want to do is create a staging table. This is the one we will work in and clean the data. We want a table with the raw data in case something happens
CREATE TABLE superstore_sales_db.superstore_sales_staging 
LIKE superstore_sales_db.superstore_sales;

INSERT superstore_sales_staging 
SELECT * FROM superstore_sales_db.superstore_sales;

-- now when we are data cleaning we usually follow a few steps
-- 1. check for missing, duplicates and remove any
-- 2. standardize data and fix errors
-- 3. Look at null values and see what 
-- 4. remove any columns and rows that are not necessary - few ways

/* Define Columns name */
ALTER TABLE superstore_sales
    CHANGE COLUMN `Row ID`        row_id        VARCHAR(20),
    CHANGE COLUMN `Order ID`      order_id      VARCHAR(30),
    CHANGE COLUMN `Order Date`    order_date    VARCHAR(20),
    CHANGE COLUMN `Ship Date`     ship_date     VARCHAR(20),
    CHANGE COLUMN `Ship Mode`     ship_mode     VARCHAR(50),
    CHANGE COLUMN `Customer ID`   customer_id   VARCHAR(30),
    CHANGE COLUMN `Customer Name` customer_name VARCHAR(120),
    CHANGE COLUMN `Segment`       segment       VARCHAR(40),
    CHANGE COLUMN `Country`       country       VARCHAR(60),
    CHANGE COLUMN `City`          city          VARCHAR(80),
    CHANGE COLUMN `State`         state         VARCHAR(60),
    CHANGE COLUMN `Postal Code`   postal_code   VARCHAR(20),
    CHANGE COLUMN `Region`        region        VARCHAR(30),
    CHANGE COLUMN `Product ID`    product_id    VARCHAR(40),
    CHANGE COLUMN `Category`      category      VARCHAR(50),
    CHANGE COLUMN `Sub-Category`  sub_category  VARCHAR(50),
    CHANGE COLUMN `Product Name`  product_name  VARCHAR(300),
    CHANGE COLUMN `Sales`         sales         VARCHAR(30),
    CHANGE COLUMN `Quantity`      quantity      VARCHAR(20),
    CHANGE COLUMN `Discount`      discount      VARCHAR(20),
    CHANGE COLUMN `Profit`        profit        VARCHAR(30);

/* Data Validation before cleaning */
/* 1. Checking Missing Values */
SELECT
    SUM(order_id      IS NULL OR order_id      = '') AS missing_order_id,
    SUM(order_date    IS NULL OR order_date    = '') AS missing_order_date,
    SUM(ship_date     IS NULL OR ship_date     = '') AS missing_ship_date,
    SUM(customer_id   IS NULL OR customer_id   = '') AS missing_customer_id,
    SUM(customer_name IS NULL OR customer_name = '') AS missing_customer_name,
    SUM(product_id    IS NULL OR product_id    = '') AS missing_product_id,
    SUM(product_name  IS NULL OR product_name  = '') AS missing_product_name,
    SUM(postal_code   IS NULL OR postal_code   = '') AS missing_postal_code,
    SUM(region        IS NULL OR region        = '') AS missing_region,
    SUM(sales         IS NULL OR sales         = '') AS missing_sales,
    SUM(quantity      IS NULL OR quantity      = '') AS missing_quantity,
    SUM(discount      IS NULL OR discount      = '') AS missing_discount,
    SUM(profit        IS NULL OR profit        = '') AS missing_profit
FROM superstore_sales;

-- 1. Remove Duplicates


SELECT *
FROM superstore_sales_db.superstore_sales_staging;
-- these are our real duplicates
SELECT *
FROM (
	SELECT order_id, order_date, ship_date, ship_mode, customer_id, customer_name,
	       segment, country, city, state, postal_code, region, product_id,
	       category, sub_category, product_name, sales, quantity, discount, profit,
		ROW_NUMBER() OVER (
			PARTITION BY order_id, order_date, ship_date, ship_mode, customer_id,
			             customer_name, segment, country, city, state, postal_code,
			             region, product_id, category, sub_category, product_name,
			             sales, quantity, discount, profit
			) AS row_num
	FROM
		superstore_sales_staging
) duplicates
WHERE
	row_num > 1;
 -- Still there. One duplicate pair, confirmed on all 20 business columns.

 -- let's look at that order to confirm
SELECT *  
FROM superstore_sales_staging
WHERE order_id = 'US-2014-150119';  -- 4
 
 

-- these are the ones we want to delete where the row number is > 1
 
 
-- ⚠️ You may want to write it like this. IT WILL NOT WORK IN MySQL — you cannot
-- DELETE from a CTE:
/*
WITH DELETE_CTE AS
(
SELECT *
FROM (
	SELECT order_id, product_id, order_date, sales,
		ROW_NUMBER() OVER (
			PARTITION BY order_id, product_id, order_date, sales
			) AS row_num
	FROM superstore_sales_staging
) duplicates
WHERE row_num > 1
)
DELETE
FROM DELETE_CTE;
*/
 -- that datasets without a key require. We can just delete by row_id.
 SET SQL_SAFE_UPDATES = 0;
DELETE FROM superstore_sales_db.superstore_sales_staging
WHERE row_id IN (
    SELECT row_id FROM (                   
        SELECT
            row_id,
            ROW_NUMBER() OVER (
                PARTITION BY order_id, order_date, ship_date, ship_mode, customer_id,
                             customer_name, segment, country, city, state, postal_code,
                             region, product_id, category, sub_category, product_name,
                             sales, quantity, discount, profit
                ORDER BY CAST(row_id AS SIGNED)     -- keep the LOWEST row_id
            ) AS row_num
        FROM superstore_sales_db.superstore_sales_staging
    ) AS ranked
    WHERE row_num > 1
);
 
-- 1 row(s) affected.
-- seatbelt back on
 SET SQL_SAFE_UPDATES = 1;

  
-- if we check, they're gone
SELECT *
FROM (
	SELECT row_id,
		ROW_NUMBER() OVER (
			PARTITION BY order_id, order_date, ship_date, ship_mode, customer_id,
			             customer_name, segment, country, city, state, postal_code,
			             region, product_id, category, sub_category, product_name,
			             sales, quantity, discount, profit
			) AS row_num
	FROM superstore_sales_db.superstore_sales_staging
) duplicates
WHERE row_num > 1;
-- 0 rows. An empty result grid IS the pass, not a failure.
 
 
SELECT COUNT(*) AS rows_now
FROM superstore_sales_db.superstore_sales_staging;
-- 9,694.  (9,993 - 1 duplicate)

/* ------------------------------------------*/
-- 2. Standardize Data


SELECT * 
FROM superstore_sales_db.superstore_sales_staging;


-- Let's look at the categorical columns first. Typos, inconsistent casing and
-- stray spaces are the classic silent killer: a file containing 'West', 'west '
-- and 'WEST' splits every regional total three ways and nobody notices.
 
SELECT DISTINCT region
FROM superstore_sales_db.superstore_sales_staging
ORDER BY region;
-- 4 clean values: Central, East, South, West. Nothing to fix.
 
SELECT DISTINCT segment
FROM superstore_sales_db.superstore_sales_staging
ORDER BY segment;
-- 3 clean values.
 
SELECT DISTINCT category
FROM superstore_sales_db.superstore_sales_staging
ORDER BY category;
-- 3 clean values.
 
SELECT DISTINCT sub_category
FROM superstore_sales_db.superstore_sales_staging
ORDER BY sub_category;
-- 17 clean values.
 
SELECT DISTINCT ship_mode
FROM superstore_sales_db.superstore_sales_staging
ORDER BY ship_mode;
-- 4 clean values.
 
SELECT DISTINCT country
FROM superstore_sales_db.superstore_sales_staging;
-- 1 value: 'United States'. Hold that thought — see step 4.
 
select * from superstore_sales_staging;
 


 
-- Now the postal codes. Let's look at them.
 
SELECT DISTINCT postal_code
FROM superstore_sales_db.superstore_sales_staging
ORDER BY LENGTH(postal_code), postal_code;
 
-- ⚠️ Some are only 4 characters long. Let's see who.
 
SELECT state,
       COUNT(*)                        AS rows_affected,
       MIN(postal_code)                AS example_broken,
       LPAD(MIN(postal_code), 5, '0')  AS example_fixed
FROM superstore_sales_db.superstore_sales_staging
WHERE CHAR_LENGTH(postal_code) < 5
GROUP BY state
ORDER BY rows_affected DESC;
 
--  across 7 North-East states: MA, RI, NH, ME, VT, CT, NJ.

 

 
SELECT COUNT(*) AS still_broken
FROM superstore_sales_db.superstore_sales_staging
WHERE CHAR_LENGTH(postal_code) < 5;
-- 1 row with 3 digit.
 
  
SELECT state,
       COUNT(*)                        AS rows_affected,
       MIN(postal_code)                AS example_broken,
       LPAD(MIN(postal_code), 5, '0')  AS example_fixed
FROM superstore_sales_db.superstore_sales_staging
WHERE CHAR_LENGTH(postal_code) < 5
GROUP BY state
ORDER BY rows_affected DESC;
 
 SELECT *
FROM superstore_sales_db.superstore_sales_staging
WHERE CHAR_LENGTH(postal_code) < 5;
 
 
SET SQL_SAFE_UPDATES = 0;

UPDATE superstore_sales_db.superstore_sales_staging
SET postal_code = LPAD(postal_code, 5, '0')
WHERE CHAR_LENGTH(postal_code) < 5;

SET SQL_SAFE_UPDATES = 1;
 
 /* Checking  postal-code degit under 5 digits */
  SELECT *
FROM superstore_sales_db.superstore_sales_staging
WHERE CHAR_LENGTH(postal_code) < 5;
-- O
 
/* -- --------------------------------------------------- */
 
-- Let's also fix the date columns:
 
SELECT row_id, order_date, ship_date
FROM superstore_sales_db.superstore_sales_staging
LIMIT 5;

SELECT
    SUM(STR_TO_DATE(order_date, '%m/%d/%Y') IS NULL) AS order_dates_wont_parse,
    SUM(STR_TO_DATE(ship_date,  '%m/%d/%Y') IS NULL) AS ship_dates_wont_parse
FROM superstore_sales_db.superstore_sales_staging;
-- 0, 0. Every date parses.
 
 /*
-- And do they make BUSINESS sense? Can anything ship before it was ordered?
SELECT
    SUM(STR_TO_DATE(ship_date,  '%m/%d/%Y')
      < STR_TO_DATE(order_date, '%m/%d/%Y')) AS shipped_before_ordered,
    MIN(STR_TO_DATE(order_date, '%m/%d/%Y')) AS first_order,
    MAX(STR_TO_DATE(order_date, '%m/%d/%Y')) AS last_order
FROM superstore_sales_db.superstore_sales_staging;
-- 0 shipped-before-ordered. Range: 2014-01-03 to 2017-12-30. All sane.
 
-- we can use STR_TO_DATE to update this field
 SET SQL_SAFE_UPDATES = 0;

UPDATE superstore_sales_db.superstore_sales_staging
SET order_date = STR_TO_DATE(order_date, '%m/%d/%Y'),
    ship_date  = STR_TO_DATE(ship_date,  '%m/%d/%Y');
 
UPDATE superstore_sales_db.superstore_sales_staging
SET order_date = DATE_FORMAT(STR_TO_DATE(order_date, '%m/%d/%Y'), '%Y-%m-%d'),
    ship_date  = DATE_FORMAT(STR_TO_DATE(ship_date,  '%m/%d/%Y'), '%Y-%m-%d');
 SET SQL_SAFE_UPDATES = 1;

-- check before converting the type — if anything went NULL, STOP.
SELECT SUM(order_date IS NULL OR ship_date IS NULL) AS dates_lost
FROM superstore_sales_db.superstore_sales_staging;
-- 0. Safe to convert.
   */
 
-- now we can convert the data type properly
ALTER TABLE superstore_sales_db.superstore_sales_staging
MODIFY COLUMN order_date DATE,
MODIFY COLUMN ship_date  DATE;
 
 select * from superstore_sales_staging;
/* -- ---------------------------------------------------
Checking Numeric Data
 */
 
-- Now the numbers. They're all still text. Check they'll convert before you
-- convert them.
 
SELECT
    SUM(CAST(sales    AS DECIMAL(12,4)) IS NULL) AS sales_wont_convert,
    SUM(CAST(quantity AS SIGNED)        IS NULL) AS quantity_wont_convert,
    SUM(CAST(discount AS DECIMAL(5,4))  IS NULL) AS discount_wont_convert,
    SUM(CAST(profit   AS DECIMAL(12,4)) IS NULL) AS profit_wont_convert
FROM superstore_sales_db.superstore_sales_staging;
-- 0, 0, 0, 0.
 
 
-- And are they in valid RANGES?
SELECT
    SUM(CAST(sales    AS DECIMAL(12,4)) <= 0)  AS non_positive_sales,     
    SUM(CAST(quantity AS SIGNED)        <= 0)  AS non_positive_quantity, 
    SUM(CAST(discount AS DECIMAL(5,4)) < 0
     OR CAST(discount AS DECIMAL(5,4)) > 1)    AS discount_out_of_range,  
    SUM(CAST(profit   AS DECIMAL(12,4)) < 0)   AS negative_profit_rows   
FROM superstore_sales_db.superstore_sales_staging;
 
-- 1,807 rows have NEGATIVE PROFIT.
--
-- THEY ARE NOT ERRORS. They are real sales that lost money, 
-- sells at a loss.

 
 

 
ALTER TABLE superstore_sales_db.superstore_sales_staging
MODIFY COLUMN row_id      INT,
MODIFY COLUMN postal_code CHAR(5),
MODIFY COLUMN sales       DECIMAL(12,4),
MODIFY COLUMN quantity    INT,
MODIFY COLUMN discount    DECIMAL(5,4),
MODIFY COLUMN profit      DECIMAL(12,4);   -- stays SIGNED. Negatives are the finding.
 
 
SELECT *
FROM superstore_sales_db.superstore_sales_staging;
 
DESCRIBE superstore_sales_db.superstore_sales_staging;
-- Real types now. The table has stopped being a pile of strings.
 
 -- 3. Look at Null Values
 
 
SELECT
    SUM(order_id      IS NULL OR order_id      = '') AS missing_order_id,
    SUM(customer_id   IS NULL OR customer_id   = '') AS missing_customer_id,
    SUM(product_id    IS NULL OR product_id    = '') AS missing_product_id,
    SUM(postal_code   IS NULL OR postal_code   = '') AS missing_postal_code,
    SUM(region        IS NULL OR region        = '') AS missing_region,
    SUM(order_date    IS NULL)                       AS missing_order_date,
    SUM(sales         IS NULL)                       AS missing_sales,
    SUM(quantity      IS NULL)                       AS missing_quantity,
    SUM(discount      IS NULL)                       AS missing_discount,
    SUM(profit        IS NULL)                       AS missing_profit
FROM superstore_sales_db.superstore_sales_staging;
 -- 0, All zeros. Not one missing value in the entire dataset.
 
 /* -------------------------------------------*/
 -- 4. Remove any columns and rows when need to/ add column if need
-- ---------------------------------------------------------------------------
 
-- Look at them before judge them:
SELECT order_id, product_name, sub_category, sales,
       CONCAT(ROUND(discount * 100), '%') AS discount,
       profit
FROM superstore_sales_db.superstore_sales_staging
WHERE profit < 0
ORDER BY profit ASC
LIMIT 10;
 
-- Heavily-discounted Machines, Binders and Tables. Nothing is corrupt. The
-- business genuinely lost this money. Finding that out is why you're here.
 
 
-- SO: WE DELETE NO ROWS. Not one.
SELECT COUNT(*) AS rows_kept FROM superstore_sales_db.superstore_sales_staging;
-- 9,693. Same as after step 1.

 
-- Columns. Is any column carrying zero information?
 
SELECT DISTINCT country
FROM superstore_sales_db.superstore_sales_staging;
-- One value: 'United States'.


 
-- And a derived column, now that dates are real dates:
ALTER TABLE superstore_sales_db.superstore_sales_staging
ADD COLUMN ship_days SMALLINT AFTER ship_date;
 
 SET SQL_SAFE_UPDATES = 0;
UPDATE superstore_sales_db.superstore_sales_staging
SET ship_days = DATEDIFF(ship_date, order_date);

 SET SQL_SAFE_UPDATES = 0;
 
SELECT *
FROM superstore_sales_db.superstore_sales_staging;
 
 
 
 
 





