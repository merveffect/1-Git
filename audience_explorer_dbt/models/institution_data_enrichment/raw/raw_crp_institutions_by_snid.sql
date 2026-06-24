-- snid -> mapping for institution name and country, as a fallback when email and researcher_id based matching doesn't work.

with researcher_profiles as (

    select
        researcher_id,
        trim(current_institute_name)  as raw_inst_name,
        current_grid_country          as country_name,
        current_grid_country_code     as country_iso,
        snids
    from {{ source('core_researcher_profiles', 'researcher_profiles_out') }}
    where current_institute_name is not null
      and trim(current_institute_name) != ''

),

exploded as (

    select
        snid_struct.snid as snid,   
        rp.raw_inst_name,
        rp.country_name,
        rp.country_iso,
        rp.researcher_id
    from researcher_profiles rp,
        unnest(rp.snids) as snid_struct

)

select
    snid,
    raw_inst_name,
    country_name,
    country_iso
from exploded
where raw_inst_name is not null
    and trim(raw_inst_name) != ''
    and raw_inst_name not like '%&#%'
    and raw_inst_name not like '%&amp;%'
    and raw_inst_name not like '%&lt;%'
    and raw_inst_name not like '%&gt;%'
qualify row_number() over (
    partition by snid          
    order by researcher_id
) = 1