/*
    ============================================================================
    HOW MANY PEOPLE CAN WE REACH AT ALL?
    ============================================================================
    We have measured the two consent flags separately:
        marketing consent     423,904
        advertising consent   328,406
    but never their union, which is the number that actually answers
    "how many people is this project working with".

    The two cannot simply be added. The Phase-2 document observed on the
    HCP subset that the flags overlap almost completely - 11,827 people
    held both out of 11,830 with advertising consent - meaning advertising
    consent is essentially a subset of marketing consent. If that holds on
    the full population, the union is close to 423,904 rather than the
    752,310 you would get by adding them.

    This query settles it on the real population instead of assuming.
    ============================================================================
*/

-- ---------------------------------------------------------------------------
-- 1. THE HEADLINE NUMBER
--    Everyone we could contact through at least one channel.
-- ---------------------------------------------------------------------------
WITH orcid_people AS (
  SELECT DISTINCT r.snid
  FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers` r
  WHERE r.snid IS NOT NULL
),
scoreable AS (
  -- people who additionally have a usable employment record, i.e. the
  -- population this pipeline can actually assign a role to
  SELECT DISTINCT r.snid
  FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers` r,
  UNNEST(r.employments) e
  WHERE r.snid IS NOT NULL
    AND UPPER(e.visibility) = 'PUBLIC'
    AND e.role IS NOT NULL AND TRIM(e.role) != ''
)
SELECT
    'all ORCID people with an SNID'                             AS population,
    COUNT(DISTINCT o.snid)                                      AS people,
    COUNT(DISTINCT IF(c.snid IS NOT NULL, o.snid, NULL))        AS in_cdp,
    COUNT(DISTINCT IF(c.mkt_pref_opt_in, o.snid, NULL))         AS marketing_only_flag,
    COUNT(DISTINCT IF(c.advertising_opt_in, o.snid, NULL))      AS advertising_only_flag,
    COUNT(DISTINCT IF(c.mkt_pref_opt_in OR c.advertising_opt_in,
                      o.snid, NULL))                            AS reachable_either,
    COUNT(DISTINCT IF(c.mkt_pref_opt_in AND c.advertising_opt_in,
                      o.snid, NULL))                            AS both_consents
FROM orcid_people o
LEFT JOIN `researcher-360-prod-e7fd74be.researcher_profiles.audience_builder_big` c
       ON o.snid = c.snid

UNION ALL

SELECT
    'with a usable employment record',
    COUNT(DISTINCT s.snid),
    COUNT(DISTINCT IF(c.snid IS NOT NULL, s.snid, NULL)),
    COUNT(DISTINCT IF(c.mkt_pref_opt_in, s.snid, NULL)),
    COUNT(DISTINCT IF(c.advertising_opt_in, s.snid, NULL)),
    COUNT(DISTINCT IF(c.mkt_pref_opt_in OR c.advertising_opt_in, s.snid, NULL)),
    COUNT(DISTINCT IF(c.mkt_pref_opt_in AND c.advertising_opt_in, s.snid, NULL))
FROM scoreable s
LEFT JOIN `researcher-360-prod-e7fd74be.researcher_profiles.audience_builder_big` c
       ON s.snid = c.snid;

/*
    reachable_either is the number to quote. The second row is the one
    this pipeline can actually act on, because a person with no public
    job title cannot be given a role.
*/


-- ---------------------------------------------------------------------------
-- 2. HOW THE TWO FLAGS OVERLAP
--    Confirms whether advertising consent really is a subset.
-- ---------------------------------------------------------------------------
WITH orcid_people AS (
  SELECT DISTINCT r.snid
  FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers` r
  WHERE r.snid IS NOT NULL
)
SELECT
    CASE
      WHEN c.snid IS NULL                                   THEN '4. not in CDP at all'
      WHEN c.mkt_pref_opt_in AND c.advertising_opt_in       THEN '1. both consents'
      WHEN c.mkt_pref_opt_in                                THEN '2. marketing only'
      WHEN c.advertising_opt_in                             THEN '3. advertising only'
      ELSE                                                       '5. in CDP, no consent'
    END                                                     AS consent_state,
    COUNT(DISTINCT o.snid)                                  AS people,
    ROUND(COUNT(DISTINCT o.snid)
          / SUM(COUNT(DISTINCT o.snid)) OVER (), 4)         AS share
FROM orcid_people o
LEFT JOIN `researcher-360-prod-e7fd74be.researcher_profiles.audience_builder_big` c
       ON o.snid = c.snid
GROUP BY consent_state
ORDER BY consent_state;

/*
    If "advertising only" is close to zero, advertising consent is a
    subset of marketing consent and the union equals the marketing figure.
    That is what the Phase-2 document found on the HCP subset; this checks
    it on the whole population.
*/
