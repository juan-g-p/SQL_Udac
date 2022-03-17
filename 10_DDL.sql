/
--: ; in POSTGRESQL
In psql you MUST add a semicolon at the end of a given command/query for it to execute.

--:FULL POSTGRESQL DATA DEFINITION LANGUAGE DOCUMENTATION
https://www.postgresql.org/docs/9.6/ddl.html

/***************************************************************
--:CREATE TABLE
****************************************************************/
-- Table and column identifiers in PostFres are double quoted!
-- https://www.postgresql.org/docs/9.6/sql-createtable.html

CREATE TABLE "table_name" (
    ...comma-separated list of columns and their types
);

-- Normalized set of tables that can support the following data
emp_id	emp_name	manager_id	manager_name	manager_phones
1	Alice	6	Frank	555-1212
2	Bob	5	Emily	555-6042, 555-7213
3	Cindy	6	Frank	555-1212
4	David	 	 	 
5	Emily	4	David	555-7654, 555-4242
6	Frank	4	David	555-7654, 555-4242

--Entities
    -- Regular employees
    -- Managers
    -- We are going to use a single table for managers and employees
    -- because managers are just regular employees!

-- Example
CREATE TABLE "employees" (
    "empl_id" SERIAL,
    "empl_name" TEXT,
    "manager_id" INTEGER
);

CREATE TABLE "employee_phpnes" (
    "emp_id" SERIAL,
    "phone" TEXT
);

/***************************************************************
--:NUMERIC DATATYPES
****************************************************************/
https://www.postgresql.org/docs/9.6/datatype-numeric.html
-- SMALLINT, INTEGER, BIGINT
-- DECIMAL, NUMERIC
-- REAL, DOUBLE PRECISION
-- SMALLSERIAL, SERIAL, BIGSERIAL

/***************************************************************
--:Integers
****************************************************************/
SMALLINT: -32,768 to +32,767
INTEGER: -2,147,483,648 to +2,147,483,647
BIGINT: -9,223,372,036,854,775,808 to +9,223,372,036,854,775,807

/***************************************************************
--:Serials
****************************************************************/
-- Mirror the integer types. They are sequences and Postgres can
-- automatically manage their values.
-- They start at 1
/* SERIAL type, if we don't give it a value when inserting data, 
Postgres will automatically generate the next integer in sequence, 
until the sequence is exhausted based on the range 
of serial we chose (small, regular, or big). */
SMALLSERIAL: 1 to +32,767
SERIAL: 1 to +2,147,483,647
BIGSERIAL: 1 to +9,223,372,036,854,775,807

/***************************************************************
--:Decimals and Floating Point
****************************************************************/
-- "Floating-point" numbers (INEXACT)
    -- Uses IEE 754 specification
REAL:~ from 1e-37 to 1e+37, ~6 decimals digits precision
DOUBLE PRECISION: from 1e-307 to 1e+308, ~15 digits precisions

-- CAN CAUSE ROUNDING ERRORS!!
-- DO NOT USE TO STORE SOMETHING WITH A DECIMAL THAT NEEDS TO BE PRECISE
    -- prices, interest rates, finance numbers...

-- "Decimal numbers" (EXACT)
NUMERIC === DECIMAL --(same data type, pick one and stick with it)
-- Store very big numbers, more than 100000 digits
    -- precision (total digits) can be defined
    -- scale (digits after decimal) can be defined
-- VERY SLOW to calculate compared to integers and floats.

--: Examples: differences between numeric
SELECT 1.1 + 1.2;
    -- Yields 2.3

SELECT '1.1' + '1.2'; --Single quotes represent text in Postgres
    -- Postgres could not choose best candidate operator. We need to cast.

--: :: to CAST
SELECT '1.1'::NUMERIC + '1.2'::NUMERIC;
    -- Yields 2.3

SELECT 1.1::REAL + 1.2::REAL;
    -- Take 1.1 and interpret it as real and add it to 1.2
    -- Yields 2.3000002 --> Not exact!
    -- In the world of finance or e-commerce this is going to be important.

TODO: Research about DECIMAL vs FLOATING POINT 

/***************************************************************
--:TEXT DATA TYPES
****************************************************************/
https://www.postgresql.org/docs/9.6/datatype-character.html
CHARACTER VARYING(n) or VARCHAR(n)
CHARACTER(n) or CHAR(n)
TEXT

/***************************************************************
--:CHARACTER VARYING(n) - VARCHAR(n) and TEXT
****************************************************************/
-- Yields an error if inserting longer value than limit n
-- If no length specified, same as TEXT

/***************************************************************
--:CHARACTER(n) or CHAR(n)
****************************************************************/
-- FIXED LENGTH but WITHOUT BENEFIT ON PERFORMANCE
-- Error if value longer than n
-- Value less than the limit --> will pad the remaining characters with SPACES

-- Rarely used, not many things with fixed length
-- Examples
    -- CODES of 8 or 6 legth...

-- Once you have a lot of numbers in a database, changing the type
-- can take hours and take your database down for that time...

-- EX: ISBN numbers... went from 10 to 13 figures

CREATE TABLE "employees" (
    "id" SERIAL,
    "badge_id" CHAR(6),
    "username" VARCHAR(30), -- Nobody will have a username of more than 30 chars
    "first_name" VARCHAR, -- We assume something of 1 line
    "last_name" VARCHAR,
    "biography" TEXT -- We assume something that can be indefinately long...
);

/* 
   Table "public.employees"
   Column   |         Type          |                       Modifiers                        
------------+-----------------------+--------------------------------------------------------
 id         | integer               | not null default nextval('employees_id_seq'::regclass)
 badge_id   | character(6)          | 
 username   | character varying(30) | 
 first_name | character varying     | 
 last_name  | character varying     | 
 biography  | text                  | 
 */

--:TEXT vs VARCHAR for documentation
-- They behave exactly the same
-- You might use VARCHAR to represent something unbounded, 
-- but that would fit on a single line, and TEXT to represent 
-- large amounts of text like the contents of a book or someone's biography.

/***************************************************************
--:DATE/TIME Data Types
****************************************************************/
https://www.postgresql.org/docs/9.6/datatype-datetime.html
TIMESTAMP === TIMESTAMP WITHOUT TIME ZONE
TIMESTAMP WITH TIME ZONE -- both date and time
    -- Stored as date/time in UTC but shifted according to the timezone of the server
    -- Number of miliseconds since the "epoch", defined as 1970-01-01 00:00:00-00
DATE -- only date without time
TIME -- only time without date



--: TIMES AND TIMEZONES
SHOW TIMEZOME and SET TIMEZONE -- to work with timezones

--:SHOW TIMEZONE;
-- Gives you the timezone of your Postgres database server

--: SELECT CURRENT_TIMESTAMP;
-- Gives you the current timestamp of your sever with its current timezone

--: SET TIMEZONE='America/Los_Angeles';
-- Changes the timezone to LA (UTC-07)

--: Timezones example
CREATE TABLE "zones" (
    "t1" TIMESTAMP WITHOUT TIME ZONE, -- Default behavior its the same as TIMESTAMP
    "t2" TIMESTAMP WITH TIME ZONE
);

INSERT INTO "zones" VALUES
    ('2020-04-19 16:00:00-04', '2020-04-19 16:00:00-04');

SELECT * FROM "zones";
-- The t1 column did not have timezone info
-- Our other column specified this clearly
/* 
         t1          |           t2           
---------------------+------------------------
 2020-04-19 16:00:00 | 2020-04-19 20:00:00+00
 */

SET TIMEZONE='America/New_York';
SELECT * FROM "zones";
/* 
         t1          |           t2           
---------------------+------------------------
 2020-04-19 16:00:00 | 2020-04-19 16:00:00-04
*/

--: Possible use to TIMESTAMP WITHOUT TIME ZONE
-- Release of album or videogame at same local time worldwide.

--: DATES

--: SELECT CURRRENT_DATE

--: SELECT CURRRENT_TIMESTAMP::DATE
    -- Exactly the same

--: SELECT '2020-04-19 16:00:00'::DATE
    -- Postgre is going to parse it as a date

/***************************************************************
--:OTHER DATATYPES
****************************************************************/
-- Documentation on all other Postgres datatypes:
https://www.postgresql.org/docs/9.6/datatype.html

Other datatypes in Postgres
-- JSON
-- Arrays (against first normal form? multiple values)
-- Geometry (lines, polygons..)

/***************************************************************
--:JSON - JavaScript Object Notation
****************************************************************/
CREATE TABLE "json_test" (
    "val" JSONB -- Not delving too much now... JSONB more efficient than JSON
);
/* 
           List of relations
 Schema |   Name    | Type  |  Owner   
--------+-----------+-------+----------
 public | json_test | table | postgres
 */

INSERT INTO "json_test" VALUES
('{"name": "Alice", "age": 30}'),
('{"name": "Bob", "language": "English"}');

SELECT * FROM "json_test"
/*                   val                   
----------------------------------------
 {"age": 30, "name": "Alice"}
 {"name": "Bob", "language": "English"} */

/***************************************************************
--:JSON OPERATORS
****************************************************************/
--: ->> OPERATOR to extract 'names'
SELECT "val" ->> 'name' FROM "json_test";
/* ?column? 
----------
 Alice
 Bob */

SELECT "val" FROM "json_test" WHERE "val" ->> 'name' = 'Alice';
/*              val              
------------------------------
 {"age": 30, "name": "Alice"} */


/***************************************************************
--:EXERCISE: Data Types
****************************************************************/
Create a schema that can accommodate a hotel reservation system.

/* 
It should have:
* The ability to store customer data: first and last name, an optional 
  phone number, and multiple email addresses.
* The ability to store the hotel's rooms: the hotel has twenty floors with 
  twenty rooms on each floor. In addition to the floor and room number,
  we need to store the room's livable area in square feet.
* The ability to store room reservations: we need to know which guest 
  reserved which room, and during what period.
 */

CREATE TABLE "customers" (
    "customer_id" SERIAL, -- One Serial per entity type is common
    "name" VARCHAR,
    "last_name" VARCHAR,
    "phone" VARCHAR
);

CREATE TABLE "cust_mails" (
    "customer_id" INTEGER,
    "email" VARCHAR
);

CREATE TABLE "reservations" (
    "reservation_id" SERIAL, -- One Serial per entity type is common
    "customer_id" INTEGER,
    "check_in" DATE,
    "check_out" DATE,
    "room_id" INTEGER
);

CREATE TABLE "rooms" (
    "room_id" SERIAL, -- One Serial per entity type is common
    "room_floor" SMALLINT,
    "room_nr" SMALLINT,
    "area" SMALLINT -- or REAL --> Discuss with client
);

/***************************************************************
--:MODIFYING TABLE STRUCTURE
****************************************************************/
-- Not frequent, but sometimes necessary. We want to get the schema
-- as accurate as possible from the beginning.
-- Can take a long time on large datasets
-- ALTERNATIVE: create a new table and migrate the date
    -- This is for database administrators... not covered here...

--: ALTER TABLE
ALTER TABLE table_name action
-- Some actions
    -- ADD COLUMN "col_name" DATA_TYPE
    -- DROP COLUMN "col_name"
    -- ALTER COLUMN "col_name" SET DATA TYPE VARCHAR DATA_TYPE

--: Example modifying table structure
CREATE TABLE "users" (
    "id" SERIAL,
    "first_name" VARCHAR(20),
    "last_name" VARCHAR(20),
    "nickname" VARCHAR(20)
);

-- We want to add more data to the table... new columns
ALTER TABLE "users" ADD COLUMN "email" VARCHAR;

ALTER TABLE "users" ALTER COLUMN "first_name" SET DATA TYPE VARCHAR;

ALTER TABLE "users" ALTER COLUMN "last_name" SET DATA TYPE VARCHAR;

-- Destructive operation! Once you do this the column is GONE
-- Practice on copies of your data prior to executing the code
ALTER TABLE "users" DROP COLUMN "nickname"

/***************************************************************
--:EXERCISE Modifying table structure
****************************************************************/
-- Remove the limit on email address lengths to keep things simple.
ALTER TABLE "students" ALTER COLUMN "email_address" SET DATA TYPE VARCHAR;

-- Course ratings to be more granular than just integers 0 to 10, 
-- also allowing values such as 6.45 or 9.5
ALTER TABLE "courses" ALTER COLUMN "rating" SET DATA TYPE REAL;

-- Discovered a potential issue with the registrations table that will 
-- manifest itself as the number of new students and new courses keeps increasing.
ALTER TABLE "registrations" ALTER COLUMN "student_id" SET DATA TYPE INTEGER;
ALTER TABLE "registrations" ALTER COLUMN "course_id" SET DATA TYPE INTEGER;


/***************************************************************
--:OTHER DDL COMMANDs
****************************************************************/
--: DROP
    -- Remove a table from the system
DROP TABLE "table_name";

--:TRUNCATE
    -- Remove all the data in a table
    -- Keep the name and structure
CREATE TABLE "demo" (
    "id" SERIAL,
    "name" VARCHAR
);

INSERT INTO "demo" ("name") VALUES ('Alice'), ('Bob');

TRUNCATE TABLE "demo"; -- Does not restart the ID

TRUNCATE TABLE "demo" RESTART IDENTITY; -- Restarts IDs

--:COMMENT
    -- Add a custom, text comment on a column
COMMENT ON COLUMN "demo"."column_name" IS 'your comment goes here'