/*
    ============================================================================
    22. PRACTITIONER — THE DIRTIEST GROUP IN THE PROJECT
    ============================================================================
    practitioner carries 25,622 distinct titles and 1,460,004 records, and
    40.6% of those records sit below 0.75 similarity. The next worst group is
    support_technical at 35.9%; teaching_academic is 6.95%. It has been the
    known weak point since the first build and has never been looked at.

    Nineteen anchors, eighteen of them English:
      consultant, physician, medical doctor, general practitioner,
      attending physician, staff physician, chief physician, surgeon,
      neurosurgeon, cardiologist, radiologist, neurologist, psychiatrist,
      nurse, registered nurse, physiotherapist, dentist, medical officer,
      dirigente medico

    NO BUILD IS NEEDED FOR ANY OF THIS. Every query reads tables that already
    exist. The point of doing all the diagnosis in one pass is that the fix
    can then be one build rather than five.

    QUERY 1 COMES FIRST BECAUSE IT CAN CANCEL THE WHOLE JOB. A dirty title
    group is not the same thing as a dirty audience. hcp_practitioner is
    title_and_field, so a wrong title with a non-clinical department never
    becomes a practitioner at all - the department axis filters it out.
    hcp_broad is title_or_field, where a wrong title ON ITS OWN is enough.
    So if the weak titles are nearly all being caught by the department
    requirement, this is a cosmetic problem and we should spend the day on
    something else.

    The others each settle one decision:
      2. are the weak assignments WRONG, or RIGHT-but-unusual? Not the same
         thing, and we have been caught by it before - 'dottorandi' looked
         like an error at 0.684 and was correct. Low similarity is low
         confidence, not error.
      3. which anchor is doing the damage? My hypothesis is 'consultant',
         a clinical title in the UK and a business title everywhere else,
         and 'medical officer', which is also military and civil service.
         The same shape as 'information professional' pulling every IT job
         into librarian. Query 3 names the culprit from data instead.
      4. how much of this is CERTAIN and does not need the embedding at
         all? A title containing 'nurse' is a nurse. Those belong in
         title_group_patterns, like librarian - exact, and it takes work
         away from the vector.
      5. are the English anchors already reaching the non-English titles?
         Facharzt, médecin, infirmière, 医師. If they are, adding foreign
         anchors would repeat the librarian mistake, where 11 translations
         cost us 69% of the group and bought nothing.
    WHAT WAS DONE, 2026-10-20, AND THE TEST SET BEFORE BUILDING IT.

    25 anchors added for specialties that had none of their own, and 19
    REJECT overrides for titles naming no clinical occupation (~24,800
    records). No country rule - the contract block in dbt_project.yml
    records why it is not needed yet and exactly when it will be. No
    patterns: query 4 killed that proposal, because clinical stems appear
    legitimately in teaching and research titles and a pattern would take
    people out of lecturer.

    Three checks, in this order:

      1. analyses/19 query 3, practitioner share_below_075 must FALL from
         0.4064. The whole point of the new anchors is that correct answers
         were scoring low for want of the right word. If it RISES, the
         anchors are behaving as magnets and this gets reverted.

      2. The same query's other groups must not shrink. teaching_academic
         12,115,778 records, researcher_early 8,297,241,
         researcher_established 1,982,124, support_technical 1,402,019.
         A new anchor can take values from a live audience - that is how
         librarian did its damage.

      3. Query 2 re-read, looking specifically at 'audiologist' and
         'pathologist', both flagged in the seed. The -ologist suffix is a
         known magnet: seismologist reached radiologist at 0.708 and
         glaciologist reached archivist. Plant pathology is also a
         different profession from medical pathology.

    ============================================================================
*/


-- ###########################################################################
-- 1. DOES THE DIRT ACTUALLY REACH AN AUDIENCE?
--
--    role_score for these rows IS the title's group_score, so it inverts
--    back to similarity: group_score = 0.70 + (sim - 0.65)/0.35 * 0.30.
--    A similarity of 0.75 is therefore a group_score of 0.7857, which is
--    where the 'weak' cut below comes from - it is the same 0.75 line
--    analyses/19 query 3 reports, not a new threshold.
--
--    READ IT LIKE THIS. The row that matters is
--        hcp_broad / CONFIRMED / title alone / weak title
--    because those are people called healthcare professionals on the
--    strength of a title the model was unsure about, with a department
--    that said something else. If that number is small, stop here.
-- ###########################################################################
SELECT
    role_key,
    role_label,
    CASE
        WHEN discipline = 'health_clinical' THEN '1. title + clinical department'
        ELSE                                     '2. title alone, department says otherwise'
    END                                                     AS evidence_path,
    CASE
        WHEN role_score < 0.7857 THEN 'weak title (similarity < 0.75)'
        ELSE                          'strong title'
    END                                                     AS title_strength,
    COUNT(DISTINCT snid)                                    AS people,
    ROUND(AVG(role_final_score), 3)                         AS avg_final_score
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles`
WHERE title_group = 'practitioner'
GROUP BY role_key, role_label, evidence_path, title_strength
ORDER BY role_key, role_label, evidence_path, title_strength;


-- ###########################################################################
-- 2. THE EYEBALL TEST — the 80 biggest weak assignments
--
--    Only the nearest anchor is shown rather than all three, to keep the
--    output small enough to read.
--
--    Sort each row into one of three piles as you read:
--      WRONG          - not a clinician at all. These need removing, and
--                       the anchor that attracted them is the real target.
--      RIGHT, UNSURE  - a genuine clinical title the model only just
--                       recognised. Leave alone. The low score is honest.
--      AMBIGUOUS      - genuinely both, like a clinical department head.
--                       These are what the review queue is for.
-- ###########################################################################
SELECT
    title,
    frequency,
    ROUND(similarity, 3)        AS similarity,
    matched_anchors[OFFSET(0)]  AS nearest_anchor,
    runner_up,
    ROUND(margin, 3)            AS margin,
    needs_human_review
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
WHERE title_group = 'practitioner'
  AND is_assigned
  AND similarity < 0.75
ORDER BY frequency DESC
LIMIT 80;


-- ###########################################################################
-- 3. WHICH ANCHOR IS RESPONSIBLE? — the magnet test, per anchor
--
--    One row per anchor, so a single bad anchor cannot hide inside a group
--    average. An anchor carrying a large share of records at a low average
--    similarity is pulling in strangers.
-- ###########################################################################
SELECT
    matched_anchors[OFFSET(0)]                      AS nearest_anchor,
    COUNT(*)                                        AS distinct_titles,
    SUM(frequency)                                  AS records,
    ROUND(AVG(similarity), 3)                       AS avg_similarity,
    COUNTIF(similarity < 0.75)                      AS titles_below_075,
    ROUND(SAFE_DIVIDE(SUM(IF(similarity < 0.75, frequency, 0)),
                      SUM(frequency)), 4)           AS share_records_below_075
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
WHERE title_group = 'practitioner'
  AND is_assigned
GROUP BY nearest_anchor
ORDER BY records DESC;

-- 3a. The titles behind the two anchors I suspect, so the hypothesis can be
--     judged rather than believed. 'consultant' is a hospital specialist in
--     the UK and a business adviser in most of the world. 'medical officer'
--     is also a rank in armies and health ministries.
SELECT
    matched_anchors[OFFSET(0)]  AS nearest_anchor,
    title,
    frequency,
    ROUND(similarity, 3)        AS similarity,
    runner_up
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
WHERE title_group = 'practitioner'
  AND is_assigned
  AND matched_anchors[OFFSET(0)] IN ('consultant', 'medical officer')
ORDER BY frequency DESC
LIMIT 60;


-- ###########################################################################
-- 4. HOW MUCH OF THIS IS CERTAIN? — sizing the pattern option
--
--    Searches EVERY title, not just practitioner ones, because the useful
--    finding would be a title containing 'nurse' sitting in some other
--    group. Those are records a pattern would recover.
--
--    Read the title_group column. Rows where it is already practitioner
--    are records we would make exact; rows where it is anything else are
--    records we would gain.
-- ###########################################################################
WITH certain_stems AS (
    SELECT stem FROM UNNEST([
        'physician', 'nurse', 'surgeon', 'dentist', 'midwife',
        'physiotherapist', 'paramedic', 'optometrist', 'podiatrist',
        'veterinarian', 'psychiatrist', 'cardiologist', 'radiologist',
        'neurologist', 'oncologist', 'anaesthetist', 'anesthesiologist',
        'paediatrician', 'pediatrician', 'obstetrician', 'dermatologist',
        'ophthalmologist'
    ]) AS stem
)
SELECT
    s.stem,
    d.title_group,
    d.is_assigned,
    COUNT(*)                    AS distinct_titles,
    SUM(d.frequency)            AS records,
    ROUND(AVG(d.similarity), 3) AS avg_similarity
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group` d
CROSS JOIN certain_stems s
WHERE REGEXP_CONTAINS(d.title, s.stem)
GROUP BY s.stem, d.title_group, d.is_assigned
HAVING records >= 50
ORDER BY s.stem, records DESC;


-- ###########################################################################
-- 5. ARE THE ENGLISH ANCHORS ALREADY REACHING THE NON-ENGLISH TITLES?
--
--    This is the librarian question asked before making the librarian
--    mistake. There, 11 translation anchors turned a sparse region of the
--    embedding into a magnet that matched on spelling rather than meaning -
--    bibliotecario pulling biólogo and catedrática - and removing them cost
--    nothing, because the foreign titles were reaching the English anchors
--    on their own at 0.75 to 0.83.
--
--    So: if these land in practitioner already, DO NOT add foreign anchors.
--    If they land somewhere wrong, the answer is still more likely a
--    pattern or an override than a translated anchor.
-- ###########################################################################
WITH foreign_stems AS (
    SELECT stem FROM UNNEST([
        'arzt', 'médico', 'medico', 'médica', 'médecin', 'infirmi',
        'enfermer', 'enfermeir', 'chirurg', 'cirurgi', 'cirujan',
        'läkare', 'lekarz', 'врач', '医師', '医生', 'hekim',
        'odontolog', 'odontólog', 'dentista', 'fisioterap', 'pediatra'
    ]) AS stem
)
SELECT
    s.stem,
    d.title_group,
    d.is_assigned,
    COUNT(*)                        AS distinct_titles,
    SUM(d.frequency)                AS records,
    ROUND(AVG(d.similarity), 3)     AS avg_similarity,
    ANY_VALUE(d.title)              AS example_title
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group` d
CROSS JOIN foreign_stems s
WHERE REGEXP_CONTAINS(d.title, s.stem)
GROUP BY s.stem, d.title_group, d.is_assigned
HAVING records >= 30
ORDER BY s.stem, records DESC;


-- ###########################################################################
-- 6. THE 854 — WHO ARE THE PEOPLE CONFIRMED ON A TITLE ALONE?
--
--    Query 1 found that hcp_broad confirms exactly one group of people
--    without a clinical department: a perfect title plus a fully resolved
--    organisation, 0.35 + 0.25 = 0.60, landing precisely on the threshold.
--    854 people, average score 0.600.
--
--    These are the only practitioners in the shipped audience that no
--    department agrees with, so they are the whole of the messaging risk
--    Merve raised. This is the most decisive query in the file: if they are
--    mostly British consultants, there is nothing to fix. If they are
--    business consultants in Germany and the United States, there is.
--
--    No country list is assumed here on purpose. Read the countries off the
--    data rather than deciding in advance which ones use the grade.
-- ###########################################################################
SELECT
    LOWER(TRIM(evidence_title))     AS title_as_written,
    country_code,
    COUNT(DISTINCT snid)            AS people,
    ROUND(AVG(role_score), 3)       AS avg_title_score,
    ROUND(AVG(org_score), 3)        AS avg_org_score
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles`
WHERE role_key = 'hcp_broad'
  AND role_label = 'CONFIRMED'
  AND title_group = 'practitioner'
  -- COALESCE, not `!=`. The first version wrote `discipline !=
  -- 'health_clinical'`, which drops every row where discipline is NULL -
  -- that is, everyone with no department at all, who are the more exposed
  -- half of this population rather than the less. The title list it
  -- returned was still complete, because confirming on a title alone needs
  -- group_score 1.0 and so an exact anchor match, but the counts were not.
  AND COALESCE(discipline, 'none') != 'health_clinical'
GROUP BY title_as_written, country_code
ORDER BY people DESC
LIMIT 60;


-- ###########################################################################
-- 7. DOES COUNTRY ACTUALLY SEPARATE THE TWO SENSES OF "CONSULTANT"?
--
--    The hypothesis is that 'consultant' is a hospital specialist grade in
--    the UK, Ireland and parts of the Commonwealth, and an adviser
--    everywhere else. If that is true, the clinical-department share should
--    be visibly higher in those countries - because a real consultant
--    physician usually also names a clinical department, and a management
--    consultant never does.
--
--    THE COLUMN THAT DECIDES IT is share_with_clinical_dept. Country is only
--    worth a rule where it tells us something the department does not. If a
--    country has a high clinical share, the department axis is already
--    handling those people and country adds nothing. The rule is for the
--    cells where the department is silent.
--
--    Includes PROBABLE deliberately: that tier is 21,645 people held back on
--    a title alone, and whether it can ever be switched on depends on
--    exactly this.
-- ###########################################################################
SELECT
    country_code,
    COUNT(DISTINCT snid)                                        AS people,
    COUNTIF(role_label = 'CONFIRMED')                           AS confirmed_records,
    COUNTIF(role_label = 'PROBABLE')                            AS probable_records,
    ROUND(SAFE_DIVIDE(COUNTIF(discipline = 'health_clinical'),
                      COUNT(*)), 4)                             AS share_with_clinical_dept,
    ROUND(AVG(role_score), 3)                                   AS avg_title_score
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles`
WHERE role_key = 'hcp_broad'
  AND title_group = 'practitioner'
  AND REGEXP_CONTAINS(LOWER(evidence_title), r'consultant|consultor|consultora')
GROUP BY country_code
HAVING people >= 25
ORDER BY people DESC;

-- 7a. The same for the medical officer family, which has the identical
--     problem from a different direction - it is also an army rank and a
--     civil service grade. 1,669 titles, 70,114 records.
SELECT
    country_code,
    COUNT(DISTINCT snid)                                        AS people,
    COUNTIF(role_label = 'CONFIRMED')                           AS confirmed_records,
    ROUND(SAFE_DIVIDE(COUNTIF(discipline = 'health_clinical'),
                      COUNT(*)), 4)                             AS share_with_clinical_dept,
    ROUND(AVG(role_score), 3)                                   AS avg_title_score
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles`
WHERE role_key = 'hcp_broad'
  AND title_group = 'practitioner'
  AND REGEXP_CONTAINS(LOWER(evidence_title), r'medical officer|health officer|^officer$')
GROUP BY country_code
HAVING people >= 15
ORDER BY people DESC;


-- ###########################################################################
-- 8. HOW MUCH COUNTRY DO WE EVEN HAVE?
--
--    A rule conditioned on a column that is half null is a rule that fires
--    half the time. country_code comes from the employment's organisation
--    address, so it is only present where the organisation resolved - and
--    analyses/17 query 2a measured 49.3% of faculty_head records sitting at
--    org_type UNKNOWN, which is a warning that resolution is far from
--    universal.
--
--    If coverage here is poor, the honest answer is that country cannot
--    carry this decision and we go back to the department axis plus
--    targeted REJECT overrides for the named business titles.
-- ###########################################################################
SELECT
    CASE
        WHEN country_code IS NULL OR TRIM(country_code) = '' THEN '2. no country'
        ELSE                                                      '1. has country'
    END                                                         AS country_known,
    COUNT(*)                                                    AS records,
    COUNT(DISTINCT snid)                                        AS people,
    ROUND(SAFE_DIVIDE(COUNT(*),
          SUM(COUNT(*)) OVER ()), 4)                            AS share
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles`
WHERE role_key = 'hcp_broad'
  AND title_group = 'practitioner'
GROUP BY country_known
ORDER BY country_known;
