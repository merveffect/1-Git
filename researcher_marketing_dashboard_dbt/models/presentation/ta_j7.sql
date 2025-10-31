{{ config(
    materialized = "incremental",
    tags= ["daily", "ta_j7"],
    partition_by = {"field": "date"},
    cluster_by = ["journal_id", "country", "oatype", "researchER_marketing_activity"]
 )}} 

SELECT
  a.*,
  b.* EXCEPT(journal_id,
    journal_title),
  CASE
    WHEN researchER_marketing_activity = TRUE AND product_code != "oaagr" THEN "researcher marketing"
    WHEN product_code = "oaagr" THEN "OAAGR campaign traffic"
    ELSE "all other traffic"
END
  AS traffic_type_ta
FROM
  {{ref('j7')}} a
LEFT JOIN
  {{source('ga4_ria_researcher_report','transformative_agreements_sheet')}} b
ON
  a.journal_id = b.journal_id
   {% if is_incremental() %}
  WHERE date BETWEEN 
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
  WHERE date BETWEEN DATE('{{ var("start_date", "2024-01-01") }}')
                  AND DATE('{{ var("end_date", "2025-12-31") }}')
{% endif %}
