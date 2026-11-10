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
--      vice_chairs_in_leadership MUST be > 0  (the unless_pattern veto held -
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
-- 2. EVERY AUDIENCE, WITH ALL THREE CONSENT BASES.
--
--    THE FIRST VERSION OF THIS QUERY WAS WRONG IN A WAY THAT MATTERED
--    MORE THAN ANY SQL ERROR IN THIS PROJECT.
--
--    It counted `marketable` as mkt_pref_opt_in alone, straight off
--    raw_audience_builder_big, and every number reported from it -
--    section 10.3 of the status document, the campaign risk analysis of
--    10 November - understated the reachable audience by whatever
--    legitimate interest and advertising consent add.
--
--    Merve: "ben coktan book legitimate interest ve legitimate
--    interestlerin alinmasi gerektigini soylemistim reachable audience a".
--    Correct, and the pipeline has done it since 2026-10-16:
--
--        dbt_project.yml   consent_basis: 'any_basis'
--        consent_predicate()  (is_marketable or is_advertisable
--                              or is_legitimate_interest)
--        fct_role_audience_summary.reachable  countif of the same three
--
--    So the data was right and my reporting was wrong. This query now
--    reads fct_role_audience_summary, which is the model that exists to
--    answer exactly this and which I should have been reading all along
--    instead of re-deriving a narrower number from the raw layer.
--
--    Still missing and NOT in the source yet: book-author consent,
--    is_book_author_communications_opted_in. That is a fourth legal basis
--    and marketing question 5 - Merve has said it counts, so reachable
--    will grow again when the column arrives.
--
--    Do NOT add the columns up across rows: one person can hold several
--    roles.
-- ----------------------------------------------------------------------------
select
    role_key,
    role_label,
    identified,
    in_cdp,
    marketable                                  as mkt_opt_in_only,
    advertisable,
    legitimate_interest,
    reachable,
    round(reachable_rate, 4)                    as reachable_rate,
    reachable - marketable                      as reachable_beyond_mkt_opt_in,
    round(safe_divide(reachable, nullif(marketable, 0)), 2) as reachable_vs_mkt_multiple
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_presentation.fct_role_audience_summary`
where role_label = 'CONFIRMED'
order by identified desc
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
