
  
    

    create or replace table `dat-analytics-eng-ec869189`.`dev_audience_explorer_analytics_dbt_raw`.`raw_information_schema_columns`
      
    
    

    OPTIONS(
      description=""""""
    )
    as (
      select
  column_name
  from `dat-analytics-eng-ec869189`.`dev_audience_explorer_analytics_dbt_staging`.`INFORMATION_SCHEMA.COLUMNS`
  where table_name = 'stg_df_audience_explorer_cleaned'
    );
  