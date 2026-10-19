-- Long-format (snid, journal_id) pairs for the favorite_snt project, built
-- independently from favorite_mpc_subject/all_users_and_journals.sql.
-- Covers every journal-relationship signal on audience_builder_big (reads,
-- eTOCs, submission guide views, submissions, pageviews, "interested in"
-- lists) plus Snail's journal recommendations (a separate source, validated
-- 100% of its ids match real journal_metadata.journal_id as of 2026-09).

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
),

raw AS (
  SELECT
      snid,
      list_journals_read_last_30_d,
      list_journals_read_last_60_d,
      list_journals_etocs_last_180_d,
      list_journals_submguide_about_last_30_d,
      list_journals_submissions_alltime,
      list_journals_allpageviews_30_d,
      interested_journal_ids,
      interested_journal_ids_90
  FROM {{ source('prod_audience_explorer_analytics_dbt_presentation', 'audience_builder_big') }} ab
  WHERE ab.snid IS NOT NULL
    AND (ab.advertising_opt_in = TRUE OR ab.mkt_pref_opt_in = TRUE OR ab.is_legitimate_interest_author_opted_in = TRUE)
    AND NOT EXISTS (
      SELECT 1
      FROM {{ source('prod_mpc_dbt_presentation', 'snid_deletions') }} d
      WHERE d.snid = ab.snid
    )
),

unpivoted AS (
  SELECT snid, journal_id FROM raw, UNNEST(JSON_EXTRACT_STRING_ARRAY(list_journals_read_last_30_d)) AS journal_id
  UNION ALL
  SELECT snid, journal_id FROM raw, UNNEST(JSON_EXTRACT_STRING_ARRAY(list_journals_read_last_60_d)) AS journal_id
  UNION ALL
  SELECT snid, journal_id FROM raw, UNNEST(JSON_EXTRACT_STRING_ARRAY(list_journals_etocs_last_180_d)) AS journal_id
  UNION ALL
  SELECT snid, journal_id FROM raw, UNNEST(JSON_EXTRACT_STRING_ARRAY(list_journals_submguide_about_last_30_d)) AS journal_id
  UNION ALL
  SELECT snid, journal_id FROM raw, UNNEST(JSON_EXTRACT_STRING_ARRAY(list_journals_submissions_alltime)) AS journal_id
  UNION ALL
  SELECT snid, journal_id FROM raw, UNNEST(JSON_EXTRACT_STRING_ARRAY(list_journals_allpageviews_30_d)) AS journal_id
  UNION ALL
  SELECT snid, journal_id FROM raw, UNNEST(JSON_EXTRACT_STRING_ARRAY(interested_journal_ids)) AS journal_id
  UNION ALL
  SELECT snid, journal_id FROM raw, UNNEST(JSON_EXTRACT_STRING_ARRAY(interested_journal_ids_90)) AS journal_id
  UNION ALL
  SELECT snail.snid, rec.id AS journal_id
  FROM {{ source('prod_mdt_dbt_presentation', 'snail_recommendation_journals') }} snail
  JOIN target_snids USING (snid),
  UNNEST(snail.recommendations) AS rec
)

SELECT DISTINCT snid, journal_id
FROM unpivoted
WHERE journal_id IS NOT NULL
  AND TRIM(journal_id) != ''
  AND TRIM(journal_id) != '(not set)'
  AND TRIM(journal_id) != 'NULL'
