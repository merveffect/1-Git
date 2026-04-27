regions /* 4. Updated with the new table and column names */
  AS(
    SELECT DISTINCT
      -- Clean the Springer Nature standard location name and use it as the join key
      REGEXP_REPLACE(LOWER(springer_nature_data_standard_location_name), '&(.)', 'and ') AS regions_country,
      -- Rename the alpha_2_code column as isoalphatwo to preserve the remaining logic
      LOWER(alpha_2_code) AS isoalphatwo,
      -- Rename the cpo_region_name column as world_region
      LOWER(cpo_region_name) AS world_region
    FROM {{ source('datasn_tools_live', 'full_location_standard') }}
  )
  SELECT *
  FROM {{ ref('country_cleaned') }} m_country
  LEFT JOIN regions
  ON m_country.country = regions.regions_country