/********************************************************************
OVER CLAUSE() ORDER BY AND PARTITION BY CLAUSES
********************************************************************/
-- https://www.databasejournal.com/features/mssql/introduction-to-the-partition-by-window-function.html
-- https://drill.apache.org/docs/sql-window-functions-introduction/

-- The OVER() clause has the following capabilities:
       -- PARTITION BY: Defines window partitions to form groups of rows
              -- PARTITION BY - PARTITION BY resets the value of the aggregating function everytime the
              -- column used in the partition by criteria changes
              -- Example: in a SUM() OVER (a cumsum), the sum counter y reset to zero everytime the column used
              -- in the PARTITION BY CRITERIA
       -- ORDER BY Orders rows within a partition:
              -- ORDER BY - ORDER BY orders the rows (in the window only) the function evaluates.
              -- Rows that have the same ORDER BY value will be aggregated together and assigned the same value.
              -- It adds the aggregated values in chunks with the same ORDER BY criteria.
              -- Example: in a SUM() OVER (cumsum) all the rows matching in ORDER BY creatiria will have.
              -- the same value.

/********************************************************************
CUMSUM EXAMPLE
********************************************************************/
-- 1. Create a running total of standard_amt_usd (in the orders table)
-- over order time with no date truncation. Your final table should have
-- two columns: one with the amount being added for each new row,
-- and a second with the running total.

/*
CUMSUM
The over clause only has an ORDER BY clause and not a PARTITION BY. The counter
is never reset (the sum occurs over the whole dataset), ordering by date. Since
the occurred_at column never repeats itself, the running_total column is constantly
changing.
*/
SELECT standard_amt_usd,
       SUM(standard_amt_usd) OVER (ORDER BY occurred_at) AS running_total
FROM orders

-- 2. Now, modify your query from the previous quiz to include partitions.
-- Still create a running total of standard_amt_usd (in the orders table) over
-- order time, but this time, date truncate occurred_at by year and partition
-- by that same year-truncated occurred_at variable. Your final table should
-- have three columns: One with the amount being added for each row, one for
-- the truncated date, and a final column with the running total within each year.
/*
CUMSUM POR AÑO
PARTITION BY Resetea el contador de cumsum cada cambio de año.
*/
SELECT standard_amt_usd,
       DATE_TRUNC('year', occurred_at) as year,
       SUM(standard_amt_usd) OVER
       (PARTITION BY DATE_TRUNC('year', occurred_at)
        ORDER BY occurred_at) AS running_total
FROM orders

/*
CUMSUM POR AÑO SIN ORDER BY
PARTITION BY Resetea el contador de cumsum cada cambio de año.
Assumes that the ORDER BY function is that specified in PARTITION BY
and therefore every value with the same year is assigned the same running_total
(the added total for the year)
*/
SELECT standard_amt_usd,
       DATE_TRUNC('year', occurred_at) as year,
       SUM(standard_amt_usd) OVER
       (PARTITION BY DATE_TRUNC('year', occurred_at)
        ) AS running_total
FROM orders

/********************************************************************
AGGREGATE FUNCTIONS AND PARTITION
********************************************************************/

-- The ORDER and PARTITION define what is referred to as the “window”—the
-- ordered subset of data over which calculations are made. Removing ORDER BY
-- just leaves an unordered partition; in our query's case, each column's value
-- is simply an aggregation (e.g., sum, count, average, minimum, or maximum)
-- of all the standard_qty values in its respective account_id.

-- Example:
-- Example:
       -- SUM(standard_qty) OVER (PARTITION BY account_id ORDER BY DATE_TRUNC('month',occurred_at)) AS sum_std_qty,
       -- PARTITION BY -->
SELECT id,
       account_id,
       standard_qty,
       DATE_TRUNC('month', occurred_at) AS month,
       DENSE_RANK() OVER (PARTITION BY account_id ORDER BY DATE_TRUNC('month',occurred_at)) AS dense_rank,
       SUM(standard_qty) OVER (PARTITION BY account_id ORDER BY DATE_TRUNC('month',occurred_at)) AS sum_std_qty,
       COUNT(standard_qty) OVER (PARTITION BY account_id ORDER BY DATE_TRUNC('month',occurred_at)) AS count_std_qty,
       AVG(standard_qty) OVER (PARTITION BY account_id ORDER BY DATE_TRUNC('month',occurred_at)) AS avg_std_qty,
       MIN(standard_qty) OVER (PARTITION BY account_id ORDER BY DATE_TRUNC('month',occurred_at)) AS min_std_qty,
       MAX(standard_qty) OVER (PARTITION BY account_id ORDER BY DATE_TRUNC('month',occurred_at)) AS max_std_qty
FROM orders

-- Example:
-- When we omit the order by statement the functions applied are not run month by month, but only account
-- by account.
-- Example: the same cumsum for each account and not divided by the month
SELECT id,
       account_id,
       standard_qty,
       DATE_TRUNC('month', occurred_at) AS month,
       DENSE_RANK() OVER (PARTITION BY account_id)  AS dense_rank,
       SUM(standard_qty) OVER (PARTITION BY account_id)  AS sum_std_qty,
       COUNT(standard_qty) OVER (PARTITION BY account_id) AS count_std_qty,
       AVG(standard_qty) OVER (PARTITION BY account_id)  AS avg_std_qty,
       MIN(standard_qty) OVER (PARTITION BY account_id)  AS min_std_qty,
       MAX(standard_qty) OVER (PARTITION BY account_id)  AS max_std_qty
FROM orders

/********************************************************************
RANKING WINDOW FUNCTIONS
ROW_NUMBER(): distinct numbers for each record
RANK(): ties are given the same numbers and numbers are skipped for subsequent records
DENSE_RANK(): ties are given the same number and numbers are not skipped for subsequent records
********************************************************************/

-- Select the id, account_id, and total variable from the orders table, then create a column
-- called total_rank that ranks this total amount of paper ordered (from highest to lowest)
-- for each account using a partition. Your final table should have these four columns.
SELECT id,
       account_id,
       total,
       RANK() OVER (PARTITION BY account_id ORDER BY total DESC) AS total_rank
FROM orders

/********************************************************************
WINDOW FUNCTIONS AND ALIASES
********************************************************************/
-- If you are planning to write multiple window functions that leverage the same
-- PARTITION BY, OVER and ORDER BY in a single query, aliases come in handy
SELECT order_id,
       order_total,
       order_price,
       SUM(order_total) OVER monthly_window AS running_monthly_sales,
       COUNT(order_id) OVER monthly_window AS running_monthly_orders,
       AVG(order_price) OVER monthly_window AS average_monthly_price
FROM   amazon_sales_db
WHERE  order_date < '2017-01-01'
WINDOW monthly_window AS
       (PARTITION BY month(order_date) ORDER BY order_date)

-- ANOTHER EXAMPLE WITHOT ALIAS AND WINDOWS FUNCTION
SELECT id,
       account_id,
       DATE_TRUNC('year',occurred_at) AS year,
       DENSE_RANK() OVER (PARTITION BY account_id ORDER BY DATE_TRUNC('year',occurred_at)) AS dense_rank,
       total_amt_usd,
       SUM(total_amt_usd) OVER (PARTITION BY account_id ORDER BY DATE_TRUNC('year',occurred_at)) AS sum_total_amt_usd,
       COUNT(total_amt_usd) OVER (PARTITION BY account_id ORDER BY DATE_TRUNC('year',occurred_at)) AS count_total_amt_usd,
       AVG(total_amt_usd) OVER (PARTITION BY account_id ORDER BY DATE_TRUNC('year',occurred_at)) AS avg_total_amt_usd,
       MIN(total_amt_usd) OVER (PARTITION BY account_id ORDER BY DATE_TRUNC('year',occurred_at)) AS min_total_amt_usd,
       MAX(total_amt_usd) OVER (PARTITION BY account_id ORDER BY DATE_TRUNC('year',occurred_at)) AS max_total_amt_usd
FROM orders

-- REWRITTEN USING A WINDOW FUNCTION AND THE ALIAS OF THAT WINDOW FUNCTION
SELECT id,
       account_id,
       DATE_TRUNC('year',occurred_at) AS year,
       DENSE_RANK() OVER account_yearly_window AS dense_rank,
       total_amt_usd,
       SUM(total_amt_usd) OVER account_yearly_window AS sum_total_amt_usd,
       COUNT(total_amt_usd) OVER account_yearly_window AS count_total_amt_usd,
       AVG(total_amt_usd) OVER account_yearly_window AS avg_total_amt_usd,
       MIN(total_amt_usd) OVER account_yearly_window AS min_total_amt_usd,
       MAX(total_amt_usd) OVER account_yearly_window AS max_total_amt_usd
FROM orders
WINDOW account_yearly_window AS
       (PARTITION BY account_id ORDER BY DATE_TRUNC('year',occurred_at))

/********************************************************************
COMPARING ROW TO A PREVIOUS ROW
********************************************************************/
/*
https://www.sqlservertutorial.net/sql-server-window-functions/sql-server-lag-function/
LAG(return_value, offset, default)
       - return_value: return value of the previos row based on a specified offset.
       - offset: number of rows back from the current row from which to access data
       - default: value to be returned if the offset goes beyond the scope of the partition
       - PARTITION BY: distributes rows of the result set into partitions to which the LAG() is applied
       - ORDER BY: specifies the logical order of the rows in each partition to which the LAG() is applied
Returns the value from a previos row to the current row in the table
*/

-- Step 1: look at the inner query and see what this creates
SELECT     account_id, SUM(standard_qty) AS standard_sum
FROM       orders
GROUP BY   1

-- Step 2: start bulding the outer query and name the inner query as sub
SELECT account_id, standard_sum
FROM   (
        SELECT   account_id, SUM(standard_qty) AS standard_sum
        FROM     orders
        GROUP BY 1
       ) sub

-- Step 3 (part A): add a window function OVER (ORDER BY standard_sum) in the outer query
-- that will create a result set in ascending order based on the standard_sum column
-- Step 3 (part B): the LAG function creates a new column as part of the outer query.
-- This new column named lag uses the values from the ordered "standard_sum" (part A in step 3).
ELECT account_id,
       standard_sum,
       LAG(standard_sum) OVER (ORDER BY standard_sum) AS lag
FROM   (
        SELECT   account_id, SUM(standard_qty) AS standard_sum
        FROM     orders
        GROUP BY 1
       ) sub

-- Step 4: add the lag difference
SELECT account_id,
       standard_sum,
       LAG(standard_sum) OVER (ORDER BY standard_sum) AS lag,
       standard_sum - LAG(standard_sum) OVER (ORDER BY standard_sum) AS lag_difference
FROM (
       SELECT account_id,
       SUM(standard_qty) AS standard_sum
       FROM orders
       GROUP BY 1
      ) sub

/*
https://www.sqlservertutorial.net/sql-server-window-functions/sql-server-lag-function/
LEAD(return_value, offset, default)
       - return_value: return value of the previos row based on a specified offset.
       - offset: number of rows back from the current row from which to access data
       - default: value to be returned if the offset goes beyond the scope of the partition
       - PARTITION BY: distributes rows of the result set into partitions to which the LAG() is applied
       - ORDER BY: specifies the logical order of the rows in each partition to which the LAG() is applied
Returns the value from a previos row to the current row in the table
*/

-- EXAMPLE
-- Determine how the current order's total revenue ("total" from sales of all types of paper) compares to the
-- next order's total revenue.
       -- You will need: occurred_at, total_amt_usd in orders along with LEAD
       -- Four columns: occurred_at, total_amt_usd, lead and lead_difference

SELECT order_id,
       account_id,
       occurred_at,
       total_amt_usd,
       LEAD(total_amt_usd) OVER (ORDER BY total_amt_usd) as lead
FROM orders

/*
PERCENTILES
Window functions can be used to generate percentiles
NTILE(# of buckets)
       - ORDER BY determines which column to used to determine the tiles

1. NTILE + the number of buckets you’d like to create within a column
       (e.g., 100 buckets would create traditional percentiles, 4 buckets would create quartiles, etc.)
2. OVER
3. ORDER BY (optional, typically a date column)
4. AS + the new column name

PERCENTILES AND LOW NUMBER OF ROWS
If the number of rows is lower than NTILE+ then NTILE will divide the rows into as many groups as there
are members (rows) in the set, but then stop short of the requested number of groups.

If working with very small windows keep this in mind and consider using quartiles or similarly small bands.
*/
NTILE (# of buckets) OVER
       (ORDER BY ranking_column)
       AS new_column name


-- PERCENTILES EXAMES
-- 1. Use the NTILE functionality to divide the accounts into 4 levels in terms of the amount of 
-- standard_qty for their orders. Your resulting table should have the account_id, the occurred_at 
-- time for each order, the total amount of standard_qty paper purchased, and one of four levels 
-- in a standard_quartile column.

-- Quartiles example
-- This groups the order for each account and ranks all the orders within each account in quartiles
-- The partition by ensures that the classification is carried out independently within each account.
SELECT account_id,
       occurred_at,
       standard_qty,
       NTILE(4) OVER (PARTITION BY account_id ORDER BY standard_qty) as std_quartiles
FROM orders
ORDER BY account_id DESC, std_quartiles DESC

-- 2. Use the NTILE functionality to divide the accounts into two levels in terms of the amount of 
-- gloss_qty for their orders. Your resulting table should have the account_id, the occurred_at 
-- time for each order, the total amount of gloss_qty paper purchased, and one of two 
-- levels in a gloss_half column.
SELECT account_id,
       occurred_at,
       gloss_qty,
       NTILE(2) OVER (PARTITION BY account_id ORDER BY gloss_qty) as gloss_half
FROM orders
ORDER BY account_id DESC, gloss_half DESC

-- 3. Use the NTILE functionality to divide the orders for each account into 100 levels in terms of the 
-- amount of total_amt_usd for their orders. Your resulting table should have the account_id, 
-- the occurred_at time for each order, the total amount of total_amt_usd paper purchased, and one 
-- of 100 levels in a total_percentile column.
SELECT account_id,
       total_amt_usd,
       gloss_qty,
       NTILE(100) OVER (PARTITION BY account_id ORDER BY total_amt_usd) as total_percentile
FROM orders
ORDER BY account_id DESC, total_percentile DESC