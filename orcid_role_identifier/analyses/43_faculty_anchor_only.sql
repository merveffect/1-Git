/*
    ============================================================================
    43. THE DEPARTMENTS THOSE TWO ANCHORS ARE ACTUALLY HOLDING UP
    ============================================================================
    analyses/42 asked whether removing `faculty of medicine` and `school of
    medicine` would lose anything, and classified the answer with a regex
    for medicine|medical|clinic|klinik|surg|hospital.

    THAT CLASSIFICATION WAS WRONG AND THE OUTPUT SAID SO IMMEDIATELY. The
    "names something else - this is the ERROR" bucket opened with:

        school of nursing             29,373
        school of public health       26,227
        department of neurology       19,903
        department of psychiatry      18,890
        department of pediatrics      13,519
        department of radiology       12,016
        department of cardiology      11,519

    All unambiguously clinical, all in the error bucket, because none of
    them contains the word medicine. 243,927 records in the first 28 rows
    alone, every one of them correctly placed. The list left out
    neurology, cardiology, nursing, psychiatry, pediatrics, radiology,
    pathology, dentistry, oncology, urology, epidemiology, dermatology,
    anesthesiology, nephrology, rheumatology, endocrinology, geriatrics,
    ophthalmology, gastroenterology, hematology and public health.

    FOURTH TIME TODAY FOR THE SAME MISTAKE: a word list narrower than the
    data it is asked about. 38 query 1 matched `ecolog` inside gynecology.
    40's veto recognised a student in six languages and excused one in
    English, twice. So this file does not classify. It uses a STRUCTURAL
    criterion that needs no vocabulary at all:

        a department whose ONLY matched anchors are the two faculty/school
        ones has nothing field-specific holding it, by construction

    and then it LISTS them, because 1,844 rows can be read and a regex
    over clinical vocabulary evidently cannot be written.

    ALREADY MEASURED by 42 query 1, and this is the number that matters:

        names medicine          19,510 departments, 18,999 also held
                                by another anchor  ->    511 at risk
        names something else    16,574,             15,268  ->  1,306
        veterinary                 100,                 73  ->     27
        -------------------------------------------------------------
                                                          1,844 total

    So the two anchors are the sole support of 1,844 departments out of
    36,184 that match them at all. Everything else is anchored by its own
    field and cannot move.
    ============================================================================
*/


-- ----------------------------------------------------------------------------
-- 1. THE 1,844, NAMED. Nothing but the two anchors holds them.
--
--    Read this list. Do not classify it. The point of ordering by
--    frequency is that the top of it decides the question: if the largest
--    rows are faculties of science and sport, removal is right. If they
--    are faculties of medicine, it is not.
-- ----------------------------------------------------------------------------
with held as (
    select
        department,
        frequency,
        similarity,
        margin,
        runner_up,
        matched_anchors
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_department_discipline`
    where is_assigned
      and discipline = 'health_clinical'
)
select
    department,
    frequency,
    round(similarity, 3)  as similarity,
    round(margin, 3)      as margin,
    runner_up             as would_become
from held
where (select count(*) from unnest(matched_anchors) a
       where a not in ('faculty of medicine', 'school of medicine')) = 0
  and (select count(*) from unnest(matched_anchors) a
       where a in ('faculty of medicine', 'school of medicine')) > 0
order by frequency desc
limit 250
;


-- ----------------------------------------------------------------------------
-- 2. WHERE THEY WOULD GO, which is the second half of the decision.
--
--    42 query 3 showed `pharmacy` as the runner-up for 7,884 departments
--    and 629,116 records across the whole matching population. That is
--    worth a second look, because the Pharmacist audience is the only one
--    keyed on the pharmacy discipline. A clinical department landing
--    there does not merely leave healthcare - it JOINS Pharmacist.
--
--    This asks it only of the 1,844 that can actually move. If pharmacy
--    is large here, removing the anchors is not safe on its own and the
--    fix needs an anchor on the receiving side as well.
-- ----------------------------------------------------------------------------
with held as (
    select department, frequency, runner_up, matched_anchors
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_department_discipline`
    where is_assigned and discipline = 'health_clinical'
)
select
    coalesce(nullif(runner_up, ''), '(no runner-up - would be unassigned)') as would_become,
    count(*)        as departments,
    sum(frequency)  as records
from held
where (select count(*) from unnest(matched_anchors) a
       where a not in ('faculty of medicine', 'school of medicine')) = 0
  and (select count(*) from unnest(matched_anchors) a
       where a in ('faculty of medicine', 'school of medicine')) > 0
group by would_become
order by records desc
;
