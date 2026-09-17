{{ config(materialized='table') }}

-- Collection-based signal per user: confidence-weighted average embedding
-- across the user's recommended collections. Same weighting/averaging
-- approach as user_keyword_vector.sql: weight = 1 - nearest_snt distance
-- (floored at 0.05), grouped into a per-user array-of-structs first, then
-- averaged per-offset inside a per-row correlated subquery (avoids a
-- 768x row-explosion global shuffle).

WITH weighted AS (

    SELECT
        uc.snid,
        ce.embedding,
        GREATEST(1 - cc.distance, 0.05) AS weight
    FROM {{ ref('users_and_collections') }} uc
    JOIN {{ ref('collection_embeddings') }} ce ON uc.collection_id = ce.collection_id
    JOIN {{ ref('collection_snt_confidence') }} cc ON uc.collection_id = cc.collection_id

),

grouped AS (

    SELECT snid, ARRAY_AGG(STRUCT(embedding, weight)) AS items
    FROM weighted
    GROUP BY snid

)

SELECT
    snid,
    (
        SELECT ARRAY_AGG(w_avg ORDER BY off)
        FROM (
            SELECT off, SUM(val * item.weight) / SUM(item.weight) AS w_avg
            FROM UNNEST(items) AS item, UNNEST(item.embedding) AS val WITH OFFSET off
            GROUP BY off
        )
    ) AS embedding
FROM grouped
