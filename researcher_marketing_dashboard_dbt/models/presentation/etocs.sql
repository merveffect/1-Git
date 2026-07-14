{{ config(
    materialized = "incremental",
    incremental_strategy="insert_overwrite",
    partition_by = {"field": "etoc_date","data_type": "date"},
    tags= ["daily", "etocs"],
    require_partition_filter=true
 )}}

SELECT
  c.journal_id,
  c.journal_title,
  b.* EXCEPT(journal_id,
    journal_title,
    main_discipline),
  c.main_discipline,
  a.* EXCEPT(journal_id,
    journal_title)
FROM
  {{ref('etoc_4ria')}} a
LEFT JOIN
  {{source('e2e_b2c_researcher_dev','journal_table')}} b
ON
  SAFE_CAST(a.journal_id AS int64) = b.journal_id
LEFT JOIN (
-- ensure 1 row per journal_id from JFlow
  SELECT
    DISTINCT jf.journal_id,
    product_title as journal_title,
    m.marketing.main_discipline
  FROM
    {{source('xx_jflow','jflow')}} jf, unnest(marketing) as m ) c
ON
  COALESCE(SAFE_CAST(a.journal_id AS int64), b.journal_id) = c.journal_id


{{ incremental_date_filter('etoc_date') }}
