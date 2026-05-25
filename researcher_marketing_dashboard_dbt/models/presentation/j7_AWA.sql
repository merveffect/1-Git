{{ config(
    materialized = "incremental",
    incremental_strategy="insert_overwrite",
    tags= ["daily", "j7", "ta_j7", "transposed_awa1", "transposed_bae", "transposed_nurture"],
    partition_by = {"field": "date","data_type": "date"},
    cluster_by = ["clean_campaign", "country", "sub_channels"]
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
signup_etoc,
sum(Sessions) as sessions,
sum(journal_engagement) as journal_engagement,
sum(research_article_readership) as research_article_readership,
sum(cost) as cost,
sum(pi_reach_fta) as pi_reach_fta,
sum(search_volume) as search_volume,
sum(nav_sign_up_for_alerts) as nav_sign_up_for_alerts
from 
{{ref('j7')}}

{{ incremental_date_filter('date') }}

group by ALL