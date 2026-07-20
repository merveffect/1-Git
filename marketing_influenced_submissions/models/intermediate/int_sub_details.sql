-- Phase 2 submissions: submission x user detail (Colab mis_2_sub_details_2). Unions
-- GA submitters (from the funnel) with JSD authors (backbone), aggregates the role
-- flags per (submission, user), and applies the author-inclusion filter.
--
-- SN-REVIEW (B1): a (submission, user) is kept if it is a coauthor OR corresponding
-- author, OR a GA-only submitter (ga_submitter=1 with no JSD role). A GA submitter
-- who is also the JSD submitter but neither coauthor nor corresponding is excluded
-- (Colab treats it as "not a real author"). ~98 EM subs with null roles are dropped.

with combined as (

    select
        ga_submission_id as submission_id,
        user_pseudo_id,
        1 as ga_submitter,
        0 as submitter,
        0 as coauthor,
        0 as correspondingauthor
    from {{ ref('int_subs_clientids_ga') }}

    union all

    select
        internal_submission_id as submission_id,
        client_id as user_pseudo_id,
        0 as ga_submitter,
        case when is_submitter then 1 else 0 end as submitter,
        case when is_coauthor then 1 else 0 end as coauthor,
        case when is_corresponding_author then 1 else 0 end as correspondingauthor
    from {{ ref('int_authors_enriched') }}

),

agg as (

    select
        submission_id,
        user_pseudo_id,
        max(ga_submitter) as ga_submitter,
        max(submitter) as submitter,
        max(coauthor) as coauthor,
        max(correspondingauthor) as corresp
    from combined
    group by 1, 2

)

select
    t2.internal_submission_id,
    t2.journal_id,
    t2.imprint_code,
    t2.submission_date as submission_date_min,
    t1.user_pseudo_id,
    t1.ga_submitter,
    t1.submitter,
    t1.coauthor,
    t1.corresp
from agg t1
join {{ ref('int_subs_unique') }} t2
    on t1.submission_id = t2.internal_submission_id
where t1.coauthor = 1
   or t1.corresp = 1
   or (t1.ga_submitter = 1 and t1.submitter = 0 and t1.coauthor = 0 and t1.corresp = 0)
group by 1, 2, 3, 4, 5, 6, 7, 8, 9
