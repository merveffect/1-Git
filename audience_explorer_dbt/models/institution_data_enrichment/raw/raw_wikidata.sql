select
ror_id, 
institution_name,
website
from {{ source('WikiData', 'wikidata_first_50K') }}