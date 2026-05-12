-- Calculate composite scores and rank employment records per user
WITH composite AS (
  SELECT
    *,
    ROUND(
      (role_score * 0.50)
      + (org_score  * 0.30)
      + (dept_score * 0.20),
    4) AS employment_score
  FROM {{ ref('hcp_orcid_employment_scored') }}
),

ranked AS (
  SELECT
    *,
    ROW_NUMBER() OVER (
      PARTITION BY snid
      ORDER BY
        CASE WHEN full_end_date IS NULL THEN 0 ELSE 1 END ASC,
        full_end_date DESC NULLS LAST,
        full_start_date DESC NULLS LAST
    ) AS rn
  FROM composite
),

latest_education AS (
  SELECT snid, education_score
  FROM (
    SELECT
      snid,
      education_score,
      ROW_NUMBER() OVER (
        PARTITION BY snid
        ORDER BY
          CASE WHEN full_end_date IS NULL THEN 0 ELSE 1 END ASC,
          full_end_date DESC NULLS LAST,
          full_start_date DESC NULLS LAST
      ) AS rn
    FROM {{ ref('hcp_education_scored') }}
  )
  WHERE rn = 1
),

final AS (
  SELECT
    r.*,
    COALESCE(e.education_score, 0) AS education_score,
    ROUND(LEAST(1.0,
      r.employment_score + (COALESCE(e.education_score, 0) * 0.20)
    ), 4) AS hcp_phase1_score
  FROM ranked r
  LEFT JOIN latest_education e ON r.snid = e.snid
  WHERE r.rn = 1
)

SELECT
  snid,
  orcid_id,
  role_clean           AS orcid_role,
  org_clean            AS orcid_organisation,
  dept_clean           AS orcid_department,
  country_code,
  full_start_date      AS employment_start_date,
  full_end_date        AS employment_end_date,
  role_score,
  org_score,
  dept_score,
  employment_score,
  education_score,
  hcp_phase1_score,
  hcp_bucket,
  CASE
    WHEN hcp_phase1_score >= 0.60 THEN 'CONFIRMED_HCP_CANDIDATE'
    WHEN hcp_phase1_score >= 0.30 THEN 'PROBABLE_HCP'
    ELSE                               'NON_HCP'
  END                  AS phase1_label,
  CURRENT_TIMESTAMP()  AS pipeline_run_ts
FROM final
