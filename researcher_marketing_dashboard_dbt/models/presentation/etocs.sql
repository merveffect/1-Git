{{ config(
    materialized = "incremental",
    partition_by = {"field": "etoc_date"},
    tags= ["daily", "etocs"]
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
  {% if is_incremental() %}
  WHERE etoc_date BETWEEN 
        COALESCE(
          DATE('{{ var("backfill_start_date", "") }}') ,
          DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY)
        )
        AND
        COALESCE(
          DATE('{{ var("backfill_end_date", "") }}') ,
          DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY)
        )
{% else %}
  WHERE etoc_date BETWEEN DATE('{{ var("start_date", "2024-01-01") }}')
                  AND DATE('{{ var("end_date", "2025-12-31") }}')
{% endif %}
