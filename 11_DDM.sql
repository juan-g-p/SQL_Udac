/**************************************************************** 
--:INSERTING DATA IN POSGRES
****************************************************************/

/**************************************************************** 
--:INSERT ... VALUES
****************************************************************/
-- introducing new data in a table; 
-- this data would come from an external source like an application

--:insert values basic sytax
INSERT INTO table_name (column list...) VALUES (values),...

--:insert skipping columns
INSERT INTO "movies" ("name", "release_date") VALUES -- This will use the default value for id
    ('Episode IV - A New Hope', '1977-05-25'),
    ('Episode V - The Empire Strikes Back', '1980-05-17'),
    ('Episode VI - Return of the Jedi', '1983-05-25');
--

--:insert messing up the primary key
INSERT INTO "movies" ("id", "name", "release_date") VALUES --This creates movies with the same ID as before!
    (1, 'Episode IV - A New Hope', '1977-05-25'),          --This is misleading... not a primary key. No check in place
    (2, 'Episode V - The Empire Strikes Back', '1980-05-17'),
    (3, 'Episode VI - Return of the Jedi', '1983-05-25');
--

--:insert default values
INSERT INTO "movies" ("id", "name", "release_date") VALUES -- This automatically generates the id following the serial. Default value
    (DEFAULT, 'Episode IV - A New Hope', '1977-05-25'),
    (DEFAULT, 'Episode V - The Empire Strikes Back', '1980-05-17'),
    (DEFAULT, 'Episode VI - Return of the Jedi', '1983-05-25');
--

--:increase serial index number
SELECT nextval('movies_id_seq::regclass'); -- This increases the value of the index! (Skip indexes)
/**************************************************************** 
--:INSERT ... SELECT
****************************************************************/

--:insert data from other table
INSERT INTO table_name (column list in the order of the select) SELECT ... FROM ...

    -- EXAMPLES
    CREATE TABLE "categories" (
        "id" SERIAL,
        "name" VARCHAR
    );

    INSERT INTO "categories" ("name")
        SELECT DISTINCT "category" FROM "posts"; -- We have a table called posts with a bunch of posts
                                                 -- We wish to create a table with the categories

/**************************************************************** 
--:EXERCISE ON INSERTING DATA
****************************************************************/
-- STEP 1: Migrate the list of people without their emails into the table "normalized people"
INSERT INTO "people" ("first_name", "last_name") 
    SELECT "first_name", "last_name" FROM "denormalized_people";

-- STEP 2: Migrate all email addresses of each person to the normalized people_emails
INSERT INTO people_emails (person_id, email_address)
    SELECT p.id, 
           regexp_split_to_table(dp.emails, ',') as email
    FROM denormalized_people dp
    JOIN people p
        ON (p.first_name = dp.first_name
            AND p.last_name = dp.last_name);

TODO: parenthesis at ON clause above... cleaner
TODO: regexp_split_to_table --Clarify how this is used.

/**************************************************************** 
--:UPDATING DATA IN POSGRES
****************************************************************/
--:update vs insert
/* In an existing table, insert always adds data at the end of the column,
whereas update changes existing values. 
If you create new columns and want to populate this new columns use UPDATE
or you will make the table grow. */


--:update basic syntax
UPDATE table_name SET col1=val1, ... WHERE condition -- The where restricts the set of rows updated
                                                     -- If there is no where all the rows are updated
                                                     -- No way to go back... backup

--:update manual input
UPDATE "users" SET "mood" = 'LOW' WHERE "happiness_level" < 33;
UPDATE "users" SET "mood" = 'Average'
    WHERE "happiness_level" between 33 AND 65;
UPDATE "users" SET "mood" = 'Good' WHERE "happiness_level" >= 66;

UPDATE "users" SET "mood" = 'Excellent' -- Updates all rows

UPDATE "users" SET "mood" = 'Excellent', "happiness_level" = 100


--:update from another table with subselect
-- First add a new column
ALTER TABLE "posts" ADD COLUMN "category_id" INTEGER;

--Match categories. We set the value to another select.
UPDATE "posts" SET "category_id" = (
    --hidden join with a subselect
    SELECT "id" 
    FROM "categories"
    WHERE "categories"."name" = "posts"."category"
);

ALTER TABLE "posts" DROP COLUMN "category";

--
--:EXERCISE UPDATE TABLES

/* 
Capitalize correctly the last name
 */
TODO: initcap - string function
-- Alternative 1
UPDATE people SET last_name = initcap(last_name);

TODO: || CONCATENATE OPERATOR
-- Alternative 2 using concatenate operator || and LOWER
SELECT 
    SUBSTR("last_name", 1, 1) ||
    LOWER(SUBSTR("last_name", 2))
FROM "people";

-- Create new column
ALTER TABLE "people" ADD COLUMN "date_of_birth" DATE;

TODO:: INTERVAL
-- Populate new column based on another column
UPDATE "people" SET "date_of_birth" = (
    SELECT CURRRENT_DATE - born_ago::INTERVAL
    FROM people
);

-- Drop column born_ago
ALTER TABLE "people" DROP COLUMN "born_ago";

/**************************************************************** 
--:DELETING DATA IN POSGRES
****************************************************************/
--:delete documentation
https://www.postgresql.org/docs/9.6/sql-delete.html

--:delete basic syntax
-- If no WHERE, all rows are deleted
-- DELETES THE WHOLE ROW --> No need to specify columns
DELETE FROM table_name WHERE condition;
--

--:comparison TRUNCATE vs DELETE
    -- Truncate allows you to restart the sequence if you have one
    -- Truncate will clear these indexes, accelerating queries once
    -- new data gets inserted (see future lesson).

TODO: pg_typeof
-- Used to get the data type
SELECT pg_typeof(CURRENT_TIMESTAMP - "date_of_birth") FROM "users"; -- Intervals for each row
--

--:example of DELETE
-- If we get an interval we can compere it with another interval
DELETE FROM "users" WHERE
    (CURRENT_TIMESTAMP - "date_of_birth") < INTERVAL '21 years';

/**************************************************************** 
--:DROP vs TRUNCATE vs DELETE vs ALTER
****************************************************************/
-- DROP: removing a table from the system
-- TRUNCATE: removing all data from a table
-- DELETE: removing some data from a table
-- ALTER: removing a column from a table

/**************************************************************** 
--:TRANSACTIONS
****************************************************************/
-- Broad topic (whole course)
-- We are simply learning the basics
-- IT IS BEST TO SEE THE VIDEOS OF THIS PART OF THE COURSE

--: Transactional guarantees provided by relational databases (ACID)
    -- ATOMIC: "All or nothing"
        -- The database guarantees that a transaction will either register all the commands
        -- in a transaction or none of them
    -- CONSISTENT: 
        -- Obeys business rules. More in next lesson! (Ex: VARCHAR(10))
        -- The database guarantees that a successful transaction will leave the data in a
        -- consistent state, one that obeys all the rules that you've setup.
        -- We will see more consistency rules later on.
    -- ISOLATED: 
        -- Transactions dont "see each other" until commited
        -- The database guarantees that concurrent transactions (running in paralllel) dont "see each other" 
        -- until they are commited.
        -- Commiting a transaction is a command that tells the database to execute all the commands
        -- we passed to it since we started the transaction.
            -- Example later: we will enact manual transaction with Postgres command line
    -- DURABLE: 
        -- The database guarantees that once it accepts a transaction and returns a success, the
        -- changes introduced will be permanently stored on disk, even if the database crashes right
        -- after the success response.
        -- Examples: network goes down, operating system crashes...

-- So far we ran every command in Postgres command line as a transaction
--:transaction BEGIN/START
BEGIN TRANSACTION
--START TRANSACTION (alternative)

sql code
-- All these commands will be run in isolation from any other transactions
-- If the application (or the psql program) crashes, all the commands will
-- be discarded. 

-- We can also manually discard the commands executed after 
-- starting a transaction by running ROLLBACK

-- To make changes permanents, we execute COMMIT or END (which are equivalent)

--:transaction END
--Code since BEGIN TRANSACTION wont be commited until we state this
ROLLBACK -- discard transaction commands

END --makes changes permanent
COMMIT --equivalent to END

--:shut down AUTOCOMMIT
\set AUTOCOMMIT off -- particular command of psql command line
\echo :AUTOCOMMIT -- check the status of autocommit
-- 
--
--:FINAL EXERCISE DDM

\set AUTOCOMMIT off
\echo :AUTOCOMMIT -- check the status of autocommit

BEGIN

-- REMOVE ALL USERS FROM CALIFORNIA AND NEW YORK
DELETE FROM "user_data" 
WHERE "state" IN ('CA', 'NY');

-- CREATE NEW COLUMNS FOR FIRST AND LAST NAME
ALTER TABLE "user_data" 
    ADD COLUMN "first_name" VARCHAR,
    ADD COLUMN "last_name" VARCHAR;

TODO: SPLIT_PART - include in data manipulation
TODO: string manupaltion functions in psql
https://www.postgresql.org/docs/9.6/functions-string.html

-- IMPORTANT: WE USE UPADTE and not INSERT
-- INSERT would add values at the end of the table!!
UPDATE "user_data" SET
    "first_name" = SPLIT_PART("name", ' ', 1),
    "last_name" = SPLIT_PART("name", ' ', 2);

ALTER TABLE "user_data" DROP COLUMN "name";

-- CREATE TABLE for STATES
CREATE TABLE "states" (
    "id" SMALLSERIAL,
    "state" CHAR(2)
);


-- Bring the unique states_ids to "states" table
INSERT INTO "states" ("state")
    SELECT DISTINCT "state" FROM "user_data";

-- ADD state_id to user_data
ALTER TABLE "user_data" ADD COLUMN "state_id" SMALLINT;

-- IMPORTANT: WE USE UPADTE and not INSERT
-- INSERT would add values at the end of the table!!
UPDATE "user_data" SET "state_id" = (
    SELECT "s"."id"
    FROM "states" "s"
    WHERE "s"."state" = "user_data"."state"
)

ALTER TABLE "user_data" DROP COLUMN "state";

SELECT * FROM user_data LIMIT 10;

-- All done, commit!
COMMIT