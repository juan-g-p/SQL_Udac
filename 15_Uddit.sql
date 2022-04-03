/********************************************************
USERS TABLE
********************************************************/

-- CREATE TABLE
CREATE TABLE "users" (
    "id" SERIAL,
    "username" VARCHAR(25),
    "last_login" TIMESTAMP -- TODO: Create index
);

-- CONSTRAINTS
-- Create constraints associated with the table users
ALTER TABLE "users" 
    ADD CONSTRAINT "users_pk" PRIMARY KEY ("id"),
    ALTER COLUMN "username" SET NOT NULL;

--INDEXES
-- Create a unique index instead of unique constraint because
-- unique index allows us to check expressions for case consistency.
CREATE UNIQUE INDEX "unique_user" ON "users" (LOWER(TRIM("username")));

-- Another alternative would have been to create a check constraint that
-- checked that LOWER(TRIM("username")) = "username" and subsequently
-- add an index and a unique constraint. Much more cumbersome.

-- Index to quickly inspect last login
CREATE INDEX "last_login_idx" ON "users" ("last_login");

/********************************************************
TOPICS TABLE
********************************************************/

-- CREATE TABLE
CREATE TABLE "topics" (
    "id" SERIAL,
    "topic" VARCHAR(30),
    "description" VARCHAR(500)
);

-- CONSTRAINTS
-- Create constraints associated with the table users
ALTER TABLE "topics" 
    ADD CONSTRAINT "topics_pk" PRIMARY KEY ("id"),
    ALTER COLUMN "topic" SET NOT NULL;

-- INDEXES
-- Create a unique index instead of unique constraint because
-- unique index allows us to check expressions for case consistency.
CREATE UNIQUE INDEX "unique_topic" ON "topics" (LOWER(TRIM("topic")));

/********************************************************
POSTS TABLE
********************************************************/

-- CREATE TABLE
CREATE TABLE "posts" (
    "id" SERIAL,
    "user_id" BIGINT,
    "topic_id" BIGINT,
    "title" VARCHAR(100),
    "url" VARCHAR,
    "content" TEXT
);

-- CONSTRAINTS
ALTER TABLE "posts"
    ADD CONSTRAINT "posts_pk" PRIMARY KEY ("id"),
    ADD CONSTRAINT "post_user_fk" FOREIGN KEY ("user_id") 
        REFERENCES "users" ("id")
        ON DELETE SET NULL,
    ADD CONSTRAINT "post_topic_fk" FOREIGN KEY ("topic_id") 
        REFERENCES "topics" ("id")
        ON DELETE CASCADE,
    ALTER COLUMN "title" SET NOT NULL,
    -- Constraint to check that at least one of 'url' or 'content' is not null,
    -- while the other one remains null
    ADD CONSTRAINT "url_content" CHECK(('url' IS NULL OR 'content' IS NULL) AND
                                       ('url' IS NOT NULL OR 'content' IS NOT NULL));


-- INDEXES
-- index for to allow for seaches and partial searches on url field:
CREATE INDEX "post_url_idx" ON "posts"("url" VARCHAR_PATTERN_OPS);

-- index for quick search on user_id:
CREATE INDEX "post_user_idx" ON "posts" ("user_id");

-- index for quick search on topic_id:
CREATE INDEX "post_topic_idx" ON "posts" ("topic_id");

/********************************************************
COMMENTS TABLE
********************************************************/

-- CREATE TABLE
CREATE TABLE "comments" (
    "id" SERIAL,
    "post_id" BIGINT,
    "parent_comment_id" BIGINT,
    "user_id" BIGINT,
    "content" TEXT
);

-- CONSTRAINTS
ALTER TABLE "comments"
    ADD CONSTRAINT "comments_pk" PRIMARY KEY ("id"),
    ADD CONSTRAINT "comment_post_fk" FOREIGN KEY ("post_id") 
        REFERENCES "posts" ("id")
        ON DELETE CASCADE,
    ADD CONSTRAINT "comment_parent_fk" FOREIGN KEY ("parent_comment_id") 
        REFERENCES "comments" ("id")
        ON DELETE CASCADE,
    ADD CONSTRAINT "comment_user_fk" FOREIGN KEY ("user_id") 
        REFERENCES "users" ("id")
        ON DELETE SET NULL,
    ALTER COLUMN "content" SET NOT NULL;

-- INDEXES
-- Index to list all comments where parent_comment_id IS NULL.
CREATE INDEX "comments_parent_idx" ON "comments" ("parent_comment_id");

-- Index to quick search by user_id.
CREATE INDEX "comments_user_idx" ON "comments" ("user_id");

/********************************************************
VOTES TABLE
********************************************************/

-- CREATE TABLE
CREATE TABLE "votes" (
    "id" SERIAL,
    "post_id" BIGINT,
    "user_id" BIGINT,
    "vote" SMALLINT
);

-- CONSTRAINTS
ALTER TABLE "votes"
    ADD CONSTRAINT "votes_pk" PRIMARY KEY ("id"),
    ADD CONSTRAINT "votes_post_fk" FOREIGN KEY ("post_id") 
        REFERENCES "posts" ("id")
        ON DELETE CASCADE,
    ADD CONSTRAINT "votes_user_fk" FOREIGN KEY ("user_id") 
        REFERENCES "users" ("id")
        ON DELETE SET NULL,
    ADD CONSTRAINT "vote_range" CHECK("vote" IN (-1,1));

-- INDEXES
-- Index to quickly search by post id:
CREATE INDEX "votes_post_id" ON "votes" ("user_id");

/********************************************************
POPULATE THE SCHEMA
********************************************************/