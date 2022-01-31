/*******************************************************************
FIRST SUBQUERY WRITTEN
*******************************************************************/
-- We would like to know which channels send the most traffic per day 
-- on average to Parch and Posey. In order to do that, we'll need to 
-- aggregate events by channel by day, then we need to take 
-- those and average them.

SELECT channel,
       AVG(event_count) as avg_event_count
FROM
    -- Events in each channel each day
    -- We want to query against the result of this query
    (SELECT DATE_TRUNC('day', occurred_at) AS day,
        channel,
        COUNT(*) AS event_count
        FROM web_events
    GROUP BY 1, 2
    ) AS sub
GROUP BY 1
ORDER BY 2 DESC

-- How this works:
-- 1- Inner query will run
-- 2- Outer query will run across the result set created by the inner query

/*******************************************************************
VIEWS
*******************************************************************/
-- Suppose you are managing sales representatives who are looking after the accounts 
-- in the Northeast region only. The details of such a subset of sales 
-- representatives can be fetched from two tables, and stored as a view:
create view v1
as
select S.id, S.name as Rep_Name, R.name as Region_Name
from sales_reps S
join region R
on S.region_id = R.id
and R.name = 'Northeast';

-- Provide the name for each region for every order, as well as the account 
-- name and the unit price they paid (total_amt_usd/total) for the order. 
-- Your final result should have 3 columns: region name, 
-- account name, and unit price.

CREATE VIEW V2
AS
SELECT r.name region, a.name account, 
       o.total_amt_usd/(o.total + 0.01) unit_price
FROM region r
JOIN sales_reps s
ON s.region_id = r.id
JOIN accounts a
ON a.sales_rep_id = s.id
JOIN orders o
ON o.account_id = a.id;

-- Show the report which channels send the most traffic per day on average to Parch and Posey.
CREATE VIEW V3
AS
SELECT channel, AVG(events) AS average_events
FROM (SELECT DATE_TRUNC('day',occurred_at) AS day,
                channel, COUNT(*) as events
         FROM web_events 
         GROUP BY 1,2) sub
GROUP BY channel

select max(average_events)
from v3;

/*******************************************************************
EXAMPLE OF NESTED SUBQUERY
*******************************************************************/
-- Month/year combo for the first order placed
SELECT DATE_TRUNC('month', MIN(o.occurred_at))
FROM orders o

-- Result of previous query to find only the orders that took place
-- in the same month and year as the first order, and the pull the
-- average for each type of paper qry in this month.
SELECT AVG(standard_qty) std_avg,
	   AVG(poster_qty) poster_avg,
       AVG(gloss_qty) gloss_avg,
       SUM(total_amt_usd) total_usd
FROM orders o
WHERE DATE_TRUNC('month', o.occurred_at) = 
    (
        SELECT DATE_TRUNC('month', MIN(o.occurred_at)) AS min_month
        FROM orders o
    )

/*******************************************************************
MORE EXAMPLES OF SUBQUERIES
*******************************************************************/
/*******************************************************************
SUBQUERIES USING JOINS WITH MULTUPLE CRITERIA
*******************************************************************/
-- WHAT IS THE TOP CHANNEL USED BY EACH ACCOUNT TO MARKET PRODUCTS?
-- HOW OFTE WAS THE CHANNEL USED

-- 1- Let's find the number of times each channel is used by each account.
SELECT a.name account, w.channel, COUNT(*)
FROM accounts a
JOIN web_events w
    ON w.account_id = a.id
GROUP BY a.name, w.account_id, w.channel
ORDER BY account, COUNT(*)


-- 2. So we will need to count the number of rows by Account and Channel. 
-- This count will be our first aggregation needed.
-- The table below provides the maximum times a channel was used for each
-- account, but not the table.
SELECT sub1.account, (sub1.counts) max_chan
     FROM
         (SELECT a.name account, w.channel, COUNT(*) counts
         FROM accounts a
         JOIN web_events w
             ON w.account_id = a.id
         GROUP BY a.name, w.account_id, w.channel
         ) AS sub1
GROUP BY 1
ORDER BY 1

-- 3. Now we match both tables with a join as a way to select tables
-- when multiple criteria need to be met
SELECT sub3.account, sub3.channel, sub3.ct
FROM (SELECT a.name account, w.channel, COUNT(*) ct
      FROM accounts a
      JOIN web_events w
          ON w.account_id = a.id
      GROUP BY a.name, w.account_id, w.channel
      ) sub3

JOIN (
      SELECT sub1.account, MAX(sub1.counts) max_chan
          FROM
              (SELECT a.name account, w.channel, COUNT(*) counts
              FROM accounts a
              JOIN web_events w
                  ON w.account_id = a.id
              GROUP BY a.name, w.account_id, w.channel
              ) AS sub1
      GROUP BY 1
      ORDER BY 1) sub2   
    ON sub2.account = sub3.account
       AND sub2.max_chan = sub3.ct
ORDER BY sub3.ct

/*******************************************************************
SUBQUERIE MANIA
*******************************************************************/
-- 1. Provide the name of the sales_rep in each region with the largest 
-- amount of total_amt_usd sales.

    -- STEP 1. Create a table with sales_rep - region - total_amt_usd
SELECT sr.id, sr.name sr_name, r.name r_name, SUM(total_amt_usd)
FROM sales_reps sr
JOIN accounts a
    ON sr.id = a.sales_rep_id
JOIN orders o
    ON o.account_id = a.id
JOIN region r
    ON sr.region_id = r.id
GROUP BY 1, 2, 3
ORDER BY 4 DESC

    -- STEP 2. Create a table based on the previous table that contains only
    -- the rows of the table in 1 with the maximum sales for each region.
SELECT sub1.r_name, MAX(sub1.total_usd)
FROM (
    SELECT sr.id, sr.name sr_name, r.name r_name, SUM(total_amt_usd) total_usd
    FROM sales_reps sr
    JOIN accounts a
        ON sr.id = a.sales_rep_id
    JOIN orders o
        ON o.account_id = a.id
    JOIN region r
        ON sr.region_id = r.id
    GROUP BY 1, 2, 3
) sub1
GROUP BY 1

    -- STEP 3. Use a Join between the tables 1 and 2 to select the rows of the table in 1
    -- that match the maximal criteria of the table in 2
SELECT sub3.id, sub3.sr_name, sub3.r_name, sub3.total_usd
FROM (
    SELECT sr.id, sr.name sr_name, r.name r_name, SUM(total_amt_usd) total_usd
    FROM sales_reps sr
    JOIN accounts a
        ON sr.id = a.sales_rep_id
    JOIN orders o
        ON o.account_id = a.id
    JOIN region r
        ON sr.region_id = r.id
    GROUP BY 1, 2, 3 
) sub3
JOIN (
    SELECT sub1.r_name, MAX(sub1.total_usd) max_sale
    FROM (
        SELECT sr.id, sr.name sr_name, r.name r_name, SUM(total_amt_usd) total_usd
        FROM sales_reps sr
        JOIN accounts a
            ON sr.id = a.sales_rep_id
        JOIN orders o
            ON o.account_id = a.id
        JOIN region r
            ON sr.region_id = r.id
        GROUP BY 1, 2, 3
    ) sub1
    GROUP BY 1
) sub2
    ON sub2.r_name = sub3.r_name
       AND sub2.max_sale = sub3.total_usd

-- 2. For the region with the largest (sum) of sales total_amt_usd, how many total (count) orders were placed?

    -- STEP 1: compute the total sales per region on a table and take the max value
SELECT r.name r_name, SUM(o.total_amt_usd) total_usd
FROM sales_reps sr
JOIN region r
    ON r.id = sr.region_id
JOIN accounts a
    ON a.sales_rep_id = sr.id
JOIN orders o
    ON o.account_id = a.id
GROUP BY 1
ORDER BY total_usd DESC
LIMIT 1

    -- STEP 2: compute the total number of orders per region
SELECT r.name r_name, COUNT(*)
FROM sales_reps sr
JOIN region r
    ON r.id = sr.region_id
JOIN accounts a
    ON a.sales_rep_id = sr.id
JOIN orders o
    ON o.account_id = a.id
GROUP BY 1

    -- STEP 3: join the 2 tables
SELECT sub1.r_name, sub2.total_usd, sub1.ct
FROM (
    SELECT r.name r_name, COUNT(*) ct
    FROM sales_reps sr
    JOIN region r
        ON r.id = sr.region_id
    JOIN accounts a
        ON a.sales_rep_id = sr.id
    JOIN orders o
        ON o.account_id = a.id
    GROUP BY 1 
) sub1
JOIN (
    SELECT r.name r_name, SUM(o.total_amt_usd) total_usd
    FROM sales_reps sr
    JOIN region r
        ON r.id = sr.region_id
    JOIN accounts a
        ON a.sales_rep_id = sr.id
    JOIN orders o
        ON o.account_id = a.id
    GROUP BY 1
    ORDER BY total_usd DESC
    LIMIT 1
) sub2
    ON sub1.r_name = sub2.r_name

    -- SUBQUERIES WITH HAVING
    -- STEP 1: total_amt_usd for each region
SELECT r.name region_name, SUM(o.total_amt_usd) total_amt
FROM sales_reps s
JOIN accounts a
    ON a.sales_rep_id = s.id
JOIN orders o
    ON o.account_id = a.id
JOIN region r
    ON r.id = s.region_id
GROUP BY r.name;

    -- STEP 2: rgion with the max amount from this table
    -- This could have been done as well with limit.
SELECT MAX(total_amt)
FROM (SELECT r.name region_name, SUM(o.total_amt_usd) total_amt
      FROM sales_reps s
      JOIN accounts a
        ON a.sales_rep_id = s.id
      JOIN orders o
        ON o.account_id = a.id
      JOIN region r
        ON r.id = s.region_id
      GROUP BY r.name) sub;

    -- STEP 3: pull the total orders for the region with this amount
SELECT r.name, COUNT(o.total) total_orders
FROM sales_reps s
JOIN accounts a
    ON a.sales_rep_id = s.id
JOIN orders o
    ON o.account_id = a.id
JOIN region r
    ON r.id = s.region_id
GROUP BY r.name
HAVING SUM(o.total_amt_usd) = (
        SELECT MAX(total_amt)
        FROM (SELECT r.name region_name, SUM(o.total_amt_usd) total_amt
            FROM sales_reps s
            JOIN accounts a
                ON a.sales_rep_id = s.id
            JOIN orders o
                ON o.account_id = a.id
            JOIN region r
                ON r.id = s.region_id
            GROUP BY r.name) sub;

-- 3. How many accounts had more total purchases than the account name 
-- which has bought the most standard_qty paper throughout their lifetime as a customer?

    -- STEP 1: find the total qty of paper and of standard paper for the account with most std paper.
SELECT a.id, a.name, SUM(o.standard_qty) std_qty, SUM(o.total) total_qty
FROM accounts a
JOIN orders o
    ON o.account_id = a.id
GROUP BY 1, 2
ORDER BY 3 DESC
LIMIT 1

    -- STEP 2: find the accounts that satisfy this condition:
SELECT a.id, a.name, SUM(o.standard_qty) std_qty, SUM(o.total) total_qty
FROM accounts a
JOIN orders o
    ON o.account_id = a.id
GROUP BY 1, 2
HAVING SUM(o.total) > (
    SELECT sub1.total_qty
    FROM (
        SELECT a.id, a.name, SUM(o.standard_qty) std_qty, SUM(o.total) total_qty
        FROM accounts a
        JOIN orders o
            ON o.account_id = a.id
        GROUP BY 1, 2
        ORDER BY 3 DESC
        LIMIT 1
    ) sub1
)

    -- STEP 3: count the number of rows in the foregoing table
SELECT COUNT(*)
FROM (
    SELECT a.id, a.name, SUM(o.standard_qty) std_qty, SUM(o.total) total_qty
    FROM accounts a
    JOIN orders o
        ON o.account_id = a.id
    GROUP BY 1, 2
    HAVING SUM(o.total) > (
        SELECT sub1.total_qty
        FROM (
            SELECT a.id, a.name, SUM(o.standard_qty) std_qty, SUM(o.total) total_qty
            FROM accounts a
            JOIN orders o
                ON o.account_id = a.id
            GROUP BY 1, 2
            ORDER BY 3 DESC
            LIMIT 1
        ) sub1
    ) 
) sub2

-- 4. For the customer that spent the most (in total over their lifetime as a customer)
-- total_amt_usd, how many web_events did they have for each channel?

    --STEP 1: FIND THE MAX SPENDING ON USD BY 1 SIGNLE CUSTOMER
SELECT MAX(sub1.total_usd)
FROM (
    SELECT a.id a_id, a.name a_name, SUM(o.total_amt_usd) total_usd
    FROM accounts a
    JOIN orders o
        ON o.account_id = a.id
    GROUP BY 1, 2
) sub1

    --STEP 2: FIND ALL THE CUSTOMERS THAT SPENT THIS AMMOUNT (THERE COULD BE REPETITIONS)
    -- HAVING and NESTED QUERIES
SELECT a.id a_id, a.name a_name, SUM(o.total_amt_usd) total_usd
FROM accounts a
JOIN orders o
    ON o.account_id = a.id
GROUP BY 1, 2
HAVING SUM(o.total_amt_usd) = (
    SELECT MAX(sub1.total_usd)
    FROM (
        SELECT a.id a_id, a.name a_name, SUM(o.total_amt_usd) total_usd
        FROM accounts a
        JOIN orders o
            ON o.account_id = a.id
        GROUP BY 1, 2
    ) sub1
)

    --STEP 3: NOW FILTER THE WEB EVENTS TABLE USING THESE NAME/S
SELECT w.account_id, w.channel, COUNT(*)
FROM web_events w
WHERE w.account_id IN (
    SELECT sub2.a_id
    FROM (
        SELECT a.id a_id, a.name a_name, SUM(o.total_amt_usd) total_usd
        FROM accounts a
        JOIN orders o
            ON o.account_id = a.id
        GROUP BY 1, 2
        HAVING SUM(o.total_amt_usd) = (
            SELECT MAX(sub1.total_usd)
            FROM (
                SELECT a.id a_id, a.name a_name, SUM(o.total_amt_usd) total_usd
                FROM accounts a
                JOIN orders o
                    ON o.account_id = a.id
                GROUP BY 1, 2
            ) sub1
        )  
    ) sub2
)
GROUP BY 1, 2
ORDER BY 3 DESC

    --ALTERNATIVE SOLUTION ASSUMING THERE ARE NO REPS IN CUSTOMERS WITH THE GREATEST
    --VALUE IN total_amt_usd

    -- STEP 1: pull the customer with the most spent in lifetime value
SELECT a.id, a.name, SUM(o.total_amt_usd) tot_spent
FROM orders o
JOIN accounts a
ON a.id = o.account_id
GROUP BY a.id, a.name
ORDER BY 3 DESC
LIMIT 1;

    -- STEP 2: look at the number of events on each channel this company had,
    -- which we can match with just the id.
SELECT a.name, w.channel, COUNT(*)
FROM accounts a
JOIN web_events w
ON a.id = w.account_id AND a.id =  (SELECT id
                     FROM (SELECT a.id, a.name, SUM(o.total_amt_usd) tot_spent
                           FROM orders o
                           JOIN accounts a
                           ON a.id = o.account_id
                           GROUP BY a.id, a.name
                           ORDER BY 3 DESC
                           LIMIT 1) inner_table)
GROUP BY 1, 2
ORDER BY 3 DESC;

-- 5. What is the lifetime average amount spent in terms of total_amt_usd for the top 10 total spending accounts?

    -- STEP 1: find the amount spent by the ten biggest accounts
SELECT o.account_id, SUM(total_amt_usd) total_usd
FROM orders o
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10;

    -- STEP 2: average using that as a subquery
SELECT AVG(sub1.total_usd)
FROM (
    SELECT o.account_id, SUM(total_amt_usd) total_usd
    FROM orders o
    GROUP BY 1
    ORDER BY 2 DESC
    LIMIT 10
) sub1;

-- 6. What is the lifetime average amount spent in terms of total_amt_usd, including only 
-- the companies that spent more per order, on average, than the average of all orders.

    -- STEP 1: compute the average spenditure per order
SELECT AVG(o.total_amt_usd)
FROM orders o

    -- STEP 2: compute average spenditure per order for each company and filter
    -- with the condition that the average must be greater than value of step 1
SELECT o.account_id, AVG(total_amt_usd) avg_usd
FROM orders o
GROUP BY 1
HAVING AVG(total_amt_usd) > (
    SELECT AVG(o.total_amt_usd) avg_usd
    FROM orders o
)
    -- STEP 3: perform the average of the previous columns
SELECT AVG(sub1.avg_usd)
FROM (
    SELECT o.account_id, AVG(total_amt_usd) avg_usd
    FROM orders o
    GROUP BY 1
    HAVING AVG(total_amt_usd) > (
        SELECT AVG(o.total_amt_usd) avg_usd
        FROM orders o
    )
) sub1

/*******************************************************************
"WITH" AND SUBQUERIES
*******************************************************************/
-- EXAMPLE 1
WITH events AS (
          SELECT DATE_TRUNC('day',occurred_at) AS day, 
                        channel, COUNT(*) as events
          FROM web_events 
          GROUP BY 1,2)

SELECT channel, AVG(events) AS average_events
FROM events
GROUP BY channel
ORDER BY 2 DESC;

-- EXAMPLE 2: MULTIPLE TABLES
WITH table1 AS (
          SELECT *
          FROM web_events),

     table2 AS (
          SELECT *
          FROM accounts)


SELECT *
FROM table1
JOIN table2
ON table1.account_id = table2.id;


-- 1. Provide the name of the sales_rep in each region with the largest 
-- amount of total_amt_usd sales.

WITH table1 AS (--table 1: sales_rep - region - total_amt_usd
                SELECT sr.id, sr.name sr_name, r.name r_name, SUM(total_amt_usd) total_usd
                FROM sales_reps sr
                JOIN accounts a
                    ON sr.id = a.sales_rep_id
                JOIN orders o
                    ON o.account_id = a.id
                JOIN region r
                    ON sr.region_id = r.id
                GROUP BY 1, 2, 3
                ORDER BY 4 DESC), 

     table2 AS (
                --table 2: table based on table1 that contains only the rows
                -- of table1 with the maximum sales for each region
                SELECT r_name, MAX(total_usd) max_sale
                FROM table1
                GROUP BY 1)

    -- table 3. Use a Join between the tables 1 and 2 to select the rows of the table1
    -- that match the maximal criteria of the table in 2
SELECT table1.id, table1.sr_name, table1.r_name, table1.total_usd
FROM table1
JOIN table2
    ON table2.r_name = table1.r_name
       AND table2.max_sale = table1.total_usd

-- 2. For the region with the largest (sum) of sales total_amt_usd, how many total (count) orders were placed?

    -- SOLUTION SUBQUERIES WITH WHERE
WITH table1 AS (--total_amt_usd and total_orders for each region
                SELECT r.name region_name, COUNT(o.total) total_orders, SUM(o.total_amt_usd) total_amt
                FROM sales_reps s
                JOIN accounts a
                    ON a.sales_rep_id = s.id
                JOIN orders o
                    ON o.account_id = a.id
                JOIN region r
                    ON r.id = s.region_id
                GROUP BY 1
            ),
     
     table2 AS (--MAX total_amt for each region
                SELECT MAX(total_amt)
                FROM table1
            )

    -- FINAL SELECT
    SELECT *
    FROM table1
    WHERE total_amt = (
      					SELECT *
      					FROM table2
      					)

-- 3. How many accounts had more total purchases than the account name 
-- which has bought the most standard_qty paper throughout their lifetime as a customer?

WITH table1 AS (--find the total qty of paper and of standard paper for the account with most std paper.
                SELECT a.id, a.name, SUM(o.standard_qty) std_qty, SUM(o.total) total_qty
                FROM accounts a
                JOIN orders o
                    ON o.account_id = a.id
                GROUP BY 1, 2
                ORDER BY 3 DESC
                LIMIT 1 -- account with most paper sold
            ),

    table2 AS (--find the accounts that have more total qty than thie account with most std paper
                SELECT a.id, a.name, SUM(o.standard_qty) std_qty, SUM(o.total) total_qty
                FROM accounts a
                JOIN orders o
                    ON o.account_id = a.id
                GROUP BY 1, 2
                HAVING SUM(o.total) > (
                    SELECT table1.total_qty
                    FROM table1
                )
            )

--final select to count the number of rows in table2
SELECT COUNT(*)
FROM table2

-- 4. For the customer that spent the most (in total over their lifetime as a customer)
-- total_amt_usd, how many web_events did they have for each channel?

WITH table1 AS (--total money spent per customer
                SELECT a.id a_id, a.name a_name, SUM(o.total_amt_usd) total_usd
                FROM accounts a
                JOIN orders o
                    ON o.account_id = a.id
                GROUP BY 1, 2
            ),

    table2 AS (--max spend value
                SELECT MAX(total_usd) max_total_usd
                FROM table1
            ),
    
    table3 AS (--filter customer(s) with that maximum value
                SELECT *
                FROM table1
                WHERE total_usd = (
                                    SELECT max_total_usd
                                    FROM table2
                )
            )

    --FINAL STEP: FILTER THE WEB EVENTS TABLE USING THESE NAME/S
SELECT w.account_id, w.channel, COUNT(*)
FROM web_events w
WHERE w.account_id IN (
    SELECT a_id
    FROM table3
)
GROUP BY 1, 2
ORDER BY 3 DESC

-- 5. What is the lifetime average amount spent in terms of total_amt_usd for the top 10 total spending accounts?

WITH talbe1 AS (-- STEP 1: find the amount spent by the ten biggest accounts
                SELECT o.account_id, SUM(total_amt_usd) total_usd
                FROM orders o
                GROUP BY 1
                ORDER BY 2 DESC
                LIMIT 10
            ),

SELECT AVG(sub1.total_usd)
FROM table1 


-- 6. What is the lifetime average amount spent in terms of total_amt_usd, including only 
-- the companies that spent more per order, on average, than the average of all orders.

WITH table1 AS (-- STEP 1: compute average spenditure per order for each company and filter
                -- with the condition that the average must be greater than value of step 1
                SELECT o.account_id, AVG(total_amt_usd) avg_usd
                FROM orders o
                GROUP BY 1
                HAVING AVG(total_amt_usd) > (
                    SELECT AVG(o.total_amt_usd) avg_usd
                    FROM orders o
                )
            )

-- STEP 2: perform the average of the previous columns
SELECT AVG(avg_usd)
FROM table1



