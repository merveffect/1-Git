-- Is enriched user still valid in the source tables (JSD +CRP) or not?
-- If not, then we should remove them from the enriched audience table

{{ config(severity='warn') }}

with final as (
    select
        email,
        researcher_id,
        snid,
        enrichment_source
    from {{ ref('institution_enriched_audience') }}
    where enrichment_source in ('Authors', 'CRP_by_researcher_id', 'CRP_by_snid')
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

select
    f.email,
    f.enrichment_source
from final f
left join current_authors ca on f.email = ca.author_email
left join current_crp_researcher ccr on f.researcher_id = ccr.researcher_id
left join current_crp_snid ccs on f.snid = ccs.snid
where
    (f.enrichment_source = 'Authors' and ca.author_email is null)
    or (f.enrichment_source = 'CRP_by_researcher_id' and ccr.researcher_id is null)
    or (f.enrichment_source = 'CRP_by_snid' and ccs.snid is null)