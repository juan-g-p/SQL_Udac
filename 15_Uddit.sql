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
    -- Make sure that field does not contain empty space:
    ADD CONSTRAINT "username_nonempty" CHECK (LENGTH(TRIM("username")) > 0);

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
    -- Make sure that field does not contain empty space:
    ADD CONSTRAINT "topic_nonempty" CHECK (LENGTH(TRIM("topic")) > 0);

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
    -- Make sure that field does not contain empty space:
    ADD CONSTRAINT "post_title_nonempty" CHECK (LENGTH(TRIM("title")) > 0);
    -- Constraint to check that at least one of 'url' or 'content' is not null,
    -- while the other one remains null
    ADD CONSTRAINT "url_content" CHECK(("url" IS NULL OR "content" IS NULL) AND
                                       ("url" IS NOT NULL OR "content" IS NOT NULL));


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
    -- Make sure that field does not contain empty space:
    ADD CONSTRAINT "comment_nonempty" CHECK (LENGTH(TRIM("content")) > 0);

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

--TODO: vote por defecto en NULL??

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

TODO:UNION and UNION ALL
--:UNION AND UNION ALL
/*
-- Find all the different users to be inserted in the table
Users spread in columns "username" from tables bad_comments and bad_posts
*/

--Option 1: DISTINCT + UNION ALL
-- Added COUNT(*) to check that it ammounts to the same
SELECT COUNT(*) FROM(
    SELECT DISTINCT * FROM (
        SELECT "username" FROM bad_comments
        UNION ALL
        SELECT "username" FROM bad_posts
        UNION ALL
        -- Users that vote but do not create posts
        SELECT regexp_split_to_table("upvotes", ',') FROM bad_posts
        UNION ALL
        SELECT regexp_split_to_table("downvotes", ',') FROM bad_posts
    ) AS all_users
) AS count_users;

-- Option 2: UNION (instead of UNION ALL) -> removes repetitions
SELECT COUNT(*) FROM(
    SELECT * FROM (
        SELECT "username" FROM bad_comments
        UNION
        SELECT "username" FROM bad_posts
        UNION
        -- Users that vote but do not create posts
        SELECT regexp_split_to_table("upvotes", ',') FROM bad_posts
        UNION
        SELECT regexp_split_to_table("downvotes", ',') FROM bad_posts
    ) AS all_users
) AS count_users;

--: POPULATE USERS TABLE
INSERT INTO "users" ("username")
    SELECT * FROM (
        --UNION
        SELECT "username" FROM bad_comments
        UNION 
        SELECT "username" FROM bad_posts
        UNION
        -- Users that only vote but do not create posts
        SELECT regexp_split_to_table("upvotes", ',') FROM bad_posts
        UNION
        SELECT regexp_split_to_table("downvotes", ',') FROM bad_posts
    ) AS all_users;

--: POPULATE TOPICS TABLE
INSERT INTO "topics" ("topic")
    SELECT DISTINCT topic FROM bad_posts;

--: POPULATE POSTS TABLE
INSERT INTO "posts" ("id", "user_id", "topic_id", "title", "url", "content")
    SELECT bp.id, u.id, t.id, LEFT(bp.title, 100), bp.url, bp.text_content
    FROM bad_posts bp
    JOIN users u
        ON bp.username = u.username
    JOIN topics t
        ON bp.topic = t.topic;

--: POPULATE COMMENTS TABLE
INSERT INTO "comments" ("id", "post_id", "user_id", "content")

    SELECT bc.id, bc.post_id, u.id, bc.text_content
    FROM bad_comments bc
    JOIN users u
        ON bc.username = u.username;

--: POPULATE UPVOTES
INSERT INTO "votes" ("post_id", "user_id", "vote")

    -- table mapping post_ids to user voting up
    WITH upvotes AS (
        SELECT bo.id post_id, regexp_split_to_table(bp."upvotes", ',') username
        FROM bad_posts bp
    )

    SELECT up.post_id post_id, u.id user_id, 1 vote
    FROM upvotes up
    JOIN users u
        ON u.username = up.username;

--: FILL DOWNVOTES
INSERT INTO "votes" ("post_id", "user_id", "vote")

    -- table mapping post_ids to user voting down
    WITH downvotes AS (
        SELECT p.id post_id, regexp_split_to_table(bp."downvotes", ',') username
        FROM bad_posts bp
    )

    SELECT down.post_id post_id, u.id user_id, -1 vote
    FROM downvotes down
    JOIN users u
        ON u.username = down.username;