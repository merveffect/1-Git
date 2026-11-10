/*
    ============================================================================
    46. DID THE DEPARTMENT FIX MOVE THE hcp_researcher ACCURACY
    ============================================================================
    Two readings so far, and they agreed:

        5 Nov    400 CONFIRMED people, hand-read    90.0% of the decided
        10 Nov   100 different people, read again   89.0%

    Then the department dictionary was corrected: 108,587 records of
    non-clinical department names left health_clinical, 85% of the wrong
    population. 4 of the 10 errors found on 10 November were exactly that
    cause, and 1 more was the 1.17 student rule, which also landed. So the
    rate should have moved, and this file measures it rather than assuming.

    THE FIRST VERSION OF THIS FILE NAMED 19 PEOPLE BY snid, with my verdict
    on each, as a forecast I could not wriggle out of. It was refused for
    publication and the refusal was right. On 5 November
    validation_samples/ was removed from this repo for exactly this reason,
    and the note that removed it says why: "Raw rows: title + organisation
    + department can point to a real ORCID profile. Results are recorded in
    docs/open-questions.md and the status document instead." A per-person
    row in a QUERY RESULT, pasted into a conversation, is how this project
    has always worked. A per-person row COMMITTED to the repository is a
    different thing, and the project had already decided it.

    So the forecast is kept and the people are not. Query 1 tests the same
    claim by CAUSE instead of by person, which is both publishable and a
    better measurement - 19 people was a sample of one error each, and
    these are the whole populations.
    ============================================================================
*/


-- ----------------------------------------------------------------------------
-- 1. THE FORECAST, BY CAUSE. Every number here was measured BEFORE the
--    department fix, in analyses/38 query 1 and query 3.
--
--        family                    before   expect now   why
--        agriculture and plants       350      ~0        anchors added
--        physics                       55      ~0        anchors added
--        humanities, law, arts         50      ~0        anchors added
--        life sciences, biomedicine     -       -        anchors added
--        veterinary                   129      129       1.18, marketing
--        sport and exercise           166      166       1.19, marketing
--        ecology, animal, earth        50      mixed     partly fixed
--        engineering, computing        52      mixed     mostly clinical
--
--        student, title says no
--        research (rule 1.17)         273      ~0        pattern landed
--
--    A family that has NOT fallen is a fix that did not reach it. The two
--    marketing families must NOT fall - if veterinary or sport moved,
--    something was answered that nobody answered.
-- ----------------------------------------------------------------------------
with people as (
    select distinct
        r.snid,
        lower(coalesce(r.evidence_dept, ''))  as dept,
        lower(r.evidence_title)               as title
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles` r
    where r.role_key   = 'hcp_researcher'
      and r.role_label = 'CONFIRMED'
),
marked as (
    select
        snid,
        case
            when regexp_contains(dept, r'\bveterinar')                                          then '5 veterinary - 1.18, must NOT fall'
            when regexp_contains(dept, r'(\bplant|\bagri|\bcrop|\bsoil|\bforest|\bfisher|\bbotan|\bentomolog|\bhorticult|\bagronom)') then '1 agriculture and plants'
            when regexp_contains(dept, r'(\bsport|\bkinesiolog|physical education|\bmovement|\bexercise)') then '6 sport - 1.19, must NOT fall'
            when regexp_contains(dept, r'(\bphysik|\bphysics|\bastronom)')                      then '2 physics'
            when regexp_contains(dept, r'(\bphilosoph|\bhumanit|\btheolog|\blinguist|\bliterat|\barts\b)') then '3 humanities, law, arts'
            when regexp_contains(dept, r'(\blife science|\bbiomedicin|\bbiomedical science|faculty of biology)') then '4 life sciences and biomedicine'
            else null
        end as family,
        /*  the 1.17 population, same three regexes as the seed pattern  */
        not regexp_contains(title, r'(post[\s-]*doc|postdoc|pos[\s-]*doc|p[oó]s[\s-]*dout|post[\s-]*ph[\s.]*d|post[\s-]*doctorate)')
        and regexp_contains(title, r'\b(student|students|studente|studenti|estudiante|estudiantes|etudiant|etudiante|ogrenci|doctoral|doctorate|doctorand\w*|doktorand\w*|doutorando|doutoranda|candidate|candidato|candidata|phd|ph d|dphil|predoc\w*|pre doctoral|pre-doctoral|graduand\w*|postgraduate|post graduate)\b')
        and not regexp_contains(title, r'(research|investigaci|investigad|pesquisa|ricerc|recherche|chercheur|forsch|arastirma|scientist|scientific|cient[ií]fic)')
            as is_a_1_17_student
    from people
)
select
    coalesce(family, if(is_a_1_17_student, '7 student, title says no research', '8 everything else')) as cause,
    count(*) as people_still_confirmed
from marked
where family is not null or is_a_1_17_student
group by cause
order by cause
;


-- ----------------------------------------------------------------------------
-- 2. A FRESH 100 TO READ, for the rate itself.
--
--    A DIFFERENT hash from analyses/37 query 3 on purpose. Re-reading that
--    sample cannot give an independent number - I know its verdicts now -
--    and the audience gained 419 people in the same build, so a fresh draw
--    measures what is there rather than what survived.
--
--    This output is read in a conversation and is not committed anywhere.
-- ----------------------------------------------------------------------------
select
    r.snid,
    r.evidence_title                                as job_title,
    r.evidence_org                                  as organisation,
    r.evidence_dept                                 as department,
    r.title_group,
    r.discipline,
    round(r.role_final_score, 3)                    as score,
    round(coalesce(r.role_score, 0.0), 2)           as axis_title,
    round(coalesce(r.org_score,  0.0), 2)           as axis_org,
    round(coalesce(r.dept_score, 0.0), 2)           as axis_dept,
    r.country_code,
    r.is_current
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles` r
where r.role_key   = 'hcp_researcher'
  and r.role_label = 'CONFIRMED'
qualify row_number() over (
    order by farm_fingerprint(concat(cast(r.snid as string), '|reading3'))
) <= 100
;


-- ----------------------------------------------------------------------------
-- 1a. WHAT IS STILL THERE, BY DEPARTMENT. Run this before reading query 2.
--
--     Query 1 did not come back as forecast and the forecast was built on
--     a number that could not carry it:
--
--         family              my "before"   now    forecast
--         agriculture, plants      350      273     ~0
--         physics                   55       49     ~0
--         humanities                50       27     ~0
--         veterinary               129      178     129, must not fall
--         sport                    166      315     166, must not fall
--         student, 1.17            273       36     ~0
--
--     THE 1.17 RULE WORKED - 273 to 36, 87% gone. The department fix moved
--     108,587 records to 16,536, 85%, and moved the PEOPLE in this audience
--     by 22%, 11% and 46%. Those are different sizes of the same thing and
--     only one of them was forecast.
--
--     THE "BEFORE" NUMBERS WERE FLOORS, NOT BASELINES. 350, 55, 50, 129 and
--     166 were hand-summed off analyses/38 query 1, which is `limit 300` on
--     a department list, and that file says so in its own header: "these are
--     floors, not totals". I used them as a baseline anyway. Veterinary and
--     sport rising by 49 and 149 while nothing touched them proves it - the
--     same build lifted clinical similarity and carried more people over
--     every threshold, and a floor cannot measure against that.
--
--     So what is left is unknown rather than unchanged, and this query asks
--     it properly: one row per department, with its current discipline. A
--     department reading health_clinical here is either a gap in the new
--     anchors or a department that belongs.
-- ----------------------------------------------------------------------------
with people as (
    select distinct r.snid, r.evidence_dept
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles` r
    where r.role_key   = 'hcp_researcher'
      and r.role_label = 'CONFIRMED'
      and r.evidence_dept is not null
      and regexp_contains(lower(r.evidence_dept),
          r'(\bplant|\bagri|\bcrop|\bsoil|\bforest|\bfisher|\bbotan|\bentomolog|\bhorticult|\bagronom|\bphysik|\bphysics|\bastronom|\bphilosoph|\bhumanit|\btheolog|\blinguist|\bliterat|\barts\b|\blife science|\bbiomedicin|\bbiomedical science|faculty of biology)')
)
select
    p.evidence_dept,
    d.discipline,
    round(d.similarity, 3)                     as similarity,
    round(d.margin, 3)                         as margin,
    array_to_string(d.matched_anchors, ' | ')  as matched,
    count(distinct p.snid)                     as people
from people p
left join `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_department_discipline` d
    on to_hex(md5(p.evidence_dept)) = d.department_key
group by p.evidence_dept, d.discipline, similarity, margin, matched
order by people desc
limit 120
;
