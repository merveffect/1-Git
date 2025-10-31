{{
  config(
    materialized = 'incremental',
    incremental_strategy = 'insert_overwrite',                
    partition_by = { 'field': 'date', 'data_type': 'date' },
    cluster_by   = ['source','medium','canvas_name','variant_name']
  )
}}

{% set target_date = var('target_date', "date_sub(current_date(), interval 2 day)") %}

with braze as (
Select
REPLACE(utm_campaign, ' ', '') AS clean_utm_campaign,
execution_date,
sum(email_sent) as email_sent,
sum(email_delivered) as email_delivered,
sum(email_bounced) as email_bounced,
sum(email_opened) as email_opened,
sum(email_unsubscribed) as email_unsubscribed,
sum(email_click) as email_click
from {{ref('stg_join_all_events')}}

{% if is_incremental() %}
  where execution_date = {{target_date}}
{% endif %}

group by 1,2 
),


ga as (
  Select
  REPLACE(clean_ga_campaign, ' ', '') as clean_ga_campaign,
  source,
  medium,
  date,
  marmind_campaign_code,
  product_code,
  audience_code,
  workspace_category,
  responsible_person,
  sum(sessions) as sessions,
  sum(kpi_reach_submission_guideline_pages) as kpi_reach_submission_guideline_pages,
  sum(pi_publishing_guidelines) as pi_publishing_guidelines,
  sum(submit_clicks) as submit_clicks,
  -- , sum(pi_ealert_click) as etoc_signups
  sum(reach_fta) as reach_fta,
  sum(contact_editor) as contact_editor,
  sum(kpi_marbl_leads) as kpi_marbl_leads,
  sum(ELS) as ELS,
  sum(search_volume) as search_volume,
  sum(content_consumption) as content_consumption,
  sum(reach_india_apc_thankyou) as reach_india_apc_thankyou,
  sum(journal_engagement) as journal_engagement,
  sum(research_article_readership) as research_article_readership,
  sum(source_readership) as source_readership

from {{ref('stg_aggregated_ga4_data')}}

{% if is_incremental() %}
  where date = {{target_date}}
{% endif %}

group by 1,2,3,4,5,6,7,8,9
) 

select 

COALESCE(braze.execution_date, ga.date) as date,
braze.* except (execution_date),
ga.* except (date),

SPLIT(braze.clean_utm_campaign, '_')[SAFE_OFFSET(6)] AS canvas_name,
SPLIT(braze.clean_utm_campaign, '_')[SAFE_OFFSET(7)] AS variant_name,
SPLIT(braze.clean_utm_campaign, '_')[SAFE_OFFSET(8)] AS step_name
from braze
full join ga
on braze.execution_date=ga.date
and braze.clean_utm_campaign=ga.clean_ga_campaign

{% if is_incremental() %}
  and braze.execution_date = {{target_date}}
  and ga.date = {{target_date}}
{% endif %}

--to backfill : dbt run -s join_braze_ga --vars 'target_date: "date(2025-08-10)"'