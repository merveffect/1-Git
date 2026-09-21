{{ config(materialized='view') }}

/*
    ORCID education kayitlari. Phase-1'deki gibi kisi basina EN GUNCEL
    kayit kullanilir; egitim yalnizca bonus olarak skora girer.

    !! KOLON ADLARI DOGRULANACAK !!
*/

with source as (

    select * from {{ source('researcher_profiles', 'v_orcid_researchers') }}

),

renamed as (

    select
        snid,
        education_degree                                as degree_raw,
        education_department                            as edu_department_raw,

        {{ normalize_title('education_degree') }}       as degree,
        {{ normalize_title('education_department') }}   as edu_department,

        education_start_date                            as start_date,
        education_end_date                              as end_date

    from source
    where snid is not null
      and education_degree is not null

),

ranked as (

    select
        *,
        row_number() over (
            partition by snid
            order by end_date desc nulls last, start_date desc nulls last
        ) as recency_rank
    from renamed

)

select * from ranked where recency_rank = 1
