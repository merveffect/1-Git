-- EBM (individual) deterministic enrichment for ROR pipeline:
-- snid + latest affiliation -> institution_ror_id -> stg_ror name.
with individual_flat as (

    select
        c.snid,
        a.institution_ror_id,
        a.affiliation_start_date
    from {{ source('yy_editor_data', 'individual') }},
    unnest(individual_contact)     as c,
    unnest(individual_affiliation) as a
    where c.snid is not null and trim(c.snid) != ''
      and a.institution_ror_id is not null and trim(a.institution_ror_id) != ''

),

-- pick latest affiliation per snid (by start date)
latest_affiliation as (

    select
        snid,
        institution_ror_id
    from individual_flat
    qualify row_number() over (
        partition by snid
        order by affiliation_start_date desc
    ) = 1

)

select
    la.snid,
    la.institution_ror_id       as ror_id,
    r.ror_display_name          as standardized_institution_name,
    r.ror_country_name          as ror_country,
    'EBM' as enrichment_source
from latest_affiliation la
inner join {{ ref('stg_ror') }} r
    on la.institution_ror_id = r.ror_id