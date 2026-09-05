-- Initialize the vector benchmark environment.

-- Drop the previous benchmark schema.
-- Only vector_bench is removed; other database schemas are not affected.
DROP SCHEMA IF EXISTS vector_bench CASCADE;

CREATE SCHEMA vector_bench;

--Install the pgvector extension.

CREATE EXTENSION IF NOT EXISTS vector;

--Install the pgvector extension.

CREATE EXTENSION IF NOT EXISTS pg_prewarm;


-- Create the table containing searchable item vectors.

-- :dimensions is supplied by prepare_dataset.sh through psql -v.
-- Example:
--      vector(:dimensions)
--      vector(32)
CREATE TABLE vector_bench.items
(
    id bigint PRIMARY KEY,

    embedding vector(:dimensions) NOT NULL,

    CONSTRAINT items_embedding_dimensions_check
            CHECK (vector_dims(embedding) = :dimensions),

    CONSTRAINT items_id_positive_check
            CHECK (id > 0)
);


-- Create the table containing query vectors.
CREATE TABLE vector_bench.queries
(
    id bigint PRIMARY KEY,

    embedding vector(:dimensions) NOT NULL,

    CONSTRAINT queries_embedding_dimensions_check
            CHECK (vector_dims(embedding) = :dimensions),

    CONSTRAINT queries_id_positive_check
            CHECK (id > 0)
);


-- Create the ground-truth table for exact nearest-neighbor search.

-- Each row represents one exact result for one query and one metric.
CREATE TABLE vector_bench.truth
(
    -- Three distance metrics are currently supported.
    metric text NOT NULL,
    query_id bigint NOT NULL,
    item_id bigint NOT NULL,
    rank integer NOT NULL,

    CONSTRAINT truth_primary_key
            PRIMARY KEY (metric, query_id, rank),

    CONSTRAINT truth_mertic_key
            CHECK (metric IN ('l2', 'ip', 'cosine')),

    CONSTRAINT truth_query_id_positive_check
            CHECK (query_id > 0),

    CONSTRAINT truth_item_id_positive_check
            CHECK (item_id > 0),
    
    CONSTRAINT truth_rank_positive_check
            CHECK (rank > 0),

    CONSTRAINT truth_item_unique_per_query
            UNIQUE (metric, query_id, item_id),

    CONSTRAINT truth_query_foreign_key
            FOREIGN KEY (query_id)
            REFERENCES vector_bench.queries (id),

    CONSTRAINT truth_item_foreign_key
            FOREIGN KEY (item_id)
            REFERENCES vector_bench.items (id)
);

-- Add an auxiliary index for ground-truth lookups.
CREATE INDEX truth_lookup_idx
    ON vector_bench.truth (metric, query_id, item_id);