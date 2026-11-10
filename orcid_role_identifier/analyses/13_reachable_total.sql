/*
    ============================================================================
    HOW MANY PEOPLE CAN WE REACH AT ALL?
    ============================================================================
    REWRITTEN 2026-10-16. This file asked a two-flag question and told the
    reader "reachable_either is the number to quote". The pipeline counts
    three consent bases since legitimate interest was added, so the number
    it printed was 210,730 against a headline of 497,798 - a 2.4x
    contradiction inside our own repo, and the kind a stakeholder finds
    before we do.

    Two things were wrong, and the second one was quieter:

      1. It read mkt_pref_opt_in and advertising_opt_in only. Marketing's
         instruction on 2026-10-16 was that legitimate interest is not a
         lesser basis - a person opted in under any of the three is an
         opted-in person.

      2. It joined the raw CDP source directly, which holds several rows
         per SNID, so COUNT(DISTINCT IF(flag, snid, NULL)) counted anybody
         with ANY consenting row. The pipeline deliberately does the
         opposite: raw_audience_builder_big aggregates with LOGICAL_AND, so
         every row has to consent. This file was the more permissive of
         the two and nothing said so.

    Both are fixed by reading raw_audience_builder_big instead of the
    source. There is now one definition of consent in the project and this
    query cannot drift from it again.

    What the old header was asking, kept because the answer still matters:
    advertising consent is close to a subset of marketing consent, so the
    flags cannot be added. Query 2 is what settles that.
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
    COUNT(DISTINCT IF(c.is_legitimate_interest, o.snid, NULL)) AS legitimate_interest_flag,
    COUNT(DISTINCT IF(c.mkt_pref_opt_in OR c.advertising_opt_in
                      OR c.is_legitimate_interest,
                      o.snid, NULL))                            AS reachable_any_basis,
    COUNT(DISTINCT IF(c.mkt_pref_opt_in AND c.advertising_opt_in,
                      o.snid, NULL))                            AS both_consents
FROM orcid_people o
LEFT JOIN `dat-analytics-eng-ec869189.dev_orcid_role_identifier_raw.raw_audience_builder_big` c
       ON o.snid = c.snid

UNION ALL

SELECT
    'with a usable employment record',
    COUNT(DISTINCT s.snid),
    COUNT(DISTINCT IF(c.snid IS NOT NULL, s.snid, NULL)),
    COUNT(DISTINCT IF(c.mkt_pref_opt_in, s.snid, NULL)),
    COUNT(DISTINCT IF(c.advertising_opt_in, s.snid, NULL)),
    COUNT(DISTINCT IF(c.is_legitimate_interest, s.snid, NULL)),
    COUNT(DISTINCT IF(c.mkt_pref_opt_in OR c.advertising_opt_in
                      OR c.is_legitimate_interest, s.snid, NULL)),
    COUNT(DISTINCT IF(c.mkt_pref_opt_in AND c.advertising_opt_in, s.snid, NULL))
FROM scoreable s
LEFT JOIN `dat-analytics-eng-ec869189.dev_orcid_role_identifier_raw.raw_audience_builder_big` c
       ON s.snid = c.snid;

/*
    reachable_any_basis is the number to quote. The second row is the one
    this pipeline can actually act on, because a person with no public
    job title cannot be given a role.
*/


-- ---------------------------------------------------------------------------
-- 2. HOW THE THREE BASES OVERLAP
--    Confirms whether advertising consent really is a subset, and sizes
--    the group that legitimate interest reaches on its own. That last
--    bucket is the whole reason the headline moved: with two flags these
--    people counted as "no consent", which was not true of them.
-- ---------------------------------------------------------------------------
WITH orcid_people AS (
  SELECT DISTINCT r.snid
  FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers` r
  WHERE r.snid IS NOT NULL
)
SELECT
    CASE
      WHEN c.snid IS NULL                                   THEN '5. not in CDP at all'
      WHEN c.mkt_pref_opt_in AND c.advertising_opt_in       THEN '1. both marketing and advertising'
      WHEN c.mkt_pref_opt_in                                THEN '2. marketing only'
      WHEN c.advertising_opt_in                             THEN '3. advertising only'
      WHEN c.is_legitimate_interest                         THEN '4. legitimate interest only'
      ELSE                                                       '6. in CDP, no basis at all'
    END                                                     AS consent_state,
    COUNT(DISTINCT o.snid)                                  AS people,
    ROUND(COUNT(DISTINCT o.snid)
          / SUM(COUNT(DISTINCT o.snid)) OVER (), 4)         AS share
FROM orcid_people o
LEFT JOIN `dat-analytics-eng-ec869189.dev_orcid_role_identifier_raw.raw_audience_builder_big` c
       ON o.snid = c.snid
GROUP BY consent_state
ORDER BY consent_state;

/*
    Two things to read off this.

    If "advertising only" is close to zero, advertising consent is a
    subset of marketing consent and those two cannot be added. That is
    what the Phase-2 document found on the HCP subset; this checks it on
    the whole population, and the last measurement agreed - 152,695 with
    advertising consent, 152,682 of them also holding marketing consent.

    "legitimate interest only" is the bucket that was previously invisible.
    Under the old two-flag question these people were counted as having no
    consent, and they are the reason the reachable figure roughly doubled.
    They are not a lesser tier: marketing's instruction on 2026-10-16 was
    to treat any one of the three bases as an opted-in person.
*/
