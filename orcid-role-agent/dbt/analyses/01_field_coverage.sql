/*
    ============================================================================
    FIELD COVERAGE ANALYSIS
    ============================================================================
    Queries to run BEFORE making design decisions.
    "How populated is each field, and which can we rely on?"

    What the output decides for us:
      - if department_name is mostly empty the 0.20 dept weight is wasted -> redistribute
      - low ROR coverage makes name matching essential; high coverage makes it redundant
      - low CDP overlap means lowering the audience expectation up front
      - if publications are populated, Phase-2 signals can be derived from ORCID
    ============================================================================
*/

-- ---------------------------------------------------------------------------
-- 1. PERSON LEVEL - how many people have each array populated?
-- ---------------------------------------------------------------------------
SELECT
    COUNT(*)                                             AS people,
    COUNTIF(ARRAY_LENGTH(employments) > 0)               AS has_employment,
    COUNTIF(ARRAY_LENGTH(educations)  > 0)               AS has_education,
    COUNTIF(ARRAY_LENGTH(publications)> 0)               AS has_publications,
    COUNTIF(ARRAY_LENGTH(keywords)    > 0)               AS has_keywords,
    COUNTIF(ARRAY_LENGTH(peer_reviews)> 0)               AS has_peer_reviews,
    COUNTIF(ARRAY_LENGTH(emails)      > 0)               AS has_email,
    ROUND(COUNTIF(ARRAY_LENGTH(employments) > 0) / COUNT(*), 3)  AS employment_ratioi
FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers`;


-- ---------------------------------------------------------------------------
-- 2. EMPLOYMENT SUBFIELDS - the fields scoring depends on
--    weighted role 0.50 / organisation 0.30 / department 0.20.
--    if department is mostly empty that weight is being wasted.
-- ---------------------------------------------------------------------------
SELECT
    COUNT(*)                                                    AS employment_records,
    ROUND(COUNTIF(e.role              IS NOT NULL) / COUNT(*), 3) AS role_filled,
    ROUND(COUNTIF(e.organisation_name IS NOT NULL) / COUNT(*), 3) AS organisation_filled,
    ROUND(COUNTIF(e.department_name   IS NOT NULL) / COUNT(*), 3) AS department_filled,
    ROUND(COUNTIF(e.organisation_address_country_code IS NOT NULL) / COUNT(*), 3) AS country_filled,
    ROUND(COUNTIF(e.full_start_date   IS NOT NULL) / COUNT(*), 3) AS start_date_filled,
    ROUND(COUNTIF(e.disambiguated_organisation_id IS NOT NULL) / COUNT(*), 3) AS org_id_filled,
    -- uc alan birden dolu olan records ratioi: tam skorlanabilir recordslar
    ROUND(COUNTIF(e.role IS NOT NULL
              AND e.organisation_name IS NOT NULL
              AND e.department_name IS NOT NULL) / COUNT(*), 3)  AS all_three_filled
FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers`,
UNNEST(employments) e;


-- ---------------------------------------------------------------------------
-- 3. EDUCATION SUBFIELDS
-- ---------------------------------------------------------------------------
SELECT
    COUNT(*)                                                      AS education_records,
    ROUND(COUNTIF(d.degree            IS NOT NULL) / COUNT(*), 3) AS degree_filled,
    ROUND(COUNTIF(d.department_name   IS NOT NULL) / COUNT(*), 3) AS department_filled,
    ROUND(COUNTIF(d.organisation_name IS NOT NULL) / COUNT(*), 3) AS organisation_filled
FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers`,
UNNEST(educations) d;


-- ---------------------------------------------------------------------------
-- 4. ⭐ KURUM KIMLIGI KAYNAGI - kac records BEDAVA ROR kimligi tasiyor?
--    High ROR coverage removes the need for name matching.
-- ---------------------------------------------------------------------------
SELECT
    UPPER(e.disambiguated_organisation_source)      AS id_source,
    COUNT(*)                                        AS records,
    COUNT(DISTINCT e.organisation_name)             AS distinct_orgs,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER (), 3)      AS ratio
FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers`,
UNNEST(employments) e
GROUP BY id_source
ORDER BY records DESC;


-- ---------------------------------------------------------------------------
-- 5. VISIBILITY - non-public data will not be used.
--    PUBLIC ratioi dusukse hacim beklentisi bastan dusmeli.
-- ---------------------------------------------------------------------------
SELECT
    UPPER(e.visibility)                             AS visibility,
    COUNT(*)                                        AS records,
    COUNT(DISTINCT r.snid)                          AS people,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER (), 3)      AS ratio
FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers` r,
UNNEST(r.employments) e
GROUP BY visibility ORDER BY records DESC;

-- PUBLIC employment kaydi HIC olmayan people sayisi (tamamen disarida kalanlar)
SELECT
    COUNT(*)                                                    AS people,
    COUNTIF((SELECT COUNT(*) FROM UNNEST(employments) e
             WHERE UPPER(e.visibility) = 'PUBLIC') = 0)         AS public_no_employment
FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers`;


-- ---------------------------------------------------------------------------
-- 6. ⭐ CDP ORTAKLIGI - kac ORCID peoplesine gercekten ulasabiliriz?
--    Phase-1'de bu ratio %21'di. Audience beklentisini bu belirliyor.
-- ---------------------------------------------------------------------------
SELECT
    COUNT(DISTINCT o.snid)                                      AS orcid_people,
    COUNT(DISTINCT c.snid)                                      AS in_cdp,
    COUNT(DISTINCT IF(c.mkt_pref_opt_in,    c.snid, NULL))      AS marketing_opt_in,
    COUNT(DISTINCT IF(c.advertising_opt_in, c.snid, NULL))      AS advertising_opt_in,
    ROUND(COUNT(DISTINCT c.snid) / COUNT(DISTINCT o.snid), 3)   AS cdp_coverage
FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers` o
LEFT JOIN `researcher-360-prod-e7fd74be.researcher_profiles.audience_builder_big` c
       ON o.snid = c.snid;


-- ---------------------------------------------------------------------------
-- 7. SCRIPT DISTRIBUTION - is a multilingual model really needed?
--    Latin disi karakter iceren titlelarin ratioi.
-- ---------------------------------------------------------------------------
SELECT
    CASE
        WHEN REGEXP_CONTAINS(e.role, r'[\p{Han}\p{Hiragana}\p{Katakana}]') THEN 'CJK'
        WHEN REGEXP_CONTAINS(e.role, r'[\p{Cyrillic}]')                    THEN 'Cyrillic'
        WHEN REGEXP_CONTAINS(e.role, r'[\p{Arabic}]')                      THEN 'Arabic'
        WHEN REGEXP_CONTAINS(e.role, r'[äöüßàâçéèêëñõçğışİÖÜÇ]')           THEN 'Latin-accented'
        ELSE 'Latin-plain'
    END                                             AS script,
    COUNT(*)                                        AS records,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER (), 3)      AS ratio
FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers`,
UNNEST(employments) e
WHERE e.role IS NOT NULL
GROUP BY script ORDER BY records DESC;


-- ---------------------------------------------------------------------------
-- 8. PUBLICATIONS - can Phase-2 signals be derived from ORCID?
--    (for Phase 6; could rescue the 79% absent from CDP)
-- ---------------------------------------------------------------------------
SELECT
    COUNT(*)                                                    AS publication_records,
    COUNT(DISTINCT r.snid)                                      AS yayini_olan_people,
    ROUND(COUNTIF(p.journal_title IS NOT NULL) / COUNT(*), 3)   AS journal_title_filled,
    ROUND(COUNTIF(p.doi IS NOT NULL) / COUNT(*), 3)             AS doi_filled,
    COUNT(DISTINCT p.journal_title)                             AS distinct_journals
FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers` r,
UNNEST(r.publications) p;
