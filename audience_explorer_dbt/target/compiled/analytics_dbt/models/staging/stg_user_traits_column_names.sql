

select
name as column_names
from `dat-analytics-eng-ec869189`.`dev_audience_explorer_analytics_dbt_raw`.`user_traits_spreadsheet`
where lower(status) = '✅ keep'