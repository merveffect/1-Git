-- Long-format (snid, collection_id, title, description) from Snail's
-- collection recommendations. Unlike journals, collections have no existing
-- SNT tagging, so title + description are carried through here to be
-- embedded downstream (distinct_collections / collection_embeddings).

WITH target_snids AS (
  SELECT snid
  FROM {{ source('prod_audience_explorer_analytics_dbt_presentation', 'audience_builder_big') }}
  WHERE snid IS NOT NULL
    AND (advertising_opt_in = TRUE OR mkt_pref_opt_in = TRUE)
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
