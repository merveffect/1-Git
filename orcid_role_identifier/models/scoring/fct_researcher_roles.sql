{{ config(
    materialized   = 'table',
    partition_by   = {'field': 'scored_date', 'data_type': 'date'},
    cluster_by     = ['role_key', 'role_label']
) }}

/*
    ⭐ THE CORE MODEL

    One row = (snid, role_key). A person can hold several roles, so
    several rows. The whole presentation layer is built from this table.

    Adding a role changes nothing here - the macros read the registry
    and expand the SQL themselves.
*/

with base as (

    select
        emp.snid,
        emp.role_key,
        emp.role_score,
        emp.org_score,
        emp.dept_score,
        emp.title_group,
        emp.discipline,
        emp.evidence_title,
        emp.evidence_org,
        emp.evidence_org_canonical,
        emp.evidence_dept,
        emp.ror_id,
        emp.country_code,
        emp.is_current,
        emp.source_key,
        emp.source_last_updated,
        det.detail_label
    from {{ ref('int_employment_scored') }} emp
    left join {{ ref('int_role_detail') }} det
           on emp.snid = det.snid
          and emp.role_key = det.role_key

),

scored as (

    select
        *,
        {{ composite_score_expr() }}    as role_final_score
    from base
    where {{ current_only_predicate('is_current') }}

),

labelled as (

    select
        snid,
        role_key,
        detail_label                                as role_detail,
        {{ role_label_expr('role_final_score') }}   as role_label,
        role_final_score,
        role_score,
        org_score,
        dept_score,
        title_group,
        discipline,
        evidence_title,
        evidence_org,
        evidence_org_canonical,
        evidence_dept,
        ror_id,
        country_code,
        is_current,
        source_key,
        source_last_updated,
        cast(null as string)                        as derived_from_role
    from scored

),

qualified as (

    select * from labelled
    where role_label in ('CONFIRMED', 'PROBABLE')

),

/*
    Parent roll-up: a pharmacist also gets an hcp / PRACTITIONER row.
    Relationships come from dbt_project.yml -> roles.*.parent
*/
with_parents as (

    select
        snid, role_key, role_detail, role_final_score,
        -- the three component scores travel with the row: without them
        -- you cannot tell from this table WHICH axis carried a decision,
        -- which is the first question anyone asks of a result
        role_score, org_score, dept_score, title_group, discipline,
        evidence_title, evidence_org, evidence_dept, country_code,
        is_current, source_key, source_last_updated, derived_from_role
    from qualified

    {{ parent_rollup_union('qualified') }}

)

/*
    LABEL AFTER THE UNION, NOT BEFORE IT.

    A roll-up row arrives carrying its child's score but the PARENT's
    role_key, and the two have different thresholds - hcp_broad confirms
    at 0.60 while hcp_practitioner, hcp_researcher and hcp_administrator
    confirm at 0.70. Labelling the child and copying the answer put 5,528
    people into hcp_broad as PROBABLE when their score cleared hcp_broad's
    own threshold, and PROBABLE does not ship to Braze.

    Measured before the fix: hcp_broad PROBABLE ran from 0.303 to 0.700
    while hcp_broad CONFIRMED started at 0.600 - the two bands overlapped,
    which is impossible for a single threshold and is the symptom that
    found this.

    role_label_expr switches on role_key, which is the parent here, so
    recomputing gives the parent's thresholds. The filter below keeps the
    guard the qualified CTE applied earlier, in case a future parent is
    ever stricter than its child.
*/
relabelled as (

    select
        *,
        {{ role_label_expr('role_final_score') }}   as role_label
    from with_parents

)

select
    snid,
    role_key,
    role_detail,
    role_label,
    role_final_score,
    role_score,
    org_score,
    dept_score,
    title_group,
    discipline,
    evidence_title,
    evidence_org,
    evidence_dept,
    country_code,
    is_current,
    source_key,
    source_last_updated,
    derived_from_role,
    current_date()  as scored_date
from relabelled
where role_label in ('CONFIRMED', 'PROBABLE')
-- if the same (person, role) appears more than once keep the best score
qualify row_number() over (
    partition by snid, role_key
    order by role_final_score desc, derived_from_role nulls first
) = 1
