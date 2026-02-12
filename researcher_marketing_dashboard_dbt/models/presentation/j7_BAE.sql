{{ config(
    materialized = "incremental",
    incremental_strategy="insert_overwrite",
    tags= ["daily", "j7", "ta_j7", "transposed_awa1", "transposed_bae", "transposed_nurture"],
    partition_by = {"field": "date","data_type": "date"},
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

{{ incremental_date_filter('date') }}

group by ALL