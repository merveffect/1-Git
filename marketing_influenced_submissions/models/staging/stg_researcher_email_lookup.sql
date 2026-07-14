-- Researcher email lookup (aceproducts core_researcher_profiles_restricted):
-- email -> researcher_id, joined to researcher profiles for the power-author flag.

with source as (

    select * from {{ source('core_researcher_profiles_restricted', 'email_lookup') }}

)

select
    researcher_id,
    email
from source
