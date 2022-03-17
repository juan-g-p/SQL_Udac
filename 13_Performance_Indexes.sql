/* 
2022
 */
 -- RAM is much faster and is bvolatile (10-100x faster)
 -- Disk has 10-100x more space
-- The relational database might optimize thing keeping some things on the ram

/************************************************************************ 
--:Intro to indexes
*************************************************************************/

/* A relational database will work the same way: if you are doing a SELECT with 
a WHERE clause on a certain table, the relational database will sequentially 
scan the whole table row by row, and return all the rows that match your WHERE 
condition. Similarly, relational databases like Postgres also allow you to 
create indexes on table columns: separate structures, that are also stored 
on disk, sorted by value, and with pointers to the rows or pages of rows 
that contain those values. */
/* 
Creating these indexes will sometimes help the relational database find data 
in the same way as a book's index. Why sometimes? First, your WHERE condition 
will have to be searchable by the index, and second, the database has to deem 
that it's faster to access the index then the data itself, rather than just 
going through the data. Same thing for you and the book: if you're dealing 
with a book that only has 10 pages, even if it has an index, it might be faster 
to scan the whole book for the word you want than searching through the index. */

/************************************************************************ 
--:TIMING
*************************************************************************/
--:Timing:
-- we created a 1000000 rows database, otherwise everything would be too fast
\timing on --> will return how much time it took to execute each query

/************************************************************************ 
--:first timing comparisons
*************************************************************************/

SELECT * FROM "phonebook_1000000"
    -- goes through a pager. To exit press Q.
    -- around 800 ms

SELECT * FROM "phonebook_1000000" WHERE "last_name" = 'Hegmann'
    -- 200 ms...

/************************************************************************ 
--:CREATE AN INDEX
*************************************************************************/
CREATE INDEX ON "phonebook_100000" ("last_name");
    -- We do not use alter table because indexes will be global to our database.
    -- 2500 ms for creation approx
    -- We create it because looking by last name is pretty common.

SELECT * FROM "phonebook_1000000" WHERE "last_name" = 'Hegmann'
    -- Now this takes 6 miliseconds. 20 times less!!!
    -- If this queries are repeated a lot, then it makes a huge difference.

SELECT * FROM "phonebook_1000000" WHERE "last_name" = 'Carmelo'
    -- again 100 ms

/******************************************************************** 
--:CREATE INDEX ON EXPRESSIONS
*********************************************************************/
TODO: REGEXP_REPLACE
TODO: STRING FUNCTIONS AND OPERATORS
https://www.postgresql.org/docs/9.6/functions-string.html
--:REGEXP_REPLACE: replace some characters in a string with other characters
--Example: remove everything that is not a number on our database.
--Good to perform a reverse search on phone numbers, which are not very normalized.
SELECT "phone_number", REGEXP_REPLACE("phone_number", '[^0-9]+', '', 'g')
    FROM "phonebook_1000000" LIMIT 25;
--
--:where clause on an expression
SELECT * FROM "phonebook_1000000" 
    WHERE REGEXP_REPLACE("phone_number", '[^0-9]+', '', 'g') = '14785470433';
    -- Took 3 seconds to execute. Long number.

--:index on REGEXP expression
CREATE INDEX "reverse_phone_search" ON "phonebook_1000000" (
    REGEXP_REPLACE("phone_number", '[^0-9]+', '', 'g') --Reduces the phones to a common format prior to searching
);

SELECT * FROM "phonebook_1000000" 
    WHERE REGEXP_REPLACE("phone_number", '[^0-9]+', '', 'g') = '14785470433';
    -- Now it takes less than 1 second. Three times gain.

--:indexing expression for case insensitive indexing
CREATE INDEX "lower_last_name" ON "phonebook_1000000"(
    LOWER("last_name")
);

SELECT * FROM "phonebook_1000000" WHERE LOWER("last_name") = 'hegmann';

/******************************************************************** 
--:MULTI-COLUMN INDEXES
*********************************************************************/

--:order in multi-column queries
    -- Index on (last_name, first_name) for queries like:
        -- WHERE last_name = '...' AND first_name = '...'
        -- WHERE last_name = '...'
        -- NOT WORKING ON first_name = '...'

CREATE INDEX ON "phonebook_10000000" ('last_name', 'first_name')

/******************************************************************** 
--:UNIQUE INDEXES
*********************************************************************/
-- Internally: UNIQUE CONSTRAINT --> UNIQUE INDEX (also PRIMARY KEY)
-- It is an IMPLEMENTATION DETAIL in Postgresql, but its unlikely to change
-- Postgre will not prevent you from creating both a unique constraint 
-- and a unique index on the same column. That is a waste of resources

--:unique index instead of unique constraint
-- Example: 
    -- If we want a username to be prevented from being created if it only
    -- differs on the first letter case, we may use a unique index instead
    -- of a unique constraint, because a unique index will allow me to
    -- create expressions

CREATE UNIQUE INDEX ON "users" (LOWER("username"));

INSERT INTO "users" ("username") VALUES ('Bob');

INSERT INTO "users" ("username") VALUES ('bob');
    -- Insert fails due to a duplicate key violation.

--:EXERCISE INDEXES

-- constraints
ALTER TABLE "authors"
    ADD PRIMARY KEY ("id");

ALTER TABLE "topics"
    ADD PRIMARY KEY ("id"),
    ADD UNIQUE ("name"),
    ALTER COLUMN "name" SET NOT NULL;

ALTER TABLE "books"
    ADD PRIMARY KEY ("id"),
    ADD UNIQUE ("isbn"),
    ADD FOREIGN KEY ("author_id") REFERENCES "authors" ("id")

ALTER TABLE "book_topics"
    ADD PRIMARY KEY ("book_id", "topic_id"); -- this PRIMARY KEY allows us to search
                                             -- quickly on either "book_id" or in the
                                             -- cmbination ("book_id", "topic_id")

-- quickly find books and authors by their IDs.
    -- already achieved when creating the primary key

-- quickly tell which books an author has written
CREATE INDEX "authors_books" ON "books" ("author_id");

-- quickly find a book by ISBN
    -- already achieved when created a unique constraint on ISBN

-- Search books by titles in a case insensitive way, even if the
-- match is partial
TODO: VARCHAR_PATTERNS_OPS on indexes for partial matching using the LIKE operator
-- Because we want to do partial matching, the index needs to be
-- created using VARCHAR_PATTERN_OPS
CREATE INDEX "title_index" ON "books"(
    LOWER("title") VARCHAR_PATTERN_OPS
);

-- For a given book, we need to be able to quickly find all the topics associated to it
    -- already achieved when creating a primary key ("books_id", "topic_id") on the book_topics
    -- table

-- For a given topic, we need to be able to quickly find all the books tagged with it.
CREATE INDEX "topic_index" ON "book_topics"(
    "topic_id"
);

/******************************************************************** 
--:VERYFYING INDEXES
*********************************************************************/

-- Continues with explain
CREATE TABLE "samebook" AS
    SELECT
        generate_series(1, 100000) "id",
        'John'::varchar "first_name",
        'Smith'::varchar "last_name";

CREATE INDEX ON "samebook" ("last_name");
--
--:ANALYZE command
-- Normally done under the hood by Postgres
-- Updates statistics that Postgres is keeping about the table
-- Satatitistics about the distributions and the quantity of data
-- on the table. Will be used to create query plans.
ANALYZE "samebook";

/******************************************************************** 
--:EXPLAIN
*********************************************************************/
--:EXPLAIN DOCUMENTATION 
https://www.postgresql.org/docs/9.6/sql-explain.html

EXPLAIN SELECT * FROM "samebook" WHERE "last_name" = 'Smith';

/*                            QUERY PLAN                            
-----------------------------------------------------------------
 Seq Scan on samebook  (cost=0.00..1791.00 rows=100000 width=15)
   Filter: ((last_name)::text = 'Smith'::text) */

-- IMPORTANT: this output is read from the inside out: from the most indented
-- to the less indentent node.

-- The -> tell us how many levels there are

-- When we ran this query on a phone table that did not have all the
-- same values it was doing a bitmax index query followed by a bitmap heap scan
-- or more shortly Postgres was actually using the index

-- Here it decides to do a Seq Scan, which normally would be slower than
-- using the index. But thanks to the statistics it is keeping it is able to tell
-- that the result of this query will require to return a lot of rows of data...
-- All this while planning the query. Using the index would mean first using the index
-- and then figuring out that we need to access all the table. In this case it knows
-- that it will have to access all the table and therefore jumps directly to Seq Scan

EXPLAIN SELECT * FROM "samebook" WHERE "last_name" = 'Jones';

/*                                        QUERY PLAN                                       
----------------------------------------------------------------------------------------
 Index Scan using samebook_last_name_idx on samebook  (cost=0.29..4.31 rows=1 width=15)
   Index Cond: ((last_name)::text = 'Jones'::text)
(2 rows) */

-- Postgres usually decides to use an index_scan when it thinks it is
-- going to retrieve very few rows of data.
-- It doesnt know its 0, but it knows that even for the same query,
-- running it with different values could be faster with different
-- execution plans

-- We changed the value and now Postgres decides it will use an index scan. Because it knows
-- that it will have to return little values... so the index scan will help it determine
-- values that match our filter and then go back and forth between the items and the table
-- to grab the matching data

-- It decides to use an index scan usually when it knows that it will return very
-- few rows of data.

-- PostGres knows that even for the same query, runnin it for different values could be
-- optimized with different execution strategires, as we just explained.

EXPLAIN SELECT * FROM "phonebook_1000000" 
    WHERE "last_name" = 'Jones';
    OR "last_name" = 'Smith';

-- In this case the query plan has two nodes on the first level
    -- Two bitmap index_scan that scan the same index for lastname
    -- The next level is a BitmapOr
        -- Combines the outputs of the Bitmap Index which look for the specific lastnames
    -- Finally this result goes to the Bitmap Heap Scan which goes through the table only
    -- in those tables that returned true on the bitmap or

-- Different row numbers return
EXPLAIN SELECT * FROM "phonebook_1000000" WHERE "id" < 500000;
    -- Uses an Index Scan
        -- Goes between the index and the table and returns the data where
        -- the ID is less than 500000


EXPLAIN SELECT * FROM "phonebook_1000000" WHERE "id" < 600000;
    -- Uses a Sequential Scan
        -- Postgres has decided that it will be faster to scan through the whole
        -- table to give you back the data because now there is a big portion
        -- of the data that will be returned.

EXPLAN SELECT * FROM "phonebook_1000000" 
    WHERE "id" < 500000
     ORDER BY "id";
    
    -- Uses an Index Scan
        -- Does not add something for the ORDER BY statement
    -- The index we are using is already an index for the column and searching by the index
    -- will give them returned bt ID

EXPLAIN SELECT * FROM "phonebook_1000000"
    WHERE "last_name" = 'Smith'
    LIMIT 10;
    -- Before (without limit) Postgre used:
        -- a Bitmap index scan
        -- followed by a Bitmap Heap Scan
    
    -- Now it uses an Index Scan. 
    -- This time it does not expect to return a huge dataset, so it uses the index
    -- it knows it will stop after the first 10 matches.

/******************************************************************** 
--:EXPLAIN ANALYZE
*********************************************************************/
-- EXPLAIN:
    -- ONLY PLAN + ESTIMATES
    -- COST: unitless, difficult to compare
-- EXPLAIN ANALYZE
    -- EXPLAIN + actual execution

EXPLAIN ANALYZE SELECT * FROM "phonebook_1000000" WHERE "last_name" = 'Smith';

-- Gives you more detail
    -- Execution time
    -- Planning time...
    -- The nodes now include the approximate and ACTUAL costs (in ms)
    -- Bitmap Heap Scan also includes this actual information

-- IMPORTANT: the query is being executed
-- If you want to run EXPLAIN ANALYZE with DELETE, INSERT... or other destructive operations
-- do it within a transaction that you can ROLLBACK

/******************************************************************** 
--:examples of EXPLAIN
*********************************************************************/
 Seq Scan on phonebook_1000000  (cost=0.00..18284.00 rows=1000000 width=34)
-- We do not have the query associated to this.
    -- What query could this have been? 
    -- No filter condition... it looks like a SELECT * FROM phonebook_1000000

 Seq Scan on phonebook_1000000  (cost=0.00..20784.00 rows=324 width=34) 
 (actual time=0.169..112.646 rows=343 loops=1)
   Filter: ((first_name)::text = 'John'::text)
   Rows Removed by Filter: 999657
 Planning time: 0.213 ms
 Execution time: 117.582 ms
-- We ran explain analyze. In addition to the estimates, we also have the
-- actual values of running the qury.
-- about 99% of the rows where removed by the filter...

-- I will assume there are a million rows in the dataset and that the filter has eliminated
-- almost 99.9% of rows. It seems that there might be a better way to do this than
-- a sequential scan. The reason for this is that there might not be a proper index.

-- NEXT STEP I'd DO: check table and check if everything is indexed properly
-- I might add an index

-- The estimated rows and returned rows are very close, so the statistics postgres is 
-- keeping seem pretty good.

 Bitmap Heap Scan on phonebook  (cost=44.64..4863.00 rows=2092 width=34)
   Recheck Cond: ((last_name)::text = 'Smith'::text)
   ->  Bitmap Index Scan on phonebook_last_name_idx  
   (cost=0.00..44.11 rows=2092 width=0)
         Index Cond: ((last_name)::text = 'Smith'::text)
-- Here we have two levels in the way that the query is being planned. There is
-- indentation. The output must be read from the inside out (most indented to lest indented)

-- There seems to be a Bitmap Index Scan. This is a way that the database will use the index by first
-- going through all the index from beginning to end and matching everything that has the last name
-- of 'Smith' in terms of the tables pages of data.

-- Following that bitmap index scan, all the pages that contain one or more entries that have the
-- last name of Smith will then be scanned in the actual table itself (this is what the Heap is, 
-- the actual table data). These results in an efficient way to return the data where the condition is met.

-- This query returned a plan that is not an Index Scan, but a Bitmap Index Scan. This tells me that
-- this query might return a substantial amount of data compared to the whole data that is in the table.
-- Otherwise we would have expected a simple index scan.

 Bitmap Heap Scan on phonebook  (cost=44.12..4867.70 rows=1 width=34)
   Recheck Cond: ((last_name)::text = 'Smith'::text)
   Filter: ((first_name)::text = 'John'::text)
   ->  Bitmap Index Scan on phonebook_last_name_idx  
   (cost=0.00..44.11 rows=2092 width=0)
         Index Cond: ((last_name)::text = 'Smith'::text)

-- The only difference with the previous is that here we have an additional filter
-- After using the bitmap index scan to match for Smith, the Bitmap Heap Scan,
-- the additional filter on first_name.
        -- From this we can tell that the index for last_name is not multi-column
        -- since it is not used to scan fot the subsequent first_name.

-- We cannot conclude that there is no index on first_name itself. All we know is that
-- Postgre decided to use the index on last_name. There could be an index on a single
-- column on first_name and postgres could have decided this second search was more
-- efficiently done using a Bitmap Heap Scan instead of the index on first_name that
-- could potentially exist.

/******************************************************************** 
--:TOO MANY INDEXES 
*********************************************************************/
-- TRADE-OFFS to adding indexes:
    -- Additional disk space
        -- The most concerning one
    -- Additional I/O on INSERT/UPDATE/DELETE to keep the index in line with your data.
        -- If you modify your tables a lot... you might want to think about adding an index.


--:ALTERNATIVES TO INDEXES
-- If a query is taken a lot of time but is not frequently run, an index might not be the best
-- option.

-- OPTION 1
-- The analyst might have a serparate query of the database

-- OPTION 2
-- Run the queries in the background and output tu a .csv for the analyst

-- MAIN POINT: adding an index is not necessarily the single cure. Specially if the query is not
-- so frequent

--:ALTERNATIVES FOR TEXT
-- Example: look through a description.
-- An index would occupy a lot of space and only be able to search from the beginning of that text
--:GIN INDEX (FULLTEXT INDEX)
-- Actually analyzes the text, chops it in words and is more appropriate to analyze text
-- Postgre has this functionality, although we are not looking into it in this course

-- Also NoSQL or Non-relational databases are very good at text search. One of them is elastic-search
-- but there are others. Depending on your use case indexes are not always the proper solution to make
-- your code runs faster.

