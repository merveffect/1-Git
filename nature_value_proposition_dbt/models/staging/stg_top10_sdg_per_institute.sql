
{{config(
  materialized = 'table'
)
}}

WITH base AS (
  SELECT
    t.id AS pub_id,
    a_grid AS org_grid_id,
    sdg.code as sdgcode,
    sdg.name AS sdgname
  FROM
    {{ source('publications', 'publications') }} AS t
  LEFT JOIN UNNEST(t.authors) AS a
  LEFT JOIN UNNEST(a.grid_ids) AS a_grid
  LEFT JOIN UNNEST(t.category_sdg.full) AS sdg
  WHERE
    t.year >= 2022
    AND LENGTH(a_grid) > 0      -- must have GRID
    AND LENGTH(sdg.name) > 0   -- must have FOR2
)

, ranked AS (
  SELECT
    org_grid_id,
    sdgcode,
    sdgname,

    COUNT(DISTINCT pub_id) AS no_of_articles,
    ROW_NUMBER() OVER (
      PARTITION BY org_grid_id
      ORDER BY COUNT(DISTINCT pub_id) DESC
    ) AS rank_within_grid
  FROM
    base
  GROUP BY
    org_grid_id, base.sdgcode,base.sdgname
)

SELECT
  org_grid_id,
  ranked.sdgcode,
  ranked.sdgname,
  no_of_articles,
  rank_within_grid
FROM
  ranked
WHERE
  rank_within_grid <= 10
ORDER BY
  org_grid_id, rank_within_grid



