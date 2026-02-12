{{ config(
    materialized = "incremental",
    incremental_strategy="insert_overwrite",
    partition_by = {"field": "date","data_type": "date"},
    tags= ["daily", "j7", "ta_j7", "transposed_awa1", "transposed_bae", "transposed_nurture"]

)}}

SELECT
  a.* EXCEPT(JournalID),
  c.journal_title,
  -- from JFlow
  b.business_model,
  b.main_group,
  b.portfolio,
  -- portfolio only from sheet
  c.main_discipline,
  -- from JFlow
  COALESCE(SAFE_CAST(a.JournalID AS int64), b.journal_id) AS journal_id
FROM (
  SELECT
    * EXCEPT(Journal_ID___GA4__Google_Analytics),
    CASE
      WHEN Journal_ID___GA4__Google_Analytics IN ("(not set)|ghostery|false|(not+set)|(notset)") THEN "0"
      ELSE Journal_ID___GA4__Google_Analytics
  END
    AS JournalID
  FROM
    {{ref('b2c_googleanalytics_static')}}
   
    {{ incremental_date_filter('date') }}

    ) a
FULL JOIN (
  SELECT
    * EXCEPT(journal_title,
      main_discipline)
      -- drop sheet’s title & discipline
  FROM
   {{source('e2e_b2c_researcher_dev', 'journal_table') }} ) b
ON
  SAFE_CAST(a.JournalID AS int64) = b.journal_id
LEFT JOIN (
-- ensure 1 row per journal_id
  SELECT
    DISTINCT jf.journal_id,
    product_title as journal_title,
    m.marketing.main_discipline
  FROM
    {{source('xx_jflow','jflow') }} jf, unnest(marketing) as m  ) c
ON
  COALESCE(SAFE_CAST(a.JournalID AS int64), b.journal_id) = c.journal_id