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
--    Seen: `Physikalisches Institut`, `Plant Pathology`, `Comparative
--    Molecular Endocrinology` at a marine sciences centre, and a `Facultad
--    de Ciencias y Humanidades`. The 5 November reading named the same
--    cause independently — veterinary epidemiology, plant pathology,
--    physics — so this is now twice observed.
--
--    This is a candidate list to READ, not a list to delete. A word like
--    `animal` appears in both `animal science` and `laboratory animal
--    medicine`, and only one of those is wrong.
-- ----------------------------------------------------------------------------
select
    r.evidence_dept,
    count(distinct r.snid)  as people,
    count(*)                as rows_
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles` r
where r.role_key   = 'hcp_researcher'
  and r.role_label = 'CONFIRMED'
  and regexp_contains(lower(r.evidence_dept), r'(plant|agri|crop|soil|forest|marine|fish|aquat|veterinar|animal|zoo|entomolog|botan|ecolog|geolog|astro|physik|physics|chemistry|chimie|engineer|informatic|comput|mathemat|humanit|histor|philosoph|theolog|linguist|literat|econom|law|juris|architect|sport)')
group by r.evidence_dept
order by people desc
limit 200
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
