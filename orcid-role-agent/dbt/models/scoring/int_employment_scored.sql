{{ config(materialized='table') }}

/*
    Role / org / dept sub-scores per person x role.

    Two improvements over Phase-1:
      - role_score comes from the dictionary instead of hundreds of
        regex lines (multilingual, graded)
      - org_score comes from the canonical ROR organisation TYPE instead
        of pattern-matching the organisation name, so variants like
        "St. Mary's Hosp." are no longer missed
*/

with records as (

    select * from {{ ref('stg_role_records') }}

),

-- 1) resolve the organisation via ROR (direct id where available)
with_org as (

    select
        r.*,
        o.ror_id,
        o.canonical_name        as org_canonical_name,
        o.ror_types,
        o.resolution_method     as org_resolution_method
    from records r
    left join {{ ref('int_org_resolved') }} o
           on r.organisation = o.organisation
          and r.org_id is not distinct from o.org_id

),

-- 2) map the title to roles via the dictionary (multi-label: 1 -> N rows)
with_roles as (

    select
        w.*,
        t.role_key,
        t.role_score
    from with_org w
    join {{ ref('dim_title_role') }} t
      on w.title_key = t.title_key
    where t.is_role_member

),

/*
    3) org score from the (role, organisation type) pair.
       ROR 'types' is an ARRAY - a university hospital is both Education
       and Healthcare. We take the type that scores HIGHEST for the role:
       overlapping types are an advantage, not ambiguity.
*/
with_org_score as (

    select
        w.*,
        case
            when w.organisation is null then null      -- source carries no organisation
            else coalesce((
                /*
                    Case-insensitive on purpose. ROR v2 returns types
                    lowercase ('healthcare'); the seed is written in
                    title case. A case-sensitive join would match
                    nothing and silently drop every organisation to
                    UNKNOWN - worth 0.225 of an hcp score, which is
                    enough to push borderline people under threshold.
                */
                select max(s.org_score)
                from unnest(coalesce(w.ror_types, ['UNKNOWN'])) as t
                join {{ ref('org_type_scores') }} s
                  on s.role_key = w.role_key
                 and upper(trim(s.org_type)) = upper(trim(t))
            ), (
                select s.org_score from {{ ref('org_type_scores') }} s
                where s.role_key = w.role_key and s.org_type = 'UNKNOWN'
            ), 0.0)
        end                                             as org_score,
        coalesce(w.ror_types[safe_offset(0)], 'UNKNOWN') as org_type
    from with_roles w

),

-- 4) dept score from the (role, department pattern) pair; highest wins
with_dept_score as (

    select
        w.snid,
        w.role_key,
        w.role_score,
        w.org_score,
        case when max(w.department) is null then null
             else max(coalesce(d.dept_score, 0.0)) end  as dept_score,
        any_value(w.role_title_raw)         as evidence_title,
        any_value(w.organisation_raw)       as evidence_org,
        any_value(w.department_raw)         as evidence_dept,
        any_value(w.org_canonical_name)     as evidence_org_canonical,
        any_value(w.org_type)               as org_type,
        any_value(w.ror_id)                 as ror_id,
        any_value(w.org_resolution_method)  as org_resolution_method,
        any_value(w.country_code)           as country_code,
        any_value(w.source_key)             as source_key,
        max(w.is_current)                   as is_current,
        min(w.recency_rank)                 as recency_rank,
        max(w.source_last_updated)          as source_last_updated
    from with_org_score w
    left join {{ ref('dept_signals') }} d
           on w.role_key = d.role_key
          and regexp_contains(coalesce(w.department, ''), d.dept_pattern)
    group by w.snid, w.role_key, w.role_score, w.org_score

)

/*
    One record per person + role: current posts first, then the highest
    score. (Phase-1's "most recent employment record, preferring current
    roles".)
*/
select * from with_dept_score
qualify row_number() over (
    partition by snid, role_key
    order by is_current desc, role_score desc, recency_rank asc
) = 1
