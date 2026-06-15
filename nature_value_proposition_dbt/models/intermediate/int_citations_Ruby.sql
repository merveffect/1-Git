
{{config(
  materialized = 'table'
)
}}

with Original_DOI as (
  Select
  p.year,
  journal.title,
  case when journal.title in ("Nature","Nature Genetics","Nature Structural & Molecular Biology","Nature Medicine","Nature Biotechnology","Nature Neuroscience","Nature Cell Biology","Nature Immunology","Nature Reviews Genetics","Nature Reviews Molecular Cell Biology","Nature Reviews Neuroscience","Nature Reviews Cancer","Nature Reviews Immunology","Nature Materials","Nature Reviews Drug Discovery","Nature Reviews Microbiology","Nature Methods","Nature Reviews Cardiology","Nature Reviews Clinical Oncology","Nature Reviews Gastroenterology & Hepatology","Nature Reviews Urology","Nature Chemical Biology","Nature Physics","Nature Reviews Endocrinology","Nature Reviews Nephrology","Nature Reviews Neurology","Nature Reviews Rheumatology","Nature Nanotechnology","Nature Protocols","Nature Photonics","Nature Geoscience","Nature Chemistry","Nature Climate Change","Nature Plants","Nature Reviews Disease Primers","Nature Energy","Nature Microbiology","Nature Reviews Materials","Nature Astronomy","Nature Biomedical Engineering","Nature Ecology & Evolution","Nature Human Behaviour","Nature Reviews Chemistry","Nature Catalysis","Nature Electronics","Nature Sustainability","Nature Machine Intelligence","Nature Metabolism","Nature Reviews Physics","Nature Cancer","Nature Food","Nature Reviews Earth & Environment","Nature Aging","Nature Computational Science","Nature Reviews Methods Primers","Nature Cardiovascular Research","Nature Synthesis","Nature Reviews Psychology","Nature Mental Health","Nature Water","Nature Reviews Bioengineering","Nature Cities","Nature Chemical Engineering","Nature Reviews Electrical Engineering","Nature Reviews Biodiversity","Nature Reviews Clean Technology","Nature Health","Nature Sensors","Nature Communications") then "Nature Branded" else "Others" end as brand,
  doi,
  c.id as citation_id,
  c.year as citation_year,
  article_type,
  from 

  {{source('publications', 'publications') }} p,

  unnest (citations) c,
  unnest(open_access_categories_v2) article_type
  where type in ('article')
   and publisher.name in ("Springer Nature")
   and doi is not null
   and article_type <> "oa_all"
   and journal.id <> "jour.1043550"  ---Inactive: Frontiers of Information Technology & Electronic Engineering-20260214
),
GRID as (
  SELECT id,name
  FROM 

  {{source('grid', 'grid') }}
-- where address.country in ("China","Taiwan","South Korea")
),
----quote defined
INST as (
  Select grid,
  id,
  doi,
  year,
  EXTRACT(month from date_normal) as month,
  date_normal,
  publisher.name as publisher,
  journal.title as journal,
  type,
  citations_count,
  from 

  {{source('publications', 'publications') }} p,
  
  unnest(research_orgs) grid
  where year between 2021 and 2026
  and type="article"
  and doi is not null
),
INST_all as (
  select INST.*, name from INST inner join GRID on INST.grid=GRID.id
)
Select distinct Original_DOI.year as Cited_Item_Year,
  Original_DOI.title as Cited_Journal_Name,
  Original_DOI.brand as Cited_Journal_Brand,
  Original_DOI.doi as Cited_Item_DOI,
  Original_DOI.citation_id as Cited_CitationID,
  case when Original_DOI.article_type in  ('hybrid','gold') then 'OA'
       when Original_DOI.article_type in  ('bronze','green','closed') then 'Subscribe' end as Orignial_Item_Type,
  INST_all.name as Citing_INST_Name,
  INST_all.doi as Citing_INST_Pub_DOI,
  INST_all.year as Citing_INST_Pub_Year,
  month as Citing_INST_Pub_Month,
  INST_all.grid as Citing_INST_Pub_GRID,
  INST_all.publisher as Citing_INST_Pub_Publisher,
  INST_all.journal as Citing_INST_Pub_Journal_Name,
  INST_all.citations_count as Citing_INST_Pub_citations_count
  from Original_DOI
    inner join INST_all
    on Original_DOI.citation_id=INST_all.id



