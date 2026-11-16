/*
    ============================================================================
    53. DECISION MAKERS - sizing the request before any rule is written
    ============================================================================
    Marketing, 2026-11-15: "Could you please review the head of faculty and
    take out the focus on academia? ... it should contain also in general
    opinion leaders, budget holders, influencer to purchase. This is
    especially important for b2c2b as the sales comes a lot from outside
    academia." And: "We might find a better naming for this one as head of
    faculty is misleading."

    They sent `Head of faculty - Target sizing.xlsx` with it. Its sheet
    `B2C view role classification` is 8,911 ORCID job titles covering 17,940
    contacts, hand-sorted into 33 classes - Director 5,125, Head 4,248,
    Principal 1,504, Chair 1,233, Chief 1,197, Dean 1,182, CEO 485,
    President 407, Founder 243. Seven definition questions went back to them
    on 2026-11-16 and are not answered yet.

    WHY THIS FILE EXISTS AND WHAT IT DELIBERATELY DOES NOT DO. None of these
    queries needs their answers, and none of them changes anything. They size
    the request so that when the answers arrive we start from measurement
    rather than from the shape of the words. Nothing here proposes a
    threshold, an anchor or a seed row.

    THE FINDING THAT SHAPED THE QUESTIONS, from reading the seed rather than
    the request. The people marketing are asking for were IN this audience
    and we removed them, between 29 October and 5 November, each with a
    measured reason recorded in org_type_scores.csv:

        Nonprofit   0.40 -> 0.00   "any Director or Executive Director at
                                    ASAPbio, Coral Reef..."
        Government  0.30 -> 0.00   "WHO division directors and ministry heads"
        Healthcare  0.50 -> 0.00   hospital medical directors
        Facility    0.60 -> 0.00   research institutes
        Archive     0.20 -> 0.00   museums, archives
        Company     0.00           "a company executive is not a faculty head"

    Most of them were removed because they did not fit the NAME, not because
    the evidence was wrong. The Company note says so in as many words - and a
    company executive IS a budget holder. So reopening the gate is five
    numbers, and query 1 prices it.

    BUT THE ORG GATE IS NOT THE LEVER THE REQUEST THINKS IT IS. The
    `leadership` anchors are dean, vice dean, head of department, department
    head, department chair, director, deputy director, chief, chair,
    chairman, vice chancellor, provost, rector. `chief executive officer`,
    `founder` and `president` were REMOVED as anchors on 2026-10-16. So
    opening the gate brings back hospital directors, WHO and ministry heads,
    NGO executive directors and museum directors - and brings in almost none
    of the industry decision makers the request describes, because those
    people write CEO, Founder, VP and Managing Director and we match none of
    those. Query 5 measures that gap.

    AND THE SEED ALREADY ASKED FOR QUERY 1. The note on the `dean` anchor,
    written 2026-10-16: "faculty_head needs re-measuring now that those
    anchors are genuinely gone - the org veto may be doing far less work than
    we think."

    WHERE THE ROWS ARE. int_employment_scored keeps every record that
    qualifies on TITLE or DISCIPLINE; its per_role filter does not look at
    org_score at all. So the people the Education-only rule refuses are still
    in that table, carrying org_score 0.00, and can be counted without a
    build.
*/


/* ---------------------------------------------------------------------------
    1. WHAT THE EDUCATION-ONLY GATE IS REFUSING, BY ORGANISATION TYPE

    One row per ROR type. `people` is everybody with a leadership title at a
    post they currently hold; `confirmed_today` is how many of them the
    audience actually delivers. The difference is the size of the request.

    faculty_head weights the title 0.60 and the organisation 0.40 against a
    0.65 threshold, so with the gate fully open (org 1.00) anything with a
    role_score at or above 0.4167 confirms. `would_confirm_if_open` counts
    those, which is the upper bound on what reopening can produce.
--------------------------------------------------------------------------- */
select
    coalesce(org_type, 'NO ROR MATCH')                      as org_type,
    count(distinct snid)                                    as people,
    count(distinct if(org_score > 0, snid, null))           as scores_today,
    count(distinct if(role_score >= 0.4167, snid, null))    as would_confirm_if_open,
    round(avg(role_score), 3)                               as avg_title_score
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.int_employment_scored`
where role_key = 'faculty_head'
  and is_current
group by org_type
order by people desc
;


/* ---------------------------------------------------------------------------
    2. WHO ARRIVES - the titles behind query 1, per refused organisation type

    Query 1 gives a size; this says whether that size is worth having. Read
    it next to the request: if the top titles at Company are Directors of
    Sales then the gate is doing useful work and should not simply be opened.
--------------------------------------------------------------------------- */
select
    coalesce(org_type, 'NO ROR MATCH')  as org_type,
    lower(evidence_title)               as job_title,
    count(distinct snid)                as people,
    round(avg(role_score), 3)           as avg_title_score
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.int_employment_scored`
where role_key = 'faculty_head'
  and is_current
  and coalesce(org_score, 0) = 0        -- the refused ones only
group by org_type, job_title
qualify row_number() over (partition by org_type order by count(distinct snid) desc) <= 15
order by org_type, people desc
;


/* ---------------------------------------------------------------------------
    3. THE BARE WORD - marketing question 3, measured

    Director, Head and Chief are 10,570 of their 17,940 contacts and the word
    alone says nothing about seniority. They were offered two options: take
    every one of them, or take only the ones followed by something that names
    what the person leads. This is what each option costs, in our data rather
    than in theirs.

    BARE means the whole job title is that one word, possibly with a rank
    word in front of it (deputy, associate, executive, senior, acting, vice).
    QUALIFIED means anything else - head of department, research director,
    chief medical officer.
--------------------------------------------------------------------------- */
with leadership_now as (
    select
        snid,
        lower(trim(evidence_title))     as job_title,
        coalesce(org_type, 'NO ROR MATCH') as org_type,
        org_score,
        role_score
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.int_employment_scored`
    where role_key = 'faculty_head'
      and is_current
),

shaped as (
    select
        *,
        case
            when regexp_contains(job_title,
                 r'^((deputy|associate|assistant|executive|senior|acting|vice|co)[ -]+)*(director|head|chief|chair|chairman|chairperson)s?$')
                then 'BARE - the word and nothing else'
            when regexp_contains(job_title, r'\b(director|head|chief|chair|chairman|chairperson)\b')
                then 'QUALIFIED - names what they lead'
            else 'OTHER leadership title (dean, rector, provost...)'
        end as shape
    from leadership_now
)

select
    shape,
    count(distinct snid)                                  as people,
    count(distinct if(org_score > 0, snid, null))         as in_audience_today,
    round(avg(role_score), 3)                             as avg_title_score
from shaped
group by shape
order by people desc
;


/* ---------------------------------------------------------------------------
    3b. THE SAME SPLIT, BY ORGANISATION TYPE

    The reason to cut this two ways: in a university a bare `Director` is
    usually leadership, and outside one it usually is not. If the bare share
    is concentrated in Company and NO ROR MATCH, then the answer to question
    3 can be "take the qualified ones only" and cost the academic half
    almost nothing.
--------------------------------------------------------------------------- */
with leadership_now as (
    select
        snid,
        lower(trim(evidence_title))        as job_title,
        coalesce(org_type, 'NO ROR MATCH') as org_type
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.int_employment_scored`
    where role_key = 'faculty_head'
      and is_current
)

select
    org_type,
    count(distinct snid) as people,
    count(distinct if(regexp_contains(job_title,
         r'^((deputy|associate|assistant|executive|senior|acting|vice|co)[ -]+)*(director|head|chief|chair|chairman|chairperson)s?$'),
         snid, null)) as bare_word_people,
    round(100 * count(distinct if(regexp_contains(job_title,
         r'^((deputy|associate|assistant|executive|senior|acting|vice|co)[ -]+)*(director|head|chief|chair|chairman|chairperson)s?$'),
         snid, null)) / nullif(count(distinct snid), 0), 1) as bare_pct
from leadership_now
group by org_type
order by people desc
;


/* ---------------------------------------------------------------------------
    4. THEIR LIST AGAINST OUR DICTIONARY

    The 55 largest role names in their sheet, covering a third of their
    17,940 contacts. For each one: what title group we put it in today, who
    decided that, and what the title scores. A row with title_group null or
    `support_technical` is a title they want that reaches no audience.

    The names are their spellings, lowercased. dim_title_group holds the
    cleaned ORCID title, so near-misses are expected and are themselves a
    finding - if `chief executive officer` is absent but `ceo` is present,
    that is a vocabulary gap rather than a classification one.
--------------------------------------------------------------------------- */
with their_list as (
    select * from unnest([
        struct('director' as name, 'Director' as their_class),
        ('head of department', 'Head'), ('head', 'Head'),
        ('principal investigator', 'Principal'), ('dean', 'Dean'),
        ('group leader', 'Group Leader'), ('ceo', 'CEO'),
        ('principal scientist', 'Principal'), ('deputy director', 'Director'),
        ('president', 'President'), ('professor and head', 'Head'),
        ('research director', 'Director'), ('chief', 'Chief'),
        ('chair', 'Chair'), ('head of the department', 'Head'),
        ('founder', 'Founder'), ('professor and chair', 'Chair'),
        ('principal researcher', 'Principal'), ('associate director', 'Director'),
        ('executive director', 'Director'), ('professor & head', 'Head'),
        ('medical director', 'Director'),
        ('editorial board member', 'Editorial Board Member'),
        ('chairman', 'Chair'), ('principal', 'Principal'),
        ('scientific director', 'Director'), ('managing director', 'Director'),
        ('vice dean', 'Dean'), ('editor', 'Editor'),
        ('chief physician', 'Chief'), ('chair professor', 'Chair'),
        ('department head', 'Head'), ('vice president', 'President'),
        ('owner', 'Owner'), ('director of research', 'Director'),
        ('senior principal scientist', 'Principal'),
        ('research group leader', 'Group Leader'),
        ('principal research fellow', 'Principal'),
        ('chief scientist', 'Chief'),
        ('principal research scientist', 'Principal'),
        ('organizing committee member', 'Committee Member'),
        ('professor and director', 'Director'), ('program manager', 'Manager'),
        ('chief executive officer', 'CEO'), ('founder & ceo', 'CEO'),
        ('assistant director', 'Director'), ('department chair', 'Chair'),
        ('chief scientific officer', 'Chief'), ('associate dean', 'Dean'),
        ('co-founder', 'CEO'), ('chairperson', 'Chair')
    ])
)

select
    t.their_class,
    t.name                                   as their_title,
    g.title_group                            as our_group,
    g.title_group_2                          as our_second_group,
    g.decision_source,
    round(g.group_score, 3)                  as title_score,
    g.frequency                              as orcid_records,
    if(g.title_key is null, 'NOT IN OUR DICTIONARY AT ALL', 'known') as status
from their_list t
left join `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group` g
       on lower(trim(g.title)) = t.name
order by t.their_class, orcid_records desc nulls last
;


/* ---------------------------------------------------------------------------
    5. THE VOCABULARY WE HAVE NO ROUTE FOR

    The industry side of the request. These are the words a company decision
    maker writes, and `chief executive officer`, `founder` and `president`
    were deliberately removed as anchors on 2026-10-16. This counts how many
    people in ORCID write them and where those people land today - so the
    cost of that removal is a number rather than an argument.

    Read `title_group` null or `support_technical` as: this person is in no
    audience at all.
--------------------------------------------------------------------------- */
with corporate_titles as (
    select
        g.title_key,
        g.title,
        g.title_group,
        g.decision_source,
        g.frequency
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group` g
    where regexp_contains(lower(g.title), r'\b(ceo|chief executive|founder|co-?founder|president|vice president|vp|managing director|chief (medical|scientific|technology|operating|financial) officer|cmo|cso|cto|owner|proprietor|partner|board member|managing partner)\b')
)

select
    coalesce(title_group, 'NO GROUP - reaches no audience') as our_group,
    count(*)                                                as distinct_titles,
    sum(frequency)                                          as records,
    array_agg(title order by frequency desc limit 12)       as biggest_titles
from corporate_titles
group by our_group
order by records desc
;


/* ---------------------------------------------------------------------------
    6. THE EXCLUSION LIST - marketing question 7, sized

    Their `Exclusion Editor` sheet lists 452 organisations: 129 journals, 77
    publishers (12 of them Springer Nature), 155 other/unknown, 54
    UNIVERSITIES and 36 societies. The column is named
    `organisation_name_editorial_roles`, so the list was built from where
    people with editorial roles said they worked.

    The question put to them is whether it should drop the RECORD or the
    PERSON, and the 54 universities are why it matters: Tubingen and Huazhong
    are on that list because somebody there listed an editorial post, not
    because marketing want those universities gone.

    This sizes it from our side - how many people currently hold a leadership
    title at something that looks like a journal or a publisher. It does not
    use their list, because the list is 452 names and this is a shape
    question, not a lookup.

    NOTE: this does not bite today. faculty_head is Education-only, so a
    journal or publisher scores 0.00 and cannot get in anyway. It becomes
    live the moment the gate opens, which is the whole point of asking now.
--------------------------------------------------------------------------- */
select
    case
        when regexp_contains(lower(evidence_org), r'\b(journal|revista|zeitschrift)\b') then 'JOURNAL in the name'
        when regexp_contains(lower(evidence_org), r'\b(publish|publisher|publishing|press|editorial|elsevier|springer|wiley|taylor & francis|sage|frontiers|mdpi|karger|emerald)\b') then 'PUBLISHER in the name'
        else 'neither'
    end                                                 as employer_looks_like,
    coalesce(org_type, 'NO ROR MATCH')                  as org_type,
    count(distinct snid)                                as people,
    count(distinct if(org_score > 0, snid, null))       as in_audience_today
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.int_employment_scored`
where role_key = 'faculty_head'
  and is_current
  and evidence_org is not null
group by employer_looks_like, org_type
having employer_looks_like != 'neither'
order by people desc
;


/* ---------------------------------------------------------------------------
    6b. THE TITLES THOSE PEOPLE HOLD

    Query 6 says how many; this says whether they are editors. If the titles
    are Editor-in-Chief and Editorial Board Member, the list is about the
    ROLE and should drop the record. If they are real Directors of real
    publishing companies, it is about the ORGANISATION and the answer is
    different.
--------------------------------------------------------------------------- */
select
    lower(evidence_title)               as job_title,
    count(distinct snid)                as people,
    count(distinct evidence_org)        as distinct_employers
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.int_employment_scored`
where role_key = 'faculty_head'
  and is_current
  and evidence_org is not null
  and regexp_contains(lower(evidence_org),
        r'\b(journal|revista|zeitschrift|publish|publisher|publishing|press|editorial|elsevier|springer|wiley|sage|frontiers|mdpi|karger|emerald)\b')
group by job_title
order by people desc
limit 40
;
