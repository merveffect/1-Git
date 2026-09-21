{{ config(materialized='table') }}

/*
    SOZLUGUN 1. ADIMI
    Benzersiz unvanlar + kac kisi kullanmis.

    Tum pahali islemler (embedding, LLM) BU tablonun uzerinde calisir,
    204K kisilik tablonun degil. Maliyet farki burada.

    frequency kolonu kritik: insan review kuyrugu buna gore siralanir.
    En sik gecen birkac yuz unvani gozden gecirmek, kisilerin yarisini kapsar.
*/

with employment as (

    select role_title, organisation, department
    from {{ ref('stg_orcid__employment') }}
    where role_title is not null

),

agg as (

    select
        role_title                                  as title,
        count(*)                                    as frequency,
        count(distinct organisation)                as distinct_orgs,
        approx_top_count(organisation, 3)           as top_organisations,
        approx_top_count(department, 3)             as top_departments
    from employment
    group by title

)

select
    to_hex(md5(title))  as title_key,
    title,
    frequency,
    distinct_orgs,
    top_organisations,
    top_departments,
    sum(frequency) over ()                                            as corpus_size,
    sum(frequency) over (order by frequency desc)
        / sum(frequency) over ()                                      as cumulative_coverage
from agg
order by frequency desc
