
  
    

    create or replace table `snproject-cbb9ca25`.`dbt_dev_ga4_ria_researcher_report`.`etocs`
      
    partition by etoc_date
    

    
    OPTIONS(
      description=""""""
    )
    as (
      


SELECT
  c.journal_id,
  c.journal_title,
  b.* EXCEPT(journal_id,
    journal_title,
    main_discipline),
  c.main_discipline,
  a.* EXCEPT(journal_id,
    journal_title)
FROM
  `snproject-cbb9ca25`.`dbt_dev_ga4_ria_researcher_report`.`etoc_4ria` a
LEFT JOIN
  `snproject-cbb9ca25`.`dbt_dev_ga4_ria_researcher_report`.`journal_table` b
ON
  SAFE_CAST(a.journal_id AS int64) = b.journal_id
LEFT JOIN (
-- ensure 1 row per journal_id from JFlow
  SELECT
    DISTINCT journal_id,
    journal_title,
    main_discipline
  FROM
    `snproject52c6e272`.`zz_content_hub`.`jflow_journals` ) c
ON
  COALESCE(SAFE_CAST(a.journal_id AS int64), b.journal_id) = c.journal_id
  
  WHERE etoc_date BETWEEN DATE('2024-01-01')
                  AND DATE('2025-09-30')

    );
  