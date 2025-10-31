-- back compat for old kwarg name
  
  
        
    

    

    merge into `dat-analytics-eng-ec869189`.`prod_audience_explorer_analytics_dbt_presentation`.`audience_builder_big_history` as DBT_INTERNAL_DEST
        using (
        select
        * from `dat-analytics-eng-ec869189`.`prod_audience_explorer_analytics_dbt_presentation`.`audience_builder_big_history__dbt_tmp`
        ) as DBT_INTERNAL_SOURCE
        on (FALSE)

    

    when not matched then insert
        (`canonical_segment_id`, `ingestion_timestamp`)
    values
        (`canonical_segment_id`, `ingestion_timestamp`)


    