
{{config(
  materialized = 'table'
)
}}


WITH grant_for2_org AS (
  SELECT
    SAFE_CAST(g.id AS STRING) AS grant_id,
    f.name AS for2name,
    org.grid_id AS org_grid_id,
    org.name AS org_name,
    SUM(SAFE_CAST(g.funding_eur AS FLOAT64)) AS funding_eur
  FROM 

  {{source('grants','grants')}} g

  LEFT JOIN UNNEST(g.organisation_details) AS org
  LEFT JOIN UNNEST(g.categories.for_2020_v2022.second_level.full) AS f
  WHERE
    f.name IS NOT NULL
    AND EXISTS (
      SELECT 1
      FROM UNNEST(g.active_years) ay
      WHERE ay >= 2026
    )
  GROUP BY
    grant_id,
    for2name,
    org_grid_id,
    org_name
),

agg AS (
  SELECT
    org_grid_id,
    for2name,
    SUM(funding_eur) AS total_funding_eur,
    COUNT(grant_id) AS no_of_grants
  FROM grant_for2_org
  GROUP BY
    org_grid_id,
    for2name
),

ranked AS (
  SELECT
    *,
    ROW_NUMBER() OVER (
      PARTITION BY org_grid_id
      ORDER BY total_funding_eur DESC
    ) AS rank_within_org
  FROM agg
)

SELECT
  org_grid_id,
  for2name,
  no_of_grants,
  total_funding_eur,
  rank_within_org
FROM ranked
WHERE rank_within_org <= 10
ORDER BY org_grid_id, rank_within_org
