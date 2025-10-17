{{ config(
    materialized = "incremental"
 )}}

WITH
  main AS (
  SELECT
    DISTINCT
    -- 1.
    LOWER(REGEXP_REPLACE(Journal_Title, '&(.)', 'and ')) AS journaltitle,
    LOWER(Publishing_Model_Code[safe_offset(0)]) AS oatype,
    Journal_ID as journalkey,
    Imprint AS journal_imprint,
    Publishing_Model_Valid_From  AS JournalValidFrom
  FROM
  {{source('zz_content_hub','jflow_journals')}}
    -- `snproject52c6e272.zz_content_hub.jflow_journals`
  WHERE
    Publishing_Model_Code[safe_offset(0)] IS NOT NULL
    AND lower(Product_Status) = 'active'
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
