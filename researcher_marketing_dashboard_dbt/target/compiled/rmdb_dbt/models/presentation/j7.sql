


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
   
  WHERE date BETWEEN 
        COALESCE(
          DATE('2025-01-01') ,
          DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY)
        )
        AND
        COALESCE(
          DATE('2025-01-05') ,
          DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY)
        )
