-- assigned raw institution name: Authors (email) -> CRP (researcher_id) -> CRP (snid).

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

),

authors as (

    select
        author_email,
        raw_inst_name,
        country_iso,
        country_name
    from {{ ref('raw_authors_institutions') }}

),

crp_by_researcher as (

    select
        researcher_id,
        raw_inst_name,
        country_iso,
        country_name
    from {{ ref('raw_crp_institutions') }}

),

crp_by_snid as (

    -- snid fallback
    select
        snid,
        raw_inst_name,
        country_iso,
        country_name
    from {{ ref('raw_crp_institutions_by_snid') }}

),

resolved as (

    select
        cdp.canonical_segment_id,
        cdp.email,
        cdp.researcher_id,
        cdp.snid,

        coalesce(a.raw_inst_name, r.raw_inst_name, s.raw_inst_name) as raw_inst_name,

        case
            when a.raw_inst_name is not null then 'Authors'
            when r.raw_inst_name is not null then 'CRP by researcher id'
            when s.raw_inst_name is not null then 'CRP by snid'
        end as enrichment_source,


        case
            when a.raw_inst_name is not null then a.country_name
            when r.raw_inst_name is not null then r.country_name
            when s.raw_inst_name is not null then s.country_name
        end as country_name,

        case
            when a.raw_inst_name is not null then a.country_iso
            when r.raw_inst_name is not null then r.country_iso
            when s.raw_inst_name is not null then s.country_iso
        end as country_iso

    from cdp
    left join authors a
        on cdp.email = a.author_email
    left join crp_by_researcher r
        on cdp.researcher_id = r.researcher_id
       and cdp.researcher_id is not null
    left join crp_by_snid s
        on cdp.snid = s.snid
       and cdp.snid is not null

),

mapped as (
    select
        resolved.canonical_segment_id,
        resolved.email,
        resolved.researcher_id,
        resolved.snid,
        resolved.raw_inst_name,
        resolved.enrichment_source,
        resolved.country_iso,
        iso.country_name as country_name_std
    from resolved
    left join {{ ref('stg_iso_country_name') }} iso
        on resolved.country_iso = iso.iso_code
    where resolved.raw_inst_name is not null
        and resolved.raw_inst_name != ''
)


select
    canonical_segment_id,
    email,
    researcher_id,
    snid,
    raw_inst_name,
    enrichment_source,
    country_iso,
    nullif(country_name_std, '') as country_name,
    
    case
        when country_name_std is not null
            then concat(raw_inst_name, ', ', country_name_std)
        else raw_inst_name
    end as embedding_input
from mapped

qualify row_number() over (
    partition by canonical_segment_id
    order by email
) = 1
