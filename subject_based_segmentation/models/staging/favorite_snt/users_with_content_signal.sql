-- Raw pass-through of keyword reading-behaviour signals used only by the
-- favorite_snt project. 

-- ab is aliased so the snid_deletions subquery can qualify the outer
-- column. A bare `d.snid = snid` would bind snid to the subquery's own
-- table, making the condition always true and the filter a no-op.

SELECT
    ab.snid,

    ARRAY_AGG(ab.list_keywords_dois_last_60_d IGNORE NULLS)[SAFE_OFFSET(0)] AS keywords_last_60d

FROM {{ source('prod_audience_explorer_analytics_dbt_presentation', 'audience_builder_big') }} ab
WHERE ab.snid IS NOT NULL
  AND (ab.advertising_opt_in = TRUE OR ab.mkt_pref_opt_in = TRUE OR ab.is_legitimate_interest_author_opted_in = TRUE)
  AND NOT EXISTS (
    SELECT 1
    FROM {{ source('prod_mpc_dbt_presentation', 'snid_deletions') }} d
    WHERE d.snid = ab.snid
  )
GROUP BY ab.snid
