-- back compat for old kwarg name
  
  
        
    

    

    merge into `dat-analytics-eng-ec869189`.`dev_audience_explorer_analytics_dbt_staging`.`stg_user_traits_column_names_history` as DBT_INTERNAL_DEST
        using (
        select
        * from `dat-analytics-eng-ec869189`.`dev_audience_explorer_analytics_dbt_staging`.`stg_user_traits_column_names_history__dbt_tmp`
        ) as DBT_INTERNAL_SOURCE
        on (FALSE)

    

    when not matched then insert
        (`column_names`, `ingestion_timestamp`)
    values
        (`column_names`, `ingestion_timestamp`)


    