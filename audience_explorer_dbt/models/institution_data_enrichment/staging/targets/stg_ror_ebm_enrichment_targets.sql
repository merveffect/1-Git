-- EBM enrichment joined to CDP users (user grain).
with cdp as (

    select
        canonical_segment_id,
        email,
        researcher_id,
        snid,
        institution_name
    from {{ source('prod_audience_explorer_analytics_dbt_presentation', 'audience_builder_big') }}
    where (mkt_pref_opt_in = true or is_legitimate_interest_author_opted_in = true)
      and (institution_name is null or trim(institution_name) = '')
      and snid is not null

)

select
    cdp.email,
    cdp.canonical_segment_id,
    cdp.researcher_id,
    cdp.snid,
    cdp.institution_name         as raw_inst_name,
    ebm.enrichment_source,
    ebm.standardized_institution_name,
    ebm.ror_id,
    ebm.ror_country
from cdp
inner join {{ ref('stg_ror_ebm_enrichment') }} ebm
    on cdp.snid = ebm.snid

qualify row_number() over (
    partition by lower(cdp.email)
    order by cdp.canonical_segment_id, snid
) = 1