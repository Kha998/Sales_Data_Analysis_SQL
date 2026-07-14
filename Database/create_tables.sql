/* =============================================================================
   Database/create_tables.sql                                       STEP 2 OF 6
   ---------------------------------------------------------------------------
   Creates the two tables this project uses. Nothing to edit. Run the whole file.

   THE DESIGN — two layers, and the reason for each:

     superstore_raw    Everything VARCHAR. The CSV lands here exactly as it is.
                       A load must NEVER fail because one value was the wrong
                       shape. Get the data in first, look at it, THEN fix it.

     superstore        Typed, deduplicated, indexed. This is what every analysis
                       query reads. Built by Data_Cleaning/cleaning.sql.

   Why not just query the raw table? Two reasons, both fatal:
     1. Everything in it is TEXT. You cannot SUM('261.96') or compare dates.
     2. It still contains a duplicate row. Query it directly and your sales
        total is $2,297,200.86. The correct figure is $2,296,919.49. You would
        be $281 wrong and never know.

   NEXT: Data_Load/import_data.sql
   ============================================================================= */
USE superstore;

DROP TABLE IF EXISTS superstore;
DROP TABLE IF EXISTS superstore_raw;


/* =============================================================================
   LAYER 1 — THE RAW LANDING TABLE
   Deliberately permissive. Every column VARCHAR.
   ============================================================================= */
CREATE TABLE superstore_raw (
    row_id        VARCHAR(20),
    order_id      VARCHAR(30),
    order_date    VARCHAR(20),    -- arrives as text: '11/8/2016'
    ship_date     VARCHAR(20),
    ship_mode     VARCHAR(50),
    customer_id   VARCHAR(30),
    customer_name VARCHAR(120),
    segment       VARCHAR(40),
    country       VARCHAR(60),
    city          VARCHAR(80),
    state         VARCHAR(60),
    postal_code   VARCHAR(20),    -- text, so leading zeros can survive (05408)
    region        VARCHAR(30),
    product_id    VARCHAR(40),
    category      VARCHAR(50),
    sub_category  VARCHAR(50),
    product_name  VARCHAR(300),
    sales         VARCHAR(30),
    quantity      VARCHAR(20),
    discount      VARCHAR(20),
    profit        VARCHAR(30)
) ENGINE = InnoDB;


/* =============================================================================
   LAYER 2 — THE CLEAN ANALYTICAL TABLE
   Grain: ONE ROW = ONE PRODUCT ON ONE ORDER (an "order line").
   That grain matters: an order with 3 products is 3 rows here. It's why
   COUNT(*) = 9,993 order lines but COUNT(DISTINCT order_id) = 5,009 orders.
   ============================================================================= */
CREATE TABLE superstore (
    row_id        INT           NOT NULL,
    order_id      VARCHAR(20)   NOT NULL,
    order_date    DATE          NOT NULL,
    ship_date     DATE          NOT NULL,
    ship_days     SMALLINT      NOT NULL,   -- derived: ship_date - order_date
    ship_mode     VARCHAR(30)   NOT NULL,
    customer_id   VARCHAR(20)   NOT NULL,
    customer_name VARCHAR(100)  NOT NULL,
    segment       VARCHAR(30)   NOT NULL,
    country       VARCHAR(60)   NOT NULL,
    city          VARCHAR(60)   NOT NULL,
    state         VARCHAR(60)   NOT NULL,
    postal_code   CHAR(5)       NOT NULL,   -- CHAR(5): 05408 keeps its zero
    region        VARCHAR(20)   NOT NULL,
    product_id    VARCHAR(30)   NOT NULL,
    category      VARCHAR(40)   NOT NULL,
    sub_category  VARCHAR(40)   NOT NULL,
    product_name  VARCHAR(255)  NOT NULL,
    sales         DECIMAL(12,4) NOT NULL,   -- DECIMAL not FLOAT: money must be exact
    quantity      INT           NOT NULL,
    discount      DECIMAL(5,4)  NOT NULL,   -- 0.0000 to 0.8000
    profit        DECIMAL(12,4) NOT NULL,   -- CAN BE NEGATIVE. That is the point.

    PRIMARY KEY (row_id),

    /* Indexes on the columns the analysis actually GROUPs BY. */
    KEY ix_order_date  (order_date),
    KEY ix_region      (region),
    KEY ix_category    (category, sub_category),
    KEY ix_customer    (customer_id),
    KEY ix_discount    (discount)
) ENGINE = InnoDB;


/* -----------------------------------------------------------------------------
   CHECK — both tables exist and are empty.
----------------------------------------------------------------------------- */
SHOW TABLES;

SELECT
    (SELECT COUNT(*) FROM superstore_raw) AS raw_rows,     -- 0
    (SELECT COUNT(*) FROM superstore)     AS clean_rows;   -- 0


/* =============================================================================
   ✅ Tables created (empty).   NEXT: Data_Load/import_data.sql
   ============================================================================= */
