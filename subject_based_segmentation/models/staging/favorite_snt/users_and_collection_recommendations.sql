-- Long-format (snid, collection_id, title, description) from Snail's
-- collection recommendations. Unlike journals, collections have no existing
-- SNT tagging, so title + description are carried through here to be
-- embedded downstream (distinct_collections / collection_embeddings).

WITH target_snids AS (
  SELECT ab.snid
  FROM {{ source('prod_audience_explorer_analytics_dbt_presentation', 'audience_builder_big') }} ab
  WHERE ab.snid IS NOT NULL
    AND (ab.advertising_opt_in = TRUE OR ab.mkt_pref_opt_in = TRUE OR ab.is_legitimate_interest_author_opted_in = TRUE)
    AND NOT EXISTS (
      SELECT 1
      FROM {{ source('prod_mpc_dbt_presentation', 'snid_deletions') }} d
      WHERE d.snid = ab.snid
    )
)

SELECT DISTINCT
  snail.snid,
  rec.id AS collection_id,
  rec.title,
  rec.description
FROM {{ source('prod_mdt_dbt_presentation', 'snail_recommendation_collections') }} snail
JOIN target_snids USING (snid),
UNNEST(snail.recommendations) AS rec
WHERE rec.id IS NOT NULL
