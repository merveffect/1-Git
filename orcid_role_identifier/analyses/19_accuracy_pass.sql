/*
    ============================================================================
    19. ACCURACY WITHOUT A GROUND TRUTH
    ============================================================================
    There is no external truth set for "profession". ORCID has no such field,
    and Phase-1 is not one either - we showed it calls roughly 53,000 people
    in engineering, earth science and mathematics healthcare professionals.

    So accuracy here is not measured by comparison. It is improved by finding
    the assignments that are wrong BY DEFINITION, which needs only knowing
    what a word means. Every error found on this project so far was of that
    kind: \buniversit\b can never match "university"; a doctoral researcher
    is not a student; a company marker should beat an academic stem.

    The useful filter is SIMILARITY, not margin. A value that cleared the 0.65
    floor by a hair and carries tens of thousands of records is where the
    embedding was guessing, and matched_anchors says what it guessed from.

    Targets lecturer and researcher - 169,018 of the 224,815 reachable
    role-memberships, and the two roles with the least scrutiny so far.
    ============================================================================
*/


-- ###########################################################################
-- 1. WEAKEST ASSIGNMENTS IN teaching_academic  (feeds lecturer)
--
--    Read matched_anchors beside the value: it says WHY the embedding chose
--    this group, and a mismatch there is the tell. 'member' landing on
--    'faculty member' is the embedding matching one word out of two.
-- ###########################################################################
SELECT
    title,
    frequency,
    ROUND(similarity, 3)        AS similarity,
    ROUND(margin, 3)            AS margin,
    runner_up,
    matched_anchors,
    needs_human_review
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
WHERE is_assigned
  AND title_group = 'teaching_academic'
  AND frequency >= 2000
ORDER BY similarity ASC
LIMIT 60;


-- ###########################################################################
-- 2. WEAKEST ASSIGNMENTS IN THE TWO RESEARCHER GROUPS  (feeds researcher)
--
--    LOW SIMILARITY IS LOW CONFIDENCE, NOT ERROR. Check each candidate
--    against the decisions already made before changing it.
--
--    'dottorandi' is the worked example of that trap. Italian for doctoral
--    candidates, 47,810 records, similarity 0.684, matched on
--    'collaboratori', 'borsisti' and 'assegnisti' - Italian terms for
--    research FELLOWS rather than students. It looks like an error, and I
--    was about to move it to student. But 'doctoral researcher' had just
--    been moved the other way, from student to researcher_early, on the
--    grounds that a doctoral researcher is a researcher - and a dottorando
--    is the same person in Italian. Moving it would have broken that
--    consistency, not fixed anything. Left alone: the answer is right and
--    the embedding was simply unsure because the word is not English.
-- ###########################################################################
SELECT
    title,
    title_group,
    frequency,
    ROUND(similarity, 3)        AS similarity,
    ROUND(margin, 3)            AS margin,
    runner_up,
    matched_anchors
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
WHERE is_assigned
  AND title_group IN ('researcher_early', 'researcher_established')
  AND frequency >= 2000
ORDER BY similarity ASC
LIMIT 60;


-- ###########################################################################
-- 3. WHAT DID EACH GROUP ACCEPT AT THE VERY EDGE?
--
--    One row per group, so the shape of the problem is visible at a glance.
--    A group whose weakest accepted value sits at 0.66 and carries 50,000
--    records is taking on more guesswork than one whose weakest is 0.85.
-- ###########################################################################
SELECT
    title_group,
    COUNT(*)                                        AS values_assigned,
    SUM(frequency)                                  AS records,
    ROUND(MIN(similarity), 3)                       AS weakest_accepted,
    ROUND(APPROX_QUANTILES(similarity, 100)[OFFSET(10)], 3) AS p10_similarity,
    ROUND(AVG(similarity), 3)                       AS avg_similarity,
    SUM(IF(similarity < 0.75, frequency, 0))        AS records_below_075,
    ROUND(SUM(IF(similarity < 0.75, frequency, 0)) / SUM(frequency), 4) AS share_below_075
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
WHERE is_assigned
GROUP BY title_group
ORDER BY records DESC;


-- ###########################################################################
-- 4. NON-ENGLISH VALUES, WHICH IS WHERE THE EMBEDDING IS WEAKEST
--
--    The multilingual reach is this pipeline's main advantage over Phase-1,
--    so it is also where a wrong answer is most likely and least likely to
--    be noticed. A Portuguese medical residency - "Interno de formacao
--    especifica" - turned up in lecturer twice in the 1b sample.
--
--    Crude test for "not English": a non-ASCII letter, or none of a short
--    list of English function words. Imperfect, and good enough to surface
--    the cases worth reading.
-- ###########################################################################
SELECT
    title,
    title_group,
    frequency,
    ROUND(similarity, 3)        AS similarity,
    runner_up,
    matched_anchors
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
WHERE is_assigned
  AND frequency >= 1000
  AND title_group IN ('teaching_academic', 'researcher_early',
                      'researcher_established', 'student')
  AND (
        REGEXP_CONTAINS(title, r'[^\x00-\x7F]')
     OR NOT REGEXP_CONTAINS(title, r'\b(professor|lecturer|research|teaching|senior|assistant|associate|student|fellow|scientist|postdoc|doctoral|visiting|adjunct|instructor|faculty|head|chair|staff|member|officer|manager|technician|engineer|analyst|coordinator|director|of|the|and|in|at)\b')
      )
ORDER BY frequency DESC
LIMIT 80;
