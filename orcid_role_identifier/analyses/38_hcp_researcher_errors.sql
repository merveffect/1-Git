/*
    ============================================================================
    38. SIZING WHAT THE hcp_researcher READING FOUND
    ============================================================================
    100 CONFIRMED people read one by one on 2026-11-10, from analyses/37
    query 3. Result: 81 correct, 10 wrong, 9 not sure — 89.0% correct of the
    decided, against 90.0% measured on an independent sample on 5 November.
    Two readings of different people landing a point apart is the strongest
    evidence we have that the figure is real.

    The 10 errors are NOT spread evenly. They fall into four causes, and this
    file sizes each one across the whole audience, because a rate out of 100
    says what to look at and nothing about what it is worth fixing.

        cause                                    seen   query
        the department is not human health         4      1
        the title is not a research role           3      2
        a student whose title says no research     1      3
        industry preclinical research              1      4

    The 9 not-sure rows are not errors and are not sized here, except the
    largest cluster: 3 people whose entire job title is `Fellow`, which in a
    US or Australian hospital is a physician in subspecialty training and in
    a university is a researcher. Query 5. That is open question 1.9.

    NOTHING IS PROPOSED HERE. These queries say how big each cause is. The
    fix comes after the numbers, not before them.
    ============================================================================
*/


-- ----------------------------------------------------------------------------
-- 1. THE DEPARTMENT IS NOT HUMAN HEALTH.
--
--    THE FIRST VERSION OF THIS QUERY WAS WRONG AND IS WORTH RECORDING.
--    It matched the words as SUBSTRINGS, with no word boundary, so:
--
--        gyn-ECOLOG-y         matched `ecolog`     374 people
--        g-ASTRO-enterology   matched `astro`      269 people
--        trans-PLANT-ation    matched `plant`       35 people
--
--    45% of the first result was obstetrics, gastroenterology and
--    transplant surgery - three of the most unambiguously clinical
--    departments there are. Same family as 2.4f and 2.4g in
--    open-questions: a short token matches its spelling, not its meaning.
--    Every token is now anchored with \b.
--
--    A boundary alone is not enough either. `Medical Physics`,
--    `Computational Medicine` and `Biomedical Informatics` all match at a
--    boundary and all belong here. So a department that carries a clinical
--    anchor word keeps its place, and only `veterinary` overrides that -
--    veterinary medicine is medicine, and it is not human.
--
--    This is a list to READ, not to delete.
-- ----------------------------------------------------------------------------
with depts as (
    select
        r.evidence_dept,
        count(distinct r.snid) as people
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles` r
    where r.role_key   = 'hcp_researcher'
      and r.role_label = 'CONFIRMED'
      and r.evidence_dept is not null
    group by r.evidence_dept
),
marked as (
    select
        evidence_dept,
        people,
        regexp_contains(lower(evidence_dept),
            r'(medic|medizin|clinic|klinik|patient|hospital|surg|oncolog|onkolog|psychiatr|radiolog|nurs|health|salud|sant[eé]|biomed|epidemiolog|pharmac|cardio|neuro|p[ae]diatr|immunolog|genomic|diagnos|therap|dent|rehabilit)'
        ) as has_clinical_anchor
    from depts
)
select
    case
        /*  veterinary first and unconditionally: `Faculty of Veterinary
            Medicine` carries `medic` and would otherwise be cleared by the
            anchor test, which is exactly the wrong answer.  */
        when regexp_contains(lower(evidence_dept), r'\bveterinar')
            then '1 veterinary'
        when has_clinical_anchor
            then null
        when regexp_contains(lower(evidence_dept),
             r'(\bplant|\bagri|\bcrop|\bsoil|\bforest|\bfisher|\bbotan|\bentomolog|\bhorticult|\bagronom)')
            then '2 agriculture and plants'
        when regexp_contains(lower(evidence_dept),
             r'(\bsport|\bkinesiolog|physical education|\bmovement|\bexercise)')
            then '3 sport and exercise science'
        when regexp_contains(lower(evidence_dept),
             r'(\bphysik|\bphysics|\bastronom|\bastrophys)')
            then '4 physics'
        when regexp_contains(lower(evidence_dept),
             r'(\bphilosoph|\bhumanit|\btheolog|\bhistor|\blaw\b|\bjuris|\blinguist|\bliterat|\barts\b)')
            then '5 humanities, law, arts'
        when regexp_contains(lower(evidence_dept),
             r'(\becolog|\bzoo|\bmarine|\baquat|\bgeolog|\bfish\b|\banimal)')
            then '6 ecology, animal, earth'
        when regexp_contains(lower(evidence_dept),
             r'(\bengineer|\boptical|\bmechanic|\bchemistry|\bchimie|\bmathemat|\bcomput)')
            then '7 engineering, chemistry, computing'
        else null
    end                     as theme,
    evidence_dept,
    people
from marked
where case
        when regexp_contains(lower(evidence_dept), r'\bveterinar') then true
        when has_clinical_anchor then false
        else regexp_contains(lower(evidence_dept),
             r'(\bplant|\bagri|\bcrop|\bsoil|\bforest|\bfisher|\bbotan|\bentomolog|\bhorticult|\bagronom|\bsport|\bkinesiolog|physical education|\bmovement|\bexercise|\bphysik|\bphysics|\bastronom|\bastrophys|\bphilosoph|\bhumanit|\btheolog|\bhistor|\blaw\b|\bjuris|\blinguist|\bliterat|\barts\b|\becolog|\bzoo|\bmarine|\baquat|\bgeolog|\bfish\b|\banimal|\bengineer|\boptical|\bmechanic|\bchemistry|\bchimie|\bmathemat|\bcomput)')
      end
order by theme, people desc
limit 300
;


-- ----------------------------------------------------------------------------
-- 2. THE TITLE IS NOT A RESEARCH ROLE.
--
--    Three different causes wearing one hat, and they want different fixes:
--
--      leadership   `Medicine Program Director and Head of Department of
--                    Patology and Laboratory Services` — the whole title is
--                    a post. This is the leadership-as-attribute problem of
--                    1.10b seen from the other side: there the question was
--                    titles wrongly PROMOTED to leadership, here it is a
--                    leadership title that was never promoted at all.
--      support      `Clinical Research Coordinator Associate` — the
--                    dictionary already puts `Clinical Research Coordinator`
--                    in support_technical, so this is OUR inconsistency, not
--                    a hard case.
--      ownership    `Member/Manager` at an anaesthesia practice LLC — a
--                    practice owner, who is a clinician but not a researcher.
--
--    The grouping column is what the model decided, so a row where
--    decided_by is VECTOR is the model guessing and a row where it is HUMAN
--    is a decision somebody made and may want back.
-- ----------------------------------------------------------------------------
with people as (
    select distinct r.snid, r.evidence_title, r.title_group
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles` r
    where r.role_key   = 'hcp_researcher'
      and r.role_label = 'CONFIRMED'
)
select
    p.title_group,
    p.evidence_title,
    count(*) as people,
    case
        when regexp_contains(lower(p.evidence_title),
             r'\b(head of|director|dean|chair of|chief|president|provost|manager|member/manager|owner|partner)\b')
            then 'leadership or ownership word'
        when regexp_contains(lower(p.evidence_title),
             r'\b(coordinator|administrator|assistant to|secretar|technician|officer|nurse|librarian)\b')
            then 'support or admin word'
        else 'other'
    end as why_flagged
from people p
where regexp_contains(lower(p.evidence_title),
      r'\b(head of|director|dean|chair of|chief|president|provost|manager|owner|partner|coordinator|administrator|technician|officer)\b')
group by p.title_group, p.evidence_title, why_flagged
order by people desc
limit 200
;


-- ----------------------------------------------------------------------------
-- 3. A STUDENT WHOSE TITLE DOES NOT SAY RESEARCH.
--
--    Merve's rule of 4 November, 1.17: a doctoral student belongs in a
--    research audience only if the TITLE says research. Seen once in 100:
--    `Pre-Doctoral Fellow` at a school of public health.
--
--    The rule is DECIDED and NOT IMPLEMENTED. This is what it costs inside
--    this one audience. The postdoc family is excluded explicitly, because
--    every `post-doctoral` title contains the word `doctoral` and sweeping
--    them in is the mistake analyses/35 made.
-- ----------------------------------------------------------------------------
with people as (
    select distinct r.snid, lower(r.evidence_title) as title
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles` r
    where r.role_key   = 'hcp_researcher'
      and r.role_label = 'CONFIRMED'
),
marked as (
    select
        title,
        regexp_contains(title, r'(post[\s-]*doc|postdoc|pos[\s-]*doc|p[oó]s[\s-]*dout|post[\s-]*ph[\s.]*d|post[\s-]*doctorate)') as is_a_postdoc,
        regexp_contains(title, r'\b(student|students|studente|studenti|estudiante|etudiant|ogrenci|doctoral|doctorate|doctorand\w*|doktorand\w*|doutorando|candidate|candidato|candidata|phd|ph d|dphil|predoc\w*|pre doctoral|graduand\w*)\b') as names_a_student,
        regexp_contains(title, r'\b(research|researcher|investigador\w*|chercheur\w*|forscher\w*|arastirmaci|ricercator\w*|scientist|scientific)\b') as says_research
    from people
)
select
    case
        when is_a_postdoc                        then 'POSTDOC - not a student, stays'
        when names_a_student and says_research   then 'student AND says research - stays under 1.17'
        when names_a_student                     then 'student, title says NO research - 1.17 removes'
        else 'names no student'
    end                      as bucket,
    count(*)                 as people
from marked
group by bucket
order by people desc
;


-- ----------------------------------------------------------------------------
-- 4. INDUSTRY. Two rows in 100, and they are not the same question.
--
--    `Sr. Scientist - Preclinical` at Eli Lilly was counted WRONG, because
--    preclinical says in the title that the work is not clinical.
--    `Associate Group Clinical Science Director` at Genentech was counted
--    NOT SURE, because that work IS clinical research and whether a drug
--    company employee is a healthcare professional is marketing's call,
--    not ours. The split is the word, not the employer.
--
--    org_score below 0.70 is the practical marker for a company here: ROR
--    types them Company or has no match at all.
-- ----------------------------------------------------------------------------
select
    case
        when regexp_contains(lower(r.evidence_title), r'\b(preclinical|pre-clinical|in vitro|in vivo|discovery)\b')
            then 'says PRECLINICAL - not clinical work'
        when regexp_contains(lower(r.evidence_title), r'\b(clinical|medical|patient|trial)\b')
            then 'says clinical - marketing definition question'
        else 'neither word'
    end                            as reading,
    count(distinct r.snid)         as people,
    round(avg(r.role_final_score), 3) as mean_score
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles` r
where r.role_key   = 'hcp_researcher'
  and r.role_label = 'CONFIRMED'
  and coalesce(r.org_score, 0.0) < 0.70
group by reading
order by people desc
;


-- ----------------------------------------------------------------------------
-- 5. THE BARE WORD `Fellow`, which is the largest NOT-SURE cluster: 3 of
--    the 9. `Fellow` at Emory Gastroenterology, at Alfred Health Intensive
--    Care and at Thomas Jefferson Medical Oncology. In a US or Australian
--    teaching hospital that is a physician in subspecialty training. In a
--    British or European university it is a researcher. The same word, two
--    professions, and the record carries nothing that separates them.
--
--    This is open question 1.9 with a number attached. Splitting by country
--    is the obvious idea and query 5 is deliberately arranged to show
--    whether it would actually work, rather than assuming it.
-- ----------------------------------------------------------------------------
select
    r.country_code,
    count(distinct r.snid)  as bare_fellow_people,
    count(distinct if(regexp_contains(lower(r.evidence_org), r'(hospital|clinic|medical cent|health system|cancer cent)'),
                      r.snid, null))  as of_which_at_a_hospital
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles` r
where r.role_key   = 'hcp_researcher'
  and r.role_label = 'CONFIRMED'
  and regexp_contains(lower(trim(r.evidence_title)), r'^(clinical |senior |research )?fellow$')
group by r.country_code
order by bare_fellow_people desc
limit 40
;


-- ----------------------------------------------------------------------------
-- 6. DOES CORRECTING A DEPARTMENT LOSE THE PERSON, OR ONLY MOVE THEM?
--
--    Merve, 2026-11-10: "alan farketmeksizin bir kisi her turlu researcher
--    olabilir ki? yani plant pathology alaninda research yapiyor olabilirler."
--
--    Correct, and that is exactly why the two roles are configured
--    differently:
--
--      researcher       disciplines: []                 the title alone
--                       weights role 0.75, org 0.25     0.75 > 0.60, so a
--                       confirmed at 0.60               research title on its
--                                                       own CONFIRMS
--
--      hcp_researcher   disciplines: ['health_clinical']
--                       match: title_and_field          BOTH are required
--
--    So a plant pathologist is a researcher in Researcher, and the only
--    question is whether they are a HEALTHCARE researcher. This query
--    checks that claim against the data instead of asserting it: for the
--    people whose department is one of the non-health themes, what else
--    are they CONFIRMED in right now.
--
--    also_in_researcher SHOULD equal people. If it does not, correcting
--    the department would drop someone out of every audience, and the
--    correction needs to be looked at again before it is written.
-- ----------------------------------------------------------------------------
with flagged as (
    select distinct r.snid, r.evidence_dept
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles` r
    where r.role_key   = 'hcp_researcher'
      and r.role_label = 'CONFIRMED'
      and not regexp_contains(lower(r.evidence_dept),
            r'(medic|medizin|clinic|klinik|patient|hospital|surg|oncolog|onkolog|psychiatr|radiolog|nurs|health|salud|sant[eé]|biomed|epidemiolog|pharmac|cardio|neuro|p[ae]diatr|immunolog|genomic|diagnos|therap|dent|rehabilit)')
      and regexp_contains(lower(r.evidence_dept),
            r'(\bplant|\bagri|\bcrop|\bsoil|\bforest|\bfisher|\bbotan|\bentomolog|\bhorticult|\bagronom|\bphysik|\bphysics|\bastronom|\bphilosoph|\bhumanit|\btheolog|\blinguist|\bliterat)')
),
others as (
    select snid, role_key
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles`
    where role_label = 'CONFIRMED'
)
select
    count(distinct f.snid)                                                   as people,
    count(distinct if(o.role_key = 'researcher',  f.snid, null))             as also_in_researcher,
    count(distinct if(o.role_key = 'lecturer',    f.snid, null))             as also_in_lecturer,
    count(distinct if(o.role_key = 'hcp_broad',   f.snid, null))             as also_in_hcp_broad,
    count(distinct if(o.role_key not in ('researcher', 'hcp_researcher'),
                      f.snid, null))                                         as in_any_other_audience
from flagged f
left join others o using (snid)
;


-- ----------------------------------------------------------------------------
-- 7. WHICH TITLES ARE THE 273, so an override can be written against a title
--    rather than against a rule nobody can inspect.
--
--    Query 3 measured, and the four buckets reconcile to 54,041 exactly,
--    which is hcp_researcher CONFIRMED:
--
--        names no student                        35,846   66.33%
--        POSTDOC - not a student, stays          16,816   31.12%
--        student AND says research, stays         1,106    2.05%
--        student, title says NO research            273    0.51%
--
--    READ THIS BEFORE WRITING ANY OVERRIDE. 273 is what the rule costs
--    INSIDE this audience. An override moves a title out of
--    researcher_early everywhere, and researcher_early also feeds
--    `researcher`, which is 334,689 people and has no discipline filter at
--    all. So the number that decides whether 1.17 is cheap is the one in
--    analyses/35 query 1, not this one. This query only says which titles.
-- ----------------------------------------------------------------------------
with people as (
    select distinct r.snid, r.evidence_title, lower(r.evidence_title) as title
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles` r
    where r.role_key   = 'hcp_researcher'
      and r.role_label = 'CONFIRMED'
)
select
    evidence_title,
    count(*) as people
from people
where not regexp_contains(title, r'(post[\s-]*doc|postdoc|pos[\s-]*doc|p[oó]s[\s-]*dout|post[\s-]*ph[\s.]*d|post[\s-]*doctorate)')
  and regexp_contains(title, r'\b(student|students|studente|studenti|estudiante|etudiant|ogrenci|doctoral|doctorate|doctorand\w*|doktorand\w*|doutorando|candidate|candidato|candidata|phd|ph d|dphil|predoc\w*|pre doctoral|graduand\w*)\b')
  and not regexp_contains(title, r'\b(research|researcher|investigador\w*|chercheur\w*|forscher\w*|arastirmaci|ricercator\w*|scientist|scientific)\b')
group by evidence_title
order by people desc
limit 100
;
