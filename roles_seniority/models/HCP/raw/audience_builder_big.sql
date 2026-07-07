select 
snid, 
role, 
list_article_title_from_readership,
list_article_title_from_view, 
list_keywords_dois_last_60_d,
count_submguidelines_last_30_d,
mkt_pref_opt_in,
advertising_opt_in

from {{ source('prod_audience_explorer_analytics_dbt_presentation','audience_builder_big') }}