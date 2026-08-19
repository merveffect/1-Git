-- Final enrichment output for CDI / downstream systems.
-- Latest enrichment record per EMAIL from the append-only history.
--
-- Deduplicated by lowercased email (not canonical_segment_id) because
-- canonical_segment_id in audience_builder_big can change over time (identity
-- resolution), so the append-only history accumulates old and new segment ids
-- for the same person. Email is the stable person key here.
--
-- When one email has multiple records, we keep the most reliable enrichment
-- source (EBM > Authors > CRP > Domain > WikiData), then the most recent record.
-- Users enriched in any past run remain here even after their institution is
-- populated in the CDP (they leave the base model but stay in history).

select
    lower(email) as email,
    canonical_segment_id,
    researcher_id,
    snid,
    original_raw_name,
    enrichment_source,
    standardized_institution_name,
    ror_id,
    ror_country,
    enrichment_timestamp
from {{ ref('int_institution_enriched_valid') }}
where email is not null
  and trim(email) != ''
qualify row_number() over (
    partition by lower(email)
    order by
        case enrichment_source
            when 'EBM' then 1
            when 'Authors' then 2
            when 'CRP_by_researcher_id' then 3
            when 'CRP_by_snid' then 4
            when 'Domain_ROR_match' then 5
            when 'WIKIDATA_ROR_NAME' then 6
        end,
        enrichment_timestamp desc
) = 1