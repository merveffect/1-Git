-- A singular test fails if it returns any rows.
SELECT snid, snt_id, COUNT(*) AS n
FROM {{ ref('favorite_snt_predictions') }}
GROUP BY snid, snt_id
HAVING COUNT(*) > 1
