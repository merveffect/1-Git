{{ config(
    materialized = "incremental",
    tags= ["daily", "j7", "ta_j7", "transposed_awa1", "transposed_bae", "transposed_nurture"],
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
  {% set backfill_start = var("backfill_start_date", none) %}
  {% set backfill_end = var("backfill_end_date", none) %}
  WHERE date BETWEEN 
    {% if backfill_start %}
      DATE('{{ backfill_start }}')
    {% else %}
      DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY)
    {% endif %}
    AND
    {% if backfill_end %}
      DATE('{{ backfill_end }}')
    {% else %}
      DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY)
    {% endif %}
{% else %}
  WHERE date BETWEEN DATE('{{ var("start_date", "2024-01-01") }}')
                  AND DATE('{{ var("end_date", "2025-12-31") }}')
{% endif %}
