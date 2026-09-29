-- A singular test fails if it returns any rows.
SELECT snid, inferred_snt_id, COUNT(*) AS n
FROM {{ ref('inferred_snts') }}
GROUP BY snid, inferred_snt_id
HAVING COUNT(*) > 1
