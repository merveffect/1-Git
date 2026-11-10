/*
    ============================================================================
    44. WHAT THE 13 NEW DISCIPLINE ANCHORS WILL DO
    ============================================================================
    Merve approved the add-not-remove approach on 2026-11-10. 13 anchors
    went into seeds/discipline_anchors.csv. `faculty of medicine` and
    `school of medicine` STAY - removing them would have sent 270
    departments and 12,525 records into `pharmacy`, which is the one
    receiving discipline that feeds a live audience.

    THE FORECAST, written before the build.

    What SHOULD move out of health_clinical, from analyses/43:

        school of life sciences                     21,738 records
        faculty of biology                           2,633
        faculty of life sciences                     1,895
        department of biomedicine                    3,318
        department of biomedical science             1,187
        faculty of arts and humanities                 568
        faculty of humanities and arts                 741
        physikalisches institut family              ~1,968
        institut fur philosophie + philosophisches     ~17 departments
        plant pathology family                     ~13,000
        fisheries / aquaculture family              ~1,000
        ---------------------------------------------------------
        order of magnitude                         ~50,000 records

    That number is deliberately loose. The anchors are matched by MEANING,
    not by string, so each one also takes neighbours nobody listed - which
    is the point of an anchor and also the risk. Query 1 is the real
    forecast.

    THE TWO WAYS THIS GOES WRONG, and both are checked:

      a new anchor steals a CLINICAL department
          `plant pathology` must not reach `department of pathology`
          (11,640 records) or `institute of pathology` (1,411).
          `biomedical sciences` must not reach `school of biomedical
          sciences` if marketing later says biomedical IS clinical - that
          one is 1.2 and is flagged rather than prevented.
          Query 2.

      a new anchor does not win at all
          `life sciences` was already an anchor in life_biomedical and
          STILL lost `school of life sciences` to the faculty magnet at
          0.809. An exact phrase should beat that, but should is not
          measured. Query 3.
    ============================================================================
*/


-- ----------------------------------------------------------------------------
-- 1. THE BEFORE PICTURE. Run this BEFORE the build, then again after.
--
--    One row per family. health_clinical is the column that must fall.
-- ----------------------------------------------------------------------------
with d as (
    select
        department, discipline, frequency, similarity,
        case
            when regexp_contains(lower(department), r'(\blife science|\bbiomedicin|\bbiomedical science|\bfaculty of biology)') then '1 life sciences and biomedicine'
            when regexp_contains(lower(department), r'(\bplant|\bcrop|\bagronom)')            then '2 plants'
            when regexp_contains(lower(department), r'(\bfisher|\baquacult|\bfish\b)')        then '3 fisheries'
            when regexp_contains(lower(department), r'(\bphysik|\bphysics)')                  then '4 physics'
            when regexp_contains(lower(department), r'(\bphilosoph|\bhumanit|\barts\b)')      then '5 humanities and arts'
            else null
        end as family
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_department_discipline`
    where is_assigned
)
select
    family,
    countif(discipline = 'health_clinical')                         as depts_in_health_clinical,
    sum(if(discipline = 'health_clinical', frequency, 0))           as records_in_health_clinical,
    countif(discipline = 'pharmacy')                                as depts_in_pharmacy,
    sum(if(discipline = 'pharmacy', frequency, 0))                  as records_in_pharmacy,
    count(*)                                                        as depts_total,
    sum(frequency)                                                  as records_total
from d
where family is not null
group by family
order by family
;


-- ----------------------------------------------------------------------------
-- 2. THE CLINICAL DEPARTMENTS THE NEW ANCHORS MUST NOT STEAL.
--
--    These are correctly in health_clinical today and the build must leave
--    them there. Run before and after - every row's discipline must still
--    read health_clinical afterwards.
--
--    `pathology` is the sharp one. analyses/39 query 3 said the plant-ish
--    pathology departments sit at 0.694 and the clinical ones at 0.747, so
--    an exact `plant pathology` anchor should separate them. Should.
-- ----------------------------------------------------------------------------
select
    department,
    discipline,
    frequency,
    round(similarity, 3)                      as similarity,
    round(margin, 3)                          as margin,
    array_to_string(matched_anchors, ' | ')   as matched
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_department_discipline`
where is_assigned
  and lower(department) in (
      'department of pathology', 'institute of pathology', 'pathology',
      'department of pathology and laboratory medicine', 'surgical pathology',
      'clinical pathology', 'department of clinical pathology',
      'school of biomedical sciences', 'department of physiology',
      'department of biochemistry', 'school of life sciences',
      'faculty of biology', 'department of biomedicine'
  )
order by frequency desc
;


-- ----------------------------------------------------------------------------
-- 3. DOES THE NEW ANCHOR ACTUALLY WIN. Run AFTER the build only.
--
--    For each of the 13, what it ended up holding. An anchor with zero
--    departments did not win anything and the magnet still has them - which
--    would mean an exact phrase does not beat `faculty of medicine`, and
--    the add-not-remove approach does not work on this axis.
-- ----------------------------------------------------------------------------
with new_anchors as (
    select * from unnest([
        'school of life sciences', 'faculty of life sciences', 'faculty of biology',
        'department of biomedicine', 'biomedical sciences', 'plant pathology',
        'fisheries', 'aquaculture', 'crop science', 'physikalisches institut',
        'institut fur theoretische physik', 'institut fur philosophie',
        'faculty of arts and humanities'
    ]) as anchor_term
)
select
    n.anchor_term,
    count(distinct m.department)  as departments_held,
    sum(m.frequency)              as records_held,
    string_agg(distinct m.discipline, ', ')  as disciplines_it_landed_in
from new_anchors n
left join `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_department_discipline` m
    on m.is_assigned
       and exists (select 1 from unnest(m.matched_anchors) a where a = n.anchor_term)
group by n.anchor_term
order by records_held desc
;
