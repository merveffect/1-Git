with ror_raw as (
Select
    raw.id as ror_id,
    (
        select n.value
        from unnest(raw.names) as n
        where 'ror_display' in unnest(n.types)
        limit 1
    ) as ror_display_name,
    (
        select loc.geonames_details.country_code
        from unnest(raw.locations) as loc
        limit 1
    ) as ror_country_iso,
    (
        select loc.geonames_details.country_name
        from unnest(raw.locations) as loc
        limit 1
    ) as ror_country_name,
    raw.domains
from {{ ref('raw_ror_data') }} as raw

)

select
    ror_raw.ror_id,
    ror_raw.ror_display_name,
    ror_raw.ror_country_iso,
    iso.country_name as ror_country_name,     
    ror_raw.domains
from ror_raw
left join {{ ref('stg_iso_country_name') }} iso
    on upper(trim(ror_raw.ror_country_iso)) = upper(trim(iso.iso_code))