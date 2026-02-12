{{ config(
    materialized = "incremental",
    incremental_strategy="insert_overwrite",
    tags= ["daily", "ta_j7"],
    partition_by = {"field": "date","data_type": "date"},
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

{{ incremental_date_filter('date') }}

