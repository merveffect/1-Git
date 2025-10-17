 

SELECT
  a.*,
  b.* EXCEPT(journal_id,
    journal_title),
  CASE
    WHEN researchER_marketing_activity = TRUE AND product_code != "oaagr" THEN "researcher marketing"
    WHEN product_code = "oaagr" THEN "OAAGR campaign traffic"
    ELSE "all other traffic"
END
  AS traffic_type_ta
FROM
  `snproject-cbb9ca25`.`dbt_dev_ga4_ria_researcher_report`.`j7` a
LEFT JOIN
  `snproject-cbb9ca25`.`dbt_dev_ga4_ria_researcher_report`.`transformative_agreements_sheet` b
ON
  a.journal_id = b.journal_id
   
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
