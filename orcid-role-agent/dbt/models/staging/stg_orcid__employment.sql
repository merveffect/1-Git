{{ config(materialized='view') }}

/*
    ORCID employments[] -> ORTAK ROL KAYDI SEMASI

    Bu model ORCID'e ozel. Ama CIKTISI kaynak-bagimsiz: her yeni kaynak
    (web scraping, CDP self-reported, ...) ayni kolonlari uretecek ve
    stg_role_records altinda birlesecek.

    Gorunurluk filtresi raw katmaninda uygulandi - burada tekrar yok.
*/

with flattened as (

    select
        r.snid,
        r.orcid_id,
        r.last_updated_at,
        e.ordering,

        -- ham metinler (kanit / izlenebilirlik icin saklanir)
        e.role                                          as role_title_raw,
        e.organisation_name                             as organisation_raw,
        e.department_name                               as department_raw,

        -- normalize (butun eslestirme bunlarin uzerinden)
        {{ normalize_title('e.role') }}                 as role_title,
        {{ normalize_title('e.organisation_name') }}    as organisation,
        {{ normalize_title('e.department_name') }}      as department,

        -- ORCID'in kendi kurum kimligi: ROR / GRID / RINGGOLD
        e.disambiguated_organisation_id                 as org_id,
        upper(e.disambiguated_organisation_source)      as org_id_source,

        -- kayit bazli ulke (profil ulkesinden daha dogru)
        e.organisation_address_country_code             as country_code,

        e.full_start_date                               as start_date,
        e.full_end_date                                 as end_date

    from {{ ref('raw_orcid_researchers') }} r,
    unnest(r.employments) e

)

select
    snid,
    orcid_id,
    role_title_raw,
    role_title,
    organisation_raw,
    organisation,
    department_raw,
    department,
    org_id,
    org_id_source,
    country_code,
    start_date,
    end_date,
    ordering,
    last_updated_at                                     as source_last_updated
from flattened
where role_title is not null
