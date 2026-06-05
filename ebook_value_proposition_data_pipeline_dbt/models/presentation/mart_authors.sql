{{ config(
    materialized = "table",
    tags= ["monthly"]
 )}}

WITH pubs AS (
  SELECT
    p.id,
    p.year,
    p.doi,
    p.type,
    p.book_title.preferred AS book_title,
    p.eisbn AS book_eisbn,
    oa as oa,
    p.publisher.name AS publisher_name,
    a
  FROM
    {{source('data_analytics_eu', 'publications')}} AS p,
    UNNEST(p.authors) AS a
    LEFT JOIN UNNEST(p.open_access_categories_v2) AS oa
  WHERE
    p.publisher.name = 'Springer Nature'  AND
    p.type In ("monograph", "chapter", "proceedings")
)

SELECT
  p.id AS pub_id,
  p.year AS pub_year,
  p.doi,
  p.type,
  p.book_title,
  p.book_eisbn,
  p.publisher_name,
  oa,
  a.first_name,
  a.last_name,
  a.researcher_id,
  a.grid_ids[SAFE_OFFSET(i)] AS grid_id,
  grid.name AS grid_name,
  grid.address.country AS grid_country
FROM
  pubs p
CROSS JOIN UNNEST(
  IF(
    GREATEST(
      IFNULL(ARRAY_LENGTH(a.grid_ids), 0),
      IFNULL(ARRAY_LENGTH(a.raw_affiliations), 0)
    ) > 0,
    GENERATE_ARRAY(
      0,
      GREATEST(
        IFNULL(ARRAY_LENGTH(a.grid_ids), 0),
        IFNULL(ARRAY_LENGTH(a.raw_affiliations), 0)
      ) - 1
    ),
    ARRAY<INT64>[]
  )
) AS i
LEFT JOIN
  {{ source('data_analytics_eu','grid') }} AS grid
ON
  grid.id = a.grid_ids[SAFE_OFFSET(i)]
