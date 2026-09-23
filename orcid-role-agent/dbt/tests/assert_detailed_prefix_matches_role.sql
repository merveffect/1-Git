/*
    role_detailed_inferred[i] her zaman role_inferred[i] ile BASLAMALI.
    Dizi siralamalari kaymissa bu test yakalar.
*/

select
    snid,
    r.role      as role_inferred,
    r.detailed  as role_detailed_inferred
from {{ ref('fct_braze_contact_roles') }},
unnest(
    array(
        select as struct
            role_inferred[offset(i)]          as role,
            role_detailed_inferred[offset(i)] as detailed
        from unnest(generate_array(0, array_length(role_inferred) - 1)) as i
    )
) as r
where not starts_with(r.detailed, r.role)
