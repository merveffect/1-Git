with ror_data as (

    select
        id,
        names,
        locations
    from {{ source('prod_institution_disambiguation_raw', 'raw_ror_data') }}

)

select
    id,
    names,
    locations
from ror_data
