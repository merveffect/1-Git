
  
    

    create or replace table `snproject-cbb9ca25`.`dev_rmdb_dbt_staging`.`journal_mapping`
      
    partition by date
    

    
    OPTIONS(
      description=""""""
    )
    as (
      

SELECT
  a.* EXCEPT(JournalID),
  c.journal_title,
  -- from JFlow
  b.business_model,
  b.main_group,
  b.portfolio,
  -- portfolio only from sheet
  c.main_discipline,
  -- from JFlow
  COALESCE(SAFE_CAST(a.JournalID AS int64), b.journal_id) AS journal_id
FROM (
  SELECT
    * EXCEPT(Journal_ID___GA4__Google_Analytics),
    CASE
      WHEN Journal_ID___GA4__Google_Analytics IN ("(not set)|ghostery|false|(not+set)|(notset)") THEN "0"
      ELSE Journal_ID___GA4__Google_Analytics
  END
    AS JournalID
  FROM
    `snproject-cbb9ca25`.`dev_rmdb_dbt_raw`.`b2c_googleanalytics_static`
    
    
  WHERE date BETWEEN DATE('2024-01-01')
                  AND DATE('2025-11-09')

    ) a
FULL JOIN (
  SELECT
    * EXCEPT(journal_title,
      main_discipline)
      -- drop sheet’s title & discipline
  FROM
   `snproject-cbb9ca25`.`e2e_b2c_researcher_dev`.`journal_table` ) b
ON
  SAFE_CAST(a.JournalID AS int64) = b.journal_id
LEFT JOIN (
-- ensure 1 row per journal_id
  SELECT
    DISTINCT jf.journal_id,
    product_title as journal_title,
    m.marketing.main_discipline
  FROM
    `snproject52c6e272`.`xx_jflow`.`jflow` jf, unnest(marketing) as m  ) c
ON
  COALESCE(SAFE_CAST(a.JournalID AS int64), b.journal_id) = c.journal_id
    );
  