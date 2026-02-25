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
  campaign_code,
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

{{ incremental_date_filter('date') }}

group by ALL
