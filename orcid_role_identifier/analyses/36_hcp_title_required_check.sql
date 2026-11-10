/*
    ============================================================================
    36. DID THIS BUILD DO WHAT WE SAID IT WOULD
    ============================================================================
    Two changes went in on 2026-11-04:

      1  `associate dean for library operations` -> librarian, a HUMAN override
         that clears the assert_title_patterns_do_not_collide failure
      2  hcp_broad: match title_or_field -> title_required, because the job
         title is now mandatory ("klinik unvan yoksa asla alma iceri")

    THE FORECAST, from analyses/34 query 5, written down before the build so it
    can be wrong in public:

        hcp_broad CONFIRMED      129,373  ->  123,258   (-6,115)
        hcp_broad marketable      27,977  ->   26,532   (-1,445)
        rows with NO clinical title            6,115  ->  0
        every other audience                   unchanged

    The 1,624 people holding a clinical title with NO department must SURVIVE.
    If they moved, the change was read as "require a department" and is wrong.

    Query 1 is the whole check. Run it first; the rest only explain it.
    ============================================================================
*/


-- ----------------------------------------------------------------------------
-- 1. THE WHOLE CHECK. One row. Every number has a predicted value above.
--
--    no_title_rows_left MUST be 0. That is the change.
--    title_no_dept_rows SHOULD still be about 1,624. Those people stay.
-- ----------------------------------------------------------------------------
with own_rows as (
    select
        coalesce(role_score, 0.0)   as role_score,
        coalesce(dept_score, 0.0)   as dept_score,
        role_final_score,
        snid
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles`
    where role_key = 'hcp_broad'
      and role_label = 'CONFIRMED'
      and derived_from_role is null
),

audience as (
    select
        r.snid,
        coalesce(a.is_marketable, false) as is_marketable
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles` r
    left join `dat-analytics-eng-ec869189.dev_orcid_role_identifier_presentation.fct_role_audience` a
           on a.snid = r.snid and a.role_key = r.role_key
    where r.role_key = 'hcp_broad' and r.role_label = 'CONFIRMED'
)

select
    (select count(*) from audience)                                     as hcp_broad_confirmed,
    123258                                                              as predicted_confirmed,
    (select count(*) from audience) - 123258                            as confirmed_vs_forecast,

    (select countif(is_marketable) from audience)                       as hcp_broad_marketable,
    26532                                                               as predicted_marketable,
    (select countif(is_marketable) from audience) - 26532               as marketable_vs_forecast,

    /* the change itself - must be zero */
    (select countif(role_score = 0) from own_rows)                      as no_title_rows_left,

    /* the people who must NOT have moved - expect about 1,624 */
    (select countif(role_score > 0 and dept_score = 0) from own_rows)   as title_no_dept_rows,

    (select count(*) from own_rows)                                     as own_confirmed_rows;


-- ----------------------------------------------------------------------------
-- 2. DID ANYTHING ELSE MOVE. It should not have.
--
--    hcp_broad is the only role whose match mode changed, and the librarian
--    override is one title of one record. Compare against the 4 November
--    figures in the right-hand column.
-- ----------------------------------------------------------------------------
with now as (
    select
        role_key,
        countif(role_label = 'CONFIRMED')   as confirmed,
        countif(role_label = 'PROBABLE')    as probable
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles`
    group by role_key
),

before as (
    select * from unnest([
        struct('lecturer'         as role_key, 404061 as was_confirmed,    306 as was_probable),
        struct('researcher',                   329850,                     762),
        struct('hcp_broad',                    129373,                  107896),
        struct('hcp_practitioner',              60945,                    2911),
        struct('hcp_researcher',                53290,                    2089),
        struct('faculty_head',                  18918,                   14324),
        struct('hcp_administrator',              7580,                    1987),
        struct('pharmacist',                     2287,                    1671),
        struct('librarian',                       687,                       0)
    ])
)

select
    b.role_key,
    b.was_confirmed,
    n.confirmed,
    n.confirmed - b.was_confirmed                   as confirmed_change,
    b.was_probable,
    n.probable,
    n.probable - b.was_probable                     as probable_change
from before b
join now n using (role_key)
order by abs(n.confirmed - b.was_confirmed) desc;


-- ----------------------------------------------------------------------------
-- 3. WHO LEFT, in their own words.
--
--    THE PEOPLE WHO LEFT ARE INVISIBLE IN THE SCORED TABLES, which is the trap
--    that produced a dud query once before: int_employment_scored only emits a
--    row when the record qualifies for the role, so a record with no clinical
--    title now has no hcp_broad row to find. It has to be rebuilt from staging.
--
--    This reconstructs exactly what the old `title_or_field` arm admitted: a
--    clinical DEPARTMENT with a title that is NOT in a clinical group. It is
--    RECORD level, not person level, so it will not sum to 6,115 - a person can
--    hold several such records, and some of them are still in hcp_broad through
--    a different post.
--
--    This is the honest half of the change: 1,445 marketable contacts went, and
--    this says what they called themselves. If the list reads like real
--    clinicians, the change was wrong and it is one line to reverse.
-- ----------------------------------------------------------------------------
with recs as (
    select
        r.snid,
        r.role_title_raw                        as evidence_title,
        coalesce(t.title_group, '(unassigned)') as title_group,
        d.discipline_score
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_staging.stg_role_records` r
    left join `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group` t
           on r.title_key = t.title_key
          and t.is_assigned
    join `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_department_discipline` d
           on to_hex(md5(r.department)) = d.department_key
          and d.is_assigned
    where d.discipline = 'health_clinical'
      and (t.title_group is null
           or t.title_group not in ('practitioner', 'trainee_clinical'))
)

select
    title_group,
    evidence_title,
    count(*)                            as records,
    count(distinct snid)                as people,
    round(avg(discipline_score), 3)     as mean_dept_score
from recs
group by title_group, evidence_title
order by records desc
limit 200;
