/*
    ============================================================================
    HOW BIG IS THE AMBIGUOUS BAND?
    ============================================================================
    This is the number that decides whether the LLM judge is worth
    provisioning. It answers: how many people sit behind job titles that
    a vector model alone cannot resolve?

    A title is hard to resolve when it is GENERIC ("Director", "Consultant",
    "Head of Research") and nothing else in the record disambiguates it.
    Three tiers, each narrower than the last:

      TIER 1  generic title, no domain word in the title
      TIER 2  ... and no domain word in the department either
      TIER 3  ... and the organisation name carries no domain signal
              -> TIER 3 is what an LLM would actually adjudicate

    Runs on the source directly - no dbt models required.
    ============================================================================
*/

WITH base AS (
  SELECT
      r.snid,
      LOWER(TRIM(e.role))               AS title,
      LOWER(TRIM(e.department_name))    AS dept,
      LOWER(TRIM(e.organisation_name))  AS org
  FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers` r,
  UNNEST(r.employments) e
  WHERE r.snid IS NOT NULL
    AND UPPER(e.visibility) = 'PUBLIC'
    AND e.role IS NOT NULL
    AND TRIM(e.role) != ''
),

flagged AS (
  SELECT
      snid,
      title,
      -- a generic leadership / staff word with no occupation of its own
      REGEXP_CONTAINS(title, r'\b(director|manager|head|chief|officer|lead|leader|coordinator|consultant|fellow|associate|specialist|advisor|adviser|executive|supervisor|administrator|assistant|deputy|principal|senior|staff|member|partner|expert|analyst)\b')
          AS has_generic_word,

      -- a word that pins the title to one of our domains
      REGEXP_CONTAINS(title, r'\b(clinic\w*|medic\w*|health\w*|nurs\w*|surg\w*|cardio\w*|oncolog\w*|radiolog\w*|paediatr\w*|pediatr\w*|psychiatr\w*|dent\w*|pharmac\w*|physician|doctor|therapist|librar\w*|archiv\w*|repositor\w*|research\w*|scien\w*|professor|faculty|dean|academic|laborator\w*|postdoc\w*|investigator)\b')
          AS has_domain_word_in_title,

      REGEXP_CONTAINS(COALESCE(dept, ''), r'\b(clinic\w*|medic\w*|health\w*|nurs\w*|surg\w*|cardio\w*|oncolog\w*|radiolog\w*|pharmac\w*|librar\w*|archiv\w*|research\w*|scien\w*|faculty|school|department of|institute)\b')
          AS has_domain_word_in_dept,

      REGEXP_CONTAINS(COALESCE(org, ''), r'\b(hospital|clinic|medical|health|nhs|univers\w*|college|institut\w*|academy|librar\w*|research|pharmac\w*)\b')
          AS has_domain_word_in_org
  FROM base
)

SELECT
    'TOTAL role records'                                        AS tier,
    COUNT(*)                                                    AS records,
    COUNT(DISTINCT snid)                                        AS people,
    1.0                                                         AS share_of_records
FROM flagged

UNION ALL
SELECT
    'TIER 1  generic title, no domain word in title',
    COUNT(*),
    COUNT(DISTINCT snid),
    ROUND(COUNT(*) / (SELECT COUNT(*) FROM flagged), 4)
FROM flagged
WHERE has_generic_word AND NOT has_domain_word_in_title

UNION ALL
SELECT
    'TIER 2  ... and no domain word in department',
    COUNT(*),
    COUNT(DISTINCT snid),
    ROUND(COUNT(*) / (SELECT COUNT(*) FROM flagged), 4)
FROM flagged
WHERE has_generic_word AND NOT has_domain_word_in_title AND NOT has_domain_word_in_dept

UNION ALL
SELECT
    'TIER 3  ... and no domain signal in organisation  <-- LLM would decide these',
    COUNT(*),
    COUNT(DISTINCT snid),
    ROUND(COUNT(*) / (SELECT COUNT(*) FROM flagged), 4)
FROM flagged
WHERE has_generic_word AND NOT has_domain_word_in_title
  AND NOT has_domain_word_in_dept AND NOT has_domain_word_in_org

ORDER BY records DESC;


-- ---------------------------------------------------------------------------
-- How many of those people are actually reachable?
-- The only number the business acts on.
-- ---------------------------------------------------------------------------
WITH base AS (
  SELECT r.snid, LOWER(TRIM(e.role)) AS title,
         LOWER(TRIM(e.department_name)) AS dept, LOWER(TRIM(e.organisation_name)) AS org
  FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers` r,
  UNNEST(r.employments) e
  WHERE r.snid IS NOT NULL AND UPPER(e.visibility) = 'PUBLIC'
    AND e.role IS NOT NULL AND TRIM(e.role) != ''
),
ambiguous AS (
  SELECT DISTINCT snid FROM base
  WHERE REGEXP_CONTAINS(title, r'\b(director|manager|head|chief|officer|lead|leader|coordinator|consultant|fellow|associate|specialist|advisor|adviser|executive|supervisor|administrator|assistant|deputy|principal|senior|staff|member|partner|expert|analyst)\b')
    AND NOT REGEXP_CONTAINS(title, r'\b(clinic\w*|medic\w*|health\w*|nurs\w*|surg\w*|cardio\w*|oncolog\w*|radiolog\w*|paediatr\w*|pediatr\w*|psychiatr\w*|dent\w*|pharmac\w*|physician|doctor|therapist|librar\w*|archiv\w*|repositor\w*|research\w*|scien\w*|professor|faculty|dean|academic|laborator\w*|postdoc\w*|investigator)\b')
    AND NOT REGEXP_CONTAINS(COALESCE(dept, ''), r'\b(clinic\w*|medic\w*|health\w*|nurs\w*|surg\w*|cardio\w*|oncolog\w*|radiolog\w*|pharmac\w*|librar\w*|archiv\w*|research\w*|scien\w*|faculty|school|department of|institute)\b')
    AND NOT REGEXP_CONTAINS(COALESCE(org, ''), r'\b(hospital|clinic|medical|health|nhs|univers\w*|college|institut\w*|academy|librar\w*|research|pharmac\w*)\b')
)
SELECT
    COUNT(DISTINCT a.snid)                                      AS ambiguous_people,
    COUNT(DISTINCT IF(c.snid IS NOT NULL, a.snid, NULL))        AS in_cdp,
    COUNT(DISTINCT IF(c.mkt_pref_opt_in,  a.snid, NULL))        AS marketable,
    COUNT(DISTINCT IF(c.advertising_opt_in, a.snid, NULL))      AS advertisable
FROM ambiguous a
LEFT JOIN `researcher-360-prod-e7fd74be.researcher_profiles.audience_builder_big` c
       ON a.snid = c.snid;

/*
    HOW TO READ IT

    The "marketable" figure in the second query is the honest size of
    the decision. Those people carry a title the vector model cannot
    settle on its own. Without an LLM judge each of them is either:
      - excluded  -> a real audience member lost, or
      - included  -> a non-target contact in a targeted campaign, or
      - reviewed by hand -> works once, does not scale per role

    This is a PROXY, not the exact ambiguous set: regex over generic
    words approximates what the distractor margin will actually flag.
    Expect the real figure to land in the same order of magnitude.
*/
