WITH src AS (
  SELECT
    t.*,
    SAFE.PARSE_JSON(value) AS j
  FROM `dat-analytics-eng-ec869189`.`prod_audience_explorer_analytics_dbt_raw`.`raw_user_traits` AS t
  WHERE name = 'lifetime_aggregations'
),

payload AS (
  SELECT
    s.* EXCEPT(j),
    CASE
      WHEN JSON_VALUE(s.j, '$.all_imprints') IS NOT NULL
           AND SAFE.PARSE_JSON(JSON_VALUE(s.j, '$.all_imprints')) IS NOT NULL
        THEN SAFE.PARSE_JSON(JSON_VALUE(s.j, '$.all_imprints'))
      WHEN JSON_QUERY(s.j, '$.all_imprints') IS NOT NULL
        THEN SAFE.PARSE_JSON(TO_JSON_STRING(JSON_QUERY(s.j, '$.all_imprints')))
      ELSE NULL
    END AS ai
  FROM src AS s
)
SELECT
  p.canonical_segment_id,

  CAST(JSON_VALUE(p.ai, '$.total_accepts')        AS INT64) AS total_accepts,
  CAST(JSON_VALUE(p.ai, '$.total_rejects')        AS INT64) AS total_rejects,
  CAST(JSON_VALUE(p.ai, '$.total_oa_submissions') AS INT64) AS total_oa_submissions,
  CAST(JSON_VALUE(p.ai, '$.total_submissions')    AS INT64) AS total_submissions
FROM payload p