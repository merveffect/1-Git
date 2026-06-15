
{{config(
  materialized = 'table'
)
}}

WITH mapping AS (
  SELECT DISTINCT
    grid_id,
    BP_Full_Name AS bp_full_name,
    bp_id,
    TRIM(Jrnl_Title) AS journal_title,
    LOWER(TRIM(Jrnl_Title)) AS journal_title_clean
  FROM

{{ref('mart_top_10_denied_nature_jrnls_per_institute') }}

),

journal_meta AS (
  SELECT
    LOWER(TRIM(Title)) AS journal_title_clean,
    `Product ID` AS journal_id,
    `Launch Year` AS launch_year
  FROM

  {{source('journal_metadata', 'nature_title_list') }}

),

/* 🔹 Clean citations (exclude Nature Communications) */

ruby_clean AS (
  SELECT
    LOWER(TRIM(Cited_Journal_Name)) AS journal_title_clean,

    Cited_Item_Year AS reference_year,
    Cited_CitationID AS reference_id,
    Cited_Item_DOI,

    Citing_INST_Pub_GRID AS grid_id,
    Citing_INST_Pub_DOI AS citing_pub_id,
    Citing_INST_Pub_Year AS citing_year,
    Citing_INST_Pub_Journal_Name AS citing_source_title,
    Citing_INST_Pub_Publisher AS citing_publisher

  FROM
 
  {{ref('int_citations_Ruby') }}
  

  WHERE
    Cited_Journal_Brand = 'Nature Branded'
    AND LOWER(TRIM(Cited_Journal_Name)) != 'nature communications'   -- 🔥 exclusion
    AND Citing_INST_Pub_Year BETWEEN 2022 AND 2026
),

/* 🔹 Total Nature citations per institute (based on citation_id) */

total_citations AS (
  SELECT
    Citing_INST_Pub_GRID AS grid_id,
    COUNT(DISTINCT Cited_CitationID) AS total_citations_nature
  FROM

    {{ref('int_citations_Ruby') }}
  
  WHERE
    Cited_Journal_Brand = 'Nature Branded'
    AND LOWER(TRIM(Cited_Journal_Name)) != 'nature communications'   -- 🔥 exclusion
    AND Citing_INST_Pub_Year BETWEEN 2022 AND 2026
  GROUP BY
    grid_id
)

SELECT
  m.grid_id,
  m.bp_full_name,
  m.bp_id,
  m.journal_title,

  jm.launch_year,

  r.reference_year,
  r.reference_id,
  r.Cited_Item_DOI,

  r.citing_pub_id,
  r.citing_year,
  r.citing_source_title,
  r.citing_publisher,

  tc.total_citations_nature   -- 🔥 correct metric

FROM mapping m

JOIN ruby_clean r
  ON m.grid_id = r.grid_id
 AND m.journal_title_clean = r.journal_title_clean

LEFT JOIN journal_meta jm
  ON m.journal_title_clean = jm.journal_title_clean

LEFT JOIN total_citations tc
  ON m.grid_id = tc.grid_id

ORDER BY
  m.grid_id,
  r.reference_year DESC


