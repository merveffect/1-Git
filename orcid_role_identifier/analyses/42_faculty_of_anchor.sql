/*
    ============================================================================
    42. TWO ANCHORS DESCRIBE A BUILDING, NOT A FIELD
    ============================================================================
    analyses/39 was written to confirm that the department errors are a
    missing-anchor problem. It confirmed that for ONE family and found
    something else for the other four.

    Query 2 named the anchor holding each wrong family in health_clinical:

        family        visible records   of which from `faculty of medicine`
                                        or `school of medicine`
        sport              46,838            39,149     84%
        plants             13,878             1,013      7%
        veterinary          8,350             5,497     66%
        physics             3,958             2,621     66%
        humanities          3,539             3,539    100%
        ---------------------------------------------------------------
        TOTAL              76,563            51,819     68%

    So there are two defects wearing one symptom, and they want opposite
    fixes:

      PLANTS is a field collision. 93% of it is held by the `pathology`
      anchor, which is a real clinical field word that `Plant Pathology`
      happens to contain. A new earth_agriculture anchor fixes it, and
      analyses/39 query 3 says the separation is clean: inside
      health_clinical, the 21 plant-ish pathology departments sit at 0.694
      mean similarity and the 1,477 genuinely clinical ones at 0.747.

      THE OTHER FOUR are a structural magnet. `faculty of medicine` and
      `school of medicine` are four words of which two, `faculty of`, carry
      no field at all. Any department written as "Faculty of <anything>"
      sits close to them: `Faculty of Veterinary Medicine`, `Faculty of
      Sport and Health Sciences`, `Faculty of Arts and Humanities`. Adding
      a plant or physics anchor does nothing for these - the magnet is not
      about the field, it is about the shape of the name.

    This is the project's own documented failure mode at the department
    level. 2.4f: a short anchor attracts its spelling. The `pathologist`
    finding: how crowded the neighbouring region is predicts a magnet, not
    the suffix. Here the crowded region is every faculty in every
    university.

    REMOVING THOSE TWO ANCHORS IS NOT FREE, which is the whole reason this
    file exists rather than a commit. Departments literally named `Faculty
    of Medicine` are genuinely clinical and there are a lot of them. Query
    1 is the number that decides it.
    ============================================================================
*/


-- ----------------------------------------------------------------------------
-- 1. WHO IS HELD BY THOSE TWO ANCHORS, AND DO THEY NAME MEDICINE.
--
--    Only departments whose ONLY matched anchors are the two faculty/school
--    ones. A department also matching `cardiology` is held by something
--    real and is not at risk.
--
--    names_medicine splits the population the decision turns on:
--      true   `Faculty of Medicine`, `School of Medicine Dept of Urology`
--             - removing the anchors would lose these unless another
--             clinical anchor catches them, which is what
--             still_held_by_something_else answers
--      false  `Faculty of Sport Sciences`, `Faculty of Arts and
--             Humanities`, `Faculty of Veterinary Medicine` - these are
--             the error, and `veterinary` counts as false here on purpose
--             because veterinary medicine is not human medicine
-- ----------------------------------------------------------------------------
with held as (
    select
        department,
        frequency,
        similarity,
        margin,
        runner_up,
        matched_anchors,
        array_length(matched_anchors)  as n_anchors
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_department_discipline`
    where is_assigned
      and discipline = 'health_clinical'
      and exists (select 1 from unnest(matched_anchors) a
                  where a in ('faculty of medicine', 'school of medicine'))
)
select
    case
        when regexp_contains(lower(department), r'\bveterinar')
            then '3 names VETERINARY medicine - not human'
        when regexp_contains(lower(department),
             r'(\bmedicine\b|\bmedical\b|\bmedizin|\bm[eé]decine|\bmedicina|\bclinic|\bklinik|\bsurg|\bhospital)')
            then '1 names medicine - would be LOST'
        else '2 names something else - this is the ERROR'
    end                                                      as reading,
    count(*)                                                 as departments,
    sum(frequency)                                           as records,
    round(avg(similarity), 3)                                as mean_similarity,
    round(avg(margin), 3)                                    as mean_margin,
    /*  held by more than the two faculty/school anchors, so another
        clinical anchor would keep it even if these two went away  */
    countif(n_anchors > 2)                                   as also_held_by_others
from held
group by reading
order by reading
;


-- ----------------------------------------------------------------------------
-- 2. THE ERROR POPULATION, NAMED, so the fix can be argued per family
--    rather than as one number. Biggest first.
-- ----------------------------------------------------------------------------
select
    department,
    frequency,
    round(similarity, 3)  as similarity,
    round(margin, 3)      as margin,
    runner_up,
    array_to_string(matched_anchors, ' | ')  as matched
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_department_discipline`
where is_assigned
  and discipline = 'health_clinical'
  and exists (select 1 from unnest(matched_anchors) a
              where a in ('faculty of medicine', 'school of medicine'))
  and not regexp_contains(lower(department),
      r'(\bmedicine\b|\bmedical\b|\bmedizin|\bm[eé]decine|\bmedicina|\bclinic|\bklinik|\bsurg|\bhospital)')
order by frequency desc
limit 150
;


-- ----------------------------------------------------------------------------
-- 3. WHAT THE RUNNER-UP WOULD BE, which decides whether removing the two
--    anchors is enough on its own.
--
--    If the error population's runner_up is already the right discipline,
--    removal alone fixes them and no new anchor is needed. If the
--    runner-up is another health_clinical anchor, removal moves nothing
--    and the fix has to be an anchor on the other side.
-- ----------------------------------------------------------------------------
select
    runner_up,
    count(*)        as departments,
    sum(frequency)  as records
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_department_discipline`
where is_assigned
  and discipline = 'health_clinical'
  and exists (select 1 from unnest(matched_anchors) a
              where a in ('faculty of medicine', 'school of medicine'))
  and not regexp_contains(lower(department),
      r'(\bmedicine\b|\bmedical\b|\bmedizin|\bm[eé]decine|\bmedicina|\bclinic|\bklinik|\bsurg|\bhospital)')
group by runner_up
order by records desc
;
