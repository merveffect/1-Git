{{ config(materialized='table') }}

/*
    role_detailed_inferred'in 2. parcasi.

    Her rolun kendi "detay boyutu" var (dbt_project.yml -> detail_dimension):
        hcp           -> bucket    : Practitioner / Researcher / Administrator
        pharmacist    -> setting   : Hospital / Community / Industry / Academia
        librarian     -> org_type  : University / Hospital / National Library ...
        researcher    -> org_type  : University / Research Institute / Industry ...
        faculty_head  -> org_type  : University / Hospital ...

    Kurallar seeds/role_detail_map.csv'de; en dusuk priority kazanir.
    Yeni rol eklerken buraya satir eklemek yeterli - SQL degismez.
*/

with scored as (

    select
        snid,
        role_key,
        evidence_title,
        org_type
    from {{ ref('int_employment_scored') }}

),

title_matches as (

    select
        s.snid,
        s.role_key,
        m.detail_label,
        m.priority
    from scored s
    join {{ ref('role_detail_map') }} m
      on s.role_key = m.role_key
     and m.match_type = 'title'
     and regexp_contains({{ normalize_title('s.evidence_title') }}, m.match_value)

),

org_matches as (

    select
        s.snid,
        s.role_key,
        m.detail_label,
        m.priority
    from scored s
    join {{ ref('role_detail_map') }} m
      on s.role_key = m.role_key
     and m.match_type = 'org_type'
     and coalesce(s.org_type, 'UNKNOWN') = m.match_value

),

combined as (
    select * from title_matches
    union all
    select * from org_matches
)

select
    snid,
    role_key,
    detail_label
from combined
qualify row_number() over (
    partition by snid, role_key order by priority asc, detail_label asc
) = 1
