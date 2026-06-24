with targets as (

    select
        raw_inst_name,
        country_name,
        country_iso,
        embedding_input
    from {{ ref('stg_inst_enrichment_targets') }}
    where embedding_input is not null

),

ranked as (

    select
        raw_inst_name as inst_name,
        country_name,
        country_iso,
        embedding_input,
        row_number() over (
            partition by embedding_input
            order by country_name desc nulls last
        ) as rn
    from targets

)

select
    inst_name,
    country_name,
    country_iso,
    embedding_input
from ranked
where rn = 1
