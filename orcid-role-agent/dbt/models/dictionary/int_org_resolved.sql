{{ config(materialized='table') }}

/*
    KURUM COZUMLEME - iki yollu.

    ORCID kayitlari zaten kurum kimligi tasiyor (org_id)
    (ROR / GRID / RINGGOLD / FUNDREF). Kaynak ROR ise eslestirmeye
    HIC gerek yok - dogrudan join, %100 kesin.

    Kalanlar icin isim eslestirme (Merve'nin daha once yaptigi is).

    Cikti: (organisation, org_id) -> ror_id + ror_types
*/

with employment_orgs as (

    select distinct
        organisation,
        org_id,
        org_id_source
    from {{ ref('stg_role_records') }}
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
        o.org_id,
        r.ror_id,
        r.canonical_name,
        r.ror_types,
        r.ror_country_code,
        'ORCID_ROR_ID'      as resolution_method,
        1.0                 as resolution_confidence
    from employment_orgs o
    join ror r
      on o.org_id_source = 'ROR'
     and o.org_id = r.ror_id

),

-- YOL 2: isim eslestirme (ROR kimligi yoksa)
by_name as (

    select
        o.organisation,
        o.org_id,
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
          and b.org_id is not distinct from o.org_id
    )

),

combined as (
    select * from by_ror_id
    union all
    select * from by_name
)

select
    organisation,
    org_id,
    ror_id,
    canonical_name,
    ror_types,
    ror_country_code,
    resolution_method,
    resolution_confidence
from combined
qualify row_number() over (
    partition by organisation, org_id
    order by resolution_confidence desc
) = 1
