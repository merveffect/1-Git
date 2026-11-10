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

/*
    ============================================================================
    E-H CAME BACK 2026-10-30, AND THEY CHANGED THE ANSWER.
    ============================================================================
    E   ENDOWED CHAIRS ARE 8,889 RECORDS, not the ~1,600 the visible rows
        suggested - 335 titles against 738 whose chair might still mean a post.
        (E drops the professor-word requirement that bucket A applied, so its
        1,073 titles are a wider set than A's 968. Not a contradiction, but the
        two are not directly comparable.)

    F   THE PATTERN WOULD SWEEP ~14,500 RECORDS OUT OF EIGHT GROUPS IT HAS NO
        BUSINESS TOUCHING. This is the finding that matters.

            practitioner              2,353 records   head of department of cardiology
            researcher_early          5,217           associate dean research
            researcher_established    3,389           principal researcher - head of department
            pharmacist                1,990           cluster pharmacy manager & head of department
            support_technical         1,023
            student                     396           sub-dean graduate studies
            trainee_clinical             91           dean s clinical research fellow
            librarian                    14

        Against a gain of ~49,100 records out of teaching_academic. And the
        reason is structural, not a matter of tuning the regex:

        **`head of X` and `dean` are MODIFIERS, not professions.** They attach
        to any job. A pattern matching them overrides the profession word in the
        same string, so `head of department of cardiology` stops being a
        clinician and `cluster pharmacy manager & head of department` stops
        being a pharmacist. Pharmacist is 74,951 records in total, so that is
        2.7% of the entire group, and practitioner is the least-covered audience
        we have.

        A pattern forces is_assigned and a score of 1.0 and can only be undone
        one title at a time, so repairing 14,500 records would take hundreds of
        HUMAN exclusions - worse than the override route it was meant to replace.

        THIS IS 1.10a RESTATED WITH NUMBERS. The decision that one title names
        one profession is what makes the profession word the one that has to
        win. Leadership is an attribute of a job, not the job.

    G   THE COLLISION RISK IS THREE TITLES, 14 RECORDS - all librarian, all
        decided by the librarian pattern today:
            associate dean of library services                      5
            associate dean library services and archives            5
            head of department of library and information science    4

    H   WAS A DUD, AND THE FAULT IS IN THE QUERY. It returned "no faculty_head
        row at all" for all 1,667 people, which is not a finding about
        organisations. int_employment_scored only emits a row for a role when
        the title group qualifies for it, so a teaching_academic person has no
        faculty_head row by construction. J below asks it properly.

    SO THE DESIGN THAT SURVIVES IS A PATTERN THAT APPLIES WITHIN ONE GROUP.
    If a pattern row can say "only when the model already put this title in
    teaching_academic", then:
      - the 14,500-record sweep disappears by construction - practitioner,
        pharmacist and the researcher groups are never consulted;
      - the three librarian collisions disappear too, for the same reason;
      - the word-order split in 1.10a still closes, because the pattern matches
        every separator;
      - and the profession word still wins, which is what 1.10a decided.

    That is one nullable column on seeds/title_group_patterns and one condition
    in the join in dim_title_group. Librarian rows leave it empty and keep
    working unconditionally.
    ============================================================================
*/

-- ----------------------------------------------------------------------------
-- I. THE EXCLUSION LIST. Titles the conditional pattern would move, where the
--    leadership reading is wrong anyway. Two shapes, both already sighted:
--
--    THE POSSESSIVE. `dean s chair`, `dean s clinical research fellow`,
--    `dean s research assistant` - an award or a post NAMED AFTER the dean, not
--    a deanship. Fourth sighting of the family that gave us `member`, `fellow`
--    and `associate`: a word that only means something in company.
--
--    THE PAST POST. `dean of the sport sciences faculty 2010-2020`, `dean
--    2010-2018 adjunct professor 2008-`. The audience counts current posts, and
--    a title carrying its own end date is not one.
-- ----------------------------------------------------------------------------
select
    case
        when regexp_contains(title, r"(?i)dean\s?('|\bs\b)") then 'POSSESSIVE - named after a dean'
        when regexp_contains(title, r'(19|20)\d{2}')           then 'PAST POST - carries its own dates'
        else 'other'
    end                     as why_excluded,
    count(*)                as titles,
    sum(frequency)          as records,
    array_agg(title order by frequency desc limit 12) as examples
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
where title_group = 'teaching_academic'
  and is_assigned
  and regexp_contains(title, r'(?i)(head of (the )?(department|dept|school|faculty|'
                           || r'institute|division)|\bdean\b|decano|dekan)')
  and (regexp_contains(title, r"(?i)dean\s?('|\bs\b)")
    or regexp_contains(title, r'(19|20)\d{2}'))
group by why_excluded
order by records desc;

-- ----------------------------------------------------------------------------
-- J. DOES THE GAIN SURVIVE THE ORGANISATION - asked properly this time.
--
--    faculty_head scores the employer by its ROR type, and on 29 October
--    Healthcare, Company, Funder, Other and UNKNOWN were all set to 0.00, which
--    means they can never confirm. So read the org type off the person's
--    existing teaching row - which does exist - and price it against the
--    faculty_head column of org_type_scores.
-- ----------------------------------------------------------------------------
with compound_titles as (
    select title_key
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
    where title_group = 'teaching_academic'
      and is_assigned
      and regexp_contains(title, r'(?i)(head of (the )?(department|dept|school|faculty|'
                               || r'institute|division)|\bdean\b|decano|dekan)')
),

holders as (
    select distinct snid
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_staging.stg_role_records`
    where title_key in (select title_key from compound_titles)
),

their_org as (
    select
        s.snid,
        s.org_type,
        s.org_resolution_method
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.int_employment_scored` s
    join holders h using (snid)
    where s.role_key = 'lecturer'
      and s.title_group = 'teaching_academic'
)

select
    coalesce(o.org_type, 'no teaching row found')   as org_type,
    coalesce(fh.org_score, -1)                      as faculty_head_org_score,
    count(*)                                        as people,
    case
        when fh.org_score is null   then 'unknown - needs looking at'
        when fh.org_score = 0.0     then 'CANNOT confirm - this org type scores zero'
        when fh.org_score >= 0.6    then 'would confirm'
        else 'marginal'
    end                                             as verdict
from holders h
left join their_org o using (snid)
left join `dat-analytics-eng-ec869189.dev_orcid_role_identifier_seeds.org_type_scores` fh
    on fh.org_type = o.org_type
   and fh.role_key = 'faculty_head'
group by org_type, faculty_head_org_score, verdict
order by people desc;

/*
    ============================================================================
    I AND J CAME BACK 2026-10-30. THE ORGANISATION DOES NOT KILL IT.
    ============================================================================
    J's join was case-sensitive and the model's is not - int_employment_scored
    carries `education` and org_type_scores carries `Education`, and the model
    compares them with upper(trim()) on both sides. So the -1.0s are my query's
    fault, not a defect. Priced off the seed by hand:

        education     1.00   1,690 people   71.5%   WOULD CONFIRM
        UNKNOWN       0.00     623          26.4%   cannot - no ROR match
        funder        0.00      20                  cannot
        facility      0.60      12                  would confirm
        healthcare    0.00       9                  cannot - 29 Oct decision
        other         0.00       4                  cannot
        government    0.30       3                  marginal
        nonprofit     0.40       2                  marginal
        company       0.00       1                  cannot
                                ----
                               2,364

    1,702 of 2,364 clear the organisation. **72%.** The thing that strands
    14,600 strong leadership records does NOT strand these, because a professor
    who also heads a department is at a university by definition and the ROR
    resolves.

    AND THE NUMBERS BEFORE THIS ONE WERE ON A WIDER SCOPE. C and D used the
    broad regex, which allowed a bare `head` - 3,683 holders, +3,376, -1,739.
    This population is the narrowed one and does not require a professor word
    either, so 2,364 is the honest denominator and K below gives the honest
    trade. The +19% should be read as superseded.

    I: THE EXCLUSIONS ARE 37 TITLES, 927 RECORDS. Small enough to review one by
    one, which is just as well, because the date rule does not work:

        dean of the sport sciences faculty 2010-2020 professor   ENDED
        associate professor assistant dean academic affairs 2020-2023   ENDED
        professor of social work and co-head of department 2020-23      ENDED
        professor molecular pharmacology dean 2014-              STILL CURRENT
        professor assistant head of department 2017-             STILL CURRENT
        head of department 1997-pres professor 1996-1997 ...     STILL CURRENT

    A closed year range means the post ended; an open one means it continues;
    and the last example carries both, with the headship on the open side. So
    carrying a date is a prompt to read the title, not a rule. 11 possessive
    titles (`dean s chair associate professor`, `college of science dean s
    distinguished professor`) are unambiguous and all 11 are exclusions.
    ============================================================================
*/

-- ----------------------------------------------------------------------------
-- K. THE FINAL TRADE, ON THE EXACT SCOPE THAT WOULD SHIP. Narrowed leadership
--    words, teaching_academic only, the 11 possessives excluded. This is the
--    number that goes in the document, and it supersedes C and D.
-- ----------------------------------------------------------------------------
with scope as (
    select title_key, title, frequency
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
    where title_group = 'teaching_academic'
      and is_assigned
      and regexp_contains(title, r'(?i)(head of (the )?(department|dept|school|faculty|'
                               || r'institute|division)|\bdean\b|decano|dekan)')
      and not regexp_contains(title, r"(?i)dean\s?('|\bs\b)")
),

other_teaching as (
    select title_key
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
    where title_group = 'teaching_academic'
      and is_assigned
      and title_key not in (select title_key from scope)
),

people as (
    select
        r.snid,
        countif(r.title_key in (select title_key from other_teaching)) as other_teaching_records
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_staging.stg_role_records` r
    where r.snid in (
        select snid
        from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_staging.stg_role_records`
        where title_key in (select title_key from scope)
    )
    group by r.snid
),

org as (
    select snid, max(org_type) as org_type
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.int_employment_scored`
    where role_key = 'lecturer' and title_group = 'teaching_academic'
    group by snid
),

already as (
    select distinct snid
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_presentation.fct_role_audience`
    where role_key = 'faculty_head'
)

select
    (select count(*)     from scope)                                as titles_in_scope,
    (select sum(frequency) from scope)                              as records_in_scope,
    count(*)                                                        as holders,
    countif(p.other_teaching_records > 0)                           as stays_in_lecturer,
    countif(p.other_teaching_records = 0)                           as leaves_lecturer,
    countif(a.snid is not null)                                     as already_in_faculty_head,
    countif(a.snid is null
            and upper(coalesce(o.org_type, 'UNKNOWN'))
                in ('EDUCATION', 'FACILITY'))                       as new_and_would_confirm,
    countif(a.snid is null
            and upper(coalesce(o.org_type, 'UNKNOWN')) = 'UNKNOWN')  as new_but_org_unresolved
from people p
left join org o     using (snid)
left join already a using (snid);

/*
    ============================================================================
    K CAME BACK 2026-10-30 AND THE CHANGE WENT IN. THE FINAL NUMBERS.
    ============================================================================
        titles in scope           1,706
        records in scope         48,995
        holders                   2,354
          stays in Lecturer       1,328   holds another teaching title
          LEAVES Lecturer         1,026   this was their only one
          already in faculty_head   280
          NEW and would confirm   1,498
          new, org unresolved       543   no ROR match, so cannot confirm

        faculty_head   17,528 -> 19,026    +8.5%
        lecturer      399,884 -> 398,858   -0.26%

    So the earlier +19% was on the wider regex and is superseded. The honest
    figure is +8.5%, and the cost is 1,026 people who leave Lecturer.

    WHY THE TRADE IS DEFENSIBLE, AND IT IS NOT THAT faculty_head IS SMALL.
    Under the one-title-one-profession rule something has to be dropped from
    `professor and head of department`, and the two readings are not equal:
    heading a department at a university ENTAILS being an academic there, while
    being a professor entails nothing about leading anything. The leadership
    reading keeps both facts; the teaching reading throws one away. That is an
    argument about what the title says, which is the only admissible kind.

    WHAT SHIPPED
        10 scoped patterns in title_group_patterns, all teaching_academic only
        10 HUMAN exclusions for the possessives (`dean s chair ...`)
         1 HUMAN correction where query I's regex flagged a REAL deanship -
           `... vice dean/ acting dean/ dean s advisor` goes to leadership
         3 HUMAN decisions on the collision titles, all to librarian
           and assert_title_patterns_do_not_collide now skips HUMAN titles,
           because min() never surfaces where a reviewer has decided

    THE KNOWN RESIDUAL: 26 titles / 604 records carry their own dates, and a
    date is not a rule - `dean 2010-2018` ended, `dean 2014-` and `head of
    department 1997-pres` have not. 12 were visible in query I; L lists all 26
    for a follow-up pass. At most 604 records of 48,995, so 1.2%, and the
    employment record's own end_date already catches the ones who filled it in.
    ============================================================================
*/

-- ----------------------------------------------------------------------------
-- L. THE DATE-CARRYING TITLES, ALL OF THEM. The follow-up pass. A closed range
--    means the post ended and the title belongs back in teaching; an open one
--    means it continues and the pattern is right. Read them, do not regex them.
-- ----------------------------------------------------------------------------
select
    title,
    frequency,
    title_group,
    decision_source,
    regexp_contains(title, r'(19|20)\d{2}\s*[-–]\s*(19|20)?\d{2}') as has_a_closed_range,
    regexp_contains(title, r'(19|20)\d{2}\s*[-–]\s*($|[a-z])')      as has_an_open_range
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
where is_assigned
  and regexp_contains(title, r'(?i)(head of (the )?(department|dept|school|faculty|'
                           || r'institute|division)|\bdean\b|decano|dekan)')
  and regexp_contains(title, r'(19|20)\d{2}')
order by frequency desc;

/*
    ============================================================================
    WILL IT WORK? WHAT IS CERTAIN AND WHAT IS NOT.
    ============================================================================
    CERTAIN, because it was measured on the current build:
      - the 1,706 titles and 48,995 records the patterns claim. The patterns are
        matched against the normalised title, which is the same string query K
        counted, so the match set is identical.
      - 1,498 new confirmable people and 1,026 leaving Lecturer.
      - the collision risk is three titles and all three now carry a HUMAN
        decision, and query G showed there are no others - it listed every title
        matching both pattern sets, not a sample.

    NOT CERTAIN until the build, and both are small:

    1. A TITLE THAT IS teaching_academic BY HUMAN OVERRIDE will not be claimed,
       because the scope reads the MODEL's group and an override outranks a
       pattern anyway. teaching_academic has 26 human decisions in total and
       none of them is a head or dean compound, so this should be zero - but it
       would show up as slightly fewer than 1,706 titles moving.

    2. THE FOUR SMALLEST PATTERNS COULD FAIL assert_title_patterns_all_match_
       something. `dekan` has 2 teaching titles, `head of dept` 4, `decano` 4,
       `head of faculty` 6 - counted on the RESOLVED group. If one of those few
       is teaching by override rather than by the model, that pattern matches
       nothing and the assertion fails the build by design. The fix is one word:
       put [pre-emptive] in its note, which the test honours.

    ALREADY FIXED RATHER THAN LEFT TO THE BUILD: the scope requires the model to
    have ASSIGNED the group, not merely to have been nearest to it. Without that
    a title sitting below sim_floor with teaching_academic as its nearest group
    would have been promoted to leadership with a score of 1.0 - rescuing the
    values the floor exists to hold back, and making the shipped behaviour
    differ from what K measured. M below sizes what that would have been.
    ============================================================================
*/

-- ----------------------------------------------------------------------------
-- M. WHAT THE ASSIGNED-ONLY CONDITION HOLDS BACK. Should return nothing that
--    looks like a faculty head. If it returns something that obviously IS one,
--    the condition is costing us real people and is worth revisiting - but on
--    evidence, not on the shape of the argument.
-- ----------------------------------------------------------------------------
select
    title,
    frequency,
    round(similarity, 3)    as similarity,
    title_group             as nearest_group,
    decision_source,
    matched_anchors
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
where not is_assigned
  and title_group = 'teaching_academic'
  and regexp_contains(title, r'(?i)(head of (the )?(department|dept|school|faculty|'
                           || r'institute|division)|\bdean\b|decano|dekan)')
order by frequency desc
limit 60;
