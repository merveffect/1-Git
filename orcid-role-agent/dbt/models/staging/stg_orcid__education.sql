{{ config(materialized='view') }}

/*
    ORCID educations[] -> kisi basina EN GUNCEL egitim kaydi.
    Egitim yalnizca BONUS olarak skora girer, tek basina rol kazandirmaz.
    Gorunurluk filtresi raw katmaninda uygulandi.
*/

with flattened as (

    select
        r.snid,
        d.ordering,

        d.degree                                        as degree_raw,
        d.department_name                               as edu_department_raw,

        {{ normalize_title('d.degree') }}               as degree,
        {{ normalize_title('d.department_name') }}      as edu_department,

        d.full_start_date                               as start_date,
        d.full_end_date                                 as end_date

    from {{ ref('raw_orcid_researchers') }} r,
    unnest(r.educations) d

)

select * from flattened
where degree is not null or edu_department is not null
qualify row_number() over (
    partition by snid
    order by end_date desc nulls last,
             start_date desc nulls last,
             ordering asc nulls last
) = 1
