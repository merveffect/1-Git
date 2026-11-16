{{ config(materialized='table') }}

/*
    The second part of role_detailed_inferred.

    Each role has its own "detail dimension"
    (dbt_project.yml -> detail_dimension):
        hcp           -> bucket    : Practitioner / Researcher / Administrator
        pharmacist    -> setting   : Hospital / Community / Industry / Academia
        librarian     -> org_type  : University / Hospital / National Library ...
        researcher    -> org_type  : University / Research Institute / Industry ...
        faculty_head  -> org_type  : University / Hospital ...

    The rules live in seeds/role_detail_map.csv; the lowest priority
    wins. Adding a role means adding rows there - no SQL changes.
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
     /*
         CASE-INSENSITIVE, AND IT HAD TO BE. ROR writes its types in
         lowercase - `education`, `healthcare`, `facility` - and the seed
         writes them capitalised, so `'education' = 'Education'` was false
         for every row and NOT ONE org_type rule had ever fired. Measured
         2026-11-16, analyses/52 query 6: rows_that_match_exactly was 0 on
         all 30 pairs, against 180,682 that match once case is ignored.

         Seven audiences - researcher, students, librarian, faculty_head,
         hcp_practitioner, hcp_researcher, hcp_administrator - have ONLY
         org_type rules and no UNKNOWN fallback, so their role_detail was
         null for every person. hcp_broad and pharmacist have title rules
         as well, so theirs was partly populated and partly not, which is
         why nobody noticed.

         int_employment_scored already joins org_type_scores with
         upper(trim()) on both sides, seven lines apart from this one.
         Somebody hit this exact problem on the scoring axis and fixed it
         only there.
     */
     and upper(trim(coalesce(s.org_type, 'UNKNOWN'))) = upper(trim(m.match_value))

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
    partition by snid, role_key
    order by priority asc, detail_label asc
) = 1
