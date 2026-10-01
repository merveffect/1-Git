/*
    ============================================================================
    LIBRARIAN - ITS OWN PATH
    ============================================================================
    Measured on the whole corpus, not the top 500:

        distinct librarian titles   969
        records                  26,047
        people                    1,154
        in CDP                    1,066   (92%)
        MARKETABLE                  258

    Three conclusions follow.

    1. LIBRARIAN DOES NOT BELONG ON THE SHARED TITLE AXIS
       1,154 people cannot compete for anchor space against 9.4M
       professors. In the v2 test the librarian group collected exactly
       two titles, both wrong. A plain regex over the full corpus finds
       them perfectly - no embedding needed.

    2. 969 DISTINCT TITLES FOR 1,154 PEOPLE
       Almost one title per person. There is no frequency head to review;
       the whole thing is tail. Another reason embeddings add nothing -
       there is no repetition to amortise the cost against.

    3. ORCID IS STRUCTURALLY THE WRONG SOURCE FOR LIBRARIANS
       ORCID is a researcher identifier. Librarians are not researchers,
       so most of them never create one. 258 marketable people is not a
       pipeline failure - it is the size of the overlap between "has an
       ORCID" and "is a librarian".
       If a librarian audience matters commercially, it needs a different
       source: CDP self-reported role, institutional contacts, or
       conference registrations.

    THE REGEX NEEDS TIGHTENING. Query 1 output contained false positives:
        guest scientist-lentiviral library oxstress dna-sensing
            -> a DNA library, a laboratory technique, not a library
        chief information officer / chief data scientist & chief research
        information officer / teratogen information specialist
            -> IT and clinical roles, not library roles
    Queries below separate confident matches from the ones to exclude.
    ============================================================================
*/


-- ###########################################################################
-- QUERY 1 - TIGHTENED DETECTION
--   Strong patterns accept outright. Weak patterns only count when a
--   library word appears alongside them.
-- ###########################################################################
WITH titles AS (
  SELECT
      r.snid,
      TRIM(REGEXP_REPLACE(
        REGEXP_REPLACE(LOWER(NORMALIZE_AND_CASEFOLD(e.role, NFKC)),
          r'[^\p{L}\p{N}\s&/+-]', ' '), r'\s+', ' ')) AS title
  FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers` r,
  UNNEST(r.employments) e
  WHERE r.snid IS NOT NULL AND UPPER(e.visibility) = 'PUBLIC'
    AND e.role IS NOT NULL AND TRIM(e.role) != ''
),
classified AS (
  SELECT
      snid, title,
      CASE
        -- a laboratory DNA library is not a library
        WHEN REGEXP_CONTAINS(title,
          r'(lentiviral|plasmid|cdna|genomic|compound|peptide|phage|clone) librar')
          THEN 'excluded_lab_library'

        -- "information officer/specialist" without a library word is IT
        WHEN REGEXP_CONTAINS(title, r'(information (officer|specialist|technology))')
         AND NOT REGEXP_CONTAINS(title, r'(librar|bibliot|archiv|scholarly|repositor|open access)')
          THEN 'excluded_information_role'

        -- unambiguous
        WHEN REGEXP_CONTAINS(title,
          r'(librarian|bibliothekar|bibliotecari|bibliotecár|bibliothécaire|bibliothecaris|kutuphaneci|kütüphaneci)')
          THEN 'librarian'

        -- library staff who are not called librarian
        WHEN REGEXP_CONTAINS(title,
          r'(librar(y|ies) (assistant|manager|officer|director|trainee|intern)|head of librar|deputy director librar|librar(y|ies) staff)')
          THEN 'library_staff'

        -- scholarly communication and open access roles
        WHEN REGEXP_CONTAINS(title,
          r'(scholarly communicat|repository manager|institutional repositor|open access (officer|manager|coordinator))')
          THEN 'scholarly_communication'

        WHEN REGEXP_CONTAINS(title, r'(archivist|archiviste|arsivci|arşivci)')
          THEN 'archivist'

        ELSE 'not_librarian'
      END AS bucket
  FROM titles
)
SELECT
    bucket,
    COUNT(*)                    AS records,
    COUNT(DISTINCT snid)        AS people,
    COUNT(DISTINCT title)       AS distinct_titles,
    STRING_AGG(DISTINCT title, ' | ' ORDER BY title LIMIT 6) AS examples
FROM classified
WHERE bucket != 'not_librarian'
GROUP BY bucket
ORDER BY people DESC;


-- ###########################################################################
-- QUERY 2 - THE ADDRESSABLE AUDIENCE
--   The only number the business acts on.
-- ###########################################################################
WITH titles AS (
  SELECT
      r.snid,
      TRIM(REGEXP_REPLACE(
        REGEXP_REPLACE(LOWER(NORMALIZE_AND_CASEFOLD(e.role, NFKC)),
          r'[^\p{L}\p{N}\s&/+-]', ' '), r'\s+', ' ')) AS title,
      e.full_end_date IS NULL                         AS is_current,
      e.organisation_name                             AS organisation
  FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers` r,
  UNNEST(r.employments) e
  WHERE r.snid IS NOT NULL AND UPPER(e.visibility) = 'PUBLIC'
    AND e.role IS NOT NULL AND TRIM(e.role) != ''
),
librarians AS (
  SELECT snid, is_current, organisation
  FROM titles
  WHERE REGEXP_CONTAINS(title,
        r'(librarian|bibliothekar|bibliotecari|bibliotecár|bibliothécaire|bibliothecaris|kutuphaneci|kütüphaneci|librar(y|ies) (assistant|manager|officer|director|trainee)|head of librar|scholarly communicat|repository manager|institutional repositor|open access (officer|manager|coordinator)|archivist|archiviste|arsivci)')
    AND NOT REGEXP_CONTAINS(title,
        r'(lentiviral|plasmid|cdna|genomic|compound|peptide|phage|clone) librar')
)
SELECT
    'all librarians'                                            AS segment,
    COUNT(DISTINCT l.snid)                                      AS people,
    COUNT(DISTINCT IF(c.snid IS NOT NULL, l.snid, NULL))        AS in_cdp,
    COUNT(DISTINCT IF(c.mkt_pref_opt_in, l.snid, NULL))         AS marketable,
    COUNT(DISTINCT IF(c.advertising_opt_in, l.snid, NULL))      AS advertisable
FROM librarians l
LEFT JOIN `researcher-360-prod-e7fd74be.researcher_profiles.audience_builder_big` c
       ON l.snid = c.snid

UNION ALL

SELECT
    'current post only',
    COUNT(DISTINCT l.snid),
    COUNT(DISTINCT IF(c.snid IS NOT NULL, l.snid, NULL)),
    COUNT(DISTINCT IF(c.mkt_pref_opt_in, l.snid, NULL)),
    COUNT(DISTINCT IF(c.advertising_opt_in, l.snid, NULL))
FROM librarians l
LEFT JOIN `researcher-360-prod-e7fd74be.researcher_profiles.audience_builder_big` c
       ON l.snid = c.snid
WHERE l.is_current;

/*
    The librarian role definition requires a CURRENT post, because the
    commercial purpose is institutional sales and licence renewal - a
    librarian who left in 2014 does not sign this year's licence. The
    second row is therefore the real audience.

    Whatever that number is, the decision it forces is the same: is a
    librarian audience of this size worth carrying as a role, or does it
    need a source other than ORCID? That is a commercial call, not a
    technical one.
*/


-- ###########################################################################
-- QUERY 3 - WHO EMPLOYS THEM
--   If librarians cluster in a small number of institutions, an
--   organisation-based route could reach more of them than ORCID does.
-- ###########################################################################
WITH titles AS (
  SELECT
      r.snid,
      TRIM(REGEXP_REPLACE(
        REGEXP_REPLACE(LOWER(NORMALIZE_AND_CASEFOLD(e.role, NFKC)),
          r'[^\p{L}\p{N}\s&/+-]', ' '), r'\s+', ' ')) AS title,
      e.organisation_name                             AS organisation,
      e.organisation_address_country_code             AS country
  FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers` r,
  UNNEST(r.employments) e
  WHERE r.snid IS NOT NULL AND UPPER(e.visibility) = 'PUBLIC'
    AND e.role IS NOT NULL AND TRIM(e.role) != ''
)
SELECT
    country,
    COUNT(DISTINCT snid)    AS librarians,
    COUNT(DISTINCT organisation) AS organisations
FROM titles
WHERE REGEXP_CONTAINS(title,
      r'(librarian|bibliothekar|bibliotecari|kutuphaneci|head of librar|scholarly communicat|repository manager|archivist)')
  AND NOT REGEXP_CONTAINS(title, r'(lentiviral|plasmid|cdna|genomic|compound|peptide) librar')
GROUP BY country
ORDER BY librarians DESC
LIMIT 20;
