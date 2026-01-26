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
  goal_code,
  oatype,
  journal_id,
  business_model,
  main_group,
  portfolio,
  imprint,
  workspace_category,
  researchER_marketing_activity,
  research_marketing_activity,
  SUM(Sessions) AS Sessions,
  SUM(ELS) AS ELS,
  SUM(snapp_submission_complete) AS snapp_submission_complete,
  SUM(snapp_submission_start) AS snapp_submission_start,
  SUM(kpi_submit_click) AS kpi_submit_click,
  SUM(kpi_reach_submission_guideline_pages) AS kpi_reach_submission_guideline_pages,
  SUM(kpi_reach_about_pages) AS kpi_reach_about_pages,
  SUM(journal_engagement) AS journal_engagement,
  SUM(ejp_submission_start) AS ejp_submission_start,
  SUM(ejp_submission_complete) AS ejp_submission_complete,
  SUM(cost) AS cost

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
