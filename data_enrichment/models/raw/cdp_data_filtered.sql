select * from 
{{source('prod_audience_explorer_analytics_dbt_presentation', 'audience_builder_big')}}
WHERE 
is_legitimate_interest = true --OR mkt_pref_opt_in = true

