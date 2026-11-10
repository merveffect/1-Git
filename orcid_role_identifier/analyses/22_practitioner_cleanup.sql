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

    RESULT, measured the same day. Check 1 passed, checks 2 and 3 did not.

      1. PASSED. share_below_075 fell 0.4064 -> 0.3661 while the group GREW
         by 178,849 records, so it got both cleaner and wider. In the
         audience: hcp_practitioner confirmed 57,029 -> 60,306 people,
         reachable 42,597 -> 45,074, and the evidence shifted exactly as
         intended - hcp_broad's strong-title-plus-clinical-department row
         24,694 -> 29,527 while its weak-title row fell 12,047 -> 11,262.

      2. FAILED, partly benignly. Groups lost ~134,000 records:
         teaching_academic -43,102, researcher_established -28,981,
         trainee_clinical -27,211, pharmacist -10,426. trainee_clinical
         feeds the same two roles, so that part is an internal shift with
         no person lost, and its own share improved 0.2056 -> 0.1915. The
         pharmacist ROLE lost 25 people. The rest was check 3.

      3. FAILED, and not where I predicted. 'audiologist', which I flagged
         loudest, pulled nothing at all. 'pathologist' was the problem -
         via epidemiology, not the plant pathology I had written down:
         epidemiologist 7,779 records, plus toxicologist, entomologist and
         field epidemiologist. 'urologist' took hydrologist and
         hydrogeologist, 'veterinarian' took agronomist, 'dietitian' took
         health economist and food technologist, 'occupational therapist'
         took social worker. ~17,200 records of professions that are not
         clinical.

         Repaired with 14 ACCEPT overrides moving them back, not REJECTs -
         researcher_established feeds a live audience, and rejecting would
         have left those people in no group at all, hiding the damage
         rather than undoing it. The anchors stay: real pathologists,
         urologists and veterinarians need them, and 2,684 veterinarians
         were reaching DENTIST before this.

         The lesson for the next anchor set: the -ologist suffix is not
         what predicts a magnet. How crowded the neighbouring region is,
         is. audiologist sits beside nothing; pathologist sits beside
         every science ending in -ologist.

      3b. Original wording of check 3, kept so the prediction can be read
          against the result: query 2 re-read, looking specifically at
          'audiologist' and
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


-- ###########################################################################
-- 9. HTML ESCAPES SURVIVING NORMALISATION — SIZE IT BEFORE FIXING IT
--
--    The 2026-10-20 build surfaced this title:
--        academic professor clinical &amp personal chair of vascular medicine
--    '&amp;' came through as '&amp'. clean_text keeps '&' as a legal
--    character and strips the semicolon, so the entity is half-decoded and
--    left in place. A title stored as 'R&amp;D Manager' and one stored as
--    'R&D Manager' therefore become TWO dictionary entries, classified
--    separately, with the frequency split between them.
--
--    This is not a practitioner problem - it affects every group, and the
--    distinct-title count the whole project quotes (310,299) is inflated by
--    however much of it there is.
--
--    WHY IT IS NOT ALREADY FIXED. Changing clean_text changes every
--    normalised value, so every title_key md5 changes, so the entire
--    dictionary re-embeds - the 2.7 GiB merges that take 200+ seconds each.
--    Worse, the embedding models are incremental, so the old keys stay
--    behind and inflate dim_title_group and every quality metric read off
--    it, exactly as the anchor table did before 2026-10-16. It would need
--    --full-refresh on int_title_embeddings and int_department_embeddings.
--
--    So measure first. If this is a few hundred titles, override the loud
--    ones and leave the normaliser alone. If it is thousands, the fix is
--    worth one expensive rebuild - and it should be done in the same
--    rebuild as any other normalisation change, never on its own.
-- ###########################################################################
WITH entities AS (
    SELECT entity FROM UNNEST(['&amp', '&lt', '&gt', '&quot', '&apos',
                               '&nbsp', '&#39', '&#34']) AS entity
)

SELECT
    e.entity,
    'title'                     AS vocabulary,
    COUNT(*)                    AS distinct_values,
    SUM(d.frequency)            AS records
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group` d
CROSS JOIN entities e
WHERE STRPOS(d.title, e.entity) > 0
GROUP BY e.entity, vocabulary

UNION ALL

SELECT
    e.entity,
    'department'                AS vocabulary,
    COUNT(*)                    AS distinct_values,
    SUM(d.frequency)            AS records
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_department_discipline` d
CROSS JOIN entities e
WHERE STRPOS(d.department, e.entity) > 0
GROUP BY e.entity, vocabulary

ORDER BY records DESC;

-- 9a. The pairs that prove the split: a value containing an entity whose
--     decoded twin also exists as its own dictionary entry. Each pair is one
--     job title counted twice, with its frequency divided between the halves.
SELECT
    escaped.title                       AS escaped_form,
    escaped.frequency                   AS escaped_records,
    escaped.title_group                 AS escaped_group,
    decoded.title                       AS decoded_form,
    decoded.frequency                   AS decoded_records,
    decoded.title_group                 AS decoded_group,
    escaped.title_group = decoded.title_group
                                        AS same_group
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group` escaped
JOIN `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group` decoded
    ON decoded.title = REGEXP_REPLACE(escaped.title, r'&amp', '&')
WHERE STRPOS(escaped.title, '&amp') > 0
ORDER BY escaped.frequency + decoded.frequency DESC
LIMIT 40;


-- ###########################################################################
-- 10. THE ANCHORS STILL SHOWING THE SIGNATURE — WHAT IS ARRIVING AT THEM?
--
--    Query 3 on 2026-10-20 proved the diagnostic: a neighbouring anchor with
--    a high share below 0.75 means a MISSING anchor, and adding the missing
--    one collapses it. paramedic went 0.633 -> 0.226 once emergency
--    physician existed, anaesthetist 0.436 -> 0.122 once intensivist did,
--    haematologist 0.442 -> 0.208 once rheumatologist did.
--
--    Three did not collapse and this query says why. It is the same read as
--    query 2 but per anchor, so a single anchor's intake can be judged on
--    its own instead of inside a group average.
--
--      gynaecologist  0.557  barely moved after geriatrician was given its
--                            own anchor, so something else is arriving and
--                            we do not know what. Guessing is what this
--                            query exists to avoid.
--      pathologist    0.480  still the second-highest after the two
--                            abbreviations, even with epidemiologist,
--                            toxicologist and entomologist moved out.
--      dentist        0.403  never investigated at all.
--
--    EXPECT TWO KINDS OF ANSWER AND TREAT THEM DIFFERENTLY. A correct
--    clinical title arriving unconfidently means one more anchor. A title
--    from another profession means one more override. Nothing here is a
--    threshold problem - the weakest accepted value in every group is
--    exactly sim_floor, so moving the floor would cut correct answers first.
-- ###########################################################################
SELECT
    matched_anchors[OFFSET(0)]  AS nearest_anchor,
    title,
    frequency,
    ROUND(similarity, 3)        AS similarity,
    runner_up,
    needs_human_review
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
WHERE title_group = 'practitioner'
  AND is_assigned
  AND similarity < 0.75
  AND matched_anchors[OFFSET(0)] IN ('gynaecologist', 'pathologist', 'dentist')
-- 20 PER ANCHOR, not 60 overall. The first version ordered by anchor name and
-- took the top 60, so 'dentist' consumed the whole limit alphabetically and
-- the two anchors the query was written to investigate never appeared.
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY matched_anchors[OFFSET(0)] ORDER BY frequency DESC
) <= 20
ORDER BY matched_anchors[OFFSET(0)], frequency DESC;


-- ###########################################################################
-- 11. "PROFESSOR OF SOMETHING" — SIZE IT BEFORE WRITING A RULE
--
--    Query 10 turned up seven dental titles of the form "professor of X"
--    sitting in practitioner: professor of endodontology, professor of
--    cariology & operative dentistry, profesor de ortodoncia, professor
--    gerodontology. Each is an academic post, and each is losing the
--    lecturer audience.
--
--    The same shape appears outside dentistry - 'vip clinical professor and
--    chair' at 371 records, 'academic professor clinical ... chair of
--    vascular medicine' at 884 - so it is a pattern rather than seven
--    titles, and seven override rows would be treating the symptom.
--
--    THE PRECEDENT FOR A FIX ALREADY EXISTS AND SO DOES THE ARGUMENT. We
--    settled this for 'doç dr', the Turkish form of associate professor: the
--    title names an academic RANK, the subject after it is a field, and the
--    clinical half is carried by the department axis because hcp_broad is
--    title_or_field. On that reasoning a professor of endodontology is
--    teaching_academic and still reaches healthcare through the department.
--
--    SO WHY NOT JUST ADD A PATTERN. Because title_group_patterns beats the
--    vector unconditionally, and teaching_academic - unlike librarian - has
--    anchors of its own. A rule on 'professor of' would move titles out of
--    practitioner AND out of both researcher groups, wholesale, and I do not
--    know how many. That is the measurement.
--
--    READ IT THIS WAY. A large count outside teaching_academic means the
--    rule is worth writing. A small one means seven overrides and move on.
--    Watch 'professor emeritus' especially: it is already REJECTED by hand
--    at marketing's request, and any rule has to keep losing to that.
-- ###########################################################################
SELECT
    title_group,
    is_assigned,
    COUNT(*)                            AS distinct_titles,
    SUM(frequency)                      AS records,
    ROUND(AVG(similarity), 3)           AS avg_similarity,
    STRING_AGG(title ORDER BY frequency DESC LIMIT 4)
                                        AS biggest_examples
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
WHERE REGEXP_CONTAINS(title, r'\b(professor|profesor|professeur|professora|professore)\b')
GROUP BY title_group, is_assigned
ORDER BY records DESC;

-- 11a. The ones outside teaching_academic, which are the candidates to move.
--      If this list is short, it is an override job. If it runs to thousands
--      of records, it is a rule.
SELECT
    title,
    frequency,
    title_group,
    ROUND(similarity, 3)        AS similarity,
    matched_anchors[OFFSET(0)]  AS nearest_anchor,
    runner_up
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
WHERE REGEXP_CONTAINS(title, r'\b(professor|profesor|professeur|professora|professore)\b')
  AND is_assigned
  AND title_group != 'teaching_academic'
ORDER BY frequency DESC
LIMIT 50;
