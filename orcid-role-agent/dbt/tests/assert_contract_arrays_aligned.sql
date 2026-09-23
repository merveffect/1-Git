/*
    CONTRACT'IN EN KRITIK TESTI.

    Dort dizi pozisyonel olarak hizali olmak zorunda. Hizalama bozulursa
    Braze bunu yakalayamaz - yanlis kisi yanlis rol segmentine duser ve
    kimse fark etmez. Bu test bozulmayi build zamaninda yakalar.

    Satir donerse test BASARISIZ.
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
