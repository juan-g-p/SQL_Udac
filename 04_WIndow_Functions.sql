/********************************************************************
OVER CLAUSE() ORDER BY AND PARTITION FUNCTIONS
********************************************************************/
-- The OVER() clause has the following capabilities:
       -- Defines window partitions to form groups of rows (PARTITION BY clause).
       -- Orders rows within a partition (ORDER BY clause).

/********************************************************************
CUMSUM EXAMPLE
********************************************************************/
-- 1. Create a running total of standard_amt_usd (in the orders table) 
-- over order time with no date truncation. Your final table should have 
-- two columns: one with the amount being added for each new row, 
-- and a second with the running total.

/*
CUMSUM
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
Resetea el contador de cumsum cada cambio de año.
PARTITION BY --> indica el subconjunto de agregación.
*/
SELECT standard_amt_usd,
       DATE_TRUNC('year', occurred_at) as year,
       SUM(standard_amt_usd) OVER 
       (PARTITION BY DATE_TRUNC('year', occurred_at) 
        ORDER BY occurred_at) AS running_total
FROM orders

/********************************************************************
AGGREGATE FUNCTIONS AND PARTITION
********************************************************************/
/********************************************************************
OVER CLAUSE() ORDER BY AND PARTITION FUNCTIONS
********************************************************************/
-- https://www.databasejournal.com/features/mssql/introduction-to-the-partition-by-window-function.html
-- https://drill.apache.org/docs/sql-window-functions-introduction/

-- The OVER() clause has the following capabilities:
       -- PARTITION BY: Defines window partitions to form groups of rows
              -- PARTITION BY - PARTITION BY resets its counter every time a given column changes values.
       -- ORDER BY Orders rows within a partition
              -- ORDER BY - ORDER BY orders the rows (in the window only) the function evaluates.

-- The ORDER BY clause is one of two clauses integral to window functions. 
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
********************************************************************/
-- Example:
-- Row_nunber(): distinct numbers for each record
-- Rank(): ties are given the same numbers and numbers are skipped for subsequent records
-- Dense_rank(): ties are given the same number and numbers are not skipped for subsequent records

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