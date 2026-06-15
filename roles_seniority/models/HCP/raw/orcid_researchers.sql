-- Flatten ORCID employment records with PUBLIC visibility
SELECT
  snid,
  orcid_id,
  LOWER(TRIM(e.role))                    AS role_clean,
  LOWER(TRIM(e.organisation_name))       AS org_clean,
  LOWER(TRIM(e.department_name))         AS dept_clean,
  e.organisation_address_country_code    AS country_code,
  e.full_start_date,
  e.full_end_date
FROM {{source('researcher_profiles', 'v_orcid_researchers')}},
UNNEST(employments) AS e
WHERE e.visibility = 'PUBLIC'
  AND snid IS NOT NULL