select
  column_name
  from {{ source('dev_audience_explorer_analytics_dbt_staging','INFORMATION_SCHEMA.COLUMNS')}}
  where table_name = 'stg_df_audience_explorer_cleaned'
