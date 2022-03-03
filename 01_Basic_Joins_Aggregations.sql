/*******************************************************************
--:ORDER BY
*******************************************************************/

-- Write a query to return the 10 earliest orders in the orders table. 
-- Include the id, occurred_at, and total_amt_usd
SELECT id, occurred_at, total_amt_usd
FROM orders
ORDER BY occurred_at
LIMIT 10;

-- Write a query to return the top 5 orders in terms of largest 
-- total_amt_usd. Include the id, account_id, and total_amt_usd.
SELECT id, account_id, total_amt_usd
FROM orders
ORDER BY total_amt_usd DESC
LIMIT 5;

-- Write a query to return the lowest 20 orders in terms of smallest
-- total_amt_usd. Include the id, account_id, and total_amt_usd.
SELECT id, account_id, total_amt_usd
FROM orders
ORDER BY total_amt_usd
LIMIT 20;

/*******************************************************************
--:ORDER BY OVER MULTIPLE COLUMNS
*******************************************************************/
-- NOTE: DESC attribute can apply to every column used to order

--  When you provide a list of columns in an ORDER BY command, the sorting 
--  occurs using the leftmost column in your list first, then the next column 
--  from the left, and so on. We still have the ability to flip the way we order using DESC.

-- 1- Write a query that displays the order ID, account ID, and total dollar
--  amount for all the orders, sorted first by the account ID (in ascending
--   order), and then by the total dollar amount (in descending order).
SELECT id, account_id, total_amt_usd
FROM orders
ORDER BY account_ID, total_amt_usd DESC;

-- 2- Now write a query that again displays order ID, account ID, and total
--  dollar amount for each order, but this time sorted first by total dollar
--   amount (in descending order), and then by account ID (in ascending order).
SELECT id, account_id, total_amt_usd
FROM orders
ORDER BY total_amt_usd DESC, account_ID;

-- In query #1, all of the orders for each account ID are grouped together, 
-- and then within each of those groupings, the orders appear from the greatest
-- order amount to the least. In query #2, since you sorted by the total dollar
-- amount first, the orders appear from greatest to least regardless of which
-- account ID they were from. Then they are sorted by account ID next. 
-- (The secondary sorting by account ID is difficult to see here, since only if 
-- there were two orders with equal total dollar amounts would there need to be any sorting by account ID.)

/*******************************************************************
--:WHERE
****************************************************************/

-- 1- Pulls the first 5 rows and all columns from the orders table that have
-- a dollar amount of gloss_amt_usd greater than or equal to 1000.
SELECT *
FROM orders
WHERE gloss_amt_usd >= 1000
LIMIT 5;

-- Pulls the first 10 rows and all columns from the orders table that have 
-- a total_amt_usd less than 500.
SELECT *
FROM orders
WHERE gloss_amt_usd < 500
LIMIT 10;

/*******************************************************************
--:WHERE WITH NON-NUMERIC DATA
********************************************************************/

-- In this case we can use the operators
    -- = (equal)
    -- != (different)

-- Filter the accounts table to include the company name, website, 
-- and the primary point of contact (primary_poc) just for the 
-- Exxon Mobil company in the accounts table.

SELECT name, website, primary_poc
FROM accounts
WHERE name = 'Exxon Mobil';

/*******************************************************************
--:ARITHMETIC OPERATORS
********************************************************************/
-- 1- Create a column that divides the standard_amt_usd by the standard_qty 
-- to find the unit price for standard paper for each order. Limit the results
--  to the first 10 orders, and include the id and account_id fields.
SELECT id,
       account_id,
       standard_amt_usd / standard_qty as unit_price
FROM orders
LIMIT 10

-- 2- Write a query that finds the percentage of revenue that comes from poster 
-- paper for each order. You will need to use only the columns that end with _usd.
-- (Try to do this without using the total column.) Display the id and account_id
-- fields also. NOTE - you will receive an error with the correct solution to this
-- question. This occurs because at least one of the values in the data creates 
-- a division by zero in your formula. You will learn later in the course how to
-- fully handle this issue. For now, you can just limit your calculations to the
-- first 10 orders, as we did in question #1, 
-- and you'll avoid that set of data that causes the problem.
SELECT id,
       account_id,
       (poster_amt_usd / total_amt_usd) * 100 AS perc_poster
FROM orders
WHERE total_amt_usd != 0

SELECT id,
       account_id,
       (poster_amt_usd / total_amt_usd) * 100 AS perc_poster
FROM orders
LIMIT 10

/*******************************************************************
--:LOGICAL OPERATORS
********************************************************************/

/*******************************************************************
--:WILDCARDS
********************************************************************/
% --> any number of characters leading up to a particular set of characters
  --  or following a certain set of characters

/*******************************************************************
--:LIKE
********************************************************************/

-- Use the accounts table to find
-- 1. All the companies whose name starts with C
SELECT name
FROM accounts
WHERE name LIKE 'C%';

-- 2. All companies whose names contain the string 'one' somewhere in the name
SELECT name
FROM accounts
WHERE name LIKE '%one%';

-- 3. All companies whose names end with S
SELECT name
FROM accounts
WHERE name LIKE '%S';

/*******************************************************************
--:IN
********************************************************************/

-- 1- Use the accounts table to find the account name, primary_poc,
-- and sales_rep_id for Walmart, Target, and Nordstrom.
SELECT name, primary_poc, sales_rep_id
FROM accounts
WHERE name IN ('Walmart', 'Target', 'Nordstrom');

-- 2- Use the web_events table to find all information regarding individuals
-- who were contacted via the channel of organic or adwords.
SELECT *
FROM web_events
WHERE channel IN ('organic', 'adwords');

/*******************************************************************
--:NOT
********************************************************************/
-- 1. Use the accounts table to find the account name, primary poc, and 
-- sales rep id for all stores except Walmart, Target, and Nordstrom.
SELECT name, primary_poc, sales_rep_id
FROM accounts
WHERE name NOT IN ('Walmart', 'Target', 'Nordstrom');

-- 2. Use the web_events table to find all information regarding individuals
-- who were contacted via any method except using organic or adwords methods.
SELECT *
FROM web_events
WHERE channel NOT IN ('organic', 'adwords');

-- 3. All the companies whose names do not start with 'C'.
SELECT name
FROM accounts
WHERE name NOT LIKE 'C%';

-- 4. All companies whose names do not contain the string 'one' somewhere in the name.
SELECT name
FROM accounts
WHERE name NOT LIKE '%one%';

-- 5. All companies whose names do not end with 's'.Ç
SELECT name
FROM accounts
WHERE name NOT LIKE '%S';

/*******************************************************************
--:AND and BETWEEN
********************************************************************/
NOTE: BETWEEN includes the endpoints of the interval given as argument.

-- 1- Write a query that returns all the orders where the standard_qty 
-- is over 1000, the poster_qty is 0, and the gloss_qty is 0.
SELECT *
FROM orders
WHERE standard_qty > 1000 
      AND poster_qty = 0
      AND gloss_qty = 0

-- 2- Using the accounts table, find all the companies whose names 
-- do not start with 'C' and end with 's'.
SELECT name
FROM accounts
WHERE name NOT LIKE 'C%'
      AND name LIKE '%s'

-- 3- When you use the BETWEEN operator in SQL, do the results 
-- include the values of your endpoints, or not? Figure out the 
-- answer to this important question by writing a query that 
-- displays the order date and gloss_qty data for all orders where 
-- gloss_qty is between 24 and 29. Then look at your output to see 
-- if the BETWEEN operator included the begin and end values or not.
SELECT occurred_at, gloss_qty
FROM orders
WHERE gloss_qty BETWEEN 24 AND 29

-- 4- Use the web_events table to find all information regarding individuals
-- who were contacted via the organic or adwords channels, and started their
-- account at any point in 2016, sorted from newest to oldest.
IMPORTANT: BETWEEN AND DATES
-- using BETWEEN is tricky for dates! While BETWEEN is generally inclusive of endpoints,
-- it assumes the time is at 00:00:00 (i.e. midnight) for dates. This is the reason
-- why we set the right-side endpoint of the period at '2017-01-01'.
SELECT *
FROM web_events
WHERE channel IN ('organic', 'adwords')
      AND occurred_at BETWEEN '2016-01-01' AND '2017-01-01'

/*******************************************************************
--:OR
********************************************************************/
-- 1- Find list of orders ids where either gloss_qty or poster_qty is greater 
-- than 4000. Only include the id field in the resulting table.
SELECT id
FROM orders
WHERE gloss_qty > 4000
      OR poster_qty > 4000

-- 2- Write a query that returns a list of orders where the standard_qty is
-- zero and either the gloss_qty or poster_qty is over 1000.
SELECT id
FROM orders
WHERE standard_qty = 0
      AND (
          gloss_qty > 1000
          OR poster_qty > 1000
      )

-- 3- Find all the company names that start with a 'C' or 'W', and the primary
-- contact contains 'ana' or 'Ana', but it doesn't contain 'eana'.
-- Three equivalent queries

SELECT *
FROM accounts
WHERE (name LIKE 'C%'
      OR name LIKE 'W%')
      AND (
          primary_poc LIKE '%ana%'
          OR primary_poc LIKE '%Ana%'
      )
      AND primary_poc NOT LIKE '%eana'

SELECT *
FROM accounts
WHERE (name LIKE 'C%'
      OR name LIKE 'W%')
      AND ((
          primary_poc LIKE '%ana%'
          OR primary_poc LIKE '%Ana'
      ) 
          AND primary_poc NOT LIKE '%eana');

SELECT *
FROM accounts
WHERE (name LIKE 'C%' OR name LIKE 'W%') 
           AND ((primary_poc LIKE '%ana%' OR primary_poc LIKE '%Ana%') 
           AND primary_poc NOT LIKE '%eana%');

/*******************************************************************
--:SUMMARY DEL ORDEN DE LAS COLUMNAS
********************************************************************/
SELECT col1, col2
FROM table1
JOIN
  ON
WHERE col3  > 5 AND col4 LIKE '%os%'
GROUP BY
HAVING ...
ORDER BY col5
LIMIT 10;