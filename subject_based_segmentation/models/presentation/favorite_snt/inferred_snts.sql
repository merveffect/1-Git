{{ config(materialized='table') }}

-- Final output for the CDI pipeline. Straight reshape of the already fully
-- computed favorite_snt_predictions — no batching/looping needed here,
-- this is a cheap passthrough of existing data, not a VECTOR_SEARCH.
--
-- favorite_rank is published because the ranking is the product: rank 1 is
-- the user's strongest topic and rank 10 the weakest, and measured against
-- real opted-in subjects the hit rate falls from 55.0% at rank 1 to 46.9% at
-- rank 10. BigQuery tables have no inherent row order, so a consumer that
-- aggregates these rows (CDI does an array_agg per email) MUST sort by
-- favorite_rank or the ranking is silently lost and "the top 3" becomes a
-- random 3.
--
-- The snid_deletions filter mirrors favorite_mpc_subject/
-- cdp_inferred_mpc_subjects.sql, so both pipelines feeding CDI honour
-- deletion requests the same way. favorite_snt_predictions also clears
-- deleted users in a post_hook, so this is belt and braces: it keeps CDI
-- clean even in the window between a deletion landing in the source and
-- the next predictions run.
--
-- CONTRACT: table name (inferred_snts) and column names (inferred_snt_id,
-- inferred_snt_name) are the agreed interface for CDI. The integration is
-- not live yet, but the names were chosen with that team — do not rename
-- without coordinating with them first.

WITH deleted AS (
  SELECT snid
  FROM {{ source('prod_mpc_dbt_presentation', 'snid_deletions') }}
)

SELECT
    p.snid,
    p.inferred_snt_id,
    p.inferred_snt_name,
    p.favorite_rank
FROM {{ ref('favorite_snt_predictions') }} p
LEFT JOIN deleted USING (snid)
WHERE deleted.snid IS NULL
