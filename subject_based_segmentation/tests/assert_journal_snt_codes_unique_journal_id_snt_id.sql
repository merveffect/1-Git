-- A singular test fails if it returns any rows.
SELECT journal_id, snt_id, COUNT(*) AS n
FROM {{ ref('journal_snt_codes') }}
GROUP BY journal_id, snt_id
HAVING COUNT(*) > 1
