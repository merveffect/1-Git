{{ config(materialized='table') }}

/*
    Egitim bonusu. Phase-1 ile ayni mantik:
        education_score = degree_score * 0.5 + edu_dept_score * 0.5
    Tek basina rol kazandirmaz; sadece sinirdaki vakalari yukari iter.
    Hangi rollerde sayilacagi dbt_project.yml:roles.*.education_bonus ile.
*/

with education as (

    select * from {{ ref('stg_orcid__education') }}

),

degree_scored as (

    select
        e.snid,
        d.role_key,
        max(d.degree_score)     as degree_score
    from education e
    join {{ ref('education_signals') }} d
      on d.signal_type = 'degree'
     and regexp_contains(e.degree, d.pattern)
    group by e.snid, d.role_key

),

dept_scored as (

    select
        e.snid,
        d.role_key,
        max(d.degree_score)     as edu_dept_score
    from education e
    join {{ ref('education_signals') }} d
      on d.signal_type = 'department'
     and regexp_contains(e.edu_department, d.pattern)
    group by e.snid, d.role_key

)

select
    coalesce(dg.snid, dp.snid)           as snid,
    coalesce(dg.role_key, dp.role_key)   as role_key,
    coalesce(dg.degree_score, 0.0)       as degree_score,
    coalesce(dp.edu_dept_score, 0.0)     as edu_dept_score,
    coalesce(dg.degree_score, 0.0) * 0.5
        + coalesce(dp.edu_dept_score, 0.0) * 0.5   as education_score
from degree_scored dg
full outer join dept_scored dp
  on dg.snid = dp.snid and dg.role_key = dp.role_key
