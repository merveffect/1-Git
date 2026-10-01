/*
    ============================================================================
    WHY DID ML.DISTANCE SAY "Array inputs are not equal in length"?
    ============================================================================
    ML.GENERATE_EMBEDDING does not fail the whole job when one row cannot be
    embedded. It returns an EMPTY array for that row and carries on. Later,
    ML.DISTANCE tries to compare a 768-element vector with a 0-element one
    and raises that error.

    So the error is not about the model - it is about a handful of bad input
    strings. This query finds them.

    STATUS: the error is already fixed - analyses 05-08 and the production
    models now carry both guards, and test 07 ran clean afterwards. Query 1
    here is therefore only needed if the error comes back.

    Query 2 is still worth a minute: it reports how much volume the
    LENGTH(x) BETWEEN 2 AND 200 filter silently removes. If that turns out
    to be material rather than a rounding error, the normalisation rules
    need a look.

    Usual causes:
      - the string normalises to empty or near-empty ("---", "...", "***")
      - the string is enormous (a whole address pasted into department_name)
      - the string is a single character
    ============================================================================
*/

-- ---------------------------------------------------------------------------
-- 1. Which of the top 500 departments fail to embed, and what do they look like?
-- ---------------------------------------------------------------------------
WITH top_depts AS (
  SELECT
      TRIM(REGEXP_REPLACE(
        REGEXP_REPLACE(LOWER(NORMALIZE_AND_CASEFOLD(e.department_name, NFKC)),
          r'[^\p{L}\p{N}\s&/+-]', ' '), r'\s+', ' '))  AS department,
      COUNT(*)                                         AS records
  FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers` r,
  UNNEST(r.employments) e
  WHERE r.snid IS NOT NULL AND UPPER(e.visibility) = 'PUBLIC'
    AND e.department_name IS NOT NULL AND TRIM(e.department_name) != ''
  GROUP BY department ORDER BY records DESC LIMIT 500
),
embedded AS (
  SELECT
      department,
      records,
      ARRAY_LENGTH(ml_generate_embedding_result)  AS dims
  FROM ML.GENERATE_EMBEDDING(
    MODEL `datasn-rm-live.institution_disambiguation.embedding_model`,
    (SELECT department, records, department AS content FROM top_depts))
)
SELECT
    CASE WHEN dims = 0 THEN 'FAILED' ELSE 'ok' END  AS outcome,
    COUNT(*)                                        AS departments,
    SUM(records)                                    AS records,
    MIN(dims)                                       AS min_dims,
    MAX(dims)                                       AS max_dims,
    STRING_AGG(
      CONCAT('[', department, '] len=', CAST(LENGTH(department) AS STRING)),
      '  //  ' ORDER BY records DESC LIMIT 15)      AS examples
FROM embedded
GROUP BY outcome
ORDER BY outcome;

-- The FAILED row names the offending strings. Expect very short ones,
-- empty ones, or one absurdly long one.


-- ---------------------------------------------------------------------------
-- 2. How many distinct departments normalise to something unusable?
--    Run this to size the problem before filtering it out.
-- ---------------------------------------------------------------------------
WITH normalised AS (
  SELECT
      TRIM(REGEXP_REPLACE(
        REGEXP_REPLACE(LOWER(NORMALIZE_AND_CASEFOLD(e.department_name, NFKC)),
          r'[^\p{L}\p{N}\s&/+-]', ' '), r'\s+', ' '))  AS department,
      COUNT(*)                                         AS records
  FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers` r,
  UNNEST(r.employments) e
  WHERE r.snid IS NOT NULL AND UPPER(e.visibility) = 'PUBLIC'
    AND e.department_name IS NOT NULL AND TRIM(e.department_name) != ''
  GROUP BY department
)
SELECT
    CASE
      WHEN department IS NULL OR LENGTH(department) = 0 THEN 'empty after normalising'
      WHEN LENGTH(department) = 1                       THEN 'single character'
      WHEN LENGTH(department) > 200                     THEN 'very long (>200 chars)'
      ELSE 'usable'
    END                                                 AS bucket,
    COUNT(*)                                            AS departments,
    SUM(records)                                        AS records
FROM normalised
GROUP BY bucket
ORDER BY records DESC;

-- Same check on the title side
WITH normalised AS (
  SELECT
      TRIM(REGEXP_REPLACE(
        REGEXP_REPLACE(LOWER(NORMALIZE_AND_CASEFOLD(e.role, NFKC)),
          r'[^\p{L}\p{N}\s&/+-]', ' '), r'\s+', ' '))  AS title,
      COUNT(*)                                         AS records
  FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers` r,
  UNNEST(r.employments) e
  WHERE r.snid IS NOT NULL AND UPPER(e.visibility) = 'PUBLIC'
    AND e.role IS NOT NULL AND TRIM(e.role) != ''
  GROUP BY title
)
SELECT
    CASE
      WHEN title IS NULL OR LENGTH(title) = 0 THEN 'empty after normalising'
      WHEN LENGTH(title) = 1                  THEN 'single character'
      WHEN LENGTH(title) > 200                THEN 'very long (>200 chars)'
      ELSE 'usable'
    END                                       AS bucket,
    COUNT(*)                                  AS titles,
    SUM(records)                              AS records
FROM normalised
GROUP BY bucket
ORDER BY records DESC;

/*
    THE FIX, now applied to analyses 05 - 08:

      1. source side  - HAVING LENGTH(x) BETWEEN 2 AND 200
                        keeps unusable strings out of the model entirely
      2. model side   - WHERE ARRAY_LENGTH(ml_generate_embedding_result) > 0
                        drops anything that still failed to embed

    Both guards are needed. The first is cheap and removes the known
    causes; the second catches transient failures, which do happen at
    volume. Production models need the same two guards - a single empty
    vector would break an entire VECTOR_SEARCH run.
*/
