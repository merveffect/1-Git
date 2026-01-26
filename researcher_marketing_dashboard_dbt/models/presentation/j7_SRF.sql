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
  research_marketing_activity,
  workspace_category,
  primary_campaign_goal,
  SUM(Sessions) AS Sessions,
  SUM(EngagedSessions) AS EngagedSessions,
  SUM(ELS) AS ELS,
  SUM(kpi_submit_click) AS kpi_submit_click,
  SUM(pi_reach_fta) AS pi_reach_fta,
  SUM(kpi_reach_submission_guideline_pages) AS kpi_reach_submission_guideline_pages,
  SUM(search_volume) AS search_volume,
  SUM(journal_engagement) AS journal_engagement,
  SUM(research_article_readership) AS research_article_readership,
  SUM(source_readership) AS source_readership,
  SUM(kpi_reach_about_pages) AS kpi_reach_about_pages,
  SUM(cost) AS cost,
  SUM(clicks) AS clicks,
  SUM(impressions) AS impressions

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

group by ALL
