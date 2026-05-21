-- Target audience candidates: Phase 1 HCP candidates + CDP opt-in filters
-- Segment: Practitioners (from hcp_bucket)
WITH phase1_candidates AS (
  SELECT
    snid,
    orcid_role,
    orcid_organisation,
    orcid_department,
    country_code,
    hcp_phase1_score,
    phase1_label,
    hcp_bucket
  FROM {{ ref('hcp_phase1_candidates') }}
),

cdp_opted_in AS (
  SELECT DISTINCT
    snid
  FROM {{ ref('audience_builder_big') }}
  WHERE
    mkt_pref_opt_in = TRUE
    OR is_legitimate_interest_author_opted_in = TRUE
    OR advertising_opt_in = TRUE
)

SELECT
  p.*
FROM phase1_candidates p
INNER JOIN cdp_opted_in c
  ON p.snid = c.snid
WHERE REGEXP_CONTAINS(LOWER(COALESCE(p.hcp_bucket, '')), r'practitioner')
