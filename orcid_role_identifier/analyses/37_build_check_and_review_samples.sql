/*
    ============================================================================
    37. DID THE 5 NOVEMBER WORK LAND, AND A SAMPLE PER AUDIENCE TO READ
    ============================================================================
    Two separate jobs in one file.

    PART A (queries 1-2) checks the build. Everything the roles_embeddings
    branch changed on 5 November, plus the 4 November hcp_broad change, has
    a number that was measured BEFORE this build. If the build applied them,
    these numbers come back. If one is far off, that change did not land.

        faculty_head CONFIRMED        15,048   (was 18,869 before 5 Nov)
        hcp_administrator CONFIRMED    7,528   (was  7,616)
        pharmacist CONFIRMED           2,051   (was  2,304)
        hcp_broad rows with no
          clinical title                   0   (the 4 Nov change)

    PART B (query 3) draws the review sample. Change ONE word at the top and
    run it again for the next audience.

    WHY THESE NUMBERS AND NOT NEW ONES. Nothing in models/, seeds/ or
    dbt_project.yml changed after 5 November - the merge of 10 November
    touched only analyses/ and docs/. So this build should REPRODUCE the
    5 November figures, give or take the underlying data refreshing. A
    number that moves a lot is either a change that did not land, or the
    data moving, and query 2 separates the two by showing every audience.
    ============================================================================
*/


-- ----------------------------------------------------------------------------
-- 1. THE CHANGE CHECK. One row. Each column has a predicted value above.
--
--    The three *_vs_pred columns should be small. The last two are rules,
--    not counts, and are the point of the named-chair work:
--
--      named_chairs_in_teaching  MUST be > 0  (endowed chair etc. moved)
--      vice_chairs_in_leadership MUST be > 0  (the unless_pattern veto held;
--                                              if this is 0 the veto failed
--                                              and the pattern ate them)
-- ----------------------------------------------------------------------------
with conf as (
    select role_key, count(distinct snid) as people
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles`
    where role_label = 'CONFIRMED'
    group by role_key
),

/*  hcp_broad's own rows, excluding the roll-ups from its four children, so
    this measures hcp_broad's own admission rule and not its children's.  */
hcp_no_title as (
    select count(distinct snid) as people
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles`
    where role_key = 'hcp_broad'
      and derived_from_role is null
      and role_label = 'CONFIRMED'
      and coalesce(role_score, 0.0) = 0.0
),

titles as (
    select title, title_group
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
    where is_assigned
)

select
    (select people from conf where role_key = 'faculty_head')          as faculty_head,
    (select people from conf where role_key = 'faculty_head') - 15048  as faculty_head_vs_pred,

    (select people from conf where role_key = 'hcp_administrator')         as hcp_admin,
    (select people from conf where role_key = 'hcp_administrator') - 7528  as hcp_admin_vs_pred,

    (select people from conf where role_key = 'pharmacist')         as pharmacist,
    (select people from conf where role_key = 'pharmacist') - 2051  as pharmacist_vs_pred,

    (select people from hcp_no_title)                               as hcp_broad_no_title_rows,

    (select count(*) from titles
      where title_group = 'teaching_academic'
        and regexp_contains(title, r'(endowed chair|research chair|chair professor)')
    )                                                               as named_chairs_in_teaching,

    (select count(*) from titles
      where title_group = 'leadership'
        and regexp_contains(title, r'vice chair')
    )                                                               as vice_chairs_in_leadership
;


-- ----------------------------------------------------------------------------
-- 2. EVERY AUDIENCE, so the status document's table can be rebuilt from one
--    measurement instead of three different dates. This is the query whose
--    output I need to make section 10.3 current.
--
--    marketable = CONFIRMED and mkt_pref_opt_in. Do NOT add the column up:
--    one person can hold several roles.
-- ----------------------------------------------------------------------------
with roles as (
    select snid, role_key, role_label
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles`
),
consent as (
    select snid, logical_or(coalesce(mkt_pref_opt_in, false)) as opted_in
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_raw.raw_audience_builder_big`
    group by snid
)
select
    r.role_key,
    count(distinct if(r.role_label = 'CONFIRMED', r.snid, null))        as confirmed,
    count(distinct if(r.role_label = 'PROBABLE',  r.snid, null))        as probable,
    count(distinct if(r.role_label = 'CONFIRMED' and c.opted_in,
                      r.snid, null))                                    as marketable
from roles r
left join consent c using (snid)
group by r.role_key
order by confirmed desc
;


-- ----------------------------------------------------------------------------
-- 3. THE REVIEW SAMPLE. Change target_audience and run again.
--
--    One row per person, the most recent record, which is the one the
--    pipeline labelled them on. Everything needed to judge it by eye is on
--    the row: what they call themselves, who they work for, which
--    department, and which of the three axes carried the score.
--
--    The sample is DETERMINISTIC - it is a hash of the snid, not rand() -
--    so re-running returns the same 100 people and a second reading can be
--    compared to the first. Change sample_size, not the hash, to see more.
--
--    Audiences: lecturer, researcher, hcp_broad, hcp_practitioner,
--               hcp_researcher, faculty_head, hcp_administrator,
--               pharmacist, librarian
-- ----------------------------------------------------------------------------
declare target_audience string default 'hcp_researcher';
declare sample_size     int64  default 100;

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
    r.is_current,
    /*  Which axes are actually carrying this person. A person held up by one
        axis is the interesting case: that is where a wrong title or a wrong
        department has nothing to contradict it.  */
    (case when coalesce(r.role_score, 0.0) > 0 then 1 else 0 end
   + case when coalesce(r.org_score,  0.0) > 0 then 1 else 0 end
   + case when coalesce(r.dept_score, 0.0) > 0 then 1 else 0 end)  as axes_carrying
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles` r
where r.role_key   = target_audience
  and r.role_label = 'CONFIRMED'
/*  cast because farm_fingerprint takes STRING or BYTES and snid's type is
    not declared anywhere in the contracts. Ordering by the hash is what
    makes the sample random with respect to the data and repeatable with
    respect to the person - the same 100 people come back every time.  */
qualify row_number() over (
    order by farm_fingerprint(cast(r.snid as string))
) <= sample_size
;
