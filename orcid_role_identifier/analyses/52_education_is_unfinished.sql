/*
    ============================================================================
    52. STUDENTS FROM THE EDUCATION RECORD - "the education is not finished"
    ============================================================================
    Merve, 2026-11-12: "soyle students grubumuz su olsun. educations i daha
    bitmemis yani last date educationda girilmemis kisiler alinsin sadece."

    WHAT THIS CHANGES. Until now the students audience is decided by the
    EMPLOYMENT job title - a person writes `phd student` into an employment
    record and the embedding or a pattern puts them in the `student` title
    group. Merve's rule points at a different section of the ORCID profile
    entirely: educations[], and specifically whether its end date is empty.

    AND THAT SECTION HAS NEVER BEEN USED. raw_orcid_researchers pulls
    educations[] and filters it to PUBLIC records, and nothing downstream reads
    it - no staging model, no dictionary model, nothing. stg_orcid__employment
    has no twin. So this is not a config change like the Education-employer
    rule was; it needs a new staging model, and this file measures the ground
    before one is written.

    ⭐ DECIDED 2026-11-12, AND THE DECISION WAS TO REFUSE THE RULE. Merve,
    after reading queries 2 to 4: "bugunku kural kalsin. Education'i kapi
    olarak degil, elimizdeki kisileri dogrulamak icin kullaniriz." The
    audience keeps the rule it has - a student job title, a ROR Education
    employer, current posts only, 123,056 people - and the education record
    becomes a corroboration measure on the people we already deliver. That is
    query 10, and it is the only query in this file that is still live work.

    WHY IT WAS REFUSED, in one line each: of the 198,268 people with an open
    education record, 99,665 hold a record with NO DATES AT ALL and 29,846
    more started over ten years ago; 83% of all education records ARE closed,
    which proves people fill the field in when they finish; the strict reading
    would have cut the audience to 15,254 and the loose one would have traded
    107,802 certain people for 183,014 mostly undated ones. Full figures in
    docs/open-questions.md 2.16. Queries 1 to 9 are the record of that
    measurement and are kept because the rule will be proposed again.

    THE QUESTION THE INSTRUCTION COULD NOT ANSWER, which is what queries 3 and
    4 were for - it changed the audience by an order of magnitude, so both
    readings were measured rather than guessed:

      AND      a person is a student if they have a current student JOB TITLE
               *and* an open education record. Narrower and more certain than
               today. "alinsin sadece" - only these are taken - reads this way.
      INSTEAD  a person is a student if they have an open education record,
               whatever their job title says. This closes a real coverage gap,
               because most students never write a student employment record at
               all - their studenthood lives only in educations[]. "students
               grubumuz su olsun" - let the group BE this - reads this way.

    THE RISK THAT HAS TO BE MEASURED EITHER WAY. An empty end date in ORCID
    means "ongoing" OR "never filled in". A professor who recorded their own
    PhD in 1994 and left the end date blank is not a student. Query 2 is the
    whole of that risk in one table: if a large share of open education
    records started more than ten years ago, the signal is data hygiene rather
    than studenthood, and the rule needs a date floor to mean what Merve
    intends it to mean.

    AND ONE FINDING THAT OUTLIVES THE DECISION. The education route could not
    have been a config change in any case: int_employment_scored's grain is an
    EMPLOYMENT record, so a person with education evidence and no employment
    record has no row for a role to attach to and cannot enter any audience at
    all. Query 8 sizes that. Whoever proposes this rule next starts there.

    RUN ORDER: 1 has already run and its answer is recorded on it - educations[]
    matches employments[] in every field except that `role` is called `degree`.
    Query 10 is the live one and runs AFTER the students build. Queries 7, 8
    and 9 were written to decide a question that is now closed; they are worth
    running only to answer the next proposal, not this one.
*/


-- ----------------------------------------------------------------------------
-- 1. THE SCHEMA, FIRST AND ALONE.
--
--    educations[] is a STRUCT array that no model in this project has ever
--    read. Queries 2-5 assumed it carried the same field names as
--    employments[], because both are ORCID affiliation types. RUN 2026-11-12,
--    and the assumption was right in every field but one:
--
--      SAME   visibility, ordering, original_start_date, full_start_date,
--             original_end_date, full_end_date, department_name,
--             organisation_name, organisation_address_*,
--             disambiguated_organisation_id, disambiguated_organisation_source,
--             source STRUCT
--      ONE DIFFERENCE   employments[] has `role`; educations[] has `degree`.
--
--    full_start_date and full_end_date are real DATE columns, so the whole of
--    Merve's rule - an education record with no end date - is answerable from
--    this array exactly as written. Query 5 below was reading `role` and now
--    reads `degree`; it is the only query that changed.
--
--    Kept rather than deleted: it is the only record of the array's shape
--    anywhere in the project, and the next person to touch educations[] needs
--    it before they write a staging model.
-- ----------------------------------------------------------------------------
select column_name, data_type
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_raw.INFORMATION_SCHEMA.COLUMNS`
where table_name = 'raw_orcid_researchers'
  and column_name in ('educations', 'employments')
;


-- ----------------------------------------------------------------------------
-- 2. IS AN EMPTY END DATE EVIDENCE, OR IS IT JUST AN EMPTY FIELD?
--
--    THE QUESTION THIS FILE EXISTS TO ANSWER. ORCID does not distinguish
--    "ongoing" from "not filled in", so an open education record is only
--    evidence of studenthood if the education STARTED recently. This buckets
--    every open record by how long ago it began.
--
--    HOW TO READ IT. If most open records started within the last ten years,
--    the rule works as written and needs nothing. If a large share started in
--    the 1990s and 2000s, those are finished degrees with a blank field, the
--    rule would admit a generation of professors as students, and it needs a
--    start-date floor. Either way the number decides it, not an opinion about
--    ORCID data quality.
-- ----------------------------------------------------------------------------
with educations as (
    select
        r.snid,
        d.full_start_date   as start_date,
        d.full_end_date     as end_date
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_raw.raw_orcid_researchers` r,
    unnest(r.educations) d
)
select
    case
        when end_date is not null                       then '0 CLOSED - has an end date'
        when start_date is null                         then '1 OPEN, no start date either'
        when start_date >= date_sub(current_date(), interval 3 year)
                                                        then '2 OPEN, started within 3 years'
        when start_date >= date_sub(current_date(), interval 6 year)
                                                        then '3 OPEN, started 3-6 years ago'
        when start_date >= date_sub(current_date(), interval 10 year)
                                                        then '4 OPEN, started 6-10 years ago'
        when start_date >= date_sub(current_date(), interval 20 year)
                                                        then '5 OPEN, started 10-20 years ago'
        else                                                 '6 OPEN, started over 20 years ago'
    end                                                 as standing,
    count(*)                                            as education_records,
    count(distinct snid)                                as people
from educations
group by standing
order by standing
;


-- ----------------------------------------------------------------------------
-- 3. THE TWO READINGS OF THE INSTRUCTION, SIDE BY SIDE AND IN PEOPLE.
--
--    `title` is the audience as it stands today: a current employment record
--    whose title is in the student group, which is what analyses/51 measured
--    at 123,056 people before scoring.
--    `open_education` is Merve's new signal on its own.
--
--    The four cells are the whole decision. `title only` is what INSTEAD would
--    lose, `education only` is what AND would refuse and INSTEAD would gain,
--    and `both` is the audience the strict reading leaves.
-- ----------------------------------------------------------------------------
with by_title as (
    select distinct s.snid
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_staging.stg_role_records` s
    join `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group` t
         on s.title_key = t.title_key
        and t.is_assigned
        and (t.title_group = 'student' or t.title_group_2 = 'student')
    where s.is_current
),
by_education as (
    select distinct r.snid
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_raw.raw_orcid_researchers` r,
    unnest(r.educations) d
    where d.full_end_date is null
),
everyone as (
    select snid from by_title
    union distinct
    select snid from by_education
)
select
    case
        when t.snid is not null and e.snid is not null then '1 BOTH - the strict reading (AND)'
        when t.snid is not null                        then '2 title only - INSTEAD would lose these'
        else                                                '3 open education only - AND refuses, INSTEAD gains'
    end                                                 as cell,
    count(*)                                            as people
from everyone x
left join by_title     t using (snid)
left join by_education e using (snid)
group by cell
order by cell
;


-- ----------------------------------------------------------------------------
-- 4. AND THE SAME THING WITH A DATE FLOOR, so the choice is made against the
--    version of the rule that is actually defensible.
--
--    Query 2 says whether this is needed. If it is, the comparison that
--    matters is not "open education" but "open education that started
--    recently", and this runs the floor at three, six and ten years so the
--    cost of each is visible at once.
-- ----------------------------------------------------------------------------
with by_title as (
    select distinct s.snid
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_staging.stg_role_records` s
    join `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group` t
         on s.title_key = t.title_key
        and t.is_assigned
        and (t.title_group = 'student' or t.title_group_2 = 'student')
    where s.is_current
),
educations as (
    select r.snid, d.full_start_date as start_date
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_raw.raw_orcid_researchers` r,
    unnest(r.educations) d
    where d.full_end_date is null
),
floors as (
    select 'no floor'      as floor_name, snid from educations
    union all
    select '10 years', snid from educations
     where start_date >= date_sub(current_date(), interval 10 year)
    union all
    select '6 years',  snid from educations
     where start_date >= date_sub(current_date(), interval 6 year)
    union all
    select '3 years',  snid from educations
     where start_date >= date_sub(current_date(), interval 3 year)
)
select
    f.floor_name,
    count(distinct f.snid)                              as open_education_people,
    count(distinct if(t.snid is not null, f.snid, null)) as also_has_a_student_title,
    count(distinct if(t.snid is null,     f.snid, null)) as education_evidence_only
from floors f
left join by_title t on t.snid = f.snid
group by f.floor_name
order by open_education_people desc
;


-- ----------------------------------------------------------------------------
-- 5. WHAT THE EDUCATION RECORD ACTUALLY SAYS, for the people the title route
--    would never have found.
--
--    If INSTEAD or a widened AND is chosen, these are the new members, and
--    what an education record carries is `degree` - phd, msc, bachelor of
--    science - where an employment record carries `role`. CONFIRMED BY QUERY
--    1, which is also the reason this query changed: it was written against
--    `role` by analogy and that field does not exist here.
--
--    That difference is the thing worth knowing about this signal. A degree is
--    far more standardised than a job title - there are perhaps thirty real
--    spellings of a doctorate against the 327,291 title values the dictionary
--    holds - so this route may need no embedding at all, just a pattern list.
--    Read the output and see how long the tail really is.
-- ----------------------------------------------------------------------------
with by_title as (
    select distinct s.snid
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_staging.stg_role_records` s
    join `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group` t
         on s.title_key = t.title_key
        and t.is_assigned
        and (t.title_group = 'student' or t.title_group_2 = 'student')
    where s.is_current
)
select
    lower(d.degree)                                     as education_degree,
    count(*)                                            as records,
    count(distinct r.snid)                              as people
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_raw.raw_orcid_researchers` r,
unnest(r.educations) d
left join by_title t on t.snid = r.snid
where d.full_end_date is null
  and d.full_start_date >= date_sub(current_date(), interval 6 year)
  and t.snid is null
group by education_degree
order by records desc
limit 40
;


-- ----------------------------------------------------------------------------
-- 6. A SEPARATE BUG, FOUND BY THE SAME READING AND NOT ABOUT STUDENTS AT ALL.
--
--    analyses/51 query 1d returned `education`, `healthcare`, `facility` in
--    LOWERCASE. That is how ror_types comes out of ROR, and two seeds are
--    joined against it in different ways:
--
--      org_type_scores   int_employment_scored joins it with
--                        upper(trim(s.org_type)) = upper(trim(t))
--                        - CASE SAFE, and every org score has always worked
--      role_detail_map   int_role_detail joins it with
--                        coalesce(s.org_type,'UNKNOWN') = m.match_value
--                        - AN EXACT MATCH, against seed rows that spell it
--                        'Education', 'Healthcare', 'Company'
--
--    If that is right, then no org_type detail label has ever matched - not
--    for students, and not for researcher, lecturer, faculty_head or any of
--    the hcp roles - and role_detailed_inferred has been falling back to
--    something for every one of them. The UNKNOWN row cannot rescue it
--    either, because org_type is coalesced to 'UNKNOWN' upstream and no role
--    has an UNKNOWN row in role_detail_map.
--
--    THIS QUERY DECIDES IT RATHER THAN ARGUING IT. It is the one thing in
--    this file that is not about the students audience, and it is here
--    because the same result surfaced it.
-- ----------------------------------------------------------------------------
select
    d.role_key,
    d.match_value                                       as seed_spelling,
    count(distinct s.org_type)                          as distinct_live_values,
    string_agg(distinct s.org_type order by s.org_type limit 5) as live_spellings,
    countif(s.org_type = d.match_value)                 as rows_that_match_exactly,
    countif(upper(s.org_type) = upper(d.match_value))   as rows_that_would_match_ignoring_case
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.int_employment_scored` s
join `dat-analytics-eng-ec869189.dev_orcid_role_identifier_seeds.role_detail_map` d
     on d.role_key = s.role_key
    and d.match_type = 'org_type'
    and upper(s.org_type) = upper(d.match_value)
group by d.role_key, d.match_value
order by rows_that_would_match_ignoring_case desc
limit 30
;


-- ----------------------------------------------------------------------------
-- 7. THE HOLE IN THE RULE AS WRITTEN: AN END DATE IN THE FUTURE.
--
--    Merve's rule is "last date educationda girilmemis" - no end date entered.
--    But a doctoral student who typed 2022-2026 HAS entered an end date and is
--    still unfinished, and ORCID asks for an expected end date, so people fill
--    it in. The strict reading refuses every one of them.
--
--    Queries 2 to 4 only ever looked at `full_end_date is null`, so this group
--    has not been counted at all. If it is large, "unfinished" means
--    `end_date is null or end_date > today`, which is a different rule from
--    the one on the table and a better statement of what it was for.
--
--    THE BUCKETS ARE ASYMMETRIC ON PURPOSE. An end date in the future is a
--    claim about the future and so cannot be a stale leftover - which is
--    exactly what makes it stronger evidence than a blank field, and the
--    reason this query exists.
-- ----------------------------------------------------------------------------
with ed as (
    select
        r.snid,
        d.full_end_date                                 as end_date,
        d.full_start_date                               as start_date
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_raw.raw_orcid_researchers` r,
    unnest(r.educations) d
),
bucketed as (
    select
        case
            when end_date is null                     then '1 BLANK - the rule as written'
            when end_date >  current_date()           then '2 FUTURE - unfinished and dated'
            when end_date >= date_sub(current_date(), interval 1 year)
                                                      then '3 ended within the last year'
            else                                           '4 ended over a year ago'
        end                                             as standing,
        snid,
        start_date
    from ed
)
select
    standing,
    count(*)                                            as education_records,
    count(distinct snid)                                as people,
    count(distinct if(start_date is null, snid, null))  as people_with_no_start_date_either
from bucketed
group by standing
order by standing
;


-- ----------------------------------------------------------------------------
-- 8. ⭐ WHO THE 183,014 ACTUALLY ARE - the query that decides this.
--
--    Query 3 says an open education record would add 183,014 people the title
--    route never finds. It does not say whether they are students. Two things
--    have to be true for one of them to be a student we can deliver, and this
--    query tests both at once.
--
--    FIRST, AND IT IS A MECHANISM PROBLEM, NOT A SCORING ONE. The audience is
--    built on int_employment_scored, whose grain is an EMPLOYMENT record. A
--    person with an education record and no employment record cannot enter any
--    audience at all, however strong the evidence - there is no row to attach
--    the role to. If that bucket is large, the education route needs a new
--    model that emits rows for education records, not a config change, and the
--    size of this bucket is the size of that work.
--
--    SECOND, WHAT THEIR CURRENT JOB SAYS. A person whose current employment
--    reads `professor` and who also recorded an open PhD is the stale-record
--    risk in person, and every one of them would be delivered as a student by
--    the INSTEAD reading. A person with no title group at all, or an
--    uninformative one, is the honest gap this route exists to close.
--
--    A person can hold several groups, so the group rows sum to more than the
--    people total. The two "no" buckets are disjoint from them and from each
--    other.
-- ----------------------------------------------------------------------------
with by_title as (
    select distinct s.snid
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_staging.stg_role_records` s
    join `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group` t
         on s.title_key = t.title_key
        and t.is_assigned
        and (t.title_group = 'student' or t.title_group_2 = 'student')
    where s.is_current
),
education_only as (
    select distinct r.snid
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_raw.raw_orcid_researchers` r,
    unnest(r.educations) d
    left join by_title t on t.snid = r.snid
    where d.full_end_date is null
      and t.snid is null
),
current_jobs as (
    select
        e.snid,
        t.title_group,
        t.is_assigned
    from education_only e
    join `dat-analytics-eng-ec869189.dev_orcid_role_identifier_staging.stg_role_records` s
         on s.snid = e.snid
        and s.is_current
    left join `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group` t
         on s.title_key = t.title_key
),
buckets as (

    select
        '0 NO CURRENT EMPLOYMENT RECORD - cannot be delivered at all' as bucket,
        e.snid
    from education_only e
    left join (select distinct snid from current_jobs) c using (snid)
    where c.snid is null

    union all

    select '1 has a job, but no title group was assigned to it', snid
    from current_jobs
    where title_group is null or not is_assigned

    union all

    select '2 current job group: ' || title_group, snid
    from current_jobs
    where is_assigned

)
select
    bucket,
    count(distinct snid)                                as people
from buckets
group by bucket
order by bucket
;


-- ----------------------------------------------------------------------------
-- 9. AND THE ORG RULE, APPLIED TO THE EDUCATION RECORD'S OWN INSTITUTION.
--
--    Merve, 2026-11-12: "organizasyon bilgisi cozulmeyenler ogrenci olarak
--    atanmasin. egitim kurumunda olmalari sart." That rule is currently
--    enforced against the EMPLOYER, through org_type_scores. On the education
--    route the institution is in the education record itself, which is a
--    better place to ask it from - an education record names where somebody
--    studied by definition.
--
--    So this prices the same rule on the new evidence. ROR id and source come
--    straight off the education struct, and the join is to stg_ror__organisations
--    by ror_id rather than through int_org_resolved, because int_org_resolved
--    is keyed on the NORMALISED employment organisation name and an education
--    record's organisation_name has never been through that normalisation.
--
--    ⭐ ror_types VALUES ARE LOWERCASE - `education`, `healthcare`, `facility`.
--    analyses/51 query 1d compared against 'Education' and printed all 106,050
--    qualifying people as REFUSED. upper() on both sides, every time.
-- ----------------------------------------------------------------------------
with ed as (
    select
        r.snid,
        d.disambiguated_organisation_id                 as ror_id_raw,
        upper(d.disambiguated_organisation_source)      as id_source,
        d.full_start_date                               as start_date
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_raw.raw_orcid_researchers` r,
    unnest(r.educations) d
    where d.full_end_date is null
),
typed as (
    select
        e.*,
        case
            when e.id_source != 'ROR' or e.ror_id_raw is null then 'UNRESOLVED'
            else coalesce(upper(o.ror_types[safe_offset(0)]), 'UNRESOLVED')
        end                                             as org_type
    from ed e
    left join `dat-analytics-eng-ec869189.dev_orcid_role_identifier_staging.stg_ror__organisations` o
           on o.ror_id = e.ror_id_raw
          and e.id_source = 'ROR'
)
select
    org_type,
    if(org_type = 'EDUCATION', 'QUALIFIES', 'refused by the org rule')
                                                        as verdict,
    count(*)                                            as education_records,
    count(distinct snid)                                as people,
    count(distinct if(start_date >= date_sub(current_date(), interval 6 year),
                      snid, null))                      as people_within_6_years
from typed
group by org_type
order by people desc
;


-- ----------------------------------------------------------------------------
-- 10. ⭐ THE DECIDED USE OF THE SIGNAL: A CORROBORATION MEASURE, NOT A GATE.
--
--     Merve, 2026-11-12, after queries 2 to 4: "bugunku kural kalsin.
--     Education'i kapi olarak degil, elimizdeki kisileri dogrulamak icin
--     kullaniriz." The audience keeps its own rule - a student title, a ROR
--     Education employer, current posts only - and the education record
--     becomes an accuracy figure on the people we already deliver.
--
--     THE BASELINE IS THE WHOLE QUERY. "68% of our students also hold an open
--     education record" means nothing on its own, because a professor who
--     recorded their own PhD and left the end date blank has one too. So
--     Lecturer and Researcher are measured beside Students on the identical
--     definition, and only the DIFFERENCE between the rows is evidence. If
--     Students does not separate from them, the signal is measuring ORCID
--     form-filling habits rather than studenthood, and we say so.
--
--     THREE READINGS OF "UNFINISHED", side by side, because query 2 showed the
--     first one is mostly stale and query 7 exists to size the second:
--
--       open_or_future     end date blank OR in the future - the widest
--       future_dated       an end date that has not arrived yet. The strongest
--                          of the three: a claim about the future cannot be a
--                          leftover from a degree finished in 1994.
--       unfinished_recent  blank-or-future AND started within six years
--
--     RUN AFTER THE BUILD. fct_researcher_roles has no students rows until
--     `dbt build --select org_type_scores+ role_detail_map+ int_employment_scored+`
--     has run. Run it on the other two roles first if you want the baseline
--     early - they are already built and their figures will not move.
-- ----------------------------------------------------------------------------
with ed as (
    select
        r.snid,
        logical_or(d.full_end_date is null
                   or d.full_end_date > current_date())  as open_or_future,
        logical_or(d.full_end_date > current_date())     as future_dated,
        logical_or((d.full_end_date is null
                    or d.full_end_date > current_date())
                   and d.full_start_date
                       >= date_sub(current_date(), interval 6 year))
                                                         as unfinished_recent
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_raw.raw_orcid_researchers` r,
    unnest(r.educations) d
    group by r.snid
),
/*  fct_researcher_roles is unique on (snid, role_key), so countif over these
    rows is already a people count - no distinct needed, and using one would
    hide a grain change rather than survive it.  */
delivered as (
    select f.snid, f.role_key
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles` f
    where f.role_label = 'CONFIRMED'
      and f.role_key in ('students', 'lecturer', 'researcher')
)
select
    v.role_key,
    count(*)                                            as confirmed_people,
    countif(e.snid is null)                             as no_education_record_at_all,
    round(100 * countif(e.open_or_future)    / count(*), 1) as pct_open_or_future,
    round(100 * countif(e.future_dated)      / count(*), 1) as pct_future_dated,
    round(100 * countif(e.unfinished_recent) / count(*), 1) as pct_unfinished_recent
from delivered v
left join ed e using (snid)
group by v.role_key
order by pct_future_dated desc
;
