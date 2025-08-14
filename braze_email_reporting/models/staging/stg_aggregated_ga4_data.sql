select
campaign as ga_campaign,
REPLACE(campaign, ' ', '') AS clean_ga_campaign, 
source as source,
medium as medium,
date as date,
marmind_campaign_code as marmind_campaign_code,
product_code as product_code,
goal_code as goal_code,
audience_code as audience_code,
workspace_category as workspace_category,
responsible_person as responsible_person,
sum(sessions) as sessions,
sum(kpi_reach_submission_guideline_pages) as kpi_reach_submission_guideline_pages,
sum(pi_publishing_guidelines) as pi_publishing_guidelines,
sum(kpi_submit_click) as submit_clicks,
-- , sum(pi_ealert_click) as etoc_signups
sum(pi_reach_fta) as reach_fta,
sum(pi_contact_an_editor) as contact_editor,
sum(kpi_marbl_leads) as kpi_marbl_leads,
sum(ELS) as ELS,
sum(search_volume) as search_volume,
sum(content_consumption) as content_consumption,
sum(reach_india_apc_thankyou) as reach_india_apc_thankyou,
sum(journal_engagement) as journal_engagement,
sum(research_article_readership) as research_article_readership,
sum(source_readership) as source_readership

from {{ ref('raw_j7') }}
where date>= '2025-05-01'
and medium = "email"
and source='braze'
group by 1,2,3,4,5,6,7,8,9,10,11
