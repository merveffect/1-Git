-- Raw pass-through of keyword reading-behaviour signals used only by the
-- favorite_snt project. 

SELECT
    snid,

    ARRAY_AGG(list_keywords_dois_last_60_d IGNORE NULLS)[SAFE_OFFSET(0)] AS keywords_last_60d

FROM {{ source('prod_audience_explorer_analytics_dbt_presentation', 'audience_builder_big') }}
WHERE snid IS NOT NULL
  AND (advertising_opt_in = TRUE OR mkt_pref_opt_in = TRUE OR is_legitimate_interest_author_opted_in = TRUE)
GROUP BY snid
