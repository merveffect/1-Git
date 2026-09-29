SELECT
    snid,

    -- multi-valued signals kept as-is (we unnest later in resolved)
    ARRAY_AGG(list_journals_read_last_30_d IGNORE NULLS)[SAFE_OFFSET(0)]  AS read_last_30d,
    ARRAY_AGG(list_journals_read_last_60_d IGNORE NULLS)[SAFE_OFFSET(0)]  AS read_last_60d,
    ARRAY_AGG(list_journals_etocs_last_180_d IGNORE NULLS)[SAFE_OFFSET(0)] AS journals_etocs_180d,
    ARRAY_AGG(list_journals_submguide_about_last_30_d IGNORE NULLS)[SAFE_OFFSET(0)] AS journals_submguide_last_30d,
    ARRAY_AGG(list_journals_submissions_alltime IGNORE NULLS)[SAFE_OFFSET(0)]  AS journals_subm_alltime,
    ARRAY_AGG(list_journals_etocs_last_180_d IGNORE NULLS)[SAFE_OFFSET(0)]  AS list_journal_etocs_last_180_d,
    ARRAY_AGG(list_journals_allpageviews_30_d IGNORE NULLS)[SAFE_OFFSET(0)]  AS list_journals_allpageviews_30_d,
    
    

  FROM {{source('prod_audience_explorer_analytics_dbt_presentation', 'audience_builder_big') }}
  WHERE snid IS NOT NULL
  GROUP BY snid


