
  
    

    create or replace table `dat-analytics-eng-ec869189`.`prod_audience_explorer_analytics_dbt_staging`.`stg_df_audience_explorer_cleaned`
      
    
    

    
    OPTIONS(
      description=""""""
    )
    as (
      

SELECT

  * EXCEPT(advertising_opt_in, mkt_pref_opt_in, subjects, list_keywords_dois_last_60_d),


  NULLIF(advertising_opt_in, 'null') AS advertising_opt_in,
  NULLIF(mkt_pref_opt_in, 'null') AS mkt_pref_opt_in,
  NULLIF(subjects, '[]') AS subjects,


  REPLACE(
    REPLACE(
      REPLACE(
        REPLACE(list_keywords_dois_last_60_d, '[', ''),
        ']', ''
      ),
      '\"', ''
    ),
    '"', ''
  ) AS list_keywords_dois_last_60_d

FROM `dat-analytics-eng-ec869189`.`prod_audience_explorer_analytics_dbt_staging`.`stg_df_audience_explorer_base_2`
    );
  