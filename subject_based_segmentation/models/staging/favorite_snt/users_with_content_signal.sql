-- Raw pass-through of the article/DOI-level reading-behaviour signals used
-- only by the favorite_snt project. Article titles and newsletters were
-- dropped (article titles: 7.7M distinct values, too costly to embed for now
-- — on hold pending an article-level metadata/SNT table; newsletters: no
-- topical signal). DOI columns are kept staged but unused until we find a
-- DOI -> SNT metadata table. Journal ID lists live in users_and_journal_ids.

SELECT
    snid,

    ARRAY_AGG(list_keywords_dois_last_60_d IGNORE NULLS)[SAFE_OFFSET(0)] AS keywords_last_60d,
    ARRAY_AGG(list_doi_last_60_d IGNORE NULLS)[SAFE_OFFSET(0)] AS doi_last_60d,
    ARRAY_AGG(list_doi_last_90_d IGNORE NULLS)[SAFE_OFFSET(0)] AS doi_last_90d,
    ARRAY_AGG(list_doi_last_180_d IGNORE NULLS)[SAFE_OFFSET(0)] AS doi_last_180d

FROM {{ source('prod_audience_explorer_analytics_dbt_presentation', 'audience_builder_big') }}
WHERE snid IS NOT NULL
  AND (advertising_opt_in = TRUE OR mkt_pref_opt_in = TRUE)
GROUP BY snid
