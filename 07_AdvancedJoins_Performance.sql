/*****************************************************************
FULL OUTER JOIN
*****************************************************************/
-- Ver teoría en el word

-- Example: 
-- each account who has a sales rep and each sales rep that has an 
-- account (all of the columns in these returned rows will be full)
-- but also each account that does not have a sales rep and each 
-- sales rep that does not have an account (some of the columns in 
-- these returned rows will be empty)

SELECT a.id account_id, a.name account_name,
       s.id srep_id, s.name srep_name
FROM accounts a 
FULL OUTER JOIN sales_reps s
    ON a.sales_rep_id = s.id
-- WHERE a.sales_rep_id = NULL or s.id = NULL

/*****************************************************************
JOINS WITH COMPARISON OPERATORS
*****************************************************************/
-- START WITH A QUERY THAT TAKES THE FIRST ORDER FROM EACH ACCOUNT
-- See section "subqueries"
SELECT *
FROM orders o
WHERE DATE_TRUNC('month', o.occurred_at) =
    (SELECT DATE_TRUNC('month', MIN(o.occurred_at)) FROM orders)
ORDER BY o.occurred_at

-- Example 1
SELECT o.id,
       o.occurred_at as o_date,
       w.*
FROM orders o
LEFT JOIN web_events w
    -- even when using comparison operators, and = is often used
    -- to make sure that the proper rows are joined
    ON w.account_id = o.account_id
    -- comparison operator: each row is compared and those that
    -- evaluate to true are joined
    AND w.occurred_at < o.occurred_at
WHERE DATE_TRUNC('month', o.occurred_at) =
    (SELECT DATE_TRUNC('month', MIN(o.occurred_at)) FROM orders)
ORDER BY o.occurred_at

-- Example 2:
/*
COMPARISON OPERATORS AND STRINGS
Applied to strings, ocmparison perators use alphabetical order for
comparison
*/
SELECT a.name a_name, 
       a.primary_poc, 
       sr.name sr_name
FROM accounts a
LEFT JOIN sales_reps sr
    ON a.sales_rep_id = sr.id
    AND a.primary_poc < sr.name

/*****************************************************************
SELF JOINS
*****************************************************************/
/*
TODO: INTERVALS
https://www.postgresql.org/docs/8.2/functions-datetime.html
*/
-- sELF join CAN BE TRICKY.
-- Most of the time done in order to find cases where two events occur one after another
-- Example: which accounts made multiple orders within 30 days.

SELECT o1.id o1_id,
       o1.account_id o1_account_id,
       o1.occurred_at o1_occurred_at,
       o2.id o2_id,
       o2.account_id o2_account_id,
       o2.occurred_at o2_occurred_at
FROM orders o1
LEFT JOIN orders o2 -- join to itself and giving it a different alias.
                    -- this is necessary since otherwise it would be unclear.
    ON o1.account_id = o2.account_id
    AND o2.occurred_at > o1.occurred_at
    AND o2.occurred_at <= o1.occurred_at + INTERVAL '28 days'
ORDER BY o1.account_id, o1.occurred_at

-- Example with web-orders
-- Web_events that occurred after but not more than 1 day after another web event
SELECT w1.id w1_id,
       w1.account_id w1_account_id,
       w1.occurred_at w1_occurred_at,
       w2.id w2_id,
       w2.account_id w2_account_id,
       w2.occurred_at w2_occurred_at,
       w1.channel channel_1,
       w2.channel channel_2
FROM web_events w1
LEFT JOIN web_events w2 -- join to itself and giving it a different alias.
                        -- this is necessary since otherwise it would be unclear.
    -- account_id is not the primary key of the web_events table.
    -- The relationship will be many-to-many. Wthout furter conditions the join
    -- is rather complex and the online environment just does not compute it.
    -- Nonetheless we wish to compare events for the same accounts.
    ON w1.account_id = w2.account_id
    AND w2.occurred_at > w1.occurred_at -- this avoids merging on the exact same points.
    AND w2.occurred_at <= w1.occurred_at + INTERVAL '1 day'
ORDER BY w1.account_id, w1.occurred_at

/*****************************************************************
UNIONS VS JOINS
*****************************************************************/
-- JOINS ALLOW YOU TO COMBINE TWO DATA SETS SIDE BY SIDE
-- UNIONS ALLOW YOU TO STACK ONE ON TOP OF ANOTHER

-- EXAMPLE: several list of events... e-mail address...

-- All this can be done with a union

/*****************************************************************
UNIONS OPERATOR
*****************************************************************/
-- https://www.techonthenet.com/sql/union.php

-- 1. Combines the result sets of 2 or more select statements. 
-- 2. It removes duplicate rows between the various select statements
-- 3. Each select statement must have the SAME NUMBER OF FIELDS in 
-- the result sets with similar (the same) data types
-- 4. Example: when a user wants to pull together DISTINCT VALUES of specified
-- columns that are spread across multiple tables
-- 5. UNION ALL does NOT remove duplicate rows

-- Example
SELECT *
    FROM web_events w1

UNION

SELECT *
    FROM web_events w2

/*
UNIONS AND SUBQUERIES
*/
WITH web_events_total AS (
    SELECT *
    FROM web_events w1

    UNION ALL

    SELECT *
    FROM web_events w2
)

SELECT channel,
       COUNT(*) AS sessions
    FROM web_events_total
GROUP BY 1
ORDER BY 2 DESC

-- UNION QUIZZES
-- 1. Write a selecting query that uses UNION ALL on two instances 
-- (and selecting all columns) of the accounts table. Then inspect
-- the results and answer the subsequent quiz.
WITH double_accounts AS (
    SELECT *
    FROM accounts a1

    UNION ALL

    SELECT *
    FROM accounts a2  
)

SELECT a.name, COUNT(*)
FROM double_accounts a
GROUP BY 1

/**************************************************************
PERFORMANCE TUNING
**************************************************************/
-- High level factors affecting thenumber of calculations
-- 1. Table size
-- 2. Joins
-- 3. Aggregations

-- Other things we cannot control:
-- 1. Other users running concurrent queries
-- 2. Database software and optimisation (e.g., Postgres is optimized differently than Redshift)

-- Example: select a subset for time series data
SELECT *
FROM orders
WHERE occurred_at >= '2016-01-01'
      AND occurred_at < '2016-07-01'

-- Most SQL system automatically append a limit

/*
LIMIT AND AGGREGATIONS
*/
-- Aggregation is performed first and then the results shown are limited
-- So in this case it does not speed up your query

-- To limit the dataset before performing the aggregation you need a subquery
-- NOTE: applying a limit to a subquery will dramatically impact results.
-- Use this only to test query logic.
SELECT account_id,
       SUM(poster_qty) AS sum_poster_qty
FROM (
    SELECT * 
    FROM orders
    LIMIT 100
    ) sub
WHERE occurred_at >= '2016-01-01'
      AND occurred_at < '2016-07-01'
GROUP BY 1

/*
JOINS REDUCE COMPLEXITY
*/
It is best to reduce table sizes before joining them.

SELECT a.name,
       sub.web_events
FROM (
    -- Aggregating before joining simplifies the operation
    SELECT accounts_id,
        COUNT(*) AS web_events
    FROM web_events
    GROUP BY 1
    ) sub
JOIN accounts a
    ON a.id = sub.account_id
ORDER BY 2 DESC

/*
EXPLAIN TO SHOW THE COMPLEXITY
EXPLAIN can be added at the beginning of any working query
Not perfectly accurate but rather interesting
Gives you a sense of the order of operations and the cost
This is most useful if you run explain on a query, modify
expensive steps and then run explain again to see if the cost
is reduced
*/
EXPLAIN
SELECT *
FROM web_events
WHERE occurred_at >= '2016-01-01'
      AND occurred_at < '2016-02-01'
LIMIT 100

/*
SUBQUERIES TO IMPROVE PERFORMANCE
*/
-- Example: trying to monitor metrics on a daily basis.
-- You need to join data from a few tables and then aggregate by day.
-- You could do this in one big query, but it is best to aggregate individually
-- and then join the pre-aggregated results

-- With one big query

-- This select logic counts the distinct sales_reps, orders and web-events per date
-- JOINING ON DATES CAUES A DATA EXPLOSION!!
        -- MANY-TO-MANY RELATIONSHIP --> MULTIPLICATIVE EFFECT
        -- WE THEREFORE NEED COUNT DISTINCT INSTEAD OF COUNT
SELECT DATE_TRUNC('day', o.occurred_at) AS date,
       COUNT(DISTINCT a.sales_rep_id) AS active_sales_reps,
       COUNT(DISTINCT o.id) AS orders,
       COUNT(DISTINCT we.id) AS web_visits
FROM accounts a
JOIN orders o
    ON o.account_id = a.id
JOIN web_events we
    ON DATE_TRUNC('day', we.occurred_at) = DATE_TRUNC('day', o.occurred_at)
GROUP BY 1
ORDER BY 1 DESC

-- We can get the same results set aggregating the table separately so that the counts
-- are performed across far smaller data serts
SELECT COALESCE(orders.date, web_events.date) AS date,
       orders.active_sales_reps,
       orders.orders,
       web_events.web_visits
FROM (
    -- First subquery
    SELECT DATE_TRUNC('day', o.occurred_at) AS date,
        COUNT(a.sales_rep_id) AS active_sales_reps,
        COUNT(o.id) AS orders
    FROM accounts a
    JOIN orders o
        ON o.account_id = a.id
    GROUP BY 1
    ) orders

    -- We use the full join just in case one table has observations
    -- in a month that the other table does not.
    FULL JOIN

    -- KEY:
    -- By joining after having aggregating we have substantially reduced
    -- the number of rows in each dataset prior to the join.
    -- In fact, each day appeards only once since we have performed a
    -- GRUOP BY. In this manner we now have a 1-to-1 relationship for
    -- the days, instead of a many-to-many relationship, which caused an
    -- explosion in the amount of data.

    (
    -- Second subquery
    SELECT DATE_TRUNC('day', we.occurred_at) AS date,
        COUNT(we.id) AS web_visits
    FROM web_events we
    GROUP BY 1
    ) web_events

ON web_events.date = orders.date
ORDER BY 1 DESC

/*
WEBSITES FOR PRACTICE:
https://www.hackerrank.com/domains/sql
https://mode.com/sql-tutorial/sql-business-analytics-training/
https://www.analyticsvidhya.com/blog/2017/01/46-questions-on-sql-to-test-a-data-science-professional-skilltest-solution/
*/
