
/*
===============================================================================
Purpose
-------------------------------------------------------------------------------
Compare performance of queries on high-selectivity values (rating = 5)
between a table with and without an index, using deterministic data.

Scenario
  1. Create two tables: `reviews_with_index` and `reviews_without_index`.
  2. Insert the same 100,000 rows deterministically (80% rating = 5).
  3. Create index only on the `with_index` table.
  4. Analyze both tables.
  5. Run the same query and compare execution plans.
===============================================================================
*/

-- STEP 1: Drop both tables if they exist -------------------------------------
DROP TABLE IF EXISTS reviews_with_index;
DROP TABLE IF EXISTS reviews_without_index;

-- STEP 2: Create the two tables ----------------------------------------------
CREATE TABLE reviews_with_index (
    id     SERIAL PRIMARY KEY,
    rating INTEGER NOT NULL
);

CREATE TABLE reviews_without_index (
    id     SERIAL PRIMARY KEY,
    rating INTEGER NOT NULL
);

-- STEP 3: Create deterministic ratings and insert into a temp table ----------
CREATE TEMP TABLE biased_ratings AS
SELECT
    i,
    CASE
        WHEN i <= 80000 THEN 5
        ELSE (i % 4 + 1)
    END AS rating
FROM generate_series(1, 100000) AS s(i);

-- STEP 4: Insert the same data into both tables ------------------------------
INSERT INTO reviews_with_index (rating)
SELECT rating FROM biased_ratings;

INSERT INTO reviews_without_index (rating)
SELECT rating FROM biased_ratings;

-- STEP 5: Create index on the indexed table ----------------------------------
CREATE INDEX idx_reviews_rating ON reviews_with_index(rating);

-- STEP 6: Analyze both tables ------------------------------------------------
ANALYZE reviews_with_index;
ANALYZE reviews_without_index;

-- STEP 7: Query for high-frequency value (rating = 5) ------------------------
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM reviews_with_index WHERE rating = 5;

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM reviews_without_index WHERE rating = 5;
