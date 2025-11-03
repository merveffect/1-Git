-- back compat for old kwarg name
  
  
        
    

    

    merge into `snproject-cbb9ca25`.`dbt_dev_ga4_ria_researcher_report`.`oatype` as DBT_INTERNAL_DEST
        using (

WITH
  main AS (
  SELECT
    DISTINCT LOWER(REGEXP_REPLACE(Product_Title, '&(.)', 'and ')) AS journaltitle,
    LOWER(hd.Publishing_Model_Code) AS oatype,
    t.Journal_ID AS journalkey,
    Imprint AS journal_imprint,
    DATE(b.publishing_model_periods.valid_from) AS JournalValidFrom
  FROM
    `snproject52c6e272`.`xx_jflow`.`jflow` t
  CROSS JOIN
    UNNEST(t.hidden_dimensions) AS hd
  CROSS JOIN
    UNNEST(basic)AS b
    -- `snproject52c6e272.zz_content_hub.jflow_journals`  -- old content_hub jflow table is decommisioned and now using the new updated jflow table
  WHERE
    hd.Publishing_Model_Code IS NOT NULL
    AND LOWER(Product_Status) = 'active'
    --2a.
    ),
    row_rank AS (
    SELECT
      journaltitle,
      oatype,
      JournalKey,
      JournalValidFrom,
      journal_imprint,
      RANK() OVER (PARTITION BY journaltitle ORDER BY journalvalidfrom DESC, journalkey DESC, oatype ASC) AS sequence
    FROM
      main
    ORDER BY
      sequence DESC )
  SELECT
    *
  FROM
    row_rank
  WHERE
    sequence = 1
    /*
    selection notes:
    1. only select fields necessary for OA type mapping as there are a lot of duplicate entries in the journals table data set (pricing for instance tends to have multiple values for otherwise identical entries *shrug emoji*)
    2. only select where JournalStatus = "ACTIVE"; 5 journals who have both active and inactive entries with different journal keys, specifically: journal of activity, sedentary and sleep behaviors/quantum frontiers/african journal of urology/annals of pediatric surgery/international transactions on systems science and applications
    */
        ) as DBT_INTERNAL_SOURCE
        on (FALSE)

    

    when not matched then insert
        (`journaltitle`, `oatype`, `JournalKey`, `JournalValidFrom`, `journal_imprint`, `sequence`)
    values
        (`journaltitle`, `oatype`, `JournalKey`, `JournalValidFrom`, `journal_imprint`, `sequence`)


    