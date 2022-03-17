CREATE TABLE "movies" (
    "id" SERIAL PRIMARY KEY,
    "title" VARCHAR(500), -- The reason for the limit
                          -- is the path of data. The raltional data base is going to be
                          -- the source of truth.
                          -- The VARCHAR without limit can hold up to 1GB of data. This could lead
                          -- to system abuse, for it to store 
                          -- The longest movie title ever existed was 197 character longs
    "description" TEXT    -- We will need to check in other parts of our app that this is not abused in
                          -- the same manner
);

CREATE TABLE "categories" (
    "id" SERIAL PRIMARY KEY,
    "category" VARCHAR(50) UNIQUE
);

CREATE TABLE "movies_categories" (
    "movie_id" INTEGER,
    "category_id" INTEGER,
    CONSTRAINT "movie_fk" FOREIGN KEY ("movie_id") 
        REFERENCES "movies" ("id")
        ON DELETE CASCADE,
    CONSTRAINT "category_fk" FOREIGN KEY ("category_id") 
        REFERENCES "categories" ("id")
        ON DELETE CASCADE,
    CONSTRAINT "pk" PRIMARY KEY ("movie_id", "category_id") 
);

CREATE TABLE "users" (
    "id" SERIAL,
    "username" VARCHAR(100) NOT NULL,
    CONSTRAINT "mov_cat_pk" PRIMARY KEY ("id")
);

-- Ensure that users do not differ by capitalization. This creates an index
-- at the same time, which is another of our requirements. We use unique inde
-- plus an expression

-- Another alternative would have been to create a check constraint that
-- checked that LOWER(TRIM("username")) = "username" and subsequently
-- add an index and a unique constraint. Much more cumbersome.
CREATE UNIQUE INDEX "unique_username" ON "users" (LOWER(TRIM("username")));

CREATE TABLE "user_categories" (
    "user_id" INTEGER,
    "category_id" INTEGER
    CONSTRAINT "user_cats_cat_pk" PRIMARY KEY ("user_id", "category_id"),
    CONSTRAINT "user_cats_fk" FOREIGN KEY ("user_id") 
        REFERENCES "users" ("id")
        ON DELETE CASCADE,
    CONSTRAINT "category_fk" FOREIGN KEY ("category_id") 
        REFERENCES "categories" ("id")
        ON DELETE CASCADE
);

CREATE TABLE "users_movies" (
    "user_id" INTEGER,
    "movie_id" INTEGER,
    "rating" SMALLINT,
    CONSTRAINT "rating_range" CHECK ("rating" BETWEEN 0 and 10),
    CONSTRAINT "user_movs_pk" PRIMARY KEY ("user_id", "movie_id"),
    CONSTRAINT "user_movs_user_fk" FOREIGN KEY ("user_id") 
        REFERENCES "users" ("id")
        ON DELETE CASCADE,
    CONSTRAINT "user_movs_movie_fk" FOREIGN KEY ("movie_id") 
        REFERENCES "movies" ("id")
        ON DELETE CASCADE
);

-- Partial search on movie titles
CREATE INDEX "movie_title_idx" ON "movies"(
    LOWER("title") VARCHAR_PATTERN_OPS
    )

-- For a given movie, find all its ratings and users who rated quickly
CREATE INDEX "movie_users_rating" ON "users_movies" ("movie_id");

-- For a given category, find all the users who like them
CREATE INDEX "category_users" ON "user_categories" ("category_id");


--:ALTERNATIVE SOLUTION

The condition of quick partial search is missing 

CREATE TABLE "movies" (
  "id" SERIAL PRIMARY KEY,
  "title" VARCHAR(500), --  Night of the Day of the Dawn of the Son of the Bride of the Return of the Revenge of the Terror of the Attack of the Evil, Mutant, Hellbound, Flesh-Eating Subhumanoid Zombified Living Dead, Part 3
  "description" TEXT
);


CREATE TABLE "categories" (
  "id" SERIAL PRIMARY KEY,
  "name" VARCHAR(50) UNIQUE
);

CREATE TABLE "movie_categories" (
  "movie_id" INTEGER REFERENCES "movies",
  "category_id" INTEGER REFERENCES "categories",
  PRIMARY KEY ("movie_id", "category_id")
);

CREATE TABLE "users" (
  "id" SERIAL PRIMARY KEY,
  "username" VARCHAR(100),
);
CREATE UNIQUE INDEX ON "users" (LOWER("username"));

CREATE TABLE "user_movie_ratings" (
  "user_id" INTEGER REFERENCES "users",
  "movie_id" INTEGER REFERENCES "movies",
  "rating" SMALLINT CHECK ("rating" BETWEEN 0 AND 100),
  PRIMARY KEY ("user_id", "movie_id")
);
CREATE INDEX ON "user_movie_ratings" ("movie_id");

CREATE TABLE "user_category_likes" (
  "user_id" INTEGER REFERENCES "users",
  "category_id" INTEGER REFERENCES "categories",
  PRIMARY KEY ("user_id", "category_id")
);
CREATE INDEX ON "user_category_likes" ("category_id");