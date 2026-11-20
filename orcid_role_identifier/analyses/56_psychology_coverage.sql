/*
    ============================================================================
    56. HOW MANY PSYCHOLOGISTS AND PSYCHIATRISTS, AND HOW MANY CAN WE REACH
    ============================================================================
    Merve 2026-11-20: "Psikologlarin ve psikiyatrinin ne kadar coverage oldugu
    ve ne kadar insana ulasabildigimizi ayriyeten query'lerle bulalim. Bir
    number'ini cikaralim. Belki Matthew'a goturup bu yeni bir audience olabilir
    diye sunabiliriz."

    Same day she also closed the question the AI reviewer rules had kept open -
    "a psychologist in a clinical audience" was a `mark UNSURE` row - with: yes,
    a psychologist is a clinician, include them.

    ⭐ READ THIS BEFORE THE NUMBERS, BECAUSE THE TWO PROFESSIONS ARE NOT IN THE
    SAME POSITION TODAY AND THE SEEDS SAY SO.

      PSYCHIATRY IS FULLY IN, on both axes. `psychiatrist` is a practitioner
      title anchor and `psychiatry` is a health_clinical discipline anchor, so a
      psychiatrist in a psychiatry department satisfies hcp_practitioner, which
      needs both.

      PSYCHOLOGY IS HALF IN. There is no `psychologist` anchor and no override,
      so the title reaches the practitioner group only by resembling
      `psychiatrist` - and `psychology` is a SOCIAL_BEHAVIOURAL discipline
      anchor, not a health_clinical one. hcp_practitioner is title_and_field, so
      a psychologist in a Psychology department FAILS the field test and cannot
      enter it. They can still reach hcp_broad, which is title_required.

    So "include psychologists" is not one change. The title side may already
    work and query 2 says whether it does; the field side does not, and query 4
    sizes what it would take. No seed row is written until these have run -
    the point of the measurement is that the answer decides the rule.

    AND THE FIELD SIDE HAS A TRAP WORTH NAMING IN ADVANCE. Moving `psychology`
    wholesale into health_clinical would bring in social, organisational,
    educational and developmental psychology with it, none of which is clinical.
    The pattern Merve approved for sport on the same day applies here - split on
    the word, keep `clinical psychology`, leave plain `psychology` where it is -
    and query 4 is written to show whether that split is where the people
    actually are.
*/


-- ----------------------------------------------------------------------------
-- 1. THE CEILING. Everyone whose job title names either profession, in any
--    audience or none, read off the record table so no audience filter can
--    hide anybody.
--
--    RESULT 2026-11-20:
--      [paste here]
-- ----------------------------------------------------------------------------
select
    case
        when regexp_contains(role_title, r'psychiatr|psikiyatr|psychiatrie|psiquiatr')
            then '1 psychiatry'
        else '2 psychology'
    end                                                 as profession,
    count(distinct snid)                                as people,
    count(*)                                            as employment_records,
    count(distinct role_title)                          as distinct_titles
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_staging.stg_role_records`
where regexp_contains(role_title, r'psycholog|psychiatr|psikolog|psikiyatr|psychologue|psychiatrie|psicolog|psiquiatr|psychotherap|psikoterap')
group by profession
;


-- ----------------------------------------------------------------------------
-- 2. WHERE THEY ARE TODAY, AND HOW MANY WE CAN CONTACT.
--
--    `reachable` is any of the four legal bases. `advertising_opt_in` is broken
--    out separately because if this becomes a proposal to Matthew it will be a
--    programmatic one, and he was told on the same day that the two numbers
--    differ.
--
--    RESULT 2026-11-20:
--      [paste here]
-- ----------------------------------------------------------------------------
select
    case
        when regexp_contains(lower(evidence_title), r'psychiatr|psikiyatr|psychiatrie|psiquiatr')
            then '1 psychiatry'
        else '2 psychology'
    end                                                 as profession,
    role_key,
    count(distinct snid)                                as people,
    count(distinct if(is_marketable or is_advertisable
                      or is_legitimate_interest or is_book_author,
                      snid, null))                      as reachable_any_basis,
    count(distinct if(is_advertisable, snid, null))     as advertising_opt_in
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_presentation.fct_role_audience`
where role_label = 'CONFIRMED'
  and regexp_contains(lower(evidence_title), r'psycholog|psychiatr|psikolog|psikiyatr|psychologue|psychiatrie|psicolog|psiquiatr|psychotherap|psikoterap')
group by profession, role_key
order by profession, people desc
;


-- ----------------------------------------------------------------------------
-- 3. WHICH TITLES, AND WHICH GROUP THE DICTIONARY PUT THEM IN.
--
--    This is the one that says whether the TITLE side already works. If
--    `psychologist` and `clinical psychologist` sit in `practitioner`, the
--    title half of Merve's decision needs nothing. If they sit anywhere else,
--    it needs an override.
--
--    RESULT 2026-11-20:
--      [paste here]
-- ----------------------------------------------------------------------------
select
    title,
    frequency                                           as records,
    title_group,
    decision_source,
    round(similarity, 3)                                as similarity,
    runner_up
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
where regexp_contains(title, r'psycholog|psychiatr|psikolog|psikiyatr|psychologue|psiquiatr|psychotherap')
order by records desc
limit 40
;


-- ----------------------------------------------------------------------------
-- 4. THE FIELD SIDE. Which discipline the psychology departments land in, and
--    how many people sit behind each one.
--
--    WHAT TO LOOK FOR: whether the people are behind departments that say
--    CLINICAL psychology, or behind plain `Psychology`. If they are mostly
--    behind plain `Psychology`, then the split-on-the-word fix recovers almost
--    nobody and the decision needs a wider change - which is exactly the kind
--    of thing worth knowing before writing the rule rather than after.
--
--    RESULT 2026-11-20:
--      [paste here]
-- ----------------------------------------------------------------------------
select
    department,
    frequency                                           as records,
    discipline,
    round(similarity, 3)                                as similarity,
    runner_up
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_department_discipline`
where regexp_contains(department, r'psycholog|psikolog|psychologie|psicolog|psychiatr|psikiyatr|psiquiatr|psychotherap')
order by records desc
limit 40
;
