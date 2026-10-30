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
