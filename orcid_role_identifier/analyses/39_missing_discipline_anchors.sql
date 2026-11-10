/*
    ============================================================================
    39. THE DEPARTMENT ERRORS ARE MISSING ANCHORS, NOT BAD ONES
    ============================================================================
    analyses/38 query 1, corrected, returned 852 people in hcp_researcher on
    departments that are not human health:

        2 agriculture and plants               350     our defect
        3 sport and exercise science           166     marketing's call, 1.19
        1 veterinary                           129     marketing's call, 1.18
        4 physics                               55     our defect
        5 humanities, law, arts                 50     our defect
        6 ecology, animal, earth                50     MIXED - read it
        7 engineering, chemistry, computing     52     MIXED - read it

    Themes 6 and 7 are mixed and must not be treated as a block. `Zoonotic
    diseases`, `Viral Zoonoses` and `National Center for Emerging and
    Zoonotic Infectious Diseases` are human infectious disease work and
    belong where they are. `Fish Diseases` and `Wildlife and aquatic
    pathology` do not. Same in 7: `Computational Pathology` and `Ultrasound
    and Optical Imaging` are clinical, `Optical Metrology` is not.

    WHY IT HAPPENS. seeds/discipline_anchors.csv was read on 2026-11-10:

        plant, crop, sport, exercise, kinesiology, fish
                                 no anchor anywhere, in any discipline
        pathology                an anchor in health_clinical
        botany, zoology, veterinary medicine, animal science
                                 anchors, but in life_biomedical, which
                                 feeds no audience at all
        physics, philosophy      anchors, English only, while the
                                 departments arriving are German

    So `Plant Pathology` is not a department the model got wrong. It is a
    department with nothing correct to match, standing next to a strong
    clinical anchor. This is the diagnostic recorded in Part 2b that already
    generalised once: a neighbouring anchor carrying a high share below 0.75
    is the signature of a MISSING anchor, not of a bad one. Six anchors were
    added on that reasoning on 2026-10-20 and five of six behaved exactly as
    predicted.

    THIS FILE PREDICTS, IT DOES NOT FIX. Adding an anchor changes the
    discipline of every department in the data, not only these. Query 1 says
    how confidently each family is held today, which is what decides whether
    a new anchor can take it.
    ============================================================================
*/


-- ----------------------------------------------------------------------------
-- 1. HOW FIRMLY IS EACH FAMILY HELD IN health_clinical TODAY.
--
--    similarity is the distance to the anchor it matched. margin is how far
--    ahead that anchor was of the runner-up.
--
--    A family with LOW similarity and LOW margin is barely held and a new
--    anchor will take it. A family at 0.95 with a wide margin will not move
--    for an anchor alone and would need the override layer that the
--    department axis does not currently have - see query 3.
-- ----------------------------------------------------------------------------
with d as (
    select
        department, discipline, similarity, margin, runner_up, frequency,
        case
            when regexp_contains(lower(department), r'\bveterinar')               then 'veterinary'
            when regexp_contains(lower(department), r'(\bplant|\bcrop|\bagronom|\bhorticult|\bbotan)')   then 'plants'
            when regexp_contains(lower(department), r'(\bsport|\bkinesiolog|\bexercise|physical education)') then 'sport'
            when regexp_contains(lower(department), r'(\bphysik|\bphysics)')      then 'physics'
            when regexp_contains(lower(department), r'(\bphilosoph|\bhumanit|\btheolog)') then 'humanities'
            when regexp_contains(lower(department), r'(\bfish|\baquat|\bwildlife)') then 'fish and wildlife'
            when regexp_contains(lower(department), r'\bzoonos|\bzoonotic')       then 'zoonoses (probably STAYS)'
            else null
        end as family
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_department_discipline`
    where is_assigned
)
select
    family,
    discipline,
    count(*)                        as departments,
    sum(frequency)                  as records,
    round(avg(similarity), 3)       as mean_similarity,
    round(min(similarity), 3)       as min_similarity,
    round(avg(margin), 3)           as mean_margin,
    /*  what the model's SECOND choice was. If the runner-up is already the
        right discipline, the anchor that is missing is a small one.  */
    string_agg(distinct runner_up order by runner_up limit 4) as runners_up
from d
where family is not null
group by family, discipline
order by family, records desc
;


-- ----------------------------------------------------------------------------
-- 2. WHICH ANCHOR IS ACTING AS THE MAGNET.
--
--    matched_anchors names what each department actually matched. If the
--    plants family is held by `pathology` then one new anchor, `plant
--    pathology` in earth_agriculture, does the whole job. If it is held by
--    six different clinical anchors it is a harder problem.
-- ----------------------------------------------------------------------------
select
    case
        when regexp_contains(lower(department), r'(\bplant|\bcrop|\bagronom|\bhorticult|\bbotan)') then 'plants'
        when regexp_contains(lower(department), r'(\bsport|\bkinesiolog|\bexercise|physical education)') then 'sport'
        when regexp_contains(lower(department), r'\bveterinar')          then 'veterinary'
        when regexp_contains(lower(department), r'(\bphysik|\bphysics)') then 'physics'
        when regexp_contains(lower(department), r'(\bphilosoph|\bhumanit|\btheolog)') then 'humanities'
        else 'other'
    end                                     as family,
    cast(matched_anchors as string)         as matched,
    count(*)                                as departments,
    sum(frequency)                          as records
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_department_discipline`
where is_assigned
  and discipline = 'health_clinical'
  and regexp_contains(lower(department),
      r'(\bplant|\bcrop|\bagronom|\bhorticult|\bbotan|\bsport|\bkinesiolog|\bexercise|physical education|\bveterinar|\bphysik|\bphysics|\bphilosoph|\bhumanit|\btheolog)')
group by family, matched
order by records desc
limit 60
;


-- ----------------------------------------------------------------------------
-- 3. WHAT A NEW ANCHOR WOULD COST SOMEWHERE ELSE.
--
--    The reason to measure before writing. `plant pathology` as an
--    earth_agriculture anchor also pulls on every department whose name
--    contains pathology, and `pathology` is one of the most common clinical
--    department words there is. This counts the departments that currently
--    sit in health_clinical BECAUSE of the pathology anchor and are
--    correctly there, which is the population a careless anchor would move.
--
--    If this number is large the anchor has to be `plant pathology` and not
--    `plant`, and even then it needs checking after the build rather than
--    before.
-- ----------------------------------------------------------------------------
select
    case
        when regexp_contains(lower(department), r'(\bplant|\bcrop|\bagri)') then 'plant-ish - SHOULD move'
        else 'clinical pathology - must NOT move'
    end                             as group_,
    count(*)                        as departments,
    sum(frequency)                  as records,
    round(avg(similarity), 3)       as mean_similarity
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_department_discipline`
where is_assigned
  and discipline = 'health_clinical'
  and regexp_contains(lower(department), r'patholog')
group by group_
order by records desc
;
