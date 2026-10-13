-- A singular test fails if it returns any rows.
SELECT snid, inferred_snt_id, COUNT(*) AS n
FROM {{ ref('favorite_snt_predictions') }}
GROUP BY snid, inferred_snt_id
HAVING COUNT(*) > 1
