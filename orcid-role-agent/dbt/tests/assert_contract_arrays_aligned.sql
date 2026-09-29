/*
    THE MOST IMPORTANT TEST IN THE CONTRACT.

    The four arrays must stay positionally aligned. If they drift, Braze
    cannot detect it - the wrong person lands in the wrong role segment
    and nobody notices. This test catches drift at build time.

    The test FAILS if any row is returned.
*/

select
    snid,
    array_length(role_inferred)                             as n_role,
    array_length(role_detailed_inferred)                    as n_detailed,
    array_length(role_inferred_data_source)                 as n_source,
    array_length(role_inferred_data_source_last_updated)    as n_updated
from {{ ref('fct_braze_contact_roles') }}
where array_length(role_inferred) != array_length(role_detailed_inferred)
   or array_length(role_inferred) != array_length(role_inferred_data_source)
   or array_length(role_inferred) != array_length(role_inferred_data_source_last_updated)
   or array_length(role_inferred) = 0
