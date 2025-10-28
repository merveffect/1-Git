{{ config(
    materialized = "incremental",
    partition_by = {"field": "date"},
    cluster_by = ["clean_campaign", "country", "sub_channels"]
 )}}


SELECT
  *
FROM
  {{ref('j5')}} a
LEFT JOIN (
  SELECT
    DISTINCT * EXCEPT(channels_categories,
      programs,
      leading_product),
  FROM
    {{source('marmind_fnd','marmind_data')}} ) b
ON
  a.campaign_code = LOWER(b.marmind_campaign_code)
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
