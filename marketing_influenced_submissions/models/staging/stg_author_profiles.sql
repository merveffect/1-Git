-- SDM author profiles (datasn-rm-live.author_profile): corresponding-author email
-- -> author_country. Feeds int_country (submission country enrichment).

with source as (

    select * from {{ source('author_profile', 'sdm_author_profiles') }}

)

select
    author_email,
    author_country
from source
