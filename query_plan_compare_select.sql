
/*
===============================================================================
Purpose
-------------------------------------------------------------------------------
Demonstrate—step by step—how PostgreSQL actually leverages a B‑tree index
during query execution and how to verify that usage with
EXPLAIN (ANALYZE, BUFFERS).

Scenario
  1. Create two identical tables: `users_with_index`, `users_without_index`.
  2. Insert 100,000 rows into both with identical content.
  3. Create a B-tree index only on `users_with_index.email`.
  4. Run a selective query on both and compare execution plans and performance.
===============================================================================
*/

-- STEP 1: Drop tables if they exist ------------------------------------------
DROP TABLE IF EXISTS users_with_index;
DROP TABLE IF EXISTS users_without_index;

-- STEP 2: Create both tables -------------------------------------------------
CREATE TABLE users_with_index (
    id SERIAL PRIMARY KEY,
    email TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT now()
);

CREATE TABLE users_without_index (
    id SERIAL PRIMARY KEY,
    email TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT now()
);

-- STEP 3: Generate the same dataset ------------------------------------------
CREATE TEMP TABLE user_data AS
SELECT
    i,
    'user' || i || '@example.com' AS email
FROM generate_series(1, 100000) AS s(i);

-- STEP 4: Insert identical data into both tables -----------------------------
INSERT INTO users_with_index (email)
SELECT email FROM user_data;

INSERT INTO users_without_index (email)
SELECT email FROM user_data;

-- STEP 5: Create index only on the indexed table -----------------------------
CREATE INDEX idx_users_email ON users_with_index(email);

-- STEP 6: Analyze both tables ------------------------------------------------
ANALYZE users_with_index;
ANALYZE users_without_index;

-- STEP 7: Compare execution with and without index ---------------------------
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM users_without_index
WHERE email = 'user50000@example.com';

EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM users_with_index
WHERE email = 'user50000@example.com';
