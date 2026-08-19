-- Enrichment sources registry. New source = add one entry to the list.
{% set enrichment_sources = [
    {'cte': 'ebm_enriched',           'model': 'stg_ror_ebm_enrichment_targets',    'priority': 1},
    {'cte': 'vector_enriched',        'model': 'stg_ror_vector_enriched_targets',    'priority': 2},
    {'cte': 'domain_enriched',        'model': 'stg_ror_domain_fallback_targets',    'priority': 3},
    {'cte': 'wikidata_ror_enriched',  'model': 'stg_wikidata_fallback_targets',      'priority': 4},
] %}

with

{% for src in enrichment_sources %}
{{ src.cte }} as (
    select
        email,
        canonical_segment_id,
        researcher_id,
        snid,
        raw_inst_name,
        enrichment_source,
        standardized_institution_name,
        ror_id,
        ror_country,
        {{ src.priority }} as priority
    from {{ ref(src.model) }}
),
{% endfor %}

unioned as (
    {% for src in enrichment_sources %}
    select * from {{ src.cte }}
    {{ 'union all' if not loop.last }}
    {% endfor %}
)

select
    email,
    canonical_segment_id,
    researcher_id,
    snid,
    raw_inst_name as original_raw_name,
    enrichment_source,
    standardized_institution_name,
    ror_id,
    ror_country
from unioned
qualify row_number() over (
    partition by lower(email)
    order by priority, canonical_segment_id
) = 1
