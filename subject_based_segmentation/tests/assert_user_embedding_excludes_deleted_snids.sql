-- A singular test fails if it returns any rows.
-- A user embedding is derived personal data: it encodes what someone reads.
-- Deleting their predictions while keeping their embedding would not be an
-- honest reading of a deletion request, so deleted users are filtered at the
-- staging entry to the pipeline and never reach this table.
--
-- This test is the proof on live data. It was a real gap: 10,530 deleted
-- users were sitting in user_embedding with full vectors, filtered out only
-- at the presentation layer.

SELECT e.snid
FROM {{ ref('user_embedding') }} e
JOIN {{ source('prod_mpc_dbt_presentation', 'snid_deletions') }} d
  ON d.snid = e.snid
