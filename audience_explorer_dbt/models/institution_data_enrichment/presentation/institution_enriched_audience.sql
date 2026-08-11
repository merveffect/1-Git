-- Final enrichment output for CDI / downstream systems.
-- Latest enrichment record per user from the append-only history.
-- Users enriched in any past run remain here even after their institution is
-- populated in the CDP (they leave the base model but stay in history).

select
    canonical_segment_id,
    email,
    researcher_id,
    snid,
    original_raw_name,
    enrichment_source,
    standardized_institution_name,
    ror_id,
    ror_country,
    enrichment_timestamp
from {{ ref('institution_enriched_history') }}
qualify row_number() over (
    partition by canonical_segment_id
    order by enrichment_timestamp desc
) = 1