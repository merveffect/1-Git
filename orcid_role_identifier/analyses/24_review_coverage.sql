/*
    ============================================================================
    24. HOW MUCH OF A GROUP HAVE WE ACTUALLY READ?
    ============================================================================
    Written 2026-10-21 because Merve asked a question I could not answer: how
    did we establish that researcher_established was finished and had no
    errors left? We did not. I overstated it, and the same overstatement
    applies to practitioner, which was also called reviewed.

    WHAT THE REVIEW ACTUALLY SAW, for researcher_established:

        titles read, by hand, across three queries        ~150
        distinct titles in the group                   27,963
        records those ~150 titles carry                ~70,000
        records below 0.75 similarity                 304,478      so ~23%
        records in the group                        1,950,686      so ~3.6%

    And every query was filtered `similarity < 0.75`, so **1,646,208 records
    - 84% of the group - were never looked at in any form.**

    THAT GAP IS NOT THEORETICAL. We taught ourselves this on the clinical
    group: `business consultant` scored 0.843, `independent consultant`
    0.867, `medical director` 0.821, and all of them were wrong. The note
    written at the time said "the wrong ones score HIGHER than the right
    ones". Then every query since has filtered them out.

    So this file answers two questions, and it should be run for every group
    we claim to have reviewed, practitioner included.

      1. Is reading by hand even viable? Query 1 buckets the problem by
         frequency. If most of it sits in titles appearing twice, no top-60
         list will ever reach it and we need a different method, not more
         reading.

      2. What hides above the threshold? Query 2 is the useful one and it
         needs no threshold at all - see its own header. Query 3 is the
         blunt fallback.

    None of this needs a build.
    ============================================================================
*/


-- ###########################################################################
-- 1. IS HAND-READING VIABLE? — the problem by frequency band
--
--    A top-60 list ordered by frequency can only ever reach the top bands.
--    This says how much of the group lives below them.
--
--    Read the cumulative column. If 60% of the below-0.75 records sit in
--    titles with a frequency under 50, then reading lists is not a review
--    method for this group - it is a way of fixing the loudest twenty
--    percent and calling it done, which is what we just did.
-- ###########################################################################
SELECT
    title_group,
    CASE
        WHEN frequency >= 10000 THEN '1. 10,000+'
        WHEN frequency >=  5000 THEN '2. 5,000-9,999'
        WHEN frequency >=  1000 THEN '3. 1,000-4,999'
        WHEN frequency >=   500 THEN '4. 500-999'
        WHEN frequency >=   200 THEN '5. 200-499'
        WHEN frequency >=   100 THEN '6. 100-199'
        WHEN frequency >=    50 THEN '7. 50-99'
        WHEN frequency >=    20 THEN '8. 20-49'
        WHEN frequency >=     5 THEN '9. 5-19'
        ELSE                         '10. 1-4'
    END                                                 AS frequency_band,
    COUNT(*)                                            AS distinct_titles,
    SUM(frequency)                                      AS records,
    ROUND(SUM(frequency) / SUM(SUM(frequency)) OVER (PARTITION BY title_group), 4)
                                                        AS share_of_group,
    ROUND(SUM(SUM(frequency)) OVER (
        PARTITION BY title_group ORDER BY MIN(frequency) DESC
    ) / SUM(SUM(frequency)) OVER (PARTITION BY title_group), 4)
                                                        AS cumulative_share
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
WHERE is_assigned
  AND similarity < 0.75
  AND title_group IN ('researcher_established', 'practitioner', 'leadership')
GROUP BY title_group, frequency_band
ORDER BY title_group, frequency_band;


-- ###########################################################################
-- 2. THE TEST THAT NEEDS NO THRESHOLD — matched on the generic half
--
--    This is the query worth having. Every failure of this kind we have
--    found has the same shape: a compound anchor, and a title that matched
--    the GENERIC half of it instead of the distinctive half.
--
--        library manager   attracted  manager          (17,340 records)
--        senior scientist  attracted  senior manager   (2,772)
--        medical officer   attracted  education officer   (569)
--        head of laboratory attracted head of quality     (154)
--
--    And it is computable. For each anchor, name the stem that makes it
--    distinctive - `scien` for senior scientist, `medic` for medical
--    officer, `lab` for head of laboratory. A title that reached that anchor
--    WITHOUT containing its distinctive stem cannot have matched on meaning;
--    it matched on the word the anchor shares with the rest of the labour
--    market.
--
--    Crucially this has NO similarity filter, so it reaches the 84% of the
--    group every previous query excluded.
--
--    WHAT IT DOES NOT CATCH, so that nobody trusts it too far:
--    `business consultant` reaching `consultant` at 0.843. That title does
--    contain the distinctive stem - it is the right word from the wrong
--    domain. There is no computable test for that one; it needs reading, and
--    query 3 is where to read it.
-- ###########################################################################
WITH anchor_stems AS (
    SELECT * FROM UNNEST([
        -- researcher_established
        STRUCT('scientist'                     AS anchor, r'scien|wissenschaft'        AS distinctive_stem),
        ('senior scientist',                          r'scien|wissenschaft'),
        ('staff scientist',                           r'scien|wissenschaft'),
        ('research scientist',                        r'scien|research|investigac|recherche'),
        ('scientific director',                       r'scien|wissenschaft'),
        ('senior researcher',                         r'research|investigac|recherche|forsk'),
        ('principal investigator',                    r'investigat|^pi$|principal investigator'),
        ('head of laboratory',                        r'lab|group|unit|centre|center|institut'),
        ('group leader',                              r'group|grupo|gruppe|lab|team'),
        -- practitioner, which was also declared reviewed
        ('medical officer',                           r'medic|health|clinic|doctor|surg'),
        ('chief physician',                           r'physician|medic|doctor|arzt|chief of'),
        ('staff physician',                           r'physician|medic|doctor'),
        ('attending physician',                       r'physician|medic|doctor|attending'),
        ('general practitioner',                      r'practition|^gp$|general medic|family'),
        ('occupational therapist',                    r'therap|occupation|rehab'),
        ('speech and language therapist',             r'therap|speech|language|logoped'),
        ('oral and maxillofacial surgeon',            r'surg|oral|maxillo|dent|odonto'),
        ('dental surgeon',                            r'dent|odonto|oral'),
        ('dental hygienist',                          r'dent|odonto|hygien')
    ])
)

SELECT
    d.title_group,
    s.anchor                        AS matched_anchor,
    d.title,
    d.frequency,
    ROUND(d.similarity, 3)          AS similarity,
    d.runner_up,
    d.needs_human_review
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group` d
JOIN anchor_stems s
    ON d.matched_anchors[OFFSET(0)] = s.anchor
WHERE d.is_assigned
  AND d.decision_source = 'VECTOR'
  AND NOT REGEXP_CONTAINS(d.title, s.distinctive_stem)
ORDER BY d.frequency DESC
LIMIT 80;

-- 2a. The same, counted, so the size of the problem is visible before
--     reading any of it. A large record count against one anchor says that
--     anchor is carrying its generic half rather than its meaning.
WITH anchor_stems AS (
    SELECT * FROM UNNEST([
        STRUCT('scientist'                     AS anchor, r'scien|wissenschaft'        AS distinctive_stem),
        ('senior scientist',                          r'scien|wissenschaft'),
        ('staff scientist',                           r'scien|wissenschaft'),
        ('research scientist',                        r'scien|research|investigac|recherche'),
        ('scientific director',                       r'scien|wissenschaft'),
        ('senior researcher',                         r'research|investigac|recherche|forsk'),
        ('principal investigator',                    r'investigat|^pi$|principal investigator'),
        ('head of laboratory',                        r'lab|group|unit|centre|center|institut'),
        ('group leader',                              r'group|grupo|gruppe|lab|team'),
        ('medical officer',                           r'medic|health|clinic|doctor|surg'),
        ('chief physician',                           r'physician|medic|doctor|arzt|chief of'),
        ('staff physician',                           r'physician|medic|doctor'),
        ('attending physician',                       r'physician|medic|doctor|attending'),
        ('general practitioner',                      r'practition|^gp$|general medic|family'),
        ('occupational therapist',                    r'therap|occupation|rehab'),
        ('speech and language therapist',             r'therap|speech|language|logoped'),
        ('oral and maxillofacial surgeon',            r'surg|oral|maxillo|dent|odonto'),
        ('dental surgeon',                            r'dent|odonto|oral'),
        ('dental hygienist',                          r'dent|odonto|hygien')
    ])
)

SELECT
    d.title_group,
    s.anchor                                            AS matched_anchor,
    COUNT(*)                                            AS suspect_titles,
    SUM(d.frequency)                                    AS suspect_records,
    COUNTIF(d.similarity >= 0.75)                       AS titles_above_075,
    SUM(IF(d.similarity >= 0.75, d.frequency, 0))       AS records_above_075,
    ROUND(AVG(d.similarity), 3)                         AS avg_similarity
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group` d
JOIN anchor_stems s
    ON d.matched_anchors[OFFSET(0)] = s.anchor
WHERE d.is_assigned
  AND d.decision_source = 'VECTOR'
  AND NOT REGEXP_CONTAINS(d.title, s.distinctive_stem)
GROUP BY d.title_group, matched_anchor
ORDER BY suspect_records DESC;


-- ###########################################################################
-- 3. THE 84% NOBODY LOOKED AT — titles ABOVE 0.75
--
--    Blunt, and necessary. Every review query so far filtered
--    `similarity < 0.75`, on the assumption that a high score means a right
--    answer. `business consultant` at 0.843 disproves that assumption, and
--    it is the assumption the whole review rested on.
--
--    This reads the biggest titles above the threshold. Expect most of it to
--    be correct and boring - that is the point, it is the control group. The
--    question is whether anything in it is obviously wrong, because if the
--    answer is no across 80 titles carrying most of the records, the
--    assumption was reasonable after all and we can say so with evidence
--    instead of hope.
-- ###########################################################################
SELECT
    title_group,
    title,
    frequency,
    ROUND(similarity, 3)        AS similarity,
    matched_anchors[OFFSET(0)]  AS nearest_anchor,
    runner_up,
    decision_source
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
WHERE is_assigned
  AND similarity >= 0.75
  AND title_group IN ('researcher_established', 'practitioner')
QUALIFY ROW_NUMBER() OVER (PARTITION BY title_group ORDER BY frequency DESC) <= 40
ORDER BY title_group, frequency DESC;
