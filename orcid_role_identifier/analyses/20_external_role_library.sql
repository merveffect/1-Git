/*
    ============================================================================
    20. THE EXTERNAL ROLE LIBRARY — IS IT WORTH ADOPTING?
    ============================================================================
    Another team shared "B2C Research Audience - Job Title & Seniority
    Framework", grounded in the EURAXESS researcher career framework, UKRI
    guidance and the MORE4 R1-R4 career stages. 129 rows, and the Job title
    column holds semicolon-separated synonym clusters - 284 distinct titles
    once expanded, each with a sector, a subcategory and a proposed seniority
    category.

    The library is now seeds/external_role_library.csv - 286 titles once the
    synonym clusters are expanded. It is normalised here the same way
    int_title_distinct normalises ours - casefolded, punctuation stripped,
    whitespace collapsed, abbreviations expanded - so it joins directly on
    dim_title_group.title.

    THE QUESTION THIS ANSWERED. 286 titles against our 310,299 is 0.09% by
    distinct value, which sounds negligible. But job title distributions are
    heavily skewed, so the share of RECORDS they cover is the number that
    decides whether this file is valuable.

    It covers 45.8%, so the file was adopted as a seed. Note what it is worth
    and what it is not: 263 of its 286 titles were already in our dictionary,
    so it reads as independent confirmation of the vocabulary rather than new
    material - my own hypothesis going in, that it would be a source of new
    anchors, was wrong. What it did give us is 17 of our 44 overrides, almost
    all of them the retired and emeritus rejections from its "Former or
    inactive" sector, which is a category we had not thought to carve out.
    ============================================================================
*/

-- the shared library, normalised to match our dictionary.
-- It was inlined here as 284 hand-pasted rows while the file was still an
-- xlsx. The answer below - 45.8% of records - was the test this analysis
-- set for itself, so the file became seeds/external_role_library.csv and
-- this reads from it: one copy, and a diff when their team sends a new one.
create temp table external_titles as
select
    {{ normalize_title('job_title') }} as title,
    sector,
    subcategory,
    seniority
from {{ ref('external_role_library') }};


-- ###########################################################################
-- 1. COVERAGE — the number that decides everything else
--
--    Not "how many of their titles do we know" but "how much of our data do
--    their titles account for".
-- ###########################################################################
SELECT
    COUNT(*)                                                    AS their_titles,
    COUNTIF(d.title IS NOT NULL)                                AS found_in_our_dictionary,
    ROUND(COUNTIF(d.title IS NOT NULL) / COUNT(*), 4)           AS share_of_their_titles,
    SUM(COALESCE(d.frequency, 0))                               AS our_records_covered,
    ROUND(SUM(COALESCE(d.frequency, 0))
          / (SELECT SUM(frequency) FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`), 4) AS share_of_all_records
FROM external_titles e
LEFT JOIN `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group` d USING (title);


-- ###########################################################################
-- 2. DO WE AGREE? Their seniority category against our title group.
--
--    These answer different questions - they ask how senior a researcher is,
--    we ask what the person does - so this is not a correctness check. It is
--    a map. Read it to see which of their categories correspond to which of
--    our groups, and where one of theirs splits across several of ours.
-- ###########################################################################
SELECT
    e.seniority                                 AS their_seniority,
    COALESCE(d.title_group, '(not in our dictionary)') AS our_title_group,
    COUNT(*)                                    AS titles,
    SUM(COALESCE(d.frequency, 0))               AS records,
    ROUND(AVG(d.similarity), 3)                 AS avg_similarity
FROM external_titles e
LEFT JOIN `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group` d USING (title)
GROUP BY their_seniority, our_title_group
ORDER BY records DESC;


-- ###########################################################################
-- 3. ANCHOR CANDIDATES — their titles we do not hold at all
--
--    A title here is one of two things: a term that genuinely never appears
--    in ORCID, or a gap in our dictionary. The sector and subcategory say
--    which group it would belong to, so this is the harvest list.
--
--    Read the Healthcare and Clinical rows first. practitioner is our
--    weakest group at 40.5% low-confidence and it carries the whole
--    healthcare audience.
-- ###########################################################################
SELECT
    e.sector,
    e.subcategory,
    e.title,
    e.seniority
FROM external_titles e
LEFT JOIN `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group` d USING (title)
WHERE d.title IS NULL
ORDER BY
    CASE WHEN e.sector = 'Healthcare' OR e.subcategory LIKE '%Clinical%' THEN 0 ELSE 1 END,
    e.sector, e.subcategory, e.title;


-- ###########################################################################
-- 4. THE HIGH-TRAFFIC OVERLAP — where adopting their view would matter most
--
--    Their titles that we DO hold, ordered by how many of our records carry
--    them. A disagreement high in this list is worth a human decision; one at
--    the bottom is not.
-- ###########################################################################
SELECT
    e.title,
    d.frequency,
    d.title_group                   AS our_group,
    ROUND(d.similarity, 3)          AS similarity,
    d.decision_source,
    e.sector                        AS their_sector,
    e.seniority                     AS their_seniority
FROM external_titles e
JOIN `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group` d USING (title)
WHERE d.frequency >= 1000
ORDER BY d.frequency DESC
LIMIT 80;


-- ###########################################################################
-- 5. ANY OTHER RETIRED OR HONORARY TITLES WE STILL HOLD?
--
--     Marketing confirmed on 2026-10-16 that a retired professor is not a
--     researcher, and 14 titles from the external library are now rejected:
--     emeritus professor, professor emeritus, professor emerita, retired
--     professor, retired academic, emeritus researcher, emeritus scientist,
--     honorary researcher, retired researcher, retired scientist, not
--     currently working, career break, unemployed, between roles.
--
--     But that list is 14 titles and our dictionary holds 310,299. The same
--     status is written many other ways, and most of them are not English.
--     Prefix stems only - no trailing word boundary, which is what made the
--     organisation patterns fail silently for months.
--
--     Judge each row. 'honorary professor' is not necessarily retired, and
--     'former' appears in contexts that have nothing to do with status.
-- ###########################################################################
SELECT
    title,
    frequency,
    title_group,
    ROUND(similarity, 3)    AS similarity,
    decision_source
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
WHERE is_assigned
  AND REGEXP_CONTAINS(title, r'\b(emerit|émérit|retired|retir|honorar|honorair|former|ex-|emekli|jubilad|pension|ruhestand|aposentad|gepensioneerd|emerytowan)')
ORDER BY frequency DESC
LIMIT 60;


-- ###########################################################################
-- 6. HOW MUCH WOULD "CURRENT POSTS ONLY" COST?
--
--     THE LIMIT OF THE OVERRIDES ABOVE. Rejecting 'professor emeritus' stops
--     that RECORD counting. It does not necessarily remove the PERSON: if
--     they also hold an earlier Professor post that has ended, that record
--     still qualifies them, because seven of the eight roles run with
--     current_only: false.
--
--     So the overrides remove retired EVIDENCE, not retired PEOPLE. Removing
--     the people needs current_only: true on the role, and that is a much
--     bigger change - it also drops everyone whose current post simply is
--     not recorded in ORCID, and many profiles have none.
--
--     This sizes it before anyone decides. fct_researcher_roles already
--     prefers a current record when picking each person's representative,
--     so a row with is_current = false means the person has NO current post
--     supporting that role.
-- ###########################################################################
SELECT
    role_key,
    COUNT(DISTINCT snid)                                        AS people_now,
    COUNT(DISTINCT IF(is_current, snid, NULL))                  AS people_if_current_only,
    COUNT(DISTINCT IF(NOT is_current, snid, NULL))              AS would_be_lost,
    ROUND(COUNT(DISTINCT IF(NOT is_current, snid, NULL))
          / COUNT(DISTINCT snid), 4)                            AS share_lost
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles`
WHERE role_label = 'CONFIRMED'
GROUP BY role_key
ORDER BY would_be_lost DESC;
