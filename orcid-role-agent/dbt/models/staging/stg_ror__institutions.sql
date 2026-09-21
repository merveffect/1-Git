{{ config(materialized='view') }}

/*
    Mevcut ROR eslestirme tablosunun sarmalayicisi.

    Bu model org_score'un regex yerine CANONICAL kurum uzerinden
    hesaplanmasini saglar - Phase-1'in en buyuk false-positive kaynagini
    kapatir.

    !! ror_mapping_table ve kolon adlari doldurulacak !!
*/

with source as (

    select *
    from {{ source('researcher_profiles', 'TODO_ror_mapping_table') }}

)

select
    {{ normalize_title('raw_organisation_name') }}  as organisation,   -- join anahtari
    ror_id,
    ror_name                                        as canonical_name,
    ror_type,          -- Education / Healthcare / Company / Government / Nonprofit ...
    ror_country,
    match_confidence
from source
