{{ config(materialized='view') }}

/*
    ORCID employment kayitlarinin duzlestirilmis hali.
    Bir satir = bir kisi x bir employment kaydi.

    !! KOLON ADLARI DOGRULANACAK !!
    Asagidaki isimler Phase-1 dokumanindaki cikti alanlarindan tahmin edildi.
    `bq show --schema` ciktisina gore duzeltilecek.
*/

with source as (

    select * from {{ source('researcher_profiles', 'v_orcid_researchers') }}

),

renamed as (

    select
        snid,
        orcid_id,

        -- ham metinler (kanit/izlenebilirlik icin saklanir)
        orcid_role                                      as role_title_raw,
        orcid_organisation                              as organisation_raw,
        orcid_department                                as department_raw,
        country_code,

        -- normalize edilmis metinler (butun eslestirme bunlarin uzerinden)
        {{ normalize_title('orcid_role') }}             as role_title,
        {{ normalize_title('orcid_organisation') }}     as organisation,
        {{ normalize_title('orcid_department') }}       as department,

        -- tarihler
        employment_start_date                           as start_date,
        employment_end_date                             as end_date,
        coalesce(employment_end_date is null, false)    as is_current

    from source
    where snid is not null

),

ranked as (

    select
        *,
        -- en guncel kayit: once current olanlar, sonra en yeni baslangic
        row_number() over (
            partition by snid
            order by is_current desc,
                     start_date desc nulls last,
                     end_date   desc nulls last
        ) as recency_rank
    from renamed

)

select * from ranked
