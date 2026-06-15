WITH regions /* 4. Updated with the new table and column names */
  AS(
 SELECT DISTINCT
    REGEXP_REPLACE(LOWER(country), '&(.)', 'and ') AS regions_country,
    LOWER(isoalphatwo) AS isoalphatwo,
    LOWER(world_region) AS world_region
    FROM {{ source('ria_researcher_report', 'regions') }}
  )
  SELECT *
  FROM {{ ref('country_cleaned') }} m_country
  LEFT JOIN regions
  ON m_country.country = regions.regions_country


  