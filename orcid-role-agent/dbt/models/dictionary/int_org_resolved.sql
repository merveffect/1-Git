{{ config(materialized='table') }}

/*
    KURUM COZUMLEME - iki yollu.

    ORCID kayitlari zaten disambiguated_organisation_id tasiyor
    (ROR / GRID / RINGGOLD / FUNDREF). Kaynak ROR ise eslestirmeye
    HIC gerek yok - dogrudan join, %100 kesin.

    Kalanlar icin isim eslestirme (Merve'nin daha once yaptigi is).

    Cikti: (organisation, disambiguated_org_id) -> ror_id + ror_types
*/

with employment_orgs as (

    select distinct
        organisation,
        disambiguated_org_id,
        disambiguated_org_source
    from {{ ref('stg_orcid__employment') }}
    where organisation is not null

),

ror as (

    select ror_id, organisation, canonical_name, ror_types, ror_country_code
    from {{ ref('stg_ror__organisations') }}

),

-- YOL 1: ORCID'in kendi ROR kimligi (bedava, kesin)
by_ror_id as (

    select
        o.organisation,
        o.disambiguated_org_id,
        r.ror_id,
        r.canonical_name,
        r.ror_types,
        r.ror_country_code,
        'ORCID_ROR_ID'      as resolution_method,
        1.0                 as resolution_confidence
    from employment_orgs o
    join ror r
      on o.disambiguated_org_source = 'ROR'
     and o.disambiguated_org_id = r.ror_id

),

-- YOL 2: isim eslestirme (ROR kimligi yoksa)
by_name as (

    select
        o.organisation,
        o.disambiguated_org_id,
        r.ror_id,
        r.canonical_name,
        r.ror_types,
        r.ror_country_code,
        'NAME_EXACT'        as resolution_method,
        0.9                 as resolution_confidence
    from employment_orgs o
    join ror r
      on o.organisation = r.organisation
    where not exists (
        select 1 from by_ror_id b
        where b.organisation = o.organisation
          and b.disambiguated_org_id is not distinct from o.disambiguated_org_id
    )

),

combined as (
    select * from by_ror_id
    union all
    select * from by_name
)

select
    organisation,
    disambiguated_org_id,
    ror_id,
    canonical_name,
    ror_types,
    ror_country_code,
    resolution_method,
    resolution_confidence
from combined
qualify row_number() over (
    partition by organisation, disambiguated_org_id
    order by resolution_confidence desc
) = 1
