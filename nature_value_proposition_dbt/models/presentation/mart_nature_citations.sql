
{{config(
  materialized = 'table'
)
}}

SELECT
  p.id AS cited_pub_id,
  LOWER(p.doi) AS cited_doi,
  p.source.title AS cited_title,
  p.type AS cited_type,
  p.year AS publication_year,

  citation.id AS citing_pub_id,
  citation.year AS citation_year,

  b.bp_id,
  b.BP_Full_Name,

  j.journal_id,
  j.SN_journal_imprint

FROM 

{{source('publications', 'publications') }} AS p

LEFT JOIN UNNEST(p.citations) AS citation

/* publication belongs to institute */
LEFT JOIN UNNEST(p.research_orgs) AS pub_research_grid

/* Keep only Nature Portfolio journals */
INNER JOIN (
    SELECT
      Jrnl_Title_No AS journal_id,
      LOWER(Jrnl_Title) AS Jrnl_Title,
      Imprint AS SN_journal_imprint
    FROM
   
     {{source('journal_imprint', 'Journal_imprint') }}
   
    WHERE
    Jrnl_Title_No In ('41586','43587','41550','41551','41587','43018','44161','41929','41556',
    '41589','44286','41557','44284','41558','43588','41559','41928','41560',
    '43016','41588','41561','44360','41562','41590','42256','41563','41591',
    '44161','42255','41592','41564','41565','41593','41566','41567','41477',
    '41596','44358','44222','41568','41569','41570','44959','41571','41572',
    '41573','43017','44287','41574','41575','41576','41577','41578','43586',
    '41579','41580','41581','41582','41583','42254','44159','41584','41585',
    '44460','41594','41893','44160','44221', "44359")
    GROUP BY 1,2,3
) j
ON LOWER(p.source.title) = j.Jrnl_Title

/* Match institute owning the Nature publication */
INNER JOIN (
    SELECT DISTINCT
      grid_id,
      bp_id,
      BP_Full_Name
    FROM
    
    {{ref('stg_nature_jrnl_usage_denials') }}
     
) b
ON b.grid_id = pub_research_grid

WHERE
  p.year BETWEEN 2022 AND 2026
  AND p.publisher.name = 'Springer Nature'
  AND NOT REGEXP_CONTAINS(LOWER(p.doi), r'cureus')
  AND p.type = 'article'



