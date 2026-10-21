/*
    ============================================================================
    23. THE GROUPS NOBODY HAS LOOKED AT
    ============================================================================
    Two of the ten title groups have been reviewed properly: practitioner, over
    2026-10-20, and librarian, which was rebuilt from nothing. The other eight
    have never been read.

    That is worth saying plainly, because the review we HAVE done found a
    great deal - 2,684 veterinarians matched to DENTIST, epidemiologists
    classified as clinicians, a lawyer matched to dentist - and there is no
    reason the unreviewed groups are cleaner. We simply do not know.

    Ranked by how dirty they are, against what they feed:

      support_technical       36.64%   feeds nothing, and gets dirtier by
                                       design - it is where rejected titles
                                       are parked
      practitioner            33.80%   PARTLY reviewed 2026-10-20, from
                                       40.64% - see analyses/24, the reading
                                       covered a fraction of it
      pharmacist              31.71%   the pharmacist audience, 2,335 people
      leadership              27.76%   faculty_head + hcp_administrator, and
                                       it received 2,271 records from the
                                       researcher review without having been
                                       read itself
      trainee_clinical        18.40%   the hcp roles
      researcher_established  15.61%   PARTLY reviewed 2026-10-21, from
                                       16.29% - ~3.6% of its records were
                                       actually read, see analyses/24
      student                  8.94%   feeds nothing
      researcher_early         6.94%   researcher + hcp_researcher
      teaching_academic        6.74%   lecturer, 400,445 people - the LOWEST
                                       share anywhere and the LARGEST
                                       absolute count of low-confidence
                                       records, 813,682

    Two of the ten have been READ IN PART, which is not the same as
    reviewed, and the difference is measured in analyses/24. For
    researcher_established the hand-reading covered about 150 of 27,963
    titles - roughly 23% of the records below 0.75 and 3.6% of the group -
    and every query was filtered `similarity < 0.75`, so 84% of it was never
    looked at in any form.

    What IS established for that group is narrower and still worth something:
    the largest offenders by frequency are handled, and the remaining
    low-confidence records are substantially explained by long titles scoring
    lower against short anchors and by the sciences leaning correctly on the
    single anchor `scientist`. What is NOT established is that nothing is
    wrong above the threshold, and `business consultant` at 0.843 is the
    standing reminder that wrong answers live up there too.

    THIS FILE DELIBERATELY SKIPS support_technical AND student. They are the
    dirtiest and the second cleanest, and both feed no audience, so reviewing
    them now would be work spent on nobody. They become urgent the day
    marketing asks for a support-staff or student audience, which is question
    1.7 in docs/open-questions.md.

    Query 2 is the one I would start with. researcher_established is 2.3x
    dirtier than researcher_early for no obvious reason, and it feeds the
    second-largest audience in the project.

    No build is needed for any of this.
    ============================================================================
*/


-- ###########################################################################
-- 1. FACULTY_HEAD — IS THE COMPANY VETO STILL DOING ANYTHING?
--
--    A promise from 2026-10-16 that was never kept. org_name_patterns holds
--    three faculty_head rows with org_score 0.00, which veto a leadership
--    title at a company. They were written to stop corporate executives
--    arriving in the audience.
--
--    But we now know WHY they were arriving: int_anchor_embeddings was
--    incremental, so removing 'chief executive officer', 'founder' and
--    'president' from the leadership anchors had never taken effect. The
--    veto was built to contain a bug, and the bug is fixed.
--
--    So the veto may now be dead weight. This asks. A large count means it
--    is still load-bearing and stays. A tiny one means it is belt and braces
--    and can be retired - and retiring a rule nobody needs is worth doing,
--    because every rule left in place is a thing the next person has to
--    understand.
-- ###########################################################################
SELECT
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_seeds.org_name_patterns` p
            WHERE p.role_key = 'faculty_head'
              AND p.org_score = 0.0
              AND REGEXP_CONTAINS(COALESCE(f.evidence_org, ''), p.name_pattern)
        ) THEN '1. organisation matches a veto pattern'
        ELSE '2. no veto'
    END                                             AS veto,
    role_label,
    COUNT(DISTINCT snid)                            AS people,
    ROUND(AVG(org_score), 3)                        AS avg_org_score,
    ROUND(AVG(role_final_score), 3)                 AS avg_final_score
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles` f
WHERE role_key = 'faculty_head'
GROUP BY veto, role_label
ORDER BY veto, role_label;


-- ###########################################################################
-- 2. RESEARCHER_ESTABLISHED — THE WEAKEST END, NEVER READ
--
--    16.29% of its records sit below 0.75, against 6.94% for
--    researcher_early. Both groups feed exactly the same two roles, so the
--    difference is not design - it is that one group's nine anchors are
--    doing more work than the other's thirteen.
--
--    Nine anchors for this group: senior researcher, senior scientist,
--    research scientist, principal investigator, group leader, staff
--    scientist, scientist, head of laboratory, scientific director.
--
--    Sort what you read into the same three piles that worked on
--    practitioner: WRONG, which needs an override; RIGHT BUT UNCONFIDENT,
--    which needs an anchor and is usually the larger pile; and AMBIGUOUS,
--    which is a marketing question.
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
WHERE title_group = 'researcher_established'
  AND is_assigned
  AND similarity < 0.75
ORDER BY frequency DESC
LIMIT 60;

-- 2a. The same per anchor, which is the diagnostic that worked on
--     practitioner: an anchor carrying a high share below 0.75 is the
--     signature of a MISSING anchor, not a bad one.
SELECT
    matched_anchors[OFFSET(0)]                      AS nearest_anchor,
    COUNT(*)                                        AS distinct_titles,
    SUM(frequency)                                  AS records,
    ROUND(AVG(similarity), 3)                       AS avg_similarity,
    ROUND(SAFE_DIVIDE(SUM(IF(similarity < 0.75, frequency, 0)),
                      SUM(frequency)), 4)           AS share_records_below_075
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
WHERE title_group = 'researcher_established'
  AND is_assigned
GROUP BY nearest_anchor
ORDER BY records DESC;


-- ###########################################################################
-- 3. LEADERSHIP — 27.76%, AND IT FEEDS TWO AUDIENCES
--
--    Read alongside analyses/17 query 1, which lists this group's biggest
--    titles and how many of each confirm. That query already showed the
--    corporate titles mostly failing as intended - ceo 879 people with 55
--    confirmed, founder 411 with 31, owner 188 with 2 - so this is the
--    weakest end rather than the known-bad end.
-- ###########################################################################
SELECT
    title,
    frequency,
    ROUND(similarity, 3)        AS similarity,
    matched_anchors[OFFSET(0)]  AS nearest_anchor,
    runner_up,
    needs_human_review
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
WHERE title_group = 'leadership'
  AND is_assigned
  AND similarity < 0.75
ORDER BY frequency DESC
LIMIT 50;


-- ###########################################################################
-- 4. PHARMACIST — 31.71%, AND IT IS A STANDALONE AUDIENCE
--
--    Only 2,335 confirmed people, so the absolute numbers are small, but it
--    is the one audience where a single title group is the whole thing. Ten
--    anchors carry it.
-- ###########################################################################
SELECT
    title,
    frequency,
    ROUND(similarity, 3)        AS similarity,
    matched_anchors[OFFSET(0)]  AS nearest_anchor,
    runner_up,
    needs_human_review
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
WHERE title_group = 'pharmacist'
  AND is_assigned
  AND similarity < 0.75
ORDER BY frequency DESC
LIMIT 40;


-- ###########################################################################
-- 2b. THE TWO ANCHORS WHOSE DAMAGE IS IN THE LONG TAIL
--
--    Query 2a on 2026-10-21, after 37 overrides had cleared the obvious
--    cases, left two anchors untouched and they are the worst in the group:
--
--      scientific director   3,123 titles   84,691 records   39.65% below 0.75
--      head of laboratory    5,203 titles  128,050 records   37.19% below 0.75
--
--    Query 2 cannot show why. Ordered by frequency it surfaces about 2,583
--    of their records, because ~47,600 records below 0.75 on 'head of
--    laboratory' alone are spread across thousands of small titles. 5,203
--    distinct titles leaning on one anchor is the signal: 'head of' and
--    'director' are generic heads, the same failure as 'library manager'
--    attracting 'manager' and 'senior scientist' attracting every senior X.
--
--    So this reads them per anchor instead, 30 each, which is the shape that
--    worked on dentist, gynaecologist and pathologist in analyses/22 query
--    10.
--
--    DECIDE WHAT YOU ARE LOOKING AT BEFORE ACTING. A head of a real
--    laboratory arriving unconfidently needs nothing - the assignment is
--    right and 'researcher' confirms at 0.60, so even the weakest match
--    clears it once the organisation resolves. A head of something that is
--    not a laboratory needs an override. There is no anchor to add here:
--    unlike the dental specialties, 'head of laboratory' is not missing a
--    word, it is holding one that is too general.
--
--    AND LEAVE THE SCIENCES ALONE. microbiologist 2,559 records,
--    geophysicist 1,498, computational biologist 1,331, ecologist 1,101,
--    archaeologist 878 and a dozen more are all CORRECT and all leaning on
--    the single word 'scientist'. Giving each its own anchor would lift the
--    metric and change nobody's audience, while risking exactly what
--    'pathologist' did three times over. A high share below 0.75 can be
--    honest low confidence rather than error - the same as 'dr' and 'md'
--    carrying 146,865 records in the clinical group.
-- ###########################################################################
SELECT
    matched_anchors[OFFSET(0)]  AS nearest_anchor,
    title,
    frequency,
    ROUND(similarity, 3)        AS similarity,
    runner_up,
    needs_human_review
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
WHERE title_group = 'researcher_established'
  AND is_assigned
  AND similarity < 0.75
  AND matched_anchors[OFFSET(0)] IN ('head of laboratory', 'scientific director')
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY matched_anchors[OFFSET(0)] ORDER BY frequency DESC
) <= 30
ORDER BY matched_anchors[OFFSET(0)], frequency DESC;


-- ###########################################################################
-- 3a. LEADERSHIP, THE HALF WE LEARNED TO LOOK AT FIRST
--
--    Query 3 above reads similarity < 0.75, which is the half 2026-10-21
--    taught us is the less informative one: `junior researcher` hid at 0.870
--    and 42,949 records, invisible to every query written before that day.
--    So read this one first and query 3 second.
--
--    leadership is the group with the strongest claim on attention. 27.6% of
--    its records sit below 0.75, the highest of any group that feeds an
--    audience. It feeds TWO - faculty_head at 20,222 people and
--    hcp_administrator at 6,855. And over 2026-10-20 and 21 I moved 11,259
--    records INTO it while reviewing other groups, without ever reading it:
--    2,271 from the practitioner pass, 6,227 from researcher_established,
--    and 2,761 from the student and Italian-director fixes.
--
--    THE FLAG COLUMN carries this group's own failure modes rather than the
--    generic ones:
--
--      a corporate title - ceo, founder, owner, managing director. We know
--      these arrive: analyses/17 query 1 measured ceo at 879 people with 55
--      confirmed, founder 411 with 31, owner 188 with 2. They are supposed
--      to fail on the organisation axis, and this checks whether the title
--      axis is letting them in first.
--
--      a bare generic word - director, head, chief, chair. One single title
--      carries 16.5% of this group's below-0.75 records, 43,456 of them,
--      and it is almost certainly one of these.
--
--      a non-leadership role that matched on a leadership word - how
--      `director of studies` and `clinic director` got in, both already
--      moved out.
-- ###########################################################################
SELECT
    CASE
        WHEN REGEXP_CONTAINS(title, r'\b(ceo|cto|cfo|coo|founder|owner|proprietor|entrepreneur|managing director|general manager|partner|president|vice president|vp|board member|shareholder)\b')
            THEN '1. corporate title'
        WHEN REGEXP_CONTAINS(title, r'^(director|head|chief|chair|chairman|chairperson|manager|lead|leader|coordinator|supervisor|administrator|executive|officer|principal)$')
            THEN '2. bare generic word'
        WHEN REGEXP_CONTAINS(title, r'\b(editor|studies|programme|program|course|curriculum|library|nurse|clinic|school|museum|press|communications|marketing|sales|hr|human resources|finance|it)\b')
            THEN '3. a non-leadership role wearing a leadership word'
        ELSE '4. no flag'
    END                             AS flag,
    title,
    frequency,
    ROUND(similarity, 3)            AS similarity,
    matched_anchors[OFFSET(0)]      AS nearest_anchor,
    runner_up,
    decision_source
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
WHERE title_group = 'leadership'
  AND is_assigned
  AND similarity >= 0.75
QUALIFY ROW_NUMBER() OVER (ORDER BY frequency DESC) <= 120
ORDER BY flag, frequency DESC;

-- 3b. How far did 120 rows get, so the next pass is a decision rather than
--     a guess. Compare with practitioner, where 150 reached 52%.
SELECT
    COUNT(*)                                        AS titles_above_075,
    SUM(frequency)                                  AS records_above_075,
    SUM(IF(rn <= 120, frequency, 0))                AS covered_by_top_120,
    ROUND(SUM(IF(rn <= 120, frequency, 0)) / SUM(frequency), 4)
                                                    AS share_covered
FROM (
    SELECT frequency, ROW_NUMBER() OVER (ORDER BY frequency DESC) AS rn
    FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
    WHERE title_group = 'leadership' AND is_assigned AND similarity >= 0.75
);

-- 3c. MY OWN DECISIONS, AUDITED.
--     Every title a human put into leadership, at any similarity. 11,259
--     records were moved here during other groups' reviews on the reasoning
--     that leadership is conditional - faculty_head needs an academic
--     organisation and hcp_administrator needs a clinical department, so a
--     corporate or a clinical title should land correctly or not at all.
--
--     That reasoning is unverified. This lists the decisions so they can be
--     read as a set, which is something no amount of reading the VECTOR
--     assignments would surface.
SELECT
    title,
    frequency,
    ROUND(similarity, 3)            AS similarity_to_vector_choice,
    matched_anchors[OFFSET(0)]       AS vector_nearest_anchor,
    runner_up                        AS vector_runner_up
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
WHERE title_group = 'leadership'
  AND decision_source = 'HUMAN'
  AND is_assigned
ORDER BY frequency DESC;


-- ###########################################################################
-- 5. TEACHING_ACADEMIC — THE GROUP WHERE ERRORS ARE LEAST FILTERED
--
--    Never read. 12,065,457 records, the largest group in the project, and
--    it feeds the largest audience: lecturer, 400,445 people.
--
--    AND IT HAS NO SECOND AXIS. `lecturer` is title_required with weights
--    0.75 role / 0.25 org / 0.00 dept and a 0.60 threshold, so the weakest
--    possible assignment - group_score 0.70 - gives 0.525, and a resolved
--    organisation adds 0.25 for 0.775. Confirmed. Every title that lands in
--    this group reaches the audience once the organisation resolves, with
--    nothing to catch it, where hcp_broad has the department axis doing
--    exactly that job.
--
--    So the stakes here are higher than its 6.74% below-0.75 suggests. That
--    share is the LOWEST of any group, and 2026-10-21 taught us a low share
--    means little: `junior researcher` hid at 0.870. The absolute count is
--    813,682 records, the largest anywhere.
--
--    THE FLAG COLUMN IS DIFFERENT FOR THIS GROUP. Three of its fifteen
--    anchors are ordinary English words - `teacher`, `instructor`, `reader`
--    - and `docente` and `dozent` are the ordinary words in Italian, Spanish
--    and German. The risk is not a compound anchor's generic half, as it was
--    everywhere else. It is that the anchor itself is generic:
--
--      instructor      - a driving, fitness or flight instructor
--      trainer         - a corporate trainer, already rejected once by hand
--      reader          - a UK academic rank, and also just someone reading
--      teacher         - a school teacher, which is a MARKETING question
--                        rather than an error: see query 5b
--
--    And the reverse case we have already met twice: an academic rank word
--    on a non-teaching post. `personal chair` was a professorship sitting in
--    leadership, `vice professor` likewise.
-- ###########################################################################
SELECT
    CASE
        WHEN REGEXP_CONTAINS(title, r'\b(driving|fitness|yoga|flight|swimming|ski|tennis|football|music|dance|driver|personal trainer|corporate)\b')
            THEN '1. non-academic instruction'
        WHEN REGEXP_CONTAINS(title, r'^(teacher|instructor|reader|trainer|tutor|educator|faculty|docente|dozent|lecturer)$')
            THEN '2. bare generic anchor word'
        WHEN REGEXP_CONTAINS(title, r'\b(school|primary|secondary|elementary|high school|kindergarten|college preparatory|vocational|k-12)\b')
            THEN '3. school rather than university - see 5b'
        WHEN REGEXP_CONTAINS(title, r'\b(assistant|student|phd|doctoral|graduate|trainee|intern)\b')
            THEN '4. may belong to student or researcher_early'
        ELSE '5. no flag'
    END                             AS flag,
    title,
    frequency,
    ROUND(similarity, 3)            AS similarity,
    matched_anchors[OFFSET(0)]      AS nearest_anchor,
    runner_up,
    decision_source
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
WHERE title_group = 'teaching_academic'
  AND is_assigned
  AND similarity >= 0.75
QUALIFY ROW_NUMBER() OVER (ORDER BY frequency DESC) <= 140
ORDER BY flag, frequency DESC;

-- 5a. Coverage, and the three generic anchors measured on their own.
--     An anchor that is an ordinary word will carry far more distinct titles
--     than one that names a profession - that ratio is the thing to read.
SELECT
    matched_anchors[OFFSET(0)]                      AS nearest_anchor,
    COUNT(*)                                        AS distinct_titles,
    SUM(frequency)                                  AS records,
    ROUND(AVG(similarity), 3)                       AS avg_similarity,
    ROUND(SAFE_DIVIDE(SUM(IF(similarity < 0.75, frequency, 0)),
                      SUM(frequency)), 4)           AS share_below_075
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
WHERE title_group = 'teaching_academic'
  AND is_assigned
GROUP BY nearest_anchor
ORDER BY records DESC;

-- 5b. IS A SCHOOL TEACHER IN THE LECTURER AUDIENCE?
--
--     A marketing question, not a defect, and nobody has asked it because
--     nobody had looked at this group. `teacher` is one of our fifteen
--     anchors, so school teachers land in teaching_academic and reach the
--     Lecturer audience - and `lecturer` has no field requirement to
--     separate them from university staff.
--
--     This sizes it. If it is small, it does not matter. If it is hundreds
--     of thousands of records, marketing needs to answer before the next
--     campaign, because a Lecturer campaign is currently reaching school
--     teachers.
--
--     The organisation axis is the only thing that could separate them, so
--     org_type is shown: a school resolving as 'education' in ROR scores the
--     same as a university.
SELECT
    CASE
        WHEN REGEXP_CONTAINS(d.title, r'\b(primary|elementary|kindergarten|preschool|infant)\b')
            THEN '1. primary or pre-school'
        WHEN REGEXP_CONTAINS(d.title, r'\b(secondary|high school|middle school|grammar school|sixth form|k-12)\b')
            THEN '2. secondary school'
        WHEN REGEXP_CONTAINS(d.title, r'\b(school)\b')
            THEN '3. says school, level unclear'
        ELSE '4. no school word'
    END                                             AS level,
    COUNT(*)                                        AS distinct_titles,
    SUM(d.frequency)                                AS records,
    ROUND(AVG(d.similarity), 3)                     AS avg_similarity
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group` d
WHERE d.title_group = 'teaching_academic'
  AND d.is_assigned
GROUP BY level
ORDER BY records DESC;

-- 5c. The biggest titles behind the school buckets, so the question can be
--     judged on examples rather than on a count.
SELECT
    title,
    frequency,
    ROUND(similarity, 3)        AS similarity,
    matched_anchors[OFFSET(0)]  AS nearest_anchor,
    runner_up
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
WHERE title_group = 'teaching_academic'
  AND is_assigned
  AND REGEXP_CONTAINS(title, r'\b(school|primary|secondary|elementary|kindergarten|high school|middle school|k-12|vocational)\b')
ORDER BY frequency DESC
LIMIT 40;


-- ###########################################################################
-- 5d. `reader` AND THE REST OF ITS 732 TITLES
--
--    Query 5a measured `reader` at 46,822 records across 732 distinct titles
--    with 44.91% below 0.75 - the worst share of any anchor in the group
--    that carries real volume. `dozent` is worse at 54.38% but holds only
--    5,695 records.
--
--    `reader` is a senior academic rank in the UK and an ordinary English
--    word everywhere else, so it cannot be removed and cannot be trusted.
--    Query 5 showed only the anchor matching itself at 16,564 records; the
--    other 731 titles are invisible at that depth.
-- ###########################################################################
SELECT
    matched_anchors[OFFSET(0)]  AS nearest_anchor,
    title,
    frequency,
    ROUND(similarity, 3)        AS similarity,
    runner_up,
    needs_human_review
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
WHERE title_group = 'teaching_academic'
  AND is_assigned
  AND matched_anchors[OFFSET(0)] IN ('reader', 'dozent', 'faculty member')
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY matched_anchors[OFFSET(0)] ORDER BY frequency DESC
) <= 25
ORDER BY matched_anchors[OFFSET(0)], frequency DESC;


-- ###########################################################################
-- 6. RESEARCHER_EARLY — 8.3 MILLION RECORDS, NEVER READ
--
--    The second-largest group in the project and the second-largest
--    audience: `researcher`, 322,266 people. 8,341,542 records at 6.9%
--    below 0.75 - a low share, and 2026-10-21 taught us a low share means
--    little, since `junior researcher` hid at 0.870.
--
--    THIS GROUP'S ANCHORS ARE THE MOST GENERIC IN THE PROJECT. Thirteen of
--    them, and look at what they are made of:
--
--      researcher                  the single most generic occupational
--                                  word we use anywhere
--      research assistant          'assistant' is the generic half
--      research associate          'associate' is the generic half
--      research fellow             'fellow' is the generic half
--      collaboratori               Italian for 'collaborators'
--      borsisti                    Italian for 'scholarship holders'
--      assegnisti                  Italian for 'grant holders'
--      post doctor                 and this one can reach plain 'doctor'
--
--    So every failure mode we have catalogued applies here at once: the
--    generic half (library manager / manager), the short foreign word in a
--    sparse region (bibliotecario / biologo), and the ordinary English word
--    as an anchor (teacher, reader).
--
--    Read 6a FIRST - it is the per-anchor table and it will say which of the
--    thirteen to worry about before anyone reads a title.
-- ###########################################################################
SELECT
    CASE
        WHEN REGEXP_CONTAINS(title, r'\b(phd student|doctoral student|doctoral candidate|phd candidate|graduate student|masters student|undergraduate|estudiante|doctorando|doctoranda)\b')
            THEN '1. a student, not a researcher'
        WHEN REGEXP_CONTAINS(title, r'^(researcher|research assistant|research associate|research fellow|associate|assistant|fellow|collaborator|collaboratori|borsisti|assegnisti)$')
            THEN '2. bare generic anchor word'
        WHEN REGEXP_CONTAINS(title, r'\b(administrative|executive|personal|sales|teaching|clinical trial|laboratory|lab|technical|it|hr)\s+(assistant|associate|officer|coordinator)\b')
            THEN '3. an assistant or associate of something else'
        WHEN REGEXP_CONTAINS(title, r'\b(senior|principal|chief|lead|head|distinguished|professor)\b')
            THEN '4. carries a senior marker - see 1.16'
        ELSE '5. no flag'
    END                             AS flag,
    title,
    frequency,
    ROUND(similarity, 3)            AS similarity,
    matched_anchors[OFFSET(0)]      AS nearest_anchor,
    runner_up,
    decision_source
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
WHERE title_group = 'researcher_early'
  AND is_assigned
  AND similarity >= 0.75
QUALIFY ROW_NUMBER() OVER (ORDER BY frequency DESC) <= 140
ORDER BY flag, frequency DESC;

-- 6a. Per anchor. RUN THIS FIRST.
--     The ratio to read is distinct_titles against records: an anchor that is
--     an ordinary word carries far more distinct titles per record than one
--     naming a position. `researcher` and `collaboratori` are the two to
--     watch.
SELECT
    matched_anchors[OFFSET(0)]                      AS nearest_anchor,
    COUNT(*)                                        AS distinct_titles,
    SUM(frequency)                                  AS records,
    ROUND(AVG(similarity), 3)                       AS avg_similarity,
    ROUND(SAFE_DIVIDE(SUM(IF(similarity < 0.75, frequency, 0)),
                      SUM(frequency)), 4)           AS share_below_075
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
WHERE title_group = 'researcher_early'
  AND is_assigned
GROUP BY nearest_anchor
ORDER BY records DESC;

-- 6b. Coverage, so going deeper than 140 is a decision rather than a guess.
SELECT
    COUNT(*)                                        AS titles_above_075,
    SUM(frequency)                                  AS records_above_075,
    SUM(IF(rn <= 140, frequency, 0))                AS covered_by_top_140,
    ROUND(SUM(IF(rn <= 140, frequency, 0)) / SUM(frequency), 4)
                                                    AS share_covered
FROM (
    SELECT frequency, ROW_NUMBER() OVER (ORDER BY frequency DESC) AS rn
    FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
    WHERE title_group = 'researcher_early' AND is_assigned AND similarity >= 0.75
);


-- ###########################################################################
-- 6c. THE THREE DIRTY ANCHORS IN researcher_early
--
--    Query 6 covered 80.58% of the group's above-0.75 records with 140
--    titles - the best coverage of any group so far, because the
--    distribution is extremely concentrated. `researcher` alone is 744,598
--    records.
--
--    It also showed the group is cleaner than expected. `researcher`, which
--    I flagged as the most generic anchor in the project, came in at 8.1%
--    below 0.75. Three anchors did not:
--
--      collaboratori                  104,162 records   54.6% below 0.75
--      wissenschaftlicher mitarbeiter 148,253           27.4%
--      post doctor                     60,590           21.1%
--
--    `collaboratori` is Italian for 'collaborators' - a short foreign word
--    in a sparse region, which is the `dozent` pattern (2.4f), and it should
--    be read the same way. `post doctor` is the one that could reach plain
--    `doctor`, which is why it was flagged before the group was opened.
--    `wissenschaftlicher mitarbeiter` is long and specific, so its 27.4% is
--    more likely the title-length effect (2.4b) than contamination - the
--    query will say which.
-- ###########################################################################
SELECT
    matched_anchors[OFFSET(0)]  AS nearest_anchor,
    title,
    frequency,
    ROUND(similarity, 3)        AS similarity,
    runner_up,
    needs_human_review
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
WHERE title_group = 'researcher_early'
  AND is_assigned
  AND similarity < 0.75
  AND matched_anchors[OFFSET(0)] IN ('collaboratori', 'wissenschaftlicher mitarbeiter',
                                     'post doctor', 'research fellow')
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY matched_anchors[OFFSET(0)] ORDER BY frequency DESC
) <= 22
ORDER BY matched_anchors[OFFSET(0)], frequency DESC;


-- ###########################################################################
-- 7. TRAINEE_CLINICAL — TWO OF ITS ANCHORS ARE ORDINARY WORDS
--
--    Never read. 873,102 records at 18.4% below 0.75, and it feeds
--    hcp_broad and hcp_practitioner - the same two roles `practitioner`
--    feeds, which has two consequences worth holding onto.
--
--    Moving a title between trainee_clinical and practitioner changes NO
--    audience, which is why the UK trainee grades found on 2026-10-20 -
--    core surgical trainee 2,050 records, foundation doctor 2,038 - were
--    left where they were rather than corrected for tidiness.
--
--    But a title arriving from OUTSIDE either group does reach the audience,
--    and hcp_broad is title_or_field, so a perfect title match plus a
--    resolved organisation confirms at exactly 0.60 with no department
--    agreeing. That is the 1,008 people measured in analyses/22 query 1.
--
--    ITS ANCHORS: resident, resident physician, senior resident, specialist
--    registrar, clinical fellow, intern, house officer, medical resident.
--
--    Two of those are ordinary English words and that is the whole risk:
--
--      intern        every industry has interns - software, marketing,
--                    legal, engineering. `research intern` 28,124 records
--                    was already moved to researcher_early by hand.
--      resident      someone who lives somewhere. Also artist in residence,
--                    resident engineer, resident representative.
--
--    This is the `teacher` and `reader` pattern from teaching_academic
--    rather than the compound-anchor pattern - the anchor itself is generic,
--    not its generic half. And `clinical fellow` and `house officer` carry
--    generic halves on top of that.
-- ###########################################################################
SELECT
    CASE
        WHEN REGEXP_CONTAINS(title, r'\b(software|marketing|business|finance|legal|law|sales|hr|human resources|communications|engineering|data|design|media|policy|consulting)\b')
            THEN '1. an intern or resident of something non-clinical'
        WHEN REGEXP_CONTAINS(title, r'\b(artist|writer|composer|residence|scholar in|fellow in residence)\b')
            THEN '2. in RESIDENCE, not a resident doctor'
        WHEN REGEXP_CONTAINS(title, r'^(intern|resident|fellow|trainee|registrar|officer|house officer)$')
            THEN '3. bare generic anchor word'
        WHEN REGEXP_CONTAINS(title, r'\b(consultant|attending|specialist physician|senior physician|chief|head of)\b')
            THEN '4. may be fully qualified, not a trainee'
        ELSE '5. no flag'
    END                             AS flag,
    title,
    frequency,
    ROUND(similarity, 3)            AS similarity,
    matched_anchors[OFFSET(0)]      AS nearest_anchor,
    runner_up,
    decision_source
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
WHERE title_group = 'trainee_clinical'
  AND is_assigned
  AND similarity >= 0.75
QUALIFY ROW_NUMBER() OVER (ORDER BY frequency DESC) <= 100
ORDER BY flag, frequency DESC;

-- 7a. Per anchor. RUN FIRST - it will say whether `intern` and `resident`
--     are behaving as feared before anyone reads a title.
SELECT
    matched_anchors[OFFSET(0)]                      AS nearest_anchor,
    COUNT(*)                                        AS distinct_titles,
    SUM(frequency)                                  AS records,
    ROUND(AVG(similarity), 3)                       AS avg_similarity,
    ROUND(SAFE_DIVIDE(SUM(IF(similarity < 0.75, frequency, 0)),
                      SUM(frequency)), 4)           AS share_below_075
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
WHERE title_group = 'trainee_clinical'
  AND is_assigned
GROUP BY nearest_anchor
ORDER BY records DESC;

-- 7b. Coverage of 100 rows, plus the below-0.75 half read at the same time -
--     this group is small enough that one query can cover both halves, which
--     was not true of teaching_academic or researcher_early.
SELECT
    CASE WHEN similarity >= 0.75 THEN '1. above 0.75' ELSE '2. below 0.75' END AS band,
    COUNT(*)                                        AS titles,
    SUM(frequency)                                  AS records,
    SUM(IF(rn <= 100, frequency, 0))                AS covered_by_top_100_of_band,
    ROUND(SUM(IF(rn <= 100, frequency, 0)) / SUM(frequency), 4) AS share_covered
FROM (
    SELECT frequency, similarity,
           ROW_NUMBER() OVER (
               PARTITION BY similarity >= 0.75 ORDER BY frequency DESC
           ) AS rn
    FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
    WHERE title_group = 'trainee_clinical' AND is_assigned
)
GROUP BY band
ORDER BY band;

-- 7c. The below-0.75 half, 60 titles, since 7b will show it is reachable.
SELECT
    title,
    frequency,
    ROUND(similarity, 3)            AS similarity,
    matched_anchors[OFFSET(0)]      AS nearest_anchor,
    runner_up,
    needs_human_review
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
WHERE title_group = 'trainee_clinical'
  AND is_assigned
  AND similarity < 0.75
ORDER BY frequency DESC
LIMIT 60;
