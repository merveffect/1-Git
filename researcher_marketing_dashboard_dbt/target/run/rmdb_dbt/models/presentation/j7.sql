
  
    

    create or replace table `snproject-cbb9ca25`.`dbt_dev_ga4_ria_researcher_report`.`j7`
      
    partition by date
    cluster by clean_campaign, country, sub_channels

    
    OPTIONS(
      description=""""""
    )
    as (
      


SELECT
  *
FROM
  `snproject-cbb9ca25`.`dbt_dev_ga4_ria_researcher_report`.`j5` a
LEFT JOIN (
  SELECT
    DISTINCT * EXCEPT(channels_categories,
      programs,
      leading_product),
  FROM
    `datasn-rm-live`.`marmind_fnd`.`marmind_data` ) b
ON
  a.campaign_code = LOWER(b.marmind_campaign_code)
  
  
  WHERE date BETWEEN DATE('2024-01-01')
                  AND DATE('2025-11-01')

    );
  