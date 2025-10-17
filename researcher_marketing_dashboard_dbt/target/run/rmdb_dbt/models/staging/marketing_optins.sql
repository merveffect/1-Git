
  
    

    create or replace table `snproject-cbb9ca25`.`dbt_dev_ga4_ria_researcher_report`.`marketing_optins`
      
    
    

    
    OPTIONS(
      description=""""""
    )
    as (
      

SELECT
  date,
  b2cCntctOptin_actual
FROM
  `snproject-cbb9ca25`.`dbt_dev_ga4_ria_researcher_report`.`optins_sheet`
    );
  