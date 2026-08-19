{{ config(
    materialized='incremental',
    full_refresh=False,
    partition_by={
        'field': 'enrichment_timestamp',
        'data_type': 'timestamp',
        'granularity': 'day'
    },
    tags=['institution_enrichment', 'institution_history']
) }}

-- Append-only enrichment history.
-- A new row is added only for a new user, or when their institution enrichment
-- changes (institution name, ROR id, or enrichment source). Nothing is ever
-- removed, so users enriched in the past remain here even after their institution
-- is populated in the CDP and they drop out of the base model.
-- full_refresh is disabled so past enrichments can never be wiped by accident.

with final_records as (

    select
        email,
        canonical_segment_id,
        researcher_id,
        snid,
        original_raw_name,
        enrichment_source,
        standardized_institution_name,
        ror_id,
        ror_country,
        current_timestamp() as enrichment_timestamp
    from {{ ref('int_institution_enriched_audience_base') }}

)

select final.*
from final_records as final

{% if is_incremental() %}
-- change detection against each user's latest existing record
left join (
    select *
    from {{ this }}
    qualify row_number() over (
        partition by canonical_segment_id
        order by enrichment_timestamp desc
    ) = 1
) as last_record
    on final.canonical_segment_id = last_record.canonical_segment_id

where
    last_record.canonical_segment_id is null
    or coalesce(final.standardized_institution_name, '__NULL__')
       != coalesce(last_record.standardized_institution_name, '__NULL__')
    or coalesce(final.ror_id, '__NULL__')
       != coalesce(last_record.ror_id, '__NULL__')
    or coalesce(final.enrichment_source, '__NULL__')
       != coalesce(last_record.enrichment_source, '__NULL__')
{% endif %}
