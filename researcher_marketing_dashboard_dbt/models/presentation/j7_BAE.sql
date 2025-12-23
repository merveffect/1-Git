{{ config(
    materialized = "incremental",
    tags= ["daily", "j7", "ta_j7", "transposed_awa1", "transposed_bae", "transposed_nurture"],
    partition_by = {"field": "date"},
    cluster_by = ["clean_campaign", "country", "sub_channels"]
 )}}

SELECT
  date,
  campaign,
  clean_campaign,
  main_channels,
  sub_channels,
  country,
  goal_code,
  geo_code,
  main_discipline,
  main_group,
  portfolio,
  imprint,
  research_marketing_activity,
  workspace_category,
  sum(clicks) as clicks,
  sum(impressions) as impressions,
  sum(Sessions) as Sessions,
  sum(search_volume) as search_volume,
  sum(reach_b2c_blog_page) as reach_b2c_blog_page ,
  sum(source_readership) as source_readership ,
  sum(cost) as cost
  FROM
{{ref('j7')}}

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

group by 
  date,
  campaign,
  clean_campaign,
  main_channels,
  sub_channels,
  country,
  goal_code,
  geo_code,
  main_discipline,
  main_group,
  portfolio,
  imprint,
  research_marketing_activity,
  workspace_category