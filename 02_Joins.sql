/*******************************************************************
--:JOIN GENERAL SYNTAX ONE COLUMN JOIN
********************************************************************/
-- IMPORTANT: in a JOIN operation, AT LEAST ONE OF THE KEYS needs to
-- be a PRIMARY KEY

-- PRIMARY KEY: unique column in a particlar table.
-- FOREIGN KEy: column in one table that is a primary key in a different table.

-- Location of left and right talbes in a join 
SELECT 
FROM left_table
JOIN right_table

-- BY CONVENTION: always use left join, never right join.
SELECT
FROM left_table
JOIN right_table --JOIN alone = LEFT INNER JOIN
ON left_table.columnA = right_table.columnA

/*******************************************************************
--:OUTER JOINS SYNTHAX
********************************************************************/
LEFT OUTER = LEFT JOIN
RIGHT OUTER = RIGHT JOIN
FULL OUTER JOIN = OUTER JOIN

/*******************************************************************
--:MULTI-COLUMN JOIN
********************************************************************/
/* 
Example: database with three tables T1, T2, and T3
NOTE: in the example C1, C2... represent column names
- table_1 (T1): 
    - primary key: C1 and column C2 (primary compound key)
    - data: C3 and C4
- table_2 (T2):
    - foreign key: C1 and C2 (the primary keys of the enrolement table)
    - data: C5 and C6
- table_3 (T3):
    - primary key: C1 (same key as in tables 1 and 2)
    - data: C7, C8

You want to join all tables into a single one
 */
SELECT T1.*, T2.*, T3.*
FROM table_1 T1
JOIN T2 -- Multiple keys join
    ON T1.C1 = T2.C1
    AND T1.C2 = T2.C2
JOIN T3
    ON T1.C1 = T3.C1

/*******************************************************************
--:JOINS EXAMPLES
********************************************************************/
-- 1- Try pulling all the data from the accounts table, and 
-- all the data from the orders table.
SELECT *
FROM orders
JOIN accounts
    ON accounts.id = orders.account_id

SELECT orders.*, accounts.*
FROM orders
JOIN accounts
    ON accounts.id = orders.account_id

-- 2- Try pulling standard_qty, gloss_qty, and poster_qty from
-- the orders table, and the website and the primary_poc from the accounts table.
SELECT orders.standard_qty, orders.gloss_qty, orders.poster_qty,
       accounts.website, accounts.primary_poc
FROM orders
JOIN accounts
    ON accounts.id = orders.account_id

-- 1 Provide a table for all web_events associated with account name of Walmart. 
-- There should be three columns. Be sure to include the primary_poc, 
-- time of the event, and the channel for each event. Additionally, 
-- you might choose to add a fourth column to assure only Walmart events were chosen.
SELECT a.name, a.primary_poc, 
	   w.occurred_at, w.channel
FROM accounts a
JOIN web_events w
ON a.id = w.account_id
WHERE a.name = 'Walmart';

-- 2 Provide a table that provides the region for each sales_rep along with their 
-- associated accounts. Your final table should include three columns: the region 
-- name, the sales rep name, and the account name. Sort the accounts 
-- alphabetically (A-Z) according to account name.
SELECT a.name a_name, r.name r_name, sr.name sr_name
FROM sales_reps sr
JOIN region r
    ON r.id = sr.region_id
JOIN accounts a
    ON a.sales_rep_id = sr.id
ORDER BY a_name

-- 3. Provide the name for each region for every order, as well as the account name 
-- and the unit price they paid (total_amt_usd/total) for the order. Your final 
-- table should have 3 columns: region name, account name, and unit price. 
-- A few accounts have 0 for total, so I divided by (total + 0.01) to assure not dividing by zero.
SELECT a.name a_name, 
	   r.name r_name,
       o.total_amt_usd/o.total unit_price
FROM accounts a
JOIN sales_reps sr
    ON a.sales_rep_id = sr.id
JOIN region r
    ON sr.region_id = r.id
JOIN orders o
    ON o.account_id = a.id
WHERE o.total != 0;

/*******************************************************************
--:JOINS - AND vs WHERE to filter
********************************************************************/
-- EXAMPLE:
-- AND prefilters the right table.
    -- Reduces the rows before combining the tables

-- WHERE is applied to the end result of the JOIN
    -- Logic applied after the join accours.

--: AND vs WHERE - Example 1 - Inner join
-- When using and inner join the result of both queries is the same

-- WHERE VERSION
SELECT orders.*,
       accounts.*
FROM orders
JOIN accounts
    ON orders.account_id = accounts.id
WHERE accounts.sales_rep_id = 321500

-- AND VERSION - FILTERS ON THE ON JOIN CLAUSE 
-- Result equivalent to the previous WHERE but more efficient because
-- the table accounts is filtered prior to performing the join.
SELECT orders.*,
       accounts.*
FROM orders
JOIN accounts
    ON orders.account_id = accounts.id
    AND accounts.sales_rep_id = 321500

--: AND vs WHERE - Example 2
-- We wanto to include the information from table accounts only for those accounts
-- with sales_rep_id = 321500 while keeping the information from table orders
-- of all other accounts --> LEFT JOIN + AND to filter where the join occurs.
SELECT orders.*,
       accounts.*
FROM orders
LEFT JOIN accounts
    ON orders.account_id = accounts.id
    AND accounts.sales_rep_id = 321500

-- Doing a LEFT JOIN + WHERE returns the same result as in example 1, because the filtering
-- occurs after the join operation. It makes the operation even more innefficient, because
-- now we need to include all rows from the orders table and not only those that have a match in 
-- in orders and accounts as occurred with the inner join.
SELECT orders.*,
       accounts.*
FROM orders
LEFT JOIN accounts
    ON orders.account_id = accounts.id
WHERE accounts.sales_rep_id = 321500

/*******************************************************************
--:JOINS - MORE EXAMPLES
********************************************************************/

-- 1- Provide a table that provides the region for each sales_rep along with
-- their associated accounts. This time only for the Midwest region. 
-- Your final table should include three columns: the region name, 
-- the sales rep name, and the account name. 
-- Sort the accounts alphabetically (A-Z) according to account name.
SELECT a.name account, r.name region, sr.name sales_rep
FROM sales_reps sr
JOIN region r
    ON r.id = sr.region_id
JOIN accounts a
    ON sr.id = a.sales_rep_id
WHERE r.name = 'Midwest'
ORDER BY a.name

-- 2. Provide a table that provides the region for each sales_rep along 
-- with their associated accounts. This time only for accounts where
-- the sales rep has a first name starting with S and in the Midwest
-- region. Your final table should include three columns: the region name,
-- the sales rep name, and the account name.
-- Sort the accounts alphabetically (A-Z) according to account name.
SELECT a.name account, r.name region, sr.name sales_rep
FROM sales_reps sr
JOIN region r
    ON r.id = sr.region_id
JOIN accounts a
    ON sr.id = a.sales_rep_id
WHERE r.name = 'Midwest'
      AND sr.name LIKE 'S%'
ORDER BY a.name

-- 3. Provide a table that provides the region for each sales_rep along with
-- their associated accounts. This time only for accounts where the sales
-- rep has a last name starting with K and in the Midwest region.
-- Your final table should include three columns: the region name,
-- the sales rep name, and the account name.
-- Sort the accounts alphabetically (A-Z) according to account name.
SELECT a.name account, r.name region, sr.name sales_rep
FROM sales_reps sr
JOIN region r
    ON r.id = sr.region_id
JOIN accounts a
    ON sr.id = a.sales_rep_id
WHERE r.name = 'Midwest'
      AND sr.name LIKE '% K%'
ORDER BY a.name;

-- 4- Provide the name for each region for every order, as well as the account
-- name and the unit price they paid (total_amt_usd/total) for the order.
-- However, you should only provide the results if the standard order quantity exceeds 100. 
-- Your final table should have 3 columns: region name, account name, and unit price. 
-- In order to avoid a division by zero error, 
-- adding .01 to the denominator here is helpful total_amt_usd/(total+0.01).
SELECT o.id order_id, a.name account, r.name region,
       o.total_amt_usd/o.total unit_price 
FROM orders o
JOIN accounts a
    ON a.id = o.account_id
JOIN sales_reps sr
    ON a.sales_rep_id = sr.id
JOIN region r
    ON r.id = sr.region_id
WHERE o.standard_qty > 100
      AND o.total != 0;

SELECT o.id order_id, a.name account, r.name region,
       o.total_amt_usd/(o.total+0.01) unit_price 
FROM orders o
JOIN accounts a
    ON a.id = o.account_id
JOIN sales_reps sr
    ON a.sales_rep_id = sr.id
JOIN region r
    ON r.id = sr.region_id
WHERE o.standard_qty > 100;

-- 5- Provide the name for each region for every order, as well as the account 
-- name and the unit price they paid (total_amt_usd/total) for the order. However, 
-- you should only provide the results if the standard order quantity exceeds 100 
-- and the poster order quantity exceeds 50. Your final table should have 3 columns: 
-- region name, account name, and unit price. Sort for the smallest unit price first.
SELECT o.id order_id, a.name account, r.name region,
       o.total_amt_usd/(o.total+0.01) unit_price 
FROM orders o
JOIN accounts a
    ON a.id = o.account_id
JOIN sales_reps sr
    ON a.sales_rep_id = sr.id
JOIN region r
    ON r.id = sr.region_id
WHERE o.standard_qty > 100
      AND o.poster_qty > 50
ORDER BY unit_price;

-- 6- Provide the name for each region for every order, as well as the account name and 
-- the unit price they paid (total_amt_usd/total) for the order. However, you should only 
-- provide the results if the standard order quantity exceeds 100 and the poster order 
-- quantity exceeds 50. Your final table should have 3 columns: region name, account name,
-- and unit price. Sort for the largest unit price first.
SELECT o.id order_id, a.name account, r.name region,
       o.total_amt_usd/(o.total+0.01) unit_price 
FROM orders o
JOIN accounts a
    ON a.id = o.account_id
JOIN sales_reps sr
    ON a.sales_rep_id = sr.id
JOIN region r
    ON r.id = sr.region_id
WHERE o.standard_qty > 100
      AND o.poster_qty > 50
ORDER BY unit_price DESC;

/*******************************************************************
--:SELECT DISTINCT
********************************************************************/
-- 7- What are the different channels used by account id 1001? Your final table should have 
-- only 2 columns: account name and the different channels. You can try SELECT DISTINCT to 
-- narrow down the results to only the unique values.
SELECT DISTINCT a.name account, w.channel
FROM accounts a
JOIN web_events w
    ON w.account_id = a.id
WHERE a.id = '1001';

-- 8- Find all the orders that occurred in 2015. Your final table should have 4 columns:
-- occurred_at, account name, order total, and order total_amt_usd.
SELECT o.occurred_at date, a.name, o.total, o.total_amt_usd
FROM orders o
JOIN accounts a
    ON a.id = o.account_id
WHERE o.occurred_at BETWEEN '2015-01-01' AND '2016-01-01' --Remembers defaults to midnight
ORDER BY o.occurred_at DESC

/*******************************************************************
--:UNION and UNION ALL
********************************************************************/
https://www.w3schools.com/sql/sql_union.asp

/*******************************************************************
--:CROSS JOIN
********************************************************************/
https://www.w3resource.com/sql/joins/cross-join.php

/*******************************************************************
--:SELF JOIN
********************************************************************/
https://www.w3schools.com/sql/sql_join_self.asp

/*******************************************************************
--:AGGREGATION FUNCITONS
********************************************************************/

/*******************************************************************
--:NULLS
********************************************************************/
-- NULLs are a datatype that specifies where no data exists in SQL.
-- They are often ignored in our aggregation functions

-- NULLs are different than a zero - they are cells where data does not exist.
-- NULLs in a WHERE clause, we write IS NULL or IS NOT NULL
-- don't use =, because NULL isn't considered a value in SQL. Rather, it is a property of the data.

/*******************************************************************
--:COUNT AND NULLS
********************************************************************/
-- Since it is very unusual to have a row that is full of nulls, we can 
-- use the count function to count the number of rows as follows
SELECT COUNT(*)
FROM accounts;


/*******************************************************************
--:SUM
********************************************************************/
-- 1. Find the total amount of poster_qty paper ordered in the orders table.
SELECT SUM(poster_qty) total_poster
FROM orders

-- 2. Find the total amount of standard_qty paper ordered in the orders table.
SELECT SUM(standard_qty) total_standard
FROM orders

-- 3. Find the total dollar amount of sales using the total_amt_usd in the orders table.
SELECT SUM(total_amt_usd)
FROM orders

-- 4. Find the total amount for each individual order that was spent on standard and 
-- gloss paper in the orders table. This should give a dollar amount for each order in the table.
SELECT standard_amt_usd + gloss_amt_usd AS total_standard_gloss
FROM orders;

-- 5. Though the price/standard_qty paper varies from one order to the next.
--  I would like this ratio across all of the sales made in the orders table.
SELECT SUM(standard_amt_usd)/SUM(standard_qty) AS standard_price_per_unit
FROM orders;

/*******************************************************************
--:MIN - MAX - AVERAGE
********************************************************************/
-- 1. When was the earliest order ever placed? You only need to return the date.
SELECT MIN(occurred_at)
FROM orders;

-- 2. Try performing the same query as in question 1 without using an aggregation function.
SELECT occurred_at
FROM orders
ORDER BY ocurred_at
LIMIT 1;

-- 3. When did the most recent (latest) web_event occur?
SELECT MAX(occurred_at)
FROM web_events;

-- 4. Try to perform the result of the previous query without using an aggregation function.
SELECT occurred_at
FROM web_events
ORDER BY occurred_at DESC
LIMIT 1;

-- 5. Find the mean (AVERAGE) amount spent per order on each paper type, as well as 
-- the mean amount of each paper type purchased per order. Your final answer should 
-- have 6 values - one for each paper type for the average number of sales, 
-- as well as the average amount.
SELECT AVG(standard_amt_usd) std_avg,
       AVG(gloss_amt_usd) gloss_avg,
       AVG(poster_amt_usd) poster_avg
FROM orders;

-- 6. Via the video, you might be interested in how to calculate the MEDIAN. 
-- Though this is more advanced than what we have covered so far try finding 
-- - what is the MEDIAN total_usd spent on all orders?

/*******************************************************************
--:GROUP-BY
********************************************************************/
-- Apply aggregation functions to different subsets of data

-- Groupby allows creating segments that will aggregate independent of one-another

-- IMPORTANT: whenever there is a field in the SELECT statement that is not being aggregated
-- the query expects it to be in the GROUP BY statement. A column that is not aggregated and 
-- not in the groupby, will return an error.



-- 1- Which account (by name) placed the earliest order? Your solution should 
-- have the account name and the date of the order.
SELECT o.occurred_at, a.name
FROM orders o
JOIN accounts a
    ON a.id = o.account_id
ORDER BY o.occurred_at
LIMIT 1;

-- 2. Find the total sales in usd for each account. You should include two columns
--  - the total sales for each company's orders in usd and the company name.
SELECT a.name, SUM(total_amt_usd) total_sales
FROM orders o
JOIN accounts a
    ON a.id = o.account_id
GROUP BY a.name;

-- 3. Via what channel did the most recent (latest) web_event occur, 
-- which account was associated with this web_event? Your query should 
-- return only three values - the date, channel, and account name.
SELECT w.occurred_at, w.channel, a.name
FROM web_events w
JOIN accounts a
    ON a.id = w.account_id
ORDER BY w.occurred_at DESC
LIMIT 1;

-- 4. Find the total number of times each type of channel from the web_events was used.
-- Your final table should have two columns - the channel and 
-- the number of times the channel was used.
SELECT channel, COUNT(*)
FROM web_events
GROUP BY channel;

-- 5. Who was the primary contact associated with the earliest web_event?
SELECT w.id, w.occurred_at, a.primary_poc
FROM web_events w
JOIN accounts a
    ON a.id = w.account_id
ORDER BY w.occurred_at
LIMIT 1;

-- 6. What was the smallest order placed by each account in terms of total usd.
-- Provide only two columns - the account name and the total usd. 
-- Order from smallest dollar amounts to largest.
SELECT a.name, MIN(o.total_amt_usd) smallest_order
FROM orders o
JOIN accounts a
    ON o.account_id = a.id
GROUP BY a.name
ORDER BY smallest_order;

-- 7. Find the number of sales reps in each region. Your final table should have two 
-- columns - the region and the number of sales_reps. Order from fewest reps to most reps.
SELECT r.name region, COUNT(sr.*) n_sales_reps
FROM region r
JOIN sales_reps sr
    ON sr.region_id = r.id
GROUP BY r.name
ORDER BY n_sales_reps;

/*******************************************************************
--:GROUP-BY WITH MULTIPLE COLUMNS
********************************************************************/
-- 1. For each account, determine the average amount of each type of 
-- paper they purchased across their orders. Your result should have 
-- four columns - one for the account name and one for the average 
-- quantity purchased for each of the paper types for each account.
SELECT a.name,
       AVG(standard_qty) standard_qty, AVG(standard_amt_usd) standard_usd,
       AVG(gloss_qty) gloss_qty, AVG(gloss_amt_usd) gloss_usd,
       AVG(poster_qty) poster_qty, AVG(poster_amt_usd) poster_usd
FROM accounts a
JOIN orders o
    ON a.id = o.account_id
GROUP BY a.name

-- 2. For each account, determine the average amount spent per order 
-- on each paper type. Your result should have four columns - one for 
-- the account name and one for the average amount spent on each paper type.
SELECT a.name,
       AVG(standard_qty) standard_qty, AVG(standard_amt_usd) standard_usd,
       AVG(gloss_qty) gloss_qty, AVG(gloss_amt_usd) gloss_usd,
       AVG(poster_qty) poster_qty, AVG(poster_amt_usd) poster_usd
FROM accounts a
JOIN orders o
    ON a.id = o.account_id
GROUP BY a.name

-- 3. Determine the number of times a particular channel was used in the web_events 
-- table for each sales rep. Your final table should have three columns - 
-- the name of the sales rep, the channel, and the number of occurrences. 
-- Order your table with the highest number of occurrences first.
SELECT sr.name, w.channel, COUNT(*) ch_counts
FROM sales_reps sr
JOIN accounts a
    ON a.sales_rep_id = sr.id
JOIN web_events w
    ON w.account_id = a.id
GROUP BY sr.name, w.channel
ORDER BY sr.name, ch_counts DESC

-- 4. Determine the number of times a particular channel was used in the web_events 
-- table for each region. Your final table should have three columns - the region name,
-- the channel, and the number of occurrences. Order your table with 
-- the highest number of occurrences first.
SELECT r.name region, w.channel, COUNT(*) ch_counts
FROM region r
JOIN sales_reps sr
    ON sr.region_id = r.id
JOIN accounts a
    ON a.sales_rep_id = sr.id
JOIN web_events w
    ON a.id = w.account_id
GROUP BY region, w.channel
ORDER BY region, ch_counts DESC

/*******************************************************************
--:DISTINCT
********************************************************************/
-- Groupby with columns, but you do not necessarily want to include any aggregations

SELECT account_id,
       channel,
       COUNT(id) AS events
    FROM web_events
GROUP BY account_id, channel
ORDER BY account ID

-- If we remove COUNT aggregator, we obtain the same result without this column
SELECT account_id,
       channel
    FROM web_events
GROUP BY account_id, channel
ORDER BY account ID

-- And we can achieve exactly the same using DISTINCT instead of GROUP BY
SELECT DISTINCT account_id,
       channel
    FROM web_events
ORDER BY account ID

-- 1- Use DISTINCT to test if there are any accounts associated with more than one region.
-- The below two queries have the same number of resulting rows (351), 
-- so we know that every account is associated with only one region. 
-- If each account was associated with more than one region, 
-- the first query should have returned more rows than the second query.

SELECT r.name, a.id
FROM accounts a
JOIN sales_reps sr
    ON sr.id = a.sales_rep_id
JOIN region r
    ON r.id = sr.region_id;

SELECT DISTINCT id, name
FROM accounts;

-- 2. Have any sales_reps worked on more than one account?
-- SOLUTION 1: groupby doble complicado (innecesario)
SELECT sr_id, sr_name, count(*) as num_accounts
FROM (SELECT sr.id sr_id, sr.name sr_name, a.id a_id, COUNT(sr.id)
     FROM accounts a
     JOIN sales_reps sr
         ON sr.id = a.sales_rep_id
     GROUP BY sr.id, sr.name, a.id) as res
GROUP BY sr_id, sr_name
ORDER BY num_accounts

-- SOLUTION 2: groupby ??nico --> al no incluir accounts ID, directamente hacer
-- el count te da el n??mero de accounts que tiene cada uno.
-- creo que realmente no es correcto porque asume impl??citamente que ante igualdad de
-- sales_rep, el account_id es el ??nico factor diferenciador. Y podr??a no ser as??.
-- Si la database est?? bien estructurada, deber??a ser as??, porque id es PK en accounts
-- y por tanto deber??a ser ??nico.
SELECT s.id, s.name, COUNT(*) num_accounts
FROM accounts a
JOIN sales_reps s
ON s.id = a.sales_rep_id
GROUP BY s.id, s.name
ORDER BY num_accounts;

-- Compareos con esto: nos dice que hay s??lo 50 sales reps.
SELECT DISTINCT id, name
FROM sales_reps;

/*******************************************************************
--:HAVING
********************************************************************/
-- WHERE DOES NOT LET YOU FILTER AGGREGATED COLUMNS
SELECT account_id,
       SUM(total_amt_usd) AS sum_total_amt_usd
FROM demo.orders
WHERE SUM(total_amt_usd) >= 250000
GROUP BY 1
ORDER BY 2 DESC

-- THIS YIELDS AN ERROR. WE NEED TO USE HAVING
SELECT account_id,
       SUM(total_amt_usd) AS sum_total_amt_usd
FROM demo.orders
GROUP BY 1
HAVING SUM(total_amt_usd) >= 250000
ORDER BY 2 DESC

-- 1. How many of the sales reps have more than 5 accounts that they manage?
-- SOLUTION 1:
SELECT s.id, s.name, COUNT(*) num_accounts
FROM accounts a
JOIN sales_reps s
ON s.id = a.sales_rep_id
GROUP BY s.id, s.name
HAVING COUNT(*) > 5
ORDER BY num_accounts;
-- 34 results

-- SOLUTION 2: UDING A SUBQUERY
SELECT COUNT(*) num_reps_above5
FROM(SELECT s.id, s.name, COUNT(*) num_accounts
     FROM accounts a
     JOIN sales_reps s
     ON s.id = a.sales_rep_id
     GROUP BY s.id, s.name
     HAVING COUNT(*) > 5
     ORDER BY num_accounts) AS Table1;

-- 2. How many accounts have more than 20 orders?
SELECT a.id as a_id, COUNT(*) n_orders
FROM accounts a
JOIN orders o
    ON o.account_id = a.id
GROUP BY a.id
HAVING COUNT(*) > 20
ORDER BY n_orders 

-- 3. Which account has the most orders?
SELECT a.id as a_id, a.name as a_name, COUNT(*) n_orders
FROM accounts a
JOIN orders o
    ON o.account_id = a.id
GROUP BY a.id, a.name
ORDER BY n_orders DESC
LIMIT 1;

-- 4. How many accounts spent more than 30,000 usd total across all orders?
SELECT a.id as a_id, SUM(o.total_amt_usd) total_usd
FROM accounts a
JOIN orders o
    ON o.account_id = a.id
GROUP BY a.id
HAVING SUM(o.total_amt_usd) > 30000
ORDER BY total_usd DESC

-- 5. How many accounts spent less than 1,000 usd total across all orders?
SELECT a.id as a_id, SUM(o.total_amt_usd) total_usd
FROM accounts a
JOIN orders o
    ON o.account_id = a.id
GROUP BY a.id
HAVING SUM(o.total_amt_usd) < 1000
ORDER BY total_usd DESC

-- 6. Which account has spent the most with us?
SELECT a.id as a_id, SUM(o.total_amt_usd) total_usd
FROM accounts a
JOIN orders o
    ON o.account_id = a.id
GROUP BY a.id
ORDER BY total_usd DESC
LIMIT 1;

-- 7. Which account has spent the least with us?
SELECT a.id as a_id, SUM(o.total_amt_usd) total_usd
FROM accounts a
JOIN orders o
    ON o.account_id = a.id
GROUP BY a.id
ORDER BY total_usd
LIMIT 1;

-- 8. Which accounts used facebook as a channel to contact customers more than 6 times?
SELECT a.id, a.name, w.channel, COUNT(*) n_times
FROM accounts a
JOIN web_events w
    ON a.id = w.account_id
GROUP BY a.id, a.name, w.channel
HAVING COUNT(*) > 6
       AND w.channel = 'facebook'
ORDER BY n_times DESC;

-- 9. Which account used facebook most as a channel?
SELECT a.id, a.name, w.channel, COUNT(*) n_times
FROM accounts a
JOIN web_events w
    ON a.id = w.account_id
GROUP BY a.id, a.name, w.channel
HAVING w.channel = 'facebook'
ORDER BY n_times DESC
LIMIT 1;

--ALTERNATIVE SOLUTION WITH WHERE
SELECT a.id, a.name, w.channel, COUNT(*) use_of_channel
FROM accounts a
JOIN web_events w
ON a.id = w.account_id
WHERE w.channel = 'facebook'
GROUP BY a.id, a.name, w.channel
ORDER BY use_of_channel DESC
LIMIT 5; -- to check for potential ties.

--10. Which channel was most frequently used by most accounts?
SELECT a.id, a.name, w.channel, COUNT(*) use_of_channel
FROM accounts a
JOIN web_events w
ON a.id = w.account_id
GROUP BY a.id, a.name, w.channel
ORDER BY use_of_channel DESC
LIMIT 10;

/*******************************************************************
--:DATES AND AGGREGATION
********************************************************************/
-- DATE TRUNCT -> granularity down to second and below
DATE_TRUNC('second', occurred_at)
DATE_TRUNC('day', occurred_at)
DATE_TRUNC('month', occurred_at)
DATE_TRUNC('year', occurred_at)

-- DATE PART -> pull out a given part of the date
DATE_PART('second', occurred_at)
DATE_PART('day', occurred_at)
DATE_PART('dow', occurred_at) -- DOW: day of the week, 0 (sunday), 6 (saturday)
DATE_PART('month', occurred_at)
DATE_PART('year', occurred_at)

SELECT DATE_TRUNC('day', occurred_at) as day,
       SUM(standard_qty) AS standard_qty_sum
    FROM orders
-- We need to group by the same metric included in the SELECT statement
GROUP BY DATE_TRUNC('day', occurred_at)
ORDER BY DATE_TRUNC('day', occurred_at)

-- BEST WAY TO ENSURE YOU GROUP CORRECTLY IS USING COLUMN NUMBERS
SELECT DATE_TRUNC('day', occurred_at) as day,
       SUM(standard_qty) AS standard_qty_sum
    FROM orders
-- We need to group by the same metric included in the SELECT statement
GROUP BY 1
ORDER BY 1

-- EXAMPLE: DAY OF THE WEEK WITH THE MOST SALES
SELECT DATE_PART('dow', occured_at) as day_of_week,
       SUM(total) AS total_qty
    FROM orders
GROUP BY 1
ORDER BY 2 DESC

-- 1- Find the sales in terms of total dollars for all orders in each year, 
-- ordered from greatest to least. Do you notice any trends in the yearly sales totals?
SELECT DATE_PART('year', o.occurred_at) as year,
       SUM(o.total_amt_usd) as total_usd
FROM orders o
GROUP BY DATE_PART('year', o.occurred_at)
ORDER BY total_usd DESC

-- 2013 and 2017 only have data for one month

-- 2- Which month did Parch & Posey have the greatest sales in terms of total dollars? 
-- Are all months evenly represented by the dataset?

-- We exclude 2013 and 2017

SELECT DATE_PART('month', occurred_at) ord_month, SUM(total_amt_usd) total_spent
FROM orders
WHERE occurred_at BETWEEN '2014-01-01' AND '2017-01-01'
GROUP BY 1
ORDER BY 2 DESC; 

-- 3. Which year did Parch & Posey have the greatest sales in terms of total number 
-- of orders? Are all years evenly represented by the dataset?
SELECT DATE_PART('year', occurred_at) ord_year, COUNT(*) n_orders
FROM orders
WHERE occurred_at BETWEEN '2014-01-01' AND '2017-01-01'
GROUP BY 1
ORDER BY 2 DESC;

-- 4. Which month did Parch & Posey have the greatest sales in terms of total 
-- number of orders? Are all months evenly represented by the dataset?
SELECT DATE_PART('month', occurred_at) ord_month, COUNT(*) n_orders
FROM orders
WHERE occurred_at BETWEEN '2014-01-01' AND '2017-01-01'
GROUP BY 1
ORDER BY 2 DESC;

-- 5. In which month of which year did Walmart spend the most on gloss paper in terms of dollars?
SELECT DATE_TRUNC('month', o.occurred_at) ord_date, a.name account, SUM(gloss_amt_usd)
FROM orders o
JOIN accounts a
    ON a.id = o.account_id
WHERE a.name = 'Walmart'
GROUP BY 1, 2
ORDER BY 3 DESC;

/*******************************************************************
--:CASE
********************************************************************/
-- USED TO CREATE "DERIVED COLUMNS" WITH "IF-THEN" LOGIC. We have done this
-- with arithmetic functions, now with "IF-THEN" logic.
SELECT id,
       account_id,
       occurred_at,
       channel,
       CASE WHEN channel = 'facebook' OR chanel = 'direct' THEN 'yes' ELSE 'no' END AS is_facebook
    FROM web_events
ORDER BY ocurred_at

SELECT id,
       account_id,
       occurred_at,
       channel,
       -- WHEN statements are executed in the order in which they are written
       -- BELOW WE WILL WRITE THIS IN A MANNER THAN WHEN STATEMENTS DO NOT OVERLAP
       CASE WHEN total > 500 THEN 'Over 500'
       WHEN total > 300 THEN '301 - 500'
       WHEN total > 100 THEN '101 - 300'
       ELSE '100 or under' 
       END AS total_group
    FROM orders

SELECT id,
       account_id,
       occurred_at,
       channel,
       -- WHEN statements are executed in the order in which they are written
       -- Question: could we use "BETWEEN"
       CASE WHEN total > 500 THEN 'Over 500'
       WHEN total > 300 AND total <= 500 THEN '301 - 500'
       WHEN total > 100 AND total <= 300 THEN '101 - 300'
       ELSE '100 or under' 
       END AS total_group
    FROM orders

-- CASE AND DIVISION BY ZERO:
SELECT account_id, 
       CASE WHEN standard_qty = 0 OR standard_qty IS NULL THEN 0
            ELSE standard_amt_usd/standard_qty 
            END AS unit_price
FROM orders
LIMIT 10;



/*******************************************************************
--:CASE AND AGGREGATIONS
********************************************************************/
-- EXAMPLE: classifying orders.
-- 1. Create a column that classifies orders the way you want
-- 2. GROUP BY to count the size of the groups.
SELECT CASE WHEN total > 500 THEN 'Over 500'
            ELSE '500 or under'
            END AS total_group
        COUNT(*) AS order_count
    FROM orders
GROUP BY 1 --Here you need to use a number or this looks really long

-- 1. Write a query to display for each order, the account ID, total 
-- amount of the order, and the level of the order - ???Large??? or ???Small??? 
-- - depending on if the order is $3000 or more, or smaller than $3000.
SELECT o.account_id, o.total_amt_usd,
       CASE WHEN o.total_amt_usd > 3000 THEN 'Large'
       ELSE 'Small'
       END AS ord_level
FROM orders o

-- 2 Write a query to display the number of orders in each of three categories, 
-- based on the total number of items in each order. The three categories are:
-- 'At Least 2000', 'Between 1000 and 2000' and 'Less than 1000'.

SELECT CASE WHEN o.total > 2000 THEN 'More than 2000'
       WHEN o.total BETWEEN 1000 AND 2000 THEN 'Between 1000 and 2000'
       WHEN o.total < 1000 THEN 'Less than 1000'
       END AS n_orders_cat,
       COUNT(*)
FROM orders o
GROUP BY 1

-- alternative solution
SELECT CASE WHEN total >= 2000 THEN 'At Least 2000'
   WHEN total >= 1000 AND total < 2000 THEN 'Between 1000 and 2000'
   ELSE 'Less than 1000' END AS order_category,
COUNT(*) AS order_count
FROM orders
GROUP BY 1;

-- 3. We would like to understand 3 different branches of customers based 
-- on the amount associated with their purchases. The top branch includes 
-- anyone with a Lifetime Value (total sales of all orders) greater than 
-- 200,000 usd. The second branch is between 200,000 and 100,000 usd. 
-- The lowest branch is anyone under 100,000 usd. Provide a table that 
-- includes the level associated with each account. You should provide 
-- the account name, the total sales of all orders for the customer, 
-- and the level. Order with the top spending customers listed first.
SELECT a.name account_name, SUM(o.total_amt_usd) total_sales_usd,
       CASE WHEN SUM(o.total_amt_usd) > 200000 THEN 'greater than 200000'
       WHEN SUM(o.total_amt_usd) BETWEEN 100000 AND 200000 THEN 'between 100000 and 200000'
       WHEN SUM(o.total_amt_usd) < 100000 THEN 'lower than 100000'
       END AS account_level
FROM orders o
JOIN accounts a
    ON a.id = o.account_id
GROUP BY 1
ORDER BY 2 DESC

-- -4. We would now like to perform a similar calculation to the first, 
-- but we want to obtain the total amount spent by customers only 
-- in 2016 and 2017. Keep the same levels as in the previous question. 
-- Order with the top spending customers listed first.
SELECT a.name account_name, SUM(o.total_amt_usd) total_sales_usd,
       CASE WHEN SUM(o.total_amt_usd) > 200000 THEN 'greater than 200000'
       WHEN SUM(o.total_amt_usd) BETWEEN 100000 AND 200000 THEN 'between 100000 and 200000'
       WHEN SUM(o.total_amt_usd) < 100000 THEN 'lower than 100000'
       END AS account_level
FROM orders o
JOIN accounts a
    ON a.id = o.account_id
WHERE o.occurred_at BETWEEN '2016-01-01' AND '2018-01-01'
GROUP BY 1
ORDER BY 2 DESC;

-- 5. We would like to identify top performing sales reps, which are sales 
-- reps associated with more than 200 orders. Create a table with the sales 
-- rep name, the total number of orders, and a column with top or not depending 
-- on if they have more than 200 orders. 
-- Place the top sales people first in your final table.
SELECT sr.name sr_name, COUNT(*) n_orders,
       CASE WHEN COUNT(*) > 200 THEN 'Top'
       ELSE 'Not Top'
       END AS top_performer
FROM orders o
JOIN accounts a
    ON a.id = o.account_id
JOIN sales_reps sr
    ON sr.id = a.sales_rep_id
GROUP BY sr.name
ORDER BY n_orders DESC;

-- 6. The previous didn't account for the middle, nor the dollar amount associated 
-- with the sales. Management decides they want to see these characteristics 
-- represented as well. We would like to identify top performing sales reps, 
-- which are sales reps associated with more than 200 orders or more than 750000 
-- in total sales. The middle group has any rep with more than 150 orders or 500000 in sales. 
-- Create a table with the sales rep name, the total number of orders, total sales 
-- across all orders, and a column with top, middle, or low depending on this criteria. 
-- Place the top sales people based on dollar amount of sales first in your final table.
SELECT sr.name sr_name, 
       COUNT(*) n_orders,
       SUM(o.total_amt_usd) as total_sales_usd,
       CASE WHEN (COUNT(*) > 200 OR SUM(o.total_amt_usd) > 750000) THEN 'Top'
       WHEN (COUNT(*) > 150 OR SUM(o.total_amt_usd) > 500000) THEN 'Middle'
       ELSE 'Low' END AS perfo_level
FROM orders o
JOIN accounts a
    ON a.id = o.account_id
JOIN sales_reps sr
    ON sr.id = a.sales_rep_id
GROUP BY sr.name
ORDER BY total_sales_usd DESC;