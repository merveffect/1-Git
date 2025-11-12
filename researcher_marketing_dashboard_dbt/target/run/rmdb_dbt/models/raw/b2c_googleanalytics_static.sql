
  
    

    create or replace table `snproject-cbb9ca25`.`dev_rmdb_dbt_raw`.`b2c_googleanalytics_static`
      
    partition by date
    

    
    OPTIONS(
      description=""""""
    )
    as (
      

select
    *
from `snproject-cbb9ca25`.`ga4_ria_researcher_report`.`googleanalytics`


  WHERE date BETWEEN DATE('2024-01-01')
                  AND DATE('2025-11-09')

    );
  