-- Raw EBM individual data passthrough from source.
select
    individual_contact,
    individual_affiliation
from {{ source('yy_editor_data', 'individual') }}