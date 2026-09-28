{{ config(materialized='table') }}

/*
    KURUM COZUMLEME - iki yollu.

    GERCEK DAGILIM (38.6M employment kaydi uzerinden olculdu):
        ROR       %35.3   -> dogrudan join, eslestirme yok
        RINGGOLD  %31.7   -> ROR'un external_ids'inden koprulenir
        kimliksiz %21.2   -> isim eslestirme
        GRID      % 7.8   -> ROR GRID'den turedi, external_ids'te var
        FUNDREF   % 4.0   -> external_ids
        LEI       % 0.0

    organisation_name ise %100 dolu - yani isim eslestirme her zaman
    yedek yol olarak duruyor.

    Sirasiyla denenir, ilk tutan kazanir.

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

/*
    YOL 2: diger kimlik sistemleri (RINGGOLD %32 + GRID %8 + FUNDREF %4)
    ROR kayitlari bu kimlikleri external_ids alaninda tasiyor.
    !! ROR semasi dogrulandiktan sonra acilacak - kolon adi surume gore
       degisiyor (external_ids / relationships / ids).
*/
by_external_id as (

    select
        o.organisation,
        o.org_id,
        cast(null as string)    as ror_id,
        cast(null as string)    as canonical_name,
        cast(null as array<string>) as ror_types,
        cast(null as string)    as ror_country_code,
        'EXTERNAL_ID'           as resolution_method,
        0.95                    as resolution_confidence
    from employment_orgs o
    where false     -- TODO: ROR external_ids semasi netlesince ac

),

-- YOL 3: isim eslestirme (kimlik yoksa; organisation_name %100 dolu)
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
    select * from by_external_id
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
