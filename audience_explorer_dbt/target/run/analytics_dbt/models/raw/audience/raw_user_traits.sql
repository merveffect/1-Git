
  
    

    create or replace table `dat-analytics-eng-ec869189`.`dev_audience_explorer_analytics_dbt_raw`.`raw_user_traits`
      
    
    

    OPTIONS(
      description=""""""
    )
    as (
      select
  *
  from `cdp-data-55497fbb`.`cdp_profile_sync`.`user_traits`
    );
  