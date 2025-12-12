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
  world_region,
  product_code,
  goal_code,
  journal_id,
  journal_title,
  business_model,
  main_discipline,
  main_group,
  portfolio,
  imprint,
  journal_imprint,
  Sessions,
  EngagedSessions,
  ELS,
  kpi_submit_click,
  pi_reach_fta,
  kpi_reach_submission_guideline_pages,
  search_volume,
  journal_engagement,
  research_article_readership,
  source_readership,
  kpi_reach_about_pages,
  cost,
  clicks,
  impressions,
  research_marketing_activity,
  workspace_category,
  primary_campaign_goal
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
