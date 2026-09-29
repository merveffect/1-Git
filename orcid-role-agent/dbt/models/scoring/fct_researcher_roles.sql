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
        coalesce(edu.education_score, 0.0)  as education_score,
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
    left join {{ ref('int_education_scored') }} edu
           on emp.snid = edu.snid
          and emp.role_key = edu.role_key
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
        education_score,
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
        snid, role_key, role_detail, role_final_score, role_label,
        evidence_title, evidence_org, evidence_dept, country_code,
        is_current, source_key, source_last_updated, derived_from_role
    from qualified

    {{ parent_rollup_union('qualified') }}

)

select
    snid,
    role_key,
    role_detail,
    role_label,
    role_final_score,
    evidence_title,
    evidence_org,
    evidence_dept,
    country_code,
    is_current,
    source_key,
    source_last_updated,
    derived_from_role,
    current_date()  as scored_date
from with_parents
-- if the same (person, role) appears more than once keep the best score
qualify row_number() over (
    partition by snid, role_key
    order by role_final_score desc, derived_from_role nulls first
) = 1
