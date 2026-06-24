With researcher_profiles as (

    select
        researcher_id,
        trim(current_institute_name)  as raw_inst_name,
        current_grid_country          as country_name,
        current_grid_country_code     as country_iso
    from {{ source('core_researcher_profiles', 'researcher_profiles_out') }}
    where current_institute_name is not null
      and trim(current_institute_name) != ''
      and researcher_id is not null

)

select
    researcher_id,
    raw_inst_name,
    country_name,
    country_iso
from researcher_profiles
where raw_inst_name is not null
    and trim(raw_inst_name) != ''
    and raw_inst_name not like '%&#%'
    and raw_inst_name not like '%&amp;%'
    and raw_inst_name not like '%&lt;%'
    and raw_inst_name not like '%&gt;%'
