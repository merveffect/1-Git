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

    THERE IS ONE QUESTION I CANNOT ANSWER FROM THE INSTRUCTION, and it changes
    the audience by an order of magnitude, so queries 3 and 4 measure both
    readings rather than guessing:

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

    RUN ORDER: 1 first and on its own - it prints the schema, and queries 2 to
    5 assume field names that only query 1 can confirm.
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
