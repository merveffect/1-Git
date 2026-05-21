select 
snid, 
role, 
mkt_pref_opt_in,
is_legitimate_interest_author_opted_in,
advertising_opt_in,
list_article_title_from_readership,
list_article_title_from_view, 
list_keywords_dois_last_60_d,
count_submguidelines_last_30_d

from {{ source('prod_audience_explorer_analytics_dbt_presentation','audience_builder_big') }}