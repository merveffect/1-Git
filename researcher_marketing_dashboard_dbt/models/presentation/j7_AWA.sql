{{ config(
    materialized = "incremental",
    incremental_strategy="insert_overwrite",
    tags= ["daily", "j7", "ta_j7","rmdb_j7_mart"],
    partition_by = {"field": "date","data_type": "date"},
    cluster_by = ["clean_campaign", "country", "sub_channels"],
    require_partition_filter=true
 )}}

select 
date,
campaign,
clean_campaign,
main_channels,
sub_channels,
country,
product_code,
goal_code,
campaign_code,
geo_code,
journal_title,
oatype,
journal_id,
business_model,
main_discipline,
main_group,
portfolio,
imprint,
workspace_category,
research_marketing_activity,
society_tier,
name_of_society,
new_launch,
sum(Sessions) as sessions,
sum(journal_engagement) as journal_engagement,
sum(research_article_readership) as research_article_readership,
sum(cost) as cost,
sum(video_views) as video_views,
sum(pi_reach_fta) as pi_reach_fta,
sum(search_volume) as search_volume,
sum(nav_sign_up_for_alerts) as nav_sign_up_for_alerts,
sum(signup_etoc) as signup_etoc
from 
{{ref('j7')}}

{{ incremental_date_filter('date') }}

group by ALL