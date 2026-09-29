/*
    SOURCE PROFILE - cost and strategy follow from these numbers.
    Run in order and keep the outputs.
*/

-- ---------------------------------------------------------------------------
-- A. Overall volume
-- ---------------------------------------------------------------------------
SELECT
    COUNT(*)                                    AS people,
    SUM(ARRAY_LENGTH(employments))              AS employment_records,
    SUM(ARRAY_LENGTH(educations))               AS education_records,
    SUM(ARRAY_LENGTH(publications))             AS publication_records,
    SUM(ARRAY_LENGTH(keywords))                 AS keyword_records,
    COUNTIF(ARRAY_LENGTH(employments) = 0)      AS no_employment
FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers`;


-- ---------------------------------------------------------------------------
-- B. NORMALISED distinct title count
--    The raw count is 355,803. How far does normalisation reduce it?
--    That difference is a direct cost saving.
-- ---------------------------------------------------------------------------
WITH roles AS (
  SELECT
      e.role                                                AS raw_role,
      TRIM(REGEXP_REPLACE(
        REGEXP_REPLACE(
          LOWER(NORMALIZE_AND_CASEFOLD(e.role, NFKC)),
          r'[^\p{L}\p{N}\s&/+-]', ' '),
        r'\s+', ' '))                                       AS norm_role
  FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers`,
  UNNEST(employments) e
  WHERE e.role IS NOT NULL AND TRIM(e.role) != ''
)
SELECT
    COUNT(*)                        AS total_records,
    COUNT(DISTINCT raw_role)        AS raw_distinct,
    COUNT(DISTINCT norm_role)       AS normalised_distinct,
    ROUND(1 - COUNT(DISTINCT norm_role) / COUNT(DISTINCT raw_role), 3) AS reduction_ratio
FROM roles;


-- ---------------------------------------------------------------------------
-- C. FREQUENCY DISTRIBUTION - the whole cost strategy rests on this
--    "What share of records do the top N titles cover?"
-- ---------------------------------------------------------------------------
WITH roles AS (
  SELECT TRIM(REGEXP_REPLACE(
           REGEXP_REPLACE(LOWER(NORMALIZE_AND_CASEFOLD(e.role, NFKC)),
             r'[^\p{L}\p{N}\s&/+-]', ' '), r'\s+', ' ')) AS norm_role
  FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers`,
  UNNEST(employments) e
  WHERE e.role IS NOT NULL AND TRIM(e.role) != ''
),
freq AS (
  SELECT norm_role, COUNT(*) AS n,
         ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS rnk
  FROM roles GROUP BY norm_role
),
cum AS (
  SELECT *, SUM(n) OVER (ORDER BY rnk) / SUM(n) OVER () AS coverage
  FROM freq
)
SELECT
    cutoff AS top_n_titles,
    (SELECT ROUND(MAX(coverage), 4) FROM cum WHERE rnk <= cutoff) AS record_coverage
FROM UNNEST([100, 500, 1000, 2000, 5000, 10000, 25000, 50000, 100000]) AS cutoff
ORDER BY cutoff;


-- ---------------------------------------------------------------------------
-- D. Singleton titles - how big is the long tail?
-- ---------------------------------------------------------------------------
WITH roles AS (
  SELECT TRIM(LOWER(e.role)) AS r
  FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers`,
  UNNEST(employments) e WHERE e.role IS NOT NULL
),
freq AS (SELECT r, COUNT(*) n FROM roles GROUP BY r)
SELECT
    COUNTIF(n = 1)                              AS seen_once,
    COUNTIF(n BETWEEN 2 AND 9)                  AS seen_rarely,
    COUNTIF(n >= 10)                            AS seen_often,
    ROUND(COUNTIF(n = 1) / COUNT(*), 3)         AS singleton_ratio,
    ROUND(AVG(LENGTH(r)), 1)                    AS avg_length,
    COUNTIF(LENGTH(r) > 100)                    AS suspiciously_long
FROM freq;


-- ---------------------------------------------------------------------------
-- E. ORGANISATION IDENTITY - how many records carry a ROR id for free?
--    Where present, no name matching is needed at all.
-- ---------------------------------------------------------------------------
SELECT
    UPPER(e.disambiguated_organisation_source)  AS id_source,
    COUNT(*)                                    AS records,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER (), 3)  AS ratio
FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers`,
UNNEST(employments) e
GROUP BY id_source ORDER BY records DESC;


-- ---------------------------------------------------------------------------
-- F. VISIBILITY - only PUBLIC data is usable for marketing.
--    A high non-public share means lowering the volume expectation.
-- ---------------------------------------------------------------------------
SELECT
    UPPER(e.visibility)                         AS visibility,
    COUNT(*)                                    AS records,
    COUNT(DISTINCT r.snid)                      AS people,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER (), 3)  AS ratio
FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers` r,
UNNEST(r.employments) e
GROUP BY visibility ORDER BY records DESC;


-- ---------------------------------------------------------------------------
-- G. Current vs past posts (for the current_only roles)
-- ---------------------------------------------------------------------------
SELECT
    e.full_end_date IS NULL                     AS is_current,
    COUNT(*)                                    AS records,
    COUNT(DISTINCT r.snid)                      AS people
FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers` r,
UNNEST(r.employments) e
GROUP BY is_current;


-- ---------------------------------------------------------------------------
-- H. Top 100 titles - a preview of the human review queue
-- ---------------------------------------------------------------------------
SELECT
    TRIM(LOWER(e.role))     AS title,
    COUNT(*)                AS records,
    COUNT(DISTINCT r.snid)  AS people
FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers` r,
UNNEST(r.employments) e
WHERE e.role IS NOT NULL
GROUP BY title ORDER BY records DESC LIMIT 100;


-- ===========================================================================
-- I. THE MOST IMPORTANT QUERY - THE REAL WORKING POPULATION
--
--    The table holds 24.8M people but only 1.76M carry an SNID.
--    Without an SNID a person is unreachable and never enters the pipeline.
--    The 355,803 distinct titles were measured across the WHOLE table;
--    within the SNID population it will be far lower, and so will the cost.
-- ===========================================================================
WITH scoped AS (
  SELECT
      r.snid,
      TRIM(REGEXP_REPLACE(
        REGEXP_REPLACE(LOWER(NORMALIZE_AND_CASEFOLD(e.role, NFKC)),
          r'[^\p{L}\p{N}\s&/+-]', ' '), r'\s+', ' ')) AS norm_role
  FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers` r,
  UNNEST(r.employments) e
  WHERE r.snid IS NOT NULL
    AND UPPER(e.visibility) = 'PUBLIC'
    AND e.role IS NOT NULL AND TRIM(e.role) != ''
)
SELECT
    COUNT(*)                        AS employment_records,
    COUNT(DISTINCT snid)            AS people,
    COUNT(DISTINCT norm_role)       AS distinct_title,
    ROUND(COUNT(*) / COUNT(DISTINCT norm_role), 1) AS title_basina_records
FROM scoped;


-- ===========================================================================
-- J. Frequency distribution in that same population - this sets the tier thresholds
-- ===========================================================================
WITH scoped AS (
  SELECT TRIM(REGEXP_REPLACE(
           REGEXP_REPLACE(LOWER(NORMALIZE_AND_CASEFOLD(e.role, NFKC)),
             r'[^\p{L}\p{N}\s&/+-]', ' '), r'\s+', ' ')) AS norm_role
  FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers` r,
  UNNEST(r.employments) e
  WHERE r.snid IS NOT NULL AND UPPER(e.visibility) = 'PUBLIC'
    AND e.role IS NOT NULL AND TRIM(e.role) != ''
),
freq AS (
  SELECT norm_role, COUNT(*) n, ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) rnk
  FROM scoped GROUP BY norm_role
),
cum AS (SELECT *, SUM(n) OVER (ORDER BY rnk) / SUM(n) OVER () AS coverage FROM freq)
SELECT
    cutoff AS top_n_titles,
    (SELECT ROUND(MAX(coverage), 4) FROM cum WHERE rnk <= cutoff) AS record_coverage
FROM UNNEST([100, 500, 1000, 2000, 5000, 10000, 25000, 50000]) AS cutoff
ORDER BY cutoff;
