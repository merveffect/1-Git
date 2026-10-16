/*
    ============================================================================
    HOW MUCH OF THE DEGREE VOCABULARY DOES THE REGEX ACTUALLY CATCH?
    ============================================================================
    Job titles are matched with multilingual embeddings. Degrees are still
    matched with a hand-written English regex list (13 rules). This query
    measures the gap.

    If coverage is high, expand the regex and move on. If it is low, degrees
    need the same embedding treatment as titles - they are just another
    free-text vocabulary.

    Runs against the source; no dbt models required.
    ============================================================================
*/

-- ---------------------------------------------------------------------------
-- 1. Overall coverage of the current HCP degree rules
-- ---------------------------------------------------------------------------
WITH edu AS (
  SELECT
      r.snid,
      TRIM(REGEXP_REPLACE(
        REGEXP_REPLACE(LOWER(NORMALIZE_AND_CASEFOLD(d.degree, NFKC)),
          r'[^\p{L}\p{N}\s&/+-]', ' '), r'\s+', ' ')) AS degree
  FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers` r,
  UNNEST(r.educations) d
  WHERE r.snid IS NOT NULL
    AND UPPER(d.visibility) = 'PUBLIC'
    AND d.degree IS NOT NULL AND TRIM(d.degree) != ''
)
SELECT
    COUNT(*)                                                    AS education_records,
    COUNT(DISTINCT degree)                                      AS distinct_degrees,

    -- the clinical rules currently in seeds/education_signals.csv
    COUNTIF(REGEXP_CONTAINS(degree,
      r'\b(md|m d|mbbs|mbbch|mb chb|mbchb|bm bch|doctor of medicine|doctor of dental|bds|dds|dmd|bachelor of nursing|bsc nursing|msc nursing|registered nurse|do|doctor of osteopath|pharmd|pharm d|bpharm|b pharm|mpharm|m pharm|bachelor of pharmacy|master of pharmacy|doctor of pharmacy|mlis|mls|master of library)\b'))
                                                                AS matched_by_regex,

    -- degrees that LOOK clinical in any language but the regex misses
    COUNTIF(NOT REGEXP_CONTAINS(degree,
      r'\b(md|m d|mbbs|mbbch|mb chb|mbchb|bm bch|doctor of medicine|doctor of dental|bds|dds|dmd|bachelor of nursing|bsc nursing|msc nursing|registered nurse|do|doctor of osteopath|pharmd|pharm d|bpharm|b pharm|mpharm|m pharm|bachelor of pharmacy|master of pharmacy|doctor of pharmacy|mlis|mls|master of library)\b')
      AND REGEXP_CONTAINS(degree,
      r'(medic|medizin|medecin|medicina|tip |tıp|arzt|chirurg|surger|cirug|nurs|infirm|krankenpfleg|hemsire|zahn|dent|odonto|pharma|eczaci|apothek|farmac|clinic|klinik|医学|医師|医薬)'))
                                                                AS clinical_but_missed,

    ROUND(COUNTIF(REGEXP_CONTAINS(degree,
      r'\b(md|m d|mbbs|mbbch|mb chb|mbchb|bm bch|doctor of medicine|doctor of dental|bds|dds|dmd|bachelor of nursing|bsc nursing|msc nursing|registered nurse|do|doctor of osteopath|pharmd|pharm d|bpharm|b pharm|mpharm|m pharm|bachelor of pharmacy|master of pharmacy|doctor of pharmacy|mlis|mls|master of library)\b')) / COUNT(*), 4)
                                                                AS regex_hit_rate
FROM edu;


-- ---------------------------------------------------------------------------
-- 2. The 100 most common degrees the regex MISSES
--    This is the list that decides: expand the regex, or embed degrees.
-- ---------------------------------------------------------------------------
WITH edu AS (
  SELECT
      TRIM(REGEXP_REPLACE(
        REGEXP_REPLACE(LOWER(NORMALIZE_AND_CASEFOLD(d.degree, NFKC)),
          r'[^\p{L}\p{N}\s&/+-]', ' '), r'\s+', ' ')) AS degree
  FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers` r,
  UNNEST(r.educations) d
  WHERE r.snid IS NOT NULL AND UPPER(d.visibility) = 'PUBLIC'
    AND d.degree IS NOT NULL AND TRIM(d.degree) != ''
)
SELECT
    degree,
    COUNT(*)                                    AS records,
    ROUND(SUM(COUNT(*)) OVER (ORDER BY COUNT(*) DESC)
          / SUM(COUNT(*)) OVER (), 4)           AS cumulative_share
FROM edu
WHERE NOT REGEXP_CONTAINS(degree,
  r'\b(md|m d|mbbs|mbbch|mb chb|mbchb|bm bch|doctor of medicine|doctor of dental|bds|dds|dmd|bachelor of nursing|bsc nursing|msc nursing|registered nurse|do|doctor of osteopath|pharmd|pharm d|bpharm|b pharm|mpharm|m pharm|bachelor of pharmacy|master of pharmacy|doctor of pharmacy|mlis|mls|master of library)\b')
GROUP BY degree
ORDER BY records DESC
LIMIT 100;


-- ---------------------------------------------------------------------------
-- 3. Is the degree vocabulary small enough to embed?
--    Titles are hundreds of thousands. If degrees are far fewer, embedding
--    them is cheap and the inconsistency disappears.
-- ---------------------------------------------------------------------------
WITH edu AS (
  SELECT
      TRIM(REGEXP_REPLACE(
        REGEXP_REPLACE(LOWER(NORMALIZE_AND_CASEFOLD(d.degree, NFKC)),
          r'[^\p{L}\p{N}\s&/+-]', ' '), r'\s+', ' ')) AS degree
  FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers` r,
  UNNEST(r.educations) d
  WHERE r.snid IS NOT NULL AND UPPER(d.visibility) = 'PUBLIC'
    AND d.degree IS NOT NULL AND TRIM(d.degree) != ''
),
freq AS (
  SELECT degree, COUNT(*) n, ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) rnk
  FROM edu GROUP BY degree
),
cum AS (SELECT *, SUM(n) OVER (ORDER BY rnk) / SUM(n) OVER () AS coverage FROM freq)
SELECT
    cutoff AS top_n_degrees,
    (SELECT ROUND(MAX(coverage), 4) FROM cum WHERE rnk <= cutoff) AS record_coverage
FROM UNNEST([50, 100, 250, 500, 1000, 5000, 20000]) AS cutoff
ORDER BY cutoff;

/*
    HOW TO DECIDE

    Query 1  regex_hit_rate high and clinical_but_missed small
             -> expand the regex, done.

             regex_hit_rate low, clinical_but_missed large
             -> degrees need embeddings, same as titles.

    Query 2  read the list. If the misses are "dr med", "docteur en
             medecine", "tip doktoru" - that is exactly the multilingual
             problem embeddings already solve for titles.

    Query 3  if a few thousand distinct degrees cover most records, the
             embedding cost is trivial next to the title vocabulary.
*/
