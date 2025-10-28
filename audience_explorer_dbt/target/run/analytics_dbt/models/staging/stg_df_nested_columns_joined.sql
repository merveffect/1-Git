
  
    

    create or replace table `dat-analytics-eng-ec869189`.`dev_audience_explorer_analytics_dbt_staging`.`stg_df_nested_columns_joined`
      
    
    

    
    OPTIONS(
      description=""""""
    )
    as (
      WITH base AS (
    SELECT *
    FROM `dat-analytics-eng-ec869189`.`dev_audience_explorer_analytics_dbt_staging`.`stg_df_audience_explorer_base`
),
subs AS (
    SELECT * 
    FROM `dat-analytics-eng-ec869189`.`dev_audience_explorer_analytics_dbt_staging`.`stg_submissions`
),
life AS (
    SELECT * 
    FROM `dat-analytics-eng-ec869189`.`dev_audience_explorer_analytics_dbt_staging`.`stg_lifetime_aggregations`
)

SELECT
    base.*,
    subs.* EXCEPT(canonical_segment_id),
    life.* EXCEPT(canonical_segment_id)
FROM base
LEFT JOIN subs USING (canonical_segment_id)
LEFT JOIN life USING (canonical_segment_id)
    );
  