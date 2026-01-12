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
  SOURCE,
  medium,
  main_channels,
  sub_channels,
  country,
  isoalphatwo,
  world_region,
  audience_code,
  product_code,
  goal_code,
  campaign_code,
  geo_code,
  team_code,
  products,
  journal_title,
  oatype,
  journal_id,
  business_model,
  main_discipline,
  main_group,
  portfolio,
  imprint,
  journal_imprint,
  engagement_rate,
  kpi_marbl_leads,
  Sessions,
  pi_publishing_guidelines,
  EngagedSessions,
  ELS,
  snapp_submission_complete,
  content_consumption,
  reach_india_apc_thankyou,
  reach_oa_general,
  snapp_submission_start,
  kpi_submit_click,
  pi_reach_fta,
  kpi_reach_submission_guideline_pages,
  kpi_reach_about_pages,
  pi_contact_an_editor,
  kpi_submit_your_book_idea,
  reach_b2c_blog_page,
  ta_file_download,
  search_volume,
  journal_engagement,
  research_article_readership,
  source_readership,
  ejp_submission_start,
  ejp_submission_complete,
  nav_sign_up_for_alerts,
  cost,
  clicks,
  impressions,
  researchER_marketing_activity,
  research_marketing_activity,
  naming_convention_correct,
  nature_grp,
  is_oax,
  id,
  status,
  campaign_category,
  name,
  responsible_person,
  target_audience_name,
  validity_from,
  validity_to,
  archived,
  workspace_category,
  workspace_name,
  primary_campaign_goal,
  marmind_campaign_code,
  description
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
