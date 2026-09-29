{{ config(materialized='table') }}

/*
    Education bonus. It never qualifies a role on its own; it only lifts
    borderline cases. Which roles it counts for is set by
    dbt_project.yml -> roles.*.education_bonus.

    WEIGHTING - changed from Phase-1's even 0.5 / 0.5 split, based on
    measurement (analyses/04_degree_coverage.sql over 23M education
    records):

        The degree field mostly encodes ACADEMIC LEVEL, not subject.
        The most common values are phd (2.96M), ph d (1.47M),
        master (464k), msc (437k), bachelor (398k). "PhD" says nothing
        about whether someone practises medicine.

        The SUBJECT lives in the department field, which is populated
        on 77% of records. So the department now carries most of the
        weight:

            education_score = degree * 0.3 + department * 0.7

    Degree patterns still matter for the genuinely diagnostic ones -
    MD, MBBS, PharmD, BDS - which is why the seed keeps them and gained
    the multilingual variants the regex was missing.
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
    coalesce(dg.degree_score, 0.0)   * {{ var('education_degree_weight') }}
        + coalesce(dp.edu_dept_score, 0.0) * {{ var('education_dept_weight') }}
                                                   as education_score
from degree_scored dg
full outer join dept_scored dp
  on dg.snid = dp.snid and dg.role_key = dp.role_key
