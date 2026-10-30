/*
    ============================================================================
    29. THE FIRST EXTERNAL CHECK: OUR ANSWER vs WHAT THE PERSON SAID
    ============================================================================
    Written 2026-10-30. Market Intelligence exported two surveys in which people
    selected their own job title from a fixed list and gave an email address:

        Researcher Panel            232,648 rows   opt-in 2022-06 to 2026-10
        Journal Author Satisfaction 109,396 rows   survey 2024-04 to 2026-10

    Combined and deduplicated to the most recent answer per address:
    290,045 unique emails, of which 93.2% map onto one of our ten title groups.
    The mapping is in the uploaded file's `survey_group` column and is
    reviewable - it was built from the values actually observed, not from the
    option list we were told about, because the two differ.

    ------------------------------------------------------------------------
    READ THIS BEFORE READING ANY NUMBER THIS QUERY PRODUCES
    ------------------------------------------------------------------------
    34,372 people appear in BOTH surveys, so they declared their own job twice.
    They agree with THEMSELVES 88.9% of the time (28,866 of 32,479 comparable),
    and give word-for-word the same answer only 60.6% of the time.

        ** 88.9% IS THE CEILING. **

    An agreement rate of 85% against this source is therefore close to the best
    obtainable, not a poor result. Anything near 89% would be suspicious.

    The disagreements between the two surveys show why, and they are all real
    rather than noise:
        627  professor in one, research scientist in the other
        523  professor in one, editor in the other
        288  head of department in one, professor in the other
        180  student in one, academic in the other   (time: people move on)

    So this measures AGREEMENT WITH SELF-DECLARATION. It is not an accuracy
    rate, there is still no ground truth, and self-declaration is a second
    opinion rather than a fact. It is simply the first opinion from outside
    this project that we have ever been able to compare against.

    ------------------------------------------------------------------------
    THE UPLOADED TABLE is dev_orcid_role_identifier_raw.survey_self_declared_roles,
    loaded 2026-10-30 from survey_self_declared_roles.csv. Columns: email,
    survey_date, source, survey_role_raw, survey_group, map_status. The builder
    is setup/survey_role_mapping.py.
    ------------------------------------------------------------------------

    WHY THE JOIN GOES THROUGH stg_role_records RATHER THAN THE AUDIENCE TABLES.
    A person whose only job title is `phd student` produces NO role at all, so
    they are absent from fct_researcher_roles and from fct_role_audience. Going
    through the staging layer gives every person's full set of title groups,
    which is the only way to check the student and support groups - and student
    is about to become an audience with 0% of it ever read.
*/

with survey as (
    -- uploaded 2026-10-30 from survey_self_declared_roles.csv
    select lower(trim(email)) as email, survey_group, survey_role_raw,
           survey_date, source, map_status
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_raw.survey_self_declared_roles`
),

cdp as (
    select snid, lower(trim(email)) as email
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_raw.raw_audience_builder_big`
    where email is not null and email != ''
),

ours as (
    -- every title group a person carries, whether or not it produced a role
    select distinct r.snid, d.title_group
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_staging.stg_role_records` r
    join `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group` d
         using (title_key)
    where d.is_assigned
),

matched as (
    select
        s.email, s.survey_group, s.survey_role_raw, s.map_status,
        c.snid,
        array_agg(distinct o.title_group ignore nulls) as our_groups
    from survey s
    join cdp c using (email)
    left join ours o on o.snid = c.snid
    group by s.email, s.survey_group, s.survey_role_raw, s.map_status, c.snid
)

-- ============================ Q1. how far does the overlap reach? ==========
select 'survey people'                                as step, count(*) as people
from survey
union all
select 'matched to a person in the CDP', count(*) from matched
union all
select 'of those, we assigned at least one group',
       countif(array_length(our_groups) > 0) from matched
union all
select 'comparable (their answer maps to one of our ten)',
       countif(map_status = 'mapped' and array_length(our_groups) > 0) from matched
order by people desc;


/* ===========================================================================
   Q2.  THE HEADLINE. Is what they said about themselves among what we found?
   --------------------------------------------------------------------------
   Compare against 88.9%, not against 100%.
   =========================================================================== */
with survey as (
    select lower(trim(email)) as email, survey_group, map_status
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_raw.survey_self_declared_roles`
),
cdp as (
    select snid, lower(trim(email)) as email
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_raw.raw_audience_builder_big`
    where email is not null and email != ''
),
ours as (
    select distinct r.snid, d.title_group
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_staging.stg_role_records` r
    join `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group` d
         using (title_key)
    where d.is_assigned
),
cmp as (
    select s.survey_group,
           logical_or(o.title_group = s.survey_group) as we_found_it
    from survey s
    join cdp c using (email)
    join ours o on o.snid = c.snid
    where s.map_status = 'mapped'
    group by s.email, s.survey_group
)
select
    survey_group                                           as they_said,
    count(*)                                               as people,
    countif(we_found_it)                                   as we_agree,
    round(countif(we_found_it) / count(*), 3)              as agreement
from cmp
group by survey_group
union all
select '** ALL **', count(*), countif(we_found_it),
       round(countif(we_found_it) / count(*), 3)
from cmp
order by people desc;


/* ===========================================================================
   Q3.  WHERE WE DISAGREE, WHAT DID WE SAY INSTEAD?
   --------------------------------------------------------------------------
   Only rows where we did NOT find their own answer among our groups. The
   `we_said` column is what we gave them instead.
   =========================================================================== */
with survey as (
    select lower(trim(email)) as email, survey_group, map_status
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_raw.survey_self_declared_roles`
),
cdp as (
    select snid, lower(trim(email)) as email
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_raw.raw_audience_builder_big`
    where email is not null and email != ''
),
ours as (
    select distinct r.snid, d.title_group
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_staging.stg_role_records` r
    join `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group` d
         using (title_key)
    where d.is_assigned
),
disagreed as (
    select s.email, s.survey_group
    from survey s
    join cdp c using (email)
    join ours o on o.snid = c.snid
    where s.map_status = 'mapped'
    group by s.email, s.survey_group
    having logical_or(o.title_group = s.survey_group) = false
)
select
    d.survey_group        as they_said,
    o.title_group         as we_said,
    count(distinct d.email) as people
from disagreed d
join cdp c using (email)
join ours o on o.snid = c.snid
group by they_said, we_said
having people >= 50
order by people desc
limit 60;


/* ===========================================================================
   Q4.  THE RETIREMENT TEST - a free check on the decision of 16 October
   --------------------------------------------------------------------------
   299 people selected "Retired / Not currently working". Our rule says a
   retirement title should leave somebody unassigned. These people should
   therefore carry NO title group at all. Any that do are the residue measured
   in limitation 2.9, seen from outside for the first time.
   =========================================================================== */
with survey as (
    select lower(trim(email)) as email, survey_role_raw
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_raw.survey_self_declared_roles`
    where map_status = 'should_be_unassigned'
),
cdp as (
    select snid, lower(trim(email)) as email
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_raw.raw_audience_builder_big`
    where email is not null and email != ''
),
ours as (
    select distinct r.snid, d.title_group
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_staging.stg_role_records` r
    join `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group` d
         using (title_key)
    where d.is_assigned
)
select
    coalesce(o.title_group, '(none - as intended)') as we_said,
    count(distinct s.email)                         as people
from survey s
join cdp c using (email)
left join ours o on o.snid = c.snid
group by we_said
order by people desc;


/* ===========================================================================
   Q5.  THE SAME CHECK AT THE AUDIENCE LEVEL  -  this is the one that counts
   ---------------------------------------------------------------------------
   Merve, 2026-10-30: we do not have an early/established distinction. Both
   feed the single `researcher` audience, so comparing at title-group level
   invented a disagreement that does not exist - researcher_established
   measured 27.3% against researcher_early at 70%, and every one of those
   "misses" lands in the same audience anyway.

   Support/technical is dropped for the same reason in reverse: it feeds no
   audience, so its 8% measured nothing about anything we deliver.

   What the survey answers mean in audience terms:

       professor, lecturer, assistant/associate professor   ->  lecturer
       research scientist, PI, postdoc, senior scientist    ->  researcher
       physician, clinician, healthcare professional        ->  hcp_broad
       head of academic dept, dean, institute director      ->  faculty_head
       librarian                                            ->  librarian

   TWO NUMBERS, and they answer different questions.

       recall_all              of everyone who said it, how many did we find?
                               Dominated by coverage - most of the misses are
                               people we have no ORCID record for at all.

       recall_among_classified of the ones we DID classify, how many did we
                               put in the right audience? This is the fair
                               measure of the classifier.

   Read both against the 88.9% ceiling from the header.
   =========================================================================== */
with survey as (
    select
        lower(trim(email)) as email,
        case survey_group
            when 'teaching_academic'      then 'lecturer'
            when 'researcher_early'       then 'researcher'
            when 'researcher_established' then 'researcher'
            when 'practitioner'           then 'hcp_broad'
            when 'leadership'             then 'faculty_head'
            when 'librarian'              then 'librarian'
        end as expected_audience
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_raw.survey_self_declared_roles`
    where map_status = 'mapped'
      and survey_group in ('teaching_academic','researcher_early',
                           'researcher_established','practitioner',
                           'leadership','librarian')
),
cdp as (
    select snid, lower(trim(email)) as email
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_raw.raw_audience_builder_big`
    where email is not null and email != ''
),
aud as (
    select distinct snid, role_key
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_presentation.fct_role_audience`
    where role_label = 'CONFIRMED'
),
hit as (
    select
        s.email,
        s.expected_audience,
        logical_or(a.role_key = s.expected_audience) as in_that_audience,
        logical_or(a.role_key is not null)           as in_any_audience
    from survey s
    join cdp c using (email)
    left join aud a on a.snid = c.snid
    group by s.email, s.expected_audience
)
select
    expected_audience                                           as they_said,
    count(*)                                                    as people,
    countif(in_any_audience)                                    as we_gave_a_role,
    countif(in_that_audience)                                   as we_agree,
    round(countif(in_that_audience) / count(*), 3)              as recall_all,
    round(safe_divide(countif(in_that_audience),
                      countif(in_any_audience)), 3)             as recall_among_classified
from hit
group by expected_audience
union all
select '** ALL **', count(*), countif(in_any_audience), countif(in_that_audience),
       round(countif(in_that_audience) / count(*), 3),
       round(safe_divide(countif(in_that_audience), countif(in_any_audience)), 3)
from hit
order by people desc;


/* ===========================================================================
   Q6.  THE OTHER DIRECTION - what do the people IN our audiences say?
   ---------------------------------------------------------------------------
   Q5 asks whether we found the people who say they are X. This asks whether
   the people we call X say so themselves. A low number here means we are
   putting the wrong people in; a low number in Q5 means we are missing people.
   They fail in opposite directions and both are worth knowing.
   =========================================================================== */
with survey as (
    select lower(trim(email)) as email, survey_group, survey_role_raw
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_raw.survey_self_declared_roles`
    where map_status = 'mapped'
),
ours as (
    select distinct role_key, snid, lower(trim(contact_email)) as email
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_presentation.fct_role_audience`
    where role_label = 'CONFIRMED' and contact_email is not null
)
select
    o.role_key                                          as we_said,
    s.survey_group                                      as they_said,
    count(distinct o.snid)                              as people,
    round(count(distinct o.snid) /
          sum(count(distinct o.snid)) over (partition by o.role_key), 3) as share_of_audience
from ours o
join survey s using (email)
where o.role_key in ('lecturer','researcher','hcp_broad','faculty_head',
                     'pharmacist','librarian')
group by we_said, they_said
qualify row_number() over (partition by we_said order by people desc) <= 5
order by we_said, people desc;
