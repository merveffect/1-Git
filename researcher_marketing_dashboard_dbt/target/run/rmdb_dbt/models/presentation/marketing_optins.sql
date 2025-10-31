-- back compat for old kwarg name
  
  
        
    

    

    merge into `snproject-cbb9ca25`.`dbt_dev_ga4_ria_researcher_report`.`marketing_optins` as DBT_INTERNAL_DEST
        using (

SELECT
  date,
  b2cCntctOptin_actual
FROM
  `snproject-cbb9ca25`.`ga4_ria_researcher_report`.`optins_sheet`
        ) as DBT_INTERNAL_SOURCE
        on (FALSE)

    

    when not matched then insert
        (`date`, `b2cCntctOptin_actual`)
    values
        (`date`, `b2cCntctOptin_actual`)


    