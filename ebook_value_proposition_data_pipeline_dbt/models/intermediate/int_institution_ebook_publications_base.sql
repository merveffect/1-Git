
{{ config(
    materialized = "table",
    tags= ["monthly"],
    cluster_by = ["publisher_name", "publication_type", "pub_year"]
 )}}

WITH
doi_map AS (
  SELECT
    Item_DOI AS doi_norm,
    Bk_eBook_ISBN,
    ebook_package,
    eBook_package_R0,
    Bk_Series_Title,
    Bk_Cat,
    Bk_Subj_Coll
    
  FROM
    {{ref('stg_doi_ebookpackage')}}

  WHERE
    Item_DOI IS NOT NULL
  GROUP BY
    ALL
),

eu_pubs AS (
  SELECT
    t.id AS pub_id,
    t.year AS pub_year,
    t.doi AS doi,
    t.publisher.name AS publisher_name,
    t.type AS publication_type,
    t.book_title.preferred AS book_title_preferred,
    t.book_series_title.original AS book_series,
    t.source.title AS source_title,
    t.title.preferred AS pubs_title,
    t.eisbn AS book_eisbn,
    oa AS oa,
    for1.code AS for1_code,
    for1.name AS for1_name,
    for2.code AS for2_code,
    for2.name AS for2_name,
    sdg.code AS SDG_code,
    sdg.name AS SDG_Name,
    research_orgs_grids AS grid_id,
    grid.name AS grid_name,
    gridtype AS grid_type,
    grid.address.country AS grid_country,
    research_org_country AS Country
  FROM
    {{ source('data_analytics_eu','publications') }} t
  LEFT JOIN UNNEST(t.categories.for_2020_v2022.first_level.full) AS for1
  LEFT JOIN UNNEST(t.categories.for_2020_v2022.second_level.full) AS for2
  LEFT JOIN UNNEST(t.open_access_categories_v2) AS oa
  LEFT JOIN UNNEST(t.research_orgs) AS research_orgs_grids
  LEFT JOIN {{ source('data_analytics_eu','grid') }} grid
    ON grid.id = research_orgs_grids
  LEFT JOIN UNNEST(grid.types) AS gridtype
  LEFT JOIN UNNEST(t.research_org_country_names) AS research_org_country
  LEFT JOIN UNNEST(t.category_sdg.full) AS sdg
)

SELECT
  p.pub_id,
  p.pub_year,
  p.doi,
  p.publication_type,
  p.book_title_preferred,
  p.book_series,
  p.book_eisbn,
  p.source_title,
  p.pubs_title,
  p.oa,
  p.publisher_name,
  p.for1_code,
  p.for1_name,
  p.for2_code,
  p.for2_name,
  p.SDG_code,
  p.SDG_Name,
  p.grid_id,
  p.grid_name,
  p.grid_type,
  p.grid_country,
  p.Country,
  dm.ebook_package,
  dm.eBook_package_R0,
  dm.Bk_Series_Title,
  dm.Bk_Cat AS Bk_eBook_cat,
  dm.Bk_Subj_Coll
FROM
  eu_pubs p
LEFT JOIN
  doi_map dm
  ON LOWER(p.doi) = LOWER(dm.doi_norm)
  where p.pub_year >= 2005
  AND p.publication_type NOT IN ("article", "preprint")
  -- AND p.publisher_name = "Springer Nature"
  




