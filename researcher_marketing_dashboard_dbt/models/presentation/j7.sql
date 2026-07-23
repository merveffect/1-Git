{{ config(
    materialized = "incremental",
    incremental_strategy="insert_overwrite",
    tags= ["daily", "j7", "ta_j7", "transposed_awa1", "rmdb_j7_mart"],
    partition_by = {"field": "date","data_type": "date"},
    cluster_by = ["clean_campaign", "country", "sub_channels"],
    require_partition_filter=true

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
  signup_etoc,
  cost,
  clicks,
  impressions,
  video_views,
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
  workspace_category,
  workspace_name,
  primary_campaign_goal,
  marmind_campaign_code,
  description,
  society_tier,
  name_of_society,
  excl_marketing_restricted_by_society

FROM
  {{ref('j5')}} a
LEFT JOIN (
  SELECT
    DISTINCT *
  FROM
    {{source('prod_marmind_presentation','marmind_analytics')}} ) b
ON
  a.campaign_code = LOWER(b.marmind_campaign_code)

LEFT JOIN 
( select distinct journal_id as braze_journal_id,
society_tier,
name_of_society,
excl_marketing_restricted_by_society 
from 
{{source('prod_cdi_presentation','journal_catalog')}} ) c 

ON a.journal_id=c.braze_journal_id

  {{ incremental_date_filter('date') }}

