/*****************************************************************
--:LEFT, RIGHT, SUBSTR
******************************************************************/ 
-- LEFT: extracts a # of Characters from a string starting from the left
       LEFT(string, number_of_chars)
-- RIGHT: extracts a # of characters from the string starting from the right
       RIGHT(string, number_of_chars)
-- SUBSTR: extracts a substring from a string (starting at any position)
       SUBSTR(string, number_of_chars)

/*****************************************************************
--:LEFT-RIGHT QUIZ
******************************************************************/
-- 1. In the accounts table, there is a column holding the website for each company. 
-- The last three digits specify what type of web address they are using. 
-- A list of extensions (and pricing) is provided here. Pull these extensions 
-- and provide how many of each website type exist in the accounts table.
SELECT RIGHT(website, 3) AS domain, COUNT(*) num_companies
FROM accounts
GROUP BY 1
ORDER BY 2 DESC;

-- 2. There is much debate about how much the name (or even the first letter 
-- of a company name) matters. Use the accounts table to pull the first 
-- letter of each company name to see the distribution of company 
-- names that begin with each letter (or number).
SELECT LEFT(UPPER(name), 1) AS first_letter, COUNT(*) num_companies
FROM accounts
GROUP BY 1
ORDER BY 2 DESC;

-- 3. Use the accounts table and a CASE statement to create two groups: 
-- one group of company names that start with a number and a second group 
-- of those company names that start with a letter. What proportion of 
-- company names start with a letter?
SELECT SUM(num) nums, SUM(letter) letters
FROM (SELECT name, 
            CASE WHEN LEFT(UPPER(name), 1) IN ('0','1','2','3','4','5','6','7','8','9') 
                          THEN 1 ELSE 0 END AS num, 
            CASE WHEN LEFT(UPPER(name), 1) IN ('0','1','2','3','4','5','6','7','8','9') 
                          THEN 0 ELSE 1 END AS letter
         FROM accounts) t1;

-- 4. Consider vowels as a, e, i, o, and u. What proportion of company 
-- names start with a vowel, and what percent start with anything else?
SELECT SUM(vowel) vowels, SUM(other) others
FROM (SELECT name, 
            CASE WHEN LEFT(UPPER(name), 1) IN ('A','E','I','O','U') 
                          THEN 1 ELSE 0 END AS vowel, 
            CASE WHEN LEFT(UPPER(name), 1) IN ('A','E','I','O','U') 
                          THEN 0 ELSE 1 END AS other
         FROM accounts) t1;

/*****************************************************************
--:STTRING_SPLIT
******************************************************************/
-- IMAGINE such a format that you'd like to split into a table
-- I hope they give more examples later
student_information
3930581,F,san  francisco,3.7,100000
2842940,M,chicago,3.8,150000
28492940,F,new york city,3.9,200000

WITH table AS (
       SELECT student_information,
              value,
              ROW_NUMBER() OVER(PARTITION BY student_information ORDER BY(SELECT NULL)) AS row_number
       FROM student_db
            CROSS APPLY STRING_SPLIT(student_information, ',') AS back_values
)

SELECT student_information,
       [1] AS STUDENT_ID,
       [2] AS GENDER,
       [3] AS CITY,
       [4] AS GPA,
       [5] AS SALARY
FROM table
PIVOT (
       MAX(VALUE)
       FOR row_number IN ([1],[2],[3],[4],[5])
) AS PIVOT

-- See word file
-- WITH subquery
-- ROW_NUMBER()
-- OVER/PARTITION BY
-- SCALAR subquery
-- CROSS APPLY
-- STRING_SPLIT
-- PIVOT

/*****************************************************************
--:CONCAT
******************************************************************/
-- CONCAT(string1, string2, string3)

--:|| ALTERNATIVE CONCATENATE OPERATOR 
SELECT date orig_date, (SUBSTR(date, 7, 4) || '-' || LEFT(date, 2) || '-' || SUBSTR(date, 4, 2)) new_date
FROM sf_crime_data;


-- Common use case: create a unique identifier

-- 1. Suppose the company wants to assess the performance of all the sales representatives. 
-- Each sales representative is assigned to work in a particular region. To make it easier
-- to understand for the HR team, display the concatenated sales_reps.id, ‘_’ (underscore),
-- and region.name as EMP_ID_REGION for each sales representative.
SELECT CONCAT(SALES_REPS.ID, '_', REGION.NAME) EMP_ID_REGION, SALES_REPS.NAME
FROM SALES_REPS
JOIN REGION
    ON SALES_REPS.REGION_ID = REGION_ID;

-- 2. From the accounts table, display the name of the client, the coordinate as concatenated 
-- (latitude, longitude), email id of the primary point of contact as
SELECT CONCAT(LEFT(UPPER(a.primary_poc), 1), 
              RIGHT(UPPER(a.primary_poc), 1),
              '@',
              SUBSTR(a.website, 5))
FROM accounts a

-- 3. From the web_events table, display the concatenated value of account_id, '_' , channel, '_', 
-- count of web events of the particular channel.
WITH table1 AS (
        SELECT w.account_id, w.channel, COUNT(*) AS counts
        FROM web_events w
        GROUP BY 1, 2
        ORDER BY 1
)

SELECT CONCAT(t1.account_id, '_', t1.channel, '_', t1.counts)
FROM table1 t1

/*****************************************************************
--:CAST
******************************************************************/
-- CAST(expression AS datatype)

-- Most common use: raw data as string to be set as appropriate data type
SELECT  sf.date AS orig_date,
	     CAST (CONCAT(
            SUBSTR(sf.date,7,4), '/',
            SUBSTR(sf.date,1,2), '/',
            SUBSTR(sf.date,4,2), ' '
            ) AS DATE) new_date
FROM sf_crime_data sf

/* 
|| ALTERNATIVE CONCATENATE OPERATOR 
*/
SELECT date orig_date, (SUBSTR(date, 7, 4) || '-' || LEFT(date, 2) || '-' || SUBSTR(date, 4, 2)) new_date
FROM sf_crime_data

--::: ALTERNATIVE CAST OPERATOR
SELECT date orig_date, (SUBSTR(date, 7, 4) || '-' || LEFT(date, 2) || '-' || SUBSTR(date, 4, 2))::DATE new_date
FROM sf_crime_data

/*****************************************************************
--:POSITION and STRPOS
******************************************************************/
-- POSITION: returns the position of the first occurrence of a substring
       POSITION(substring in string)

-- STRPOS: returns the position of a subststring within a string
       STRPOS(substring in string)

-- They are equivalent:
POSITION is actually an ALIAS for STRPOS at the parser level
POSITION(foo IN bar) is transformed into STRPOS(bar, foo) during parsing.


-- 1. Use the accounts table to create first and last name columns that 
-- hold the first and last names for the primary_poc.
SELECT  LEFT(primary_poc, POSITION(' ' IN primary_poc)-1) first_name,
        SUBSTR(primary_poc, POSITION(' ' IN primary_poc)+1) last_name
FROM accounts a

-- ALTERNATIVE SOLUTION
SELECT LEFT(primary_poc, STRPOS(primary_poc, ' ') -1 ) first_name, 
RIGHT(primary_poc, LENGTH(primary_poc) - STRPOS(primary_poc, ' ')) last_name
FROM accounts;

SELECT  LEFT(sr.name, POSITION(' ' IN sr.name)-1) first_name,
        SUBSTR(sr.name, POSITION(' ' IN sr.name)+1) last_name
FROM sales_reps sr

/*****************************************************************
--:EXERCISES CONCAT AND STR POSITOIN
******************************************************************/
-- 1. Each company in the accounts table wants to create an email address for 
-- each primary_poc. The email address should be the first name 
-- of the primary_poc . last name primary_poc @ company name .com.
SELECT  CONCAT(LOWER(LEFT(primary_poc, POSITION(' ' IN primary_poc)-1)), '.',
               LOWER(SUBSTR(primary_poc, POSITION(' ' IN primary_poc)+1)), '@',
               SUBSTR(website, 5)) e_mail
FROM accounts a

/*
REPLACE
*/
-- 2. You may have noticed that in the previous solution some of the company 
-- names include spaces, which will certainly not work in an email address.
-- See if you can create an email address that will work by removing all of the 
-- spaces in the account name, but otherwise your solution should be 
-- just as in question 1. Some helpful documentation is here.
WITH t1 AS (
            SELECT LEFT(primary_poc,     STRPOS(primary_poc, ' ') -1 ) first_name,  
                   RIGHT(primary_poc, LENGTH(primary_poc) - STRPOS(primary_poc, ' ')) last_name, 
                   name
            fROM accounts)

SELECT first_name, last_name, CONCAT(first_name, '.', last_name, '@', REPLACE(name, ' ', ''), '.com')
FROM  t1;

WITH t1 AS (
            SELECT LEFT(primary_poc,     STRPOS(primary_poc, ' ') -1 ) first_name,
                   RIGHT(primary_poc, LENGTH(primary_poc) - STRPOS(primary_poc, ' ')) last_name, 
                   name
            FROM accounts)

SELECT first_name, last_name,
       -- Initial password
       CONCAT(first_name, '.', last_name, '@', name, '.com'), LEFT(LOWER(first_name), 1) || 
              RIGHT(LOWER(first_name), 1) || LEFT(LOWER(last_name), 1) || RIGHT(LOWER(last_name), 1) || 
              LENGTH(first_name) || LENGTH(last_name) || REPLACE(UPPER(name), ' ', '')
FROM t1;

/*****************************************************************
--: COALESCE
******************************************************************/
-- Rreturns the FIRST NON-NULL value in a list
COALESCE(val1, val2, val3...):

/* 
-- Use case:
multiple columns that have a combination of null and non-null falues.
The user needs to extract the first non-null value.
 */


--:COALESCE and LEFT JOINS (EXAMPLE 1)
-- IMPORTANT
-- There is a row in the accounts table with the id = 1731 and name = 'Goldman Sachs Group' 
-- that does not have a matching row in the orders table. T
-- in a LEFT JOIN:
       -- if the values in the left table (here a.id) do not have matching
       -- values on the right table (here o.account_id), the rows are
       -- preserved, but the "joining" columns (a.id and o.account_id) are kept
       -- as NULL for that particular row.
-- IF WE WANT TO CORRECT THIS WE WILL HAVE TO USE COALESCE
SELECT *
FROM accounts a
LEFT JOIN orders o
ON a.id = o.account_id 
WHERE o.total IS NULL; -- with this condition we detect rows that were in accounts that 
                       -- do not have a corresponding row in orders

-- We will fill the following columns using COALESCE:
       -- COALESCE(a.id, a.id): fills the NULL values in a.id with the values in the original a.id column 
       
       -- COALESCE(o.account_id, a.id): fills the NULL values in o.account_id (NULL values created when joining)
       -- with the values in the original a.id column

       -- COALESCE(o.standard_qty, 0): fills the NULL values created when joining with 0... etc.

/* 
NOTE the syntax:
COALESCE(a.id, a.id)
 */
SELECT COALESCE(a.id, a.id) filled_id, a.name, a.website, a.lat, a.long, a.primary_poc, a.sales_rep_id, 
       COALESCE(o.account_id, a.id) account_id, o.occurred_at, 
       -- Then fix the rest of the columns from the joined table that also will have no values
       COALESCE(o.standard_qty, 0) standard_qty, 
       COALESCE(o.gloss_qty,0) gloss_qty, 
       COALESCE(o.poster_qty,0) poster_qty, 
       COALESCE(o.total,0) total, 
       COALESCE(o.standard_amt_usd,0) standard_amt_usd, 
       COALESCE(o.gloss_amt_usd,0) gloss_amt_usd, 
       COALESCE(o.poster_amt_usd,0) poster_amt_usd, 
       COALESCE(o.total_amt_usd,0) total_amt_usd
FROM accounts a
LEFT JOIN orders o
ON a.id = o.account_id

--:COALESCE and MULTIPLE COLUMNS with ONLY 1 NON-NULL VALUE
-- PROBLEM calculate total compensation field off the 3 types of income

/* 
| HOURLY_WAGE | SALARY      | SALES       |
| null        | null        | 100         |
| 8           | null        | null        |
| null        | 200000      | null        |
 */

-- SOLUTION
commission = 100
COALESCE(hourly_wate * 40 * 52, salary, commission * sales) AS annual_income

/*****************************************************************
--: DEALING WITH NULLS - common strategies
******************************************************************/
--:COALESCE
-- Return the first non-null values across a set of columns.
-- Good approach only f a single column's value needs to be extracted
-- whilst the rest are null
-- Also good to fill some voids in LEFT JOIN

--:DROP RECORDS
-- Used to drop the row entirely if analyst decide this is feasible
-- Removes data and data is precious.
-- Think about the reason for those null values

--:IMPUTATION
-- You may want to IMPUTE missing values 
       -- Examples of conservative approaches
              -- Take MIN of a column...
              -- Take the 25th percentile value...      