/*
    ============================================================================
    30. THE PROFESSOR-PLUS-LEADERSHIP COMPOUND TITLES
    ============================================================================
    On 30 October the decision was taken that a compound title naming both a
    professorship and a leadership post should reach the leadership group, so
    that the people who run faculties are reachable in Head of Faculty.

    Reading the full list turned up a problem that makes `chair` unusable as a
    signal:

        full professor and chairholder chair of strategic entrepreneurship  227
        dean s chair associate professor                                    204
        professor canada research chair tier 1                              178
        canada research chair and full professor                            174
        professor & canada excellence research chair                        172

    None of these is a leadership post. A Canada Research Chair is a funded
    research professorship; a `Dean's Chair` is an endowed chair named after the
    office that funds it, not a deanship; a European `Chair of X` (Lehrstuhl) is
    the professorship itself. Roughly 1,600 records of the compound family are
    this shape.

    AND THE EXCLUSION CANNOT BE WRITTEN AS A PATTERN. seeds/title_group_patterns
    is a plain regexp_contains, and BigQuery's RE2 has no negative lookahead, so
    "contains professor and chair but NOT research chair" is not expressible in
    one row. A pattern would therefore have to take the endowed chairs with it.

    So this file sizes the three buckets separately. The question it answers is
    not "should chairs be leadership" - they should not - but how large the
    head/dean family is once chair is set aside, which decides whether it is
    handled by individual overrides (auditable, no architectural change) or
    needs the pattern layer extended beyond librarian for the first time.

    Run against the dictionary and audience tables after a build.
    ============================================================================
*/

-- ----------------------------------------------------------------------------
-- A. THE THREE BUCKETS. How many distinct titles and records in each.
--    Only titles currently sitting in teaching_academic and assigned - these
--    are the ones a move would take out of Lecturer.
-- ----------------------------------------------------------------------------
with compounds as (
    select
        title,
        frequency,
        regexp_contains(title, r'(?i)(\bhead\b|\bdean\b|decano|dekan)') as has_head,
        regexp_contains(title, r'(?i)(chair|lehrstuhl)')                as has_chair,
        regexp_contains(title, r'(?i)(chairholder|research chair|chaire de recherche|'
                             || r'excellence research chair|endowed chair|\bchair of\b|'
                             || r'\bchair in\b|lehrstuhl)')             as chair_is_a_professorship
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
    where title_group = 'teaching_academic'
      and is_assigned
      and regexp_contains(title, r'(?i)(profes|\bprof\b|\bprof\.|dozent|docent)')
)

select
    case
        when has_head and has_chair then 'BOTH head/dean and chair'
        when has_head               then 'HEAD or DEAN only'
        when has_chair              then 'CHAIR only'
    end                                                     as bucket,
    countif(chair_is_a_professorship)                       as titles_whose_chair_is_a_chair,
    count(*)                                                as titles,
    sum(frequency)                                          as records
from compounds
where has_head or has_chair
group by bucket
order by records desc;

-- ----------------------------------------------------------------------------
-- B. THE HEAD-OR-DEAN FAMILY, LISTED. No chair word anywhere in the title, so
--    nothing here is an endowed professorship. This is the candidate list for
--    individual overrides - if it is 30 rows, override it; if it is 300, it
--    needs a pattern.
-- ----------------------------------------------------------------------------
select
    title,
    frequency,
    round(similarity, 3)        as similarity,
    decision_source,
    matched_anchors
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
where title_group = 'teaching_academic'
  and is_assigned
  and regexp_contains(title, r'(?i)(profes|\bprof\b|\bprof\.|dozent|docent)')
  and regexp_contains(title, r'(?i)(\bhead\b|\bdean\b|decano|dekan)')
  and not regexp_contains(title, r'(?i)(chair|lehrstuhl)')
order by frequency desc
limit 120;

-- ----------------------------------------------------------------------------
-- C. WHAT THE MOVE WOULD ACTUALLY COST LECTURER.
--
--    This is the measurement that decides whether the move is cheap. Moving a
--    title out of teaching_academic only removes a person from Lecturer if they
--    hold NO OTHER teaching title. Every earlier correction in this project has
--    found that they do - somebody who wrote `professor and head of department`
--    in one employment record almost always wrote `professor` in another - so
--    measure it rather than assume it in either direction.
-- ----------------------------------------------------------------------------
with compound_titles as (
    select title_key
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
    where title_group = 'teaching_academic'
      and is_assigned
      and regexp_contains(title, r'(?i)(profes|\bprof\b|\bprof\.|dozent|docent)')
      and regexp_contains(title, r'(?i)(\bhead\b|\bdean\b|decano|dekan)')
      and not regexp_contains(title, r'(?i)(chair|lehrstuhl)')
),

plain_teaching_titles as (
    select title_key
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
    where title_group = 'teaching_academic'
      and is_assigned
      and title_key not in (select title_key from compound_titles)
),

people as (
    select
        r.snid,
        countif(r.title_key in (select title_key from compound_titles))       as compound_records,
        countif(r.title_key in (select title_key from plain_teaching_titles)) as plain_records
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_staging.stg_role_records` r
    group by r.snid
)

select
    case when p.plain_records > 0
         then 'STAYS in Lecturer - holds another teaching title'
         else 'LEAVES Lecturer - this compound was the only one'
    end                                     as outcome,
    count(distinct p.snid)                  as people,
    count(distinct a.snid)                  as people_in_lecturer_today
from people p
left join `dat-analytics-eng-ec869189.dev_orcid_role_identifier_presentation.fct_role_audience` a
    on a.snid = p.snid
   and a.role_key = 'lecturer'
where p.compound_records > 0
group by outcome
order by people desc;

-- ----------------------------------------------------------------------------
-- D. AND WHAT IT WOULD GAIN HEAD OF FACULTY. Of the same people, how many are
--    in faculty_head today. Anybody not already there is the gain - subject to
--    the organisation resolving, which is what starves that audience.
-- ----------------------------------------------------------------------------
with compound_titles as (
    select title_key
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
    where title_group = 'teaching_academic'
      and is_assigned
      and regexp_contains(title, r'(?i)(profes|\bprof\b|\bprof\.|dozent|docent)')
      and regexp_contains(title, r'(?i)(\bhead\b|\bdean\b|decano|dekan)')
      and not regexp_contains(title, r'(?i)(chair|lehrstuhl)')
),

holders as (
    select distinct r.snid
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_staging.stg_role_records` r
    where r.title_key in (select title_key from compound_titles)
)

select
    count(*)                                            as compound_holders,
    countif(fh.snid is not null)                        as already_in_faculty_head,
    countif(fh.snid is null)                            as not_in_faculty_head,
    countif(fh.snid is null and cdp.snid is not null)   as not_in_faculty_head_but_reachable
from holders h
left join (
    select distinct snid
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_presentation.fct_role_audience`
    where role_key = 'faculty_head'
) fh using (snid)
left join (
    select distinct snid
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_presentation.fct_role_audience`
    where in_cdp
) cdp using (snid);

/*
    ============================================================================
    MEASURED 2026-10-30. What A-D came back with, and what it changed.
    ============================================================================
        A   HEAD or DEAN only     1,982 titles   78,005 records
            CHAIR only              968 titles   44,611 records   290 of the 968
                                                                  are endowed chairs
            BOTH                     49 titles    1,421 records

        C   3,683 people hold a head/dean compound
              1,944 would STAY in Lecturer - they hold another teaching title
              1,739 would LEAVE - the compound is the only teaching title they have

        D   307 of the 3,683 are already in faculty_head
            3,376 are not; 3,263 of those are reachable

    So the trade is: Lecturer loses at most 1,739 of 399,884 people (0.43%),
    faculty_head gains at most 3,376 of 17,528 (+19%). "At most" on the gain,
    because faculty_head also needs the organisation to resolve, and roughly
    14,600 records with strong leadership titles already fail on exactly that.
    Query H measures it.

    AND THE 1,600 FIGURE WAS WRONG. Reading the visible rows suggested ~1,600
    records of endowed chairs. Measured, 290 of 968 chair titles are endowed
    professorships - 30% of the family by title count. Query E gets the record
    count, which is the number that matters.

    THE LIST ALSO SHOWED THAT `head` IS NOT UNIFORMLY FACULTY LEADERSHIP:

        assistant professor director head and neck surgery          107  anatomy
        professor - senior consultant - head of thrombosis unit     128  clinical unit
        assistant professor head of spine center                    151  clinical centre
        professor head of allergy clinic                            102  clinic
        associate professor - head of scientific committee          156  committee
        assistant professor and head of quality assurance unit      130  admin unit
        dean of the sport sciences faculty 2010-2020 professor      126  ENDED 2020
        dean 2010-2018 adjunct professor 2008-                      109  ENDED 2018

    About 1,500 records in the top 120 alone, and `head and neck surgery` is the
    one that settles the argument: a bare `head` match cannot be trusted.

    WHICH POINTS AT THE PATTERN LAYER, NOT AT OVERRIDES. The exclusion that
    could not be written for `chair` CAN be avoided for `head`, by never
    matching `head` on its own - only `head of department`, `head of school`,
    `head of faculty`, `head of institute`, `head of division` and `dean`. Those
    are positive, faculty-level and need no negation.

    It also settles the word-order split left open in 1.10a: a pattern matches
    `professor and head of department` and `head of department professor`
    identically, which 1,982 individual overrides never would - the top 120
    titles are only 64% of the family, so an override list would leave the same
    indefensible inconsistency at a different cut.

    THREE THINGS TO MEASURE BEFORE EXTENDING THE PATTERN LAYER. It has only ever
    held librarian, and it forces is_assigned and a score of 1.0, so it cannot be
    wrong quietly. E-H below.
    ============================================================================
*/

-- ----------------------------------------------------------------------------
-- E. HOW MANY RECORDS ARE ENDOWED CHAIRS. Replaces the eyeballed ~1,600.
-- ----------------------------------------------------------------------------
select
    case when regexp_contains(title, r'(?i)(chairholder|research chair|chaire de recherche|'
                                  || r'endowed chair|\bchair of\b|\bchair in\b|lehrstuhl|'
                                  || r'\bchair\b.{0,12}(tier|holder))')
         then 'the chair IS the professorship'
         else 'chair might mean a leadership post'
    end                     as reading,
    count(*)                as titles,
    sum(frequency)          as records
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
where title_group = 'teaching_academic'
  and is_assigned
  and regexp_contains(title, r'(?i)(chair|lehrstuhl)')
  and not regexp_contains(title, r'(?i)(\bhead\b|\bdean\b|decano|dekan)')
group by reading
order by records desc;

-- ----------------------------------------------------------------------------
-- F. WHAT A FACULTY-LEVEL PATTERN SET WOULD SWEEP, pattern by pattern, and
--    out of which group. The unintended sweep is the whole question: a pattern
--    takes EVERY title containing the phrase, not only professor compounds.
-- ----------------------------------------------------------------------------
with candidate_patterns as (
    select * from unnest([
        struct('head of department'   as p), struct('head of the department' as p),
        struct('head of school'       as p), struct('head of faculty'        as p),
        struct('head of institute'    as p), struct('head of division'       as p),
        struct('head of dept'         as p), struct(r'\bdean\b'              as p),
        struct('decano'               as p), struct('dekan'                  as p)
    ])
)

select
    cp.p                                        as pattern,
    d.title_group                               as leaves_from,
    count(*)                                    as titles,
    sum(d.frequency)                            as records,
    countif(not regexp_contains(d.title, r'(?i)(profes|\bprof\b|dozent|docent)')) as titles_with_no_professor_word,
    array_agg(d.title order by d.frequency desc limit 4)                          as biggest
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group` d
join candidate_patterns cp
    on regexp_contains(d.title, '(?i)' || cp.p)
where d.is_assigned
group by pattern, leaves_from
order by records desc;

-- ----------------------------------------------------------------------------
-- G. THE COLLISION CHECK. assert_title_patterns_do_not_collide fails the build
--    if two groups claim one title. Today only librarian has patterns, so this
--    has never fired. Anything this returns has to be resolved - by narrowing a
--    pattern or by a HUMAN override, which outranks PATTERN - BEFORE the seed
--    is changed, or the next build dies.
-- ----------------------------------------------------------------------------
with candidate_patterns as (
    select * from unnest([
        'head of department','head of the department','head of school','head of faculty',
        'head of institute','head of division','head of dept',r'\bdean\b','decano','dekan'
    ]) as p
)

select
    d.title,
    d.frequency,
    d.title_group       as current_group,
    d.decision_source,
    array_agg(lp.name_pattern) as librarian_patterns_also_matched
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group` d
join candidate_patterns cp on regexp_contains(d.title, '(?i)' || cp.p)
join `dat-analytics-eng-ec869189.dev_orcid_role_identifier_seeds.title_group_patterns` lp
    on regexp_contains(d.title, lp.name_pattern)
group by d.title, d.frequency, current_group, d.decision_source
order by d.frequency desc;

-- ----------------------------------------------------------------------------
-- H. DOES THE GAIN SURVIVE THE ORGANISATION. faculty_head needs the employer to
--    resolve to an academic organisation. ~14,600 records already carry a strong
--    leadership title and never confirm because it does not. If these people
--    fail the same way, the move buys nothing and should not be made - so this
--    is the query that decides it, not D.
--
--    A PROXY, AND SAID SO. int_employment_scored holds one row per person per
--    role - the most recent employment - and its evidence_title is the raw
--    string, not the normalised one that title_key is built from, so the
--    compound record cannot be joined to it directly. Reading the org score off
--    the person's most recent teaching row is close for this population, since
--    a stated headship is nearly always the current post, but it is not exact.
-- ----------------------------------------------------------------------------
with compound_titles as (
    select title_key
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
    where title_group = 'teaching_academic'
      and is_assigned
      and regexp_contains(title, r'(?i)(profes|\bprof\b|\bprof\.|dozent|docent)')
      and regexp_contains(title, r'(?i)(head of (the )?(department|dept|school|faculty|'
                               || r'institute|division)|\bdean\b|decano|dekan)')
),

holders as (
    select distinct snid
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_staging.stg_role_records`
    where title_key in (select title_key from compound_titles)
),

org as (
    select
        s.snid,
        max(s.org_score)    as best_org_score
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.int_employment_scored` s
    join holders h using (snid)
    where s.role_key = 'faculty_head'
      and s.title_group = 'teaching_academic'
    group by s.snid
)

select
    case
        when o.best_org_score is null then 'no faculty_head row at all'
        when o.best_org_score = 0     then 'organisation did not resolve - scores zero'
        when o.best_org_score < 0.5   then 'organisation resolved but weakly'
        else 'organisation resolved - would confirm'
    end                         as outcome,
    count(*)                    as people
from holders h
left join org o using (snid)
group by outcome
order by people desc;
