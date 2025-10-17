
  
    

    create or replace table `dat-analytics-eng-ec869189`.`dev_audience_explorer_analytics_dbt_staging`.`stg_user_traits_column_names`
        
  (
    column_names string
    
    )

      
    
    

    OPTIONS(
      description="""list of unique column names in user traits"""
    )
    as (
      
    select column_names
    from (
        select 

  distinct name as column_names

  from `dat-analytics-eng-ec869189`.`dev_audience_explorer_analytics_dbt_raw`.`raw_user_traits`
    ) as model_subq
    );
  