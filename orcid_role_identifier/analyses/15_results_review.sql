/*
    ============================================================================
    RESULTS REVIEW — run these in order after a full dbt run
    ============================================================================
    Dataset prefix below is the dev target. For prod, swap
    dev_orcid_role_identifier_* for prod_orcid_role_identifier_*.

    Order matters: 1-3 are the headline, 4-6 check whether the headline
    can be trusted, 7 is an open question the first run exposed.
    ============================================================================
*/

-- ###########################################################################
-- 1. THE HEADLINE — how many people per role, and how many we can reach
-- ###########################################################################
SELECT *
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_presentation.fct_role_audience_summary`
ORDER BY identified DESC;


-- ###########################################################################
-- 2. CONFIDENCE SPLIT — how much of each role is CONFIRMED vs PROBABLE
--    Only CONFIRMED goes to Braze by default, so this is the real size.
-- ###########################################################################
SELECT
    role_key,
    role_label,
    COUNT(DISTINCT snid)                    AS people,
    ROUND(AVG(role_final_score), 3)         AS avg_score,
    ROUND(MIN(role_final_score), 3)         AS min_score,
    ROUND(MAX(role_final_score), 3)         AS max_score
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles`
GROUP BY role_key, role_label
ORDER BY role_key, role_label;


-- ###########################################################################
-- 3. MULTI-ROLE — does a person hold more than one role, as designed?
--    A professor of cardiology should be both lecturer and hcp.
-- ###########################################################################
SELECT
    role_count,
    COUNT(*)                                AS people,
    STRING_AGG(DISTINCT ARRAY_TO_STRING(roles, ' + ') ORDER BY ARRAY_TO_STRING(roles, ' + ') LIMIT 6) AS example_combinations
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_presentation.dim_researcher_role_flags`
GROUP BY role_count
ORDER BY role_count;

-- The most common actual combinations:
SELECT
    ARRAY_TO_STRING(roles, ' + ')           AS combination,
    COUNT(*)                                AS people
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_presentation.dim_researcher_role_flags`
GROUP BY combination
ORDER BY people DESC
LIMIT 20;


-- ###########################################################################
-- 4. THE EYEBALL TEST — the 20 most common job titles behind each role
--    If these read wrong, nothing downstream matters.
-- ###########################################################################
SELECT
    role_key,
    evidence_title,
    evidence_dept,
    COUNT(*)                                AS people,
    ROUND(AVG(role_final_score), 2)         AS avg_score
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles`
WHERE role_label = 'CONFIRMED'
GROUP BY role_key, evidence_title, evidence_dept
QUALIFY ROW_NUMBER() OVER (PARTITION BY role_key ORDER BY COUNT(*) DESC) <= 20
ORDER BY role_key, people DESC;


-- ###########################################################################
-- 5. DICTIONARY QUALITY — what the two axes produced
-- ###########################################################################
SELECT
    'title' AS axis, title_group AS grp,
    COUNT(*)                                AS distinct_values,
    SUM(frequency)                          AS records,
    ROUND(AVG(margin), 3)                   AS avg_margin,
    COUNTIF(NOT is_assigned)                AS rejected
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
GROUP BY grp
UNION ALL
SELECT
    'discipline', discipline,
    COUNT(*), SUM(frequency), ROUND(AVG(margin), 3), COUNTIF(NOT is_assigned)
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_department_discipline`
GROUP BY discipline
ORDER BY axis, records DESC;


-- ###########################################################################
-- 6. THE REVIEW QUEUE — ambiguous values worth a human decision,
--    ordered by how many records ride on them
-- ###########################################################################
SELECT *
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_presentation.rpt_title_review_queue`
ORDER BY frequency DESC
LIMIT 100;


-- ###########################################################################
-- 7. OPEN QUESTION — why did the RINGGOLD bridge produce nothing?
--
--    Measured on the source: RINGGOLD is on 31.7% of ORCID employment
--    records, the biggest non-ROR identifier system. But
--    org_resolution_method returned only ORCID_ROR_ID, EXTERNAL_ID_GRID,
--    NAME_EXACT and null - no EXTERNAL_ID_RINGGOLD at all.
--
--    The likely reason: ROR publishes GRID, ISNI, FundRef and Wikidata in
--    external_ids, but NOT Ringgold, which is a commercial identifier.
--    If so the bridge cannot work for it and those records correctly fall
--    through to name matching or the organisation-name fallback.
-- ###########################################################################
SELECT
    id_type,
    COUNT(*)                                AS rows,
    COUNT(DISTINCT ror_id)                  AS organisations
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_staging.stg_ror__external_ids`
GROUP BY id_type
ORDER BY rows DESC;

-- And what ORCID is asking us to resolve, for comparison:
SELECT
    org_id_source,
    COUNT(*)                                AS records,
    COUNT(DISTINCT organisation)            AS distinct_orgs
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_staging.stg_role_records`
GROUP BY org_id_source
ORDER BY records DESC;

/*
    If stg_ror__external_ids has no RINGGOLD row, the bridge is not broken
    - ROR simply does not carry that mapping, and nothing we write will
    change it. The 31.7% then rely on name matching plus the
    org_name_patterns fallback, which is what Phase-1 did anyway.
    Worth knowing either way before anyone tries to "fix" it.
*/
