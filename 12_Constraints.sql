TODO: CONSTRAINT CREATION syntax
-- Tomar los ejemplos de unique constraint y pasarlos aquí


/**********************************************************
--:UNIQUE CONSTRAINTS
**********************************************************/
-- Ensure values are not repeated
-- Target one or more columns
    -- Usernames
    -- Email addresses
CREATE TABLE "users" (
    "id" SERIAL,
    "username" VARCHAR
)

-- Here we have not specified that the username us unique
INSERT INTO "users" ("username") VALUES ('user1');
INSERT INTO "users" ("username") VALUES ('user2');
INSERT INTO "users" ("username") VALUES ('user1');

--
--: add unique constraints
-- Here we will add A UNIQUE CONSTRAINT
ALTER TABLE "users" ADD UNIQUE ("username");
-- Now we would not be able to insert two times 'user1'


--:named unique constraints. Same result but custom name for the constraint.
ALTER TABLE "users" ADD CONSTRAINT "unique_usernames" UNIQUE ("username");

--
--:drop constraints
ALTER TABLE users DROP CONSTRAINT "constraint_name"

--:constraints upon table creation
CREATE TABLE "users" (
    "id" SERIAL,
    "username" VARCHAR, -- this syntax only works if the unique constraint applies to 1 column
    CONSTRAINT "unique_usernames" UNIQUE ("username")
)

-- alternative
CREATE TABLE "users" (
    "id" SERIAL,
    "username" VARCHAR UNIQUE, -- this syntax only works if the unique constraint applies to 1 column
)

--:unique constraint over multiple columns
CREATE TABLE "leaderboards" (
    "game_id" INTEGER,
    "plater_id" INTEGER,
    "rank" SMALLINT,
    UNIQUE ("game_id", "rank") -- there can be only a unique combination of game_id and rank
)

/**********************************************************
--:PRIMARY KEY CONSTRAINTS
**********************************************************/
-- Special unique constraints
-- Combination of two constraints
    -- UNIQUE
    -- NOT NULL
-- Only one per table
-- One or more columns

CREATE TABLE "users" (
    "id" SERIAL, 
    "username" VARCHAR UNIQUE, -- this syntax only works if the unique constraint applies to 1 column
)
-- If you describe the table, the id column says "Nullable not null"
INSERT INTO "users" ("id", "username") VALUES
    (1, 'user1'),
    (1, 'user2'); -- This corrupts your data

-- Unique constraint on the ID column
ALTER TABLE "users" ADD UNIQUE ("id");

-- We can still add NULL value usersnames, so they are still not unique.
-- We would need to add NOT NULL (UNIQUE NOT NULL)
INSERT INTO "users" ("username") VALUES
    (NULL),
    (NULL);
--
--:compare PRIMARY KEY vs UNIQUE NOT NULL
-- Only one PRIMARY KEY per column, so they are also used to document
CREATE TABLE "users" (
--: surrogate key
    "id" PRIMARY KEY, -- SURROGATE KEY: artificially generated id that does not rely on business data
                      -- example: to avoid problems if a username changes its name
    "username" VARCHAR UNIQUE NOT NULL, -- this syntax only works if the unique constraint applies to 1 column
);

CREATE TABLE "user_friends" (
    "user1" INTEGER,
    "user2" INTEGER
);
--

--:primary key upon table creation

CREATE TABLE "users" (
    "id" SERIAL, 
    "username" VARCHAR,
    CONSTRAINT "users_pk" PRIMARY KEY ("id")
    CONSTRAINT "unique_usernames" UNIQUE NOT NULL ("username")
)


--:EXERCISE book authors

-- books table
ALTER TABLE "books" ADD PRIMARY KEY ("id");
ALTER TABLE "books" ADD UNIQUE ("isbn");

-- authors talbe
ALTER TABLE "authors" ADD PRIMARY KEY ("id");
ALTER TABLE "authors" ADD UNIQUE ("email_address");

-- book authors table
ALTER TABLE "book_authors" ADD PRIMARY KEY ("book_id", "author_id");
ALTER TALBE "book_authors" ADD UNIQUE ("book_id", "contribution_rank");

/**********************************************************
--:FOREIGN KEY CONSTRAINTS
**********************************************************/
-- foreign keys documentation:
https://www.postgresql.org/docs/9.6/ddl-constraints.html

-- A column can contain only values present in another column
-- Same or different columns
-- One or more columns...
-- Common use: ensure one-to-one, one-to-many, many-to-many...

-- IMPORTANT PostreSQL will refuse to create a foreign key if there
-- is no index on the REFERENCE column (if it is not a PRIMARY KEY or UNIQUE constraint
-- or it doe snot have any)

CREATE TABLE "users" (
    "id" SERIAL PRIMARY KEY,
    "username" VARCHAR UNIQUE
);

CREATE TABLE "comments" (
    "id" SERIAL PRIMARY KEY,
    "user_id" INTEGER, -- to reference user table id
    "content" TEXT
);

CREATE TABLE "comment_likes" (
    "user_id" INTEGER,
    "comment_id" INTEGER, -- to reference user table id
    PRIMARY KEY ("user_id", "comment_id")
);

INSERT INTO "users" ("username") VALUES ('user1'), ('user2');

-- HERE LIES THE PROBLEM: we are inserting comments from user that dont exist
INSERT INTO "comments" ("user_id", "content") VALUES
    (100, 'comment_text'), (-5, 'other comment text')

--: create FOREIGN KEY constraints on existing tables
ALTER TABLE "comments"
    ADD CONSTRAINT "constraint_name"
    FOREIGN KEY ("user_id") REFERENCES "users" ("id");

ALTER TABLE "comments_like"
    ADD CONSTRAINT "constraint_name"
    FOREIGN KEY ("comment_id") REFERENCES "users"; -- IF NO COLUMN IS SPECIFIED
                                                      -- reference primary key

--: specify FOREIGN KEY constraints on table creation
CREATE TABLE "comment_likes" (
    "user_id" INTEGER REFERENCES "users", -- Method 1
    "comment_id" INTEGER
    FOREIGN KEY ("comment_id") REFERENCES "comments" -- Method 2
)

/**********************************************************
--:FOREIGN KEY MODIFIERS
**********************************************************/

-- EXAMPLE: delete a user that has comments in the comment table
-- The constraint prevents you from doing it.
-- You may use modifiers to make this possible

-- EXAMPLES OF THINGS WE CAN DO WITH MODIFIERS
/*  "if a user deletes their account, then we want to keep all their comments,
  but simply dissociate them from the now deleted user". In practice, we could 
  achieve that by setting the user_id column of the comments table to NULL 
  everywhere where the value was the now deleted user account's ID */

/*"when a post gets deleted, we will also delete any comments that were created for that post". 
  In practice, we could do that in two steps by first deleting all the comments 
  targeting the post_id we want to delete, then deleting the post itself. */

--:examples of modifiers
--: cascade deletions
CREATE TABLE "comments" (
    "id" SERIAL PRIMARY KEY,
    "user_id" INTEGER REFERENCES "users" ("id") ON DELETE CASCADE, -- (the default is ON DELETE RESTRICT)
                                                -- When referenced data gets deleted, the
                                                -- referencing rows will be deleted as well
    "content" TEXT
);

--
--: set deletions to null
CREATE TABLE "comments" (
    "id" SERIAL PRIMARY KEY,
    "user_id" INTEGER REFERENCES "users" ("id") ON DELETE SET NULL, -- (the default is ON DELETE RESITRICT)
                                                -- When referenced data gets deleted, the
                                                -- rows will stay but the user will be set to NULL
    "content" TEXT
);
--
--:foreign key exercise:

-- When a manager is deleted, keep employee, set manager_id to null
ALTER TABLE "employees" ADD FOREIGN KEY ("manager_id") 
    REFERENCES "employees" ("id")
    ON DELETE SET NULL;

ALTER TABLE "employees" 
    ADD CONSTRAINT "valid_manager" -- name the constraint
    FOREIGN KEY ("manager_id") REFERENCES "employees" ("id")
    ON DELETE SET NULL;

-- Cannot delete an employee with projects assigned
ALTER TABLE "employee_projects" 
    ADD CONSTRAINT "valid_employee" -- name the constraint
    FOREIGN KEY ("employee_id") REFERENCES "employees" ("id")
    ON DELETE RESTRICT;

-- Project gets deleted --> no need to keep track of people
ALTER TABLE "employee_projects" 
    ADD CONSTRAINT "valid_project" -- name the constraint
    FOREIGN KEY ("project_id") REFERENCES "projects" ("id")
    ON DELETE CASCADE;

/**********************************************************
--:CHECK CONSTRAINS
**********************************************************/
-- Check constraints documentation:
https://www.postgresql.org/docs/9.6/ddl-constraints.html

-- Custom constraints
    -- Accept only positive numbers...
    -- Discount not greater than 5% the regular
    -- Employee cannot be their own manager...

--:check constraints examples
ALTER TABLE "items"
    ADD CONSTRAINT "non_negative_quantity" CHECK ("quantity" > 0);

ALTER TABLE "items"
    ADD CONSTRAINT "item_must_have_name" CHECK (LENGTH(TRIM("name")) > 0); -- for value different to NULL
                                                                           -- we would use a NOT NULL constraint
                                                                           -- TRIM removes white spaces

--:check constraints upon table creation
CREATE TABLE "items" (
    "id" SERIAL PRIMARY KEY,
    "name" VARCHAR NOT NULL CHECK (LENGTH(TRIM("name")) > 0),
    "quantity" INTEGER
 );

-- Given a table users with a date_of_birth column of type DATE, 
-- write the SQL to add a requirement for users to be at least 18 years old.
ALTER TABLE "users"
  ADD CONSTRAINT "users_must_be_over_18" CHECK (
    CURRENT_DATE - "date_of_birth" > INTERVAL '18 years'
  );

-- Final exercise on constraints
/* 
- Identify the primary key for each table
- Identify the unique constraints necessary for each table
- Identify the foreign key constraints necessary for each table
- In addition to the three types of constraints above, you'll have to implement some custom business rules:
    Usernames need to have a minimum of 5 characters
    A book's name cannot be empty
    A book's name must start with a capital letter
    A user's book preferences have to be distinct
 */

--:final constraints exercise
-- books table
ALTER TABLE "books" 
    ADD CONSTRAINT "books_pk" PRIMARY KEY ("id"),
    ADD CONSTRAINT "isbn_unique" UNIQUE ("isbn"),
    ADD CONSTRAINT "min_len_name" CHECK (LENGTH(TRIM("name")) > 0),
    ADD CONSTRAINT "capitalization" CHECK (LEFT(name, 1) = UPPER(LEFT(name, 1))),
    ALTER COLUMN "name" SET NOT NULL;
    
/* ALTER TABLE "books" ADD CONSTRAINT "isbn_unique" UNIQUE ("isbn");
ALTER TABLE "books" ADD CONSTRAINT "min_len_name" CHECK (LENGTH(TRIM("name")) > 0);
ALTER TABLE "books" ALTER COLUMN "name" SET NOT NULL;
ALTER TABLE "books" ADD CONSTRAINT "capitalization" CHECK (LEFT(name, 1) = UPPER(LEFT(name, 1))); */

-- users table
ALTER TABLE "users" 
    ADD CONSTRAINT "users_pk" PRIMARY KEY ("id"),
    ADD CONSTRAINT "unique_username" UNIQUE ("username"),
    ADD CONSTRAINT "min_len_username" CHECK (LENGTH(TRIM("username")) >= 5),
    ADD CONSTRAINT "unique_email" UNIQUE ("email");

/* ALTER TABLE "users" ADD CONSTRAINT "unique_username" UNIQUE ("username");
ALTER TABLE "users" ADD CONSTRAINT "min_len_username" CHECK (LENGTH(TRIM("username")) > 5);
ALTER TABLE "users" ADD CONSTRAINT "unique_email" UNIQUE ("email"); */

-- user_book_preferences table
ALTER TABLE "user_book_preferences" ADD CONSTRAINT "user_book_pk" PRIMARY KEY ("user_id", "book_id");

ALTER TABLE "user_book_preferences" 
    ADD CONSTRAINT "user_book_book_id_ref" 
    FOREIGN KEY ("book_id") REFERENCES "books" ("id")
    ON DELETE CASCADE;

ALTER TABLE "user_book_preferences" 
    ADD CONSTRAINT "user_book_user_id_ref" 
    FOREIGN KEY ("user_id") REFERENCES "users" ("id")
    ON DELETE CASCADE;

ALTER TABLE "user_book_preferences" 
    ADD CONSTRAINT "distinct_preferences"
    UNIQUE ("user_id", "preference");

