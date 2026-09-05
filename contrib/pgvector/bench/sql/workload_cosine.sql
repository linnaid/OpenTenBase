-- Cosine distance workload for pgbench.

-- This file is intended to be executed by pgbench with the -f option.
-- The benchmark runner must provide the following variables with -D.
-- query_count: number of query vectors available in the benchmark table.
-- top_k: number of nearest neighbors returned by each query.
-- probes: number of IVFFlat lists probed by each query.

-- Example:

-- pgbench \
--     -n \
--     -M simple \
--     -c 1 \
--     -j 1 \
--     -T 10 \
--     -D query_count=100 \
--     -D top_k=10 \
--     -D probes=2 \
--     -f sql/workload_cosine.sql \
--     pgvector_bench



\set query_id random(1, :query_count)

-- Keep transaction-local settings active for the nearest-neighbor query.

BEGIN;


SET LOCAL ivfflat.probes = :probes;

SET LOCAL enable_seqscan = off;

-- Enable ordinary index scans for the IVFFlat access path.
SET LOCAL enable_indexscan = on;

-- Disable bitmap scans because they are not the target access path here.
SET LOCAL enable_bitmapscan = off;

-- Execute one cosine-distance nearest-neighbor query for the selected query vector.
-- The <=> operator returns cosine distance, where smaller values are closer.
-- The ORDER BY expression must match the IVFFlat operator class.

SELECT
    neighbor.item_id,
    neighbor.distance
FROM vector_bench.queries AS query_vector
CROSS JOIN LATERAL
(
    SELECT
        item.id AS item_id,
        item.embedding <=> query_vector.embedding AS distance
    FROM vector_bench.items AS item
    ORDER BY item.embedding <=> query_vector.embedding
    LIMIT :top_k
) AS neighbor
WHERE query_vector.id = :query_id;


COMMIT;
