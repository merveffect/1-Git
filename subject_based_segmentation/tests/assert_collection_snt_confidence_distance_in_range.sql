-- A singular test fails if it returns any rows.
-- Cosine distance is only valid in [0, 2] — anything outside that range
-- means something went wrong in the VECTOR_SEARCH computation upstream.

SELECT *
FROM {{ ref('collection_snt_confidence') }}
WHERE distance < 0 OR distance > 2
