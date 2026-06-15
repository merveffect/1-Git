
{{config(
  materialized = 'table'
)
}}

WITH base AS (
  SELECT
    t.id AS pub_id,
    a_grid AS org_grid_id,
    for2.id AS for2id,
    for2.name AS for2

  FROM
    {{source('publications', 'publications') }} t

  LEFT JOIN UNNEST(t.authors) AS a
  LEFT JOIN UNNEST(a.grid_ids) AS a_grid
  LEFT JOIN UNNEST(t.categories.for_2020_v2022.second_level.full) AS for2

  WHERE
    t.year >= 2022
    AND t.type = "article"
    AND LENGTH(a_grid) > 0
    AND LENGTH(for2.name) > 0
),

/* =========================================================
   TOTAL ARTICLES PER INSTITUTE
========================================================= */

total_articles AS (

SELECT
    org_grid_id,

    COUNT(DISTINCT pub_id) AS total_articles_institute

FROM
    base

GROUP BY
    org_grid_id
),

/* =========================================================
   FOR2 COUNTS + RANKING
========================================================= */

ranked AS (

SELECT
    b.org_grid_id,
    b.for2id,
    b.for2,

    COUNT(DISTINCT b.pub_id) AS no_of_articles,

    t.total_articles_institute,

    ROW_NUMBER() OVER (
      PARTITION BY b.org_grid_id
      ORDER BY COUNT(DISTINCT b.pub_id) DESC
    ) AS rank_within_grid

FROM
    base b

LEFT JOIN total_articles t
ON b.org_grid_id = t.org_grid_id

GROUP BY
    b.org_grid_id,
    b.for2id,
    b.for2,
    t.total_articles_institute
)

SELECT
    org_grid_id,
    for2id,
    for2,
    no_of_articles,
    total_articles_institute,
    rank_within_grid

FROM
    ranked

WHERE
    rank_within_grid <= 10

ORDER BY
    org_grid_id,
    rank_within_grid
