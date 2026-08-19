-- take from history table and check if the source is still valid in the current source tables
-- if not, then we should remove them from the enriched audience table

with history_latest as (
    select *
    from {{ ref('int_institution_enriched_history') }}
),

current_authors as (
    select distinct author_email
    from {{ ref('raw_authors_institutions') }}
),

current_crp_researcher as (
    select distinct researcher_id
    from {{ ref('raw_crp_institutions') }}
),

current_crp_snid as (
    select distinct snid
    from {{ ref('raw_crp_institutions_by_snid') }}
)

select h.*
from history_latest h
left join current_authors ca on h.email = ca.author_email
left join current_crp_researcher ccr on h.researcher_id = ccr.researcher_id
left join current_crp_snid ccs on h.snid = ccs.snid
where
    -- IF h.enrichment_source is not Authors/CRP → keep
    h.enrichment_source not in ('Authors', 'CRP_by_researcher_id', 'CRP_by_snid')
    -- IF Authors → must be in current Authors
    or (h.enrichment_source = 'Authors' and ca.author_email is not null)
    -- IF CRP_researcher → must be in current CRP_researcher
    or (h.enrichment_source = 'CRP_by_researcher_id' and ccr.researcher_id is not null)
    -- IF CRP_snid → must be in current CRP_snid
    or (h.enrichment_source = 'CRP_by_snid' and ccs.snid is not null)
qualify row_number() over (
    partition by lower(h.email)
    order by
        case h.enrichment_source
            when 'EBM' then 1
            when 'Authors' then 2
            when 'CRP_by_researcher_id' then 3
            when 'CRP_by_snid' then 4
            when 'Domain_ROR_match' then 5
            when 'WIKIDATA_ROR_NAME' then 6
        end,
        h.enrichment_timestamp desc,
        h.canonical_segment_id
) = 1
