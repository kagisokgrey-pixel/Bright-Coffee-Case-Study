-- ============================================================
-- STEP 1: OVERVIEW & SHAPE
-- ============================================================

DESCRIBE brightcoffee_salesanalysis.brightcoffeesales_schema.bright_coffee_shop_sales;

SELECT *
FROM brightcoffee_salesanalysis.brightcoffeesales_schema.bright_coffee_shop_sales
LIMIT 100;

SELECT COUNT(*) AS Num_of_rows
FROM brightcoffee_salesanalysis.brightcoffeesales_schema.bright_coffee_shop_sales;

-- ============================================================
-- STEP 2:CHECK MISSING / NULL VALUE CHECK 
-- ============================================================

SELECT
  COUNT(*)                                          AS total_rows,
  COUNT(*) - COUNT(transaction_id)                  AS null_transaction_id,
  COUNT(*) - COUNT(transaction_date)                AS null_transaction_date,
  COUNT(*) - COUNT(transaction_time)                AS null_transaction_time,
  COUNT(*) - COUNT(transaction_qty)                 AS null_transaction_qty,
  COUNT(*) - COUNT(store_id)                        AS null_store_id,
  COUNT(*) - COUNT(store_location)                  AS null_store_location,
  COUNT(*) - COUNT(product_id)                      AS null_product_id,
  COUNT(*) - COUNT(unit_price)                      AS null_unit_price,
  COUNT(*) - COUNT(product_category)                AS null_product_category,
  COUNT(*) - COUNT(product_type)                     AS null_product_type,
  COUNT(*) - COUNT(product_detail)                  AS null_product_detail
FROM brightcoffee_salesanalysis.brightcoffeesales_schema.bright_coffee_shop_sales;

-- ============================================================
-- STEP 3: DUPLICATE CHECK
-- ============================================================

SELECT transaction_id, COUNT(*) AS occurrences
FROM brightcoffee_salesanalysis.brightcoffeesales_schema.bright_coffee_shop_sales
GROUP BY transaction_id
HAVING COUNT(*) > 1;

-- ============================================================
-- STEP 4: UNIT_PRICE FORMAT CHECK
-- ============================================================

SELECT DISTINCT unit_price
FROM brightcoffee_salesanalysis.brightcoffeesales_schema.bright_coffee_shop_sales
WHERE unit_price LIKE '%,%'
ORDER BY 1
LIMIT 30;
-- Any values that won't cast cleanly even after replacing commas
SELECT DISTINCT unit_price
FROM brightcoffee_salesanalysis.brightcoffeesales_schema.bright_coffee_shop_sales
WHERE TRY_CAST(REPLACE(unit_price, ',', '.') AS DECIMAL(10,2)) IS NULL;


-- ============================================================
-- STEP 5: DATE RANGE CHECK
-- ============================================================

SELECT
  MIN(transaction_date) AS earliest_date,
  MAX(transaction_date) AS latest_date,
  COUNT(DISTINCT transaction_date) AS distinct_days
FROM brightcoffee_salesanalysis.brightcoffeesales_schema.bright_coffee_shop_sales;

-- ============================================================
-- STEP 6: TRANSACTION_TIME  CHECK
-- ============================================================
SELECT
  transaction_time,
  date_format(transaction_time, 'yyyy-MM-dd') AS date_part_seen,
  date_format(transaction_time, 'HH:mm:ss')   AS time_part_seen
FROM brightcoffee_salesanalysis.brightcoffeesales_schema.bright_coffee_shop_sales
LIMIT 10;

-- ============================================================
-- STEP 7: TEXT FIELD CONSISTENCY CHECK
-- ============================================================

SELECT DISTINCT product_category FROM brightcoffee_salesanalysis.brightcoffeesales_schema.bright_coffee_shop_sales ORDER BY 1;
SELECT DISTINCT product_type     FROM brightcoffee_salesanalysis.brightcoffeesales_schema.bright_coffee_shop_sales ORDER BY 1;
SELECT DISTINCT store_location   FROM brightcoffee_salesanalysis.brightcoffeesales_schema.bright_coffee_shop_sales ORDER BY 1;

-- ============================================================
-- STEP 8: BUILD THE CLEANED + TRANSFORMED TABLE
-- - Fixes unit_price comma decimals
-- - Adds total_amount = unit_price * transaction_qty
-- - Adds transaction_time_bucket (30-minute intervals)
--   (uses HOUR/MINUTE only — never the unreliable date part)
-- ============================================================

CREATE OR REPLACE TABLE brightcoffee_salesanalysis.brightcoffeesales_schema.bright_coffee_shop_sales_clean AS
SELECT
  transaction_id,
  transaction_date,
  transaction_time,
  transaction_qty,
  store_id,
  store_location,
  product_id,
  CAST(REPLACE(unit_price, ',', '.') AS DECIMAL(10,2)) AS unit_price,
  product_category,
  product_type,
  product_detail,
  ROUND(
    CAST(REPLACE(unit_price, ',', '.') AS DECIMAL(10,2)) * transaction_qty,
    2
  ) AS total_amount,
  CONCAT(
    LPAD(CAST(HOUR(transaction_time) AS STRING), 2, '0'), ':',
    LPAD(CAST(FLOOR(MINUTE(transaction_time) / 30) * 30 AS INT), 2, '0')
  ) AS transaction_time_bucket_30min,
  CONCAT(
    LPAD(CAST(FLOOR(HOUR(transaction_time) / 3) * 3 AS INT), 2, '0'), ':00'
  ) AS transaction_time_bucket_3hr
FROM brightcoffee_salesanalysis.brightcoffeesales_schema.bright_coffee_shop_sales;

-- ============================================================
-- STEP 9: VERIFYING  THE CLEANED TABLE
-- ============================================================

SELECT COUNT(*) AS total_rows
FROM brightcoffee_salesanalysis.brightcoffeesales_schema.bright_coffee_shop_sales_clean;

SELECT
  MIN(unit_price) AS min_price,
  MAX(unit_price) AS max_price,
  COUNT(*) - COUNT(unit_price) AS null_prices,
  MIN(total_amount) AS min_total,
  MAX(total_amount) AS max_total
FROM brightcoffee_salesanalysis.brightcoffeesales_schema.bright_coffee_shop_sales_clean;

SELECT transaction_time_bucket_30min, COUNT(*) AS n
FROM brightcoffee_salesanalysis.brightcoffeesales_schema.bright_coffee_shop_sales_clean
GROUP BY transaction_time_bucket_30min
ORDER BY transaction_time_bucket_30min;

-- Revenue and units sold by product category
SELECT
  product_category,
  SUM(total_amount)     AS revenue,
  SUM(transaction_qty)  AS units_sold,
  COUNT(*)              AS transactions
FROM brightcoffee_salesanalysis.brightcoffeesales_schema.bright_coffee_shop_sales_clean
GROUP BY product_category
ORDER BY revenue DESC;

-- Top 10 revenue-generating product types
SELECT
  product_type,
  SUM(total_amount)    AS revenue,
  SUM(transaction_qty) AS units_sold
FROM brightcoffee_salesanalysis.brightcoffeesales_schema.bright_coffee_shop_sales_clean
GROUP BY product_type
ORDER BY revenue DESC
LIMIT 10;

-- Bottom 10 revenue-generating product types (underperformers)
SELECT
  product_type,
  SUM(total_amount)    AS revenue,
  SUM(transaction_qty) AS units_sold
FROM brightcoffee_salesanalysis.brightcoffeesales_schema.bright_coffee_shop_sales_clean
GROUP BY product_type
ORDER BY revenue ASC
LIMIT 10;

-- Revenue and transaction volume by 30-minute time bucket
SELECT
  transaction_time_bucket_30min,
  SUM(total_amount)    AS revenue,
  COUNT(*)             AS transactions,
  ROUND(AVG(total_amount), 2) AS avg_transaction_value
FROM brightcoffee_salesanalysis.brightcoffeesales_schema.bright_coffee_shop_sales_clean
GROUP BY transaction_time_bucket_30min
ORDER BY transaction_time_bucket_30min;

-- Revenue trend by date
SELECT
  transaction_date,
  SUM(total_amount) AS revenue,
  COUNT(*) AS transactions
FROM brightcoffee_salesanalysis.brightcoffeesales_schema.bright_coffee_shop_sales_clean
GROUP BY transaction_date
ORDER BY transaction_date;

-- Revenue trend by month
SELECT
  date_format(transaction_date, 'yyyy-MM') AS month,
  SUM(total_amount) AS revenue
FROM brightcoffee_salesanalysis.brightcoffeesales_schema.bright_coffee_shop_sales_clean
GROUP BY date_format(transaction_date, 'yyyy-MM')
ORDER BY month;

-- Revenue trend by day of week
SELECT
  date_format(transaction_date, 'EEEE') AS day_of_week,
  SUM(total_amount) AS revenue,
  COUNT(*) AS transactions
FROM brightcoffee_salesanalysis.brightcoffeesales_schema.bright_coffee_shop_sales_clean
GROUP BY date_format(transaction_date, 'EEEE')
ORDER BY revenue DESC;

-- Product category performance by time bucket (cross-tab of what sells when)
SELECT
  transaction_time_bucket_30min,
  product_category,
  SUM(total_amount) AS revenue
FROM brightcoffee_salesanalysis.brightcoffeesales_schema.bright_coffee_shop_sales_clean
GROUP BY transaction_time_bucket_30min, product_category
ORDER BY transaction_time_bucket_30min, revenue DESC;

-- Revenue by store location (bonus, if comparing branches)
SELECT
  store_location,
  SUM(total_amount) AS revenue,
  COUNT(*) AS transactions
FROM brightcoffee_salesanalysis.brightcoffeesales_schema.bright_coffee_shop_sales_clean
GROUP BY store_location
ORDER BY revenue DESC;

-- Overall average order value
SELECT ROUND(AVG(total_amount), 2) AS avg_order_value
FROM brightcoffee_salesanalysis.brightcoffeesales_schema.bright_coffee_shop_sales_clean;

-- ============================================================
-- STEP 11: GETTING THE FINAL ANALYSIS-READY TABLE

-- ============================================================

CREATE OR REPLACE TABLE brightcoffee_salesanalysis.brightcoffeesales_schema.bright_coffee_shop_sales_final AS
SELECT
  -- identifiers
  transaction_id,
  store_id,
  store_location,
  product_id,

  -- product dimensions
  product_category,
  product_type,
  product_detail,

  -- date dimensions
  transaction_date,
  date_format(transaction_date, 'yyyy-MM')   AS transaction_month,
  date_format(transaction_date, 'EEEE')      AS day_of_week,
  CASE
    WHEN date_format(transaction_date, 'EEEE') IN ('Saturday', 'Sunday')
    THEN 'Weekend' ELSE 'Weekday'
  END                                        AS day_type,
  weekofyear(transaction_date)               AS week_number,
  -- time dimensions (time-of-day only — the date part of transaction_time is unreliable)
  date_format(transaction_time, 'HH:mm:ss')  AS transaction_time_of_day,
  HOUR(transaction_time)                     AS transaction_hour,
  transaction_time_bucket_30min,
  transaction_time_bucket_3hr,

  -- core measures
  unit_price,
  transaction_qty,
  total_amount

FROM brightcoffee_salesanalysis.brightcoffeesales_schema.bright_coffee_shop_sales_clean;

SELECT COUNT(*) AS total_rows
FROM brightcoffee_salesanalysis.brightcoffeesales_schema.bright_coffee_shop_sales_final;

SELECT *
FROM brightcoffee_salesanalysis.brightcoffeesales_schema.bright_coffee_shop_sales_final;
