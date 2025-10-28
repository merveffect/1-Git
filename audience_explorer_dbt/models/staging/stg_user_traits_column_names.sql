select
name as column_names
from {{ source('dev_audience_explorer_analytics_dbt_raw', 'user_traits_spreadsheet') }}
where lower(status) = '✅ keep'

