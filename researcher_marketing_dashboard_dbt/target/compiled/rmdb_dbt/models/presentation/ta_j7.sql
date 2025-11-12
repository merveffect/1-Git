 

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
  `snproject-cbb9ca25`.`dev_rmdb_dbt_presentation`.`j7` a
LEFT JOIN
  `snproject-cbb9ca25`.`ga4_ria_researcher_report`.`transformative_agreements_sheet` b
ON
  a.journal_id = b.journal_id
  
  WHERE date BETWEEN DATE('2024-01-01')
                  AND DATE('2025-11-09')
