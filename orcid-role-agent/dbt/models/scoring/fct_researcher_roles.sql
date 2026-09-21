{{ config(
    materialized   = 'table',
    partition_by   = {'field': 'scored_date', 'data_type': 'date'},
    cluster_by     = ['role_key', 'role_label']
) }}

/*
    ⭐ TEK GERCEK MODEL

    Bir satir = (snid, role_key). Bir kisi birden fazla rol tasiyabilir.
    Presentation katmaninin TAMAMI buradan beslenir.

    Yeni rol eklendiginde bu dosya DEGISMEZ - makrolar kayit defterini
    okuyup SQL'i kendisi genisletir.
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
        emp.is_current
    from {{ ref('int_employment_scored') }} emp
    left join {{ ref('int_education_scored') }} edu
           on emp.snid = edu.snid
          and emp.role_key = edu.role_key

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
        cast(null as string)                        as role_bucket,
        cast(null as string)                        as derived_from_role
    from scored

),

qualified as (

    select * from labelled
    where role_label in ('CONFIRMED', 'PROBABLE')

),

/*
    Ebeveyn roll-up: pharmacist olan kisi ayni zamanda hcp/PRACTITIONER
    satiri da alir. Iliskiler dbt_project.yml'deki `parent:` alanindan.
*/
with_parents as (

    select
        snid, role_key, role_bucket, role_final_score, role_label,
        evidence_title, evidence_org, evidence_dept, country_code,
        is_current, derived_from_role
    from qualified

    {{ parent_rollup_union('qualified') }}

)

select
    snid,
    role_key,
    role_bucket,
    role_label,
    role_final_score,
    evidence_title,
    evidence_org,
    evidence_dept,
    country_code,
    is_current,
    derived_from_role,
    current_date()  as scored_date
from with_parents
-- ayni (snid, role) ikiden fazla kez gelirse en yuksek skoru tut
qualify row_number() over (
    partition by snid, role_key
    order by role_final_score desc, derived_from_role nulls first
) = 1
