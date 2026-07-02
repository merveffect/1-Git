With versioned as (

    select
        canonical_segment_id,
        dbt_valid_from,
        row_number() over (
            partition by canonical_segment_id
            order by dbt_valid_from
        ) as version_num
    from {{ ref('institution_enriched_snapshot') }}

)

select
    date_trunc(date(dbt_valid_from), month) as month,
    countif(version_num = 1)  as new_enriched,      -- first time enriched 
    countif(version_num > 1)  as changed,           -- changed enrichment (e.g. ROR ID changed)
    count(*)                  as total_writes       -- total (for control)
from versioned
group by month
order by month
