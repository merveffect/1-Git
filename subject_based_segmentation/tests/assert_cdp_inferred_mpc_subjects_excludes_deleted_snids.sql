-- A singular test fails if it returns any rows.
-- Users in snid_deletions have asked for their data to be removed, so they
-- must never reach CDI through cdp_inferred_subjects.

SELECT c.snid
FROM {{ ref('cdp_inferred_mpc_subjects') }} c
WHERE EXISTS (
  SELECT 1
  FROM {{ source('prod_mpc_dbt_presentation', 'snid_deletions') }} d
  WHERE d.snid = c.snid
)
