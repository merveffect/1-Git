-- Enrichment sources registry. New source = add one entry to the list.
{% set enrichment_sources = [
    {'cte': 'ebm_enriched',           'model': 'stg_ror_ebm_enrichment_targets',    'priority': 1},
    {'cte': 'vector_enriched',        'model': 'stg_ror_vector_enriched_targets',    'priority': 2},
    {'cte': 'domain_enriched',        'model': 'stg_ror_domain_fallback_targets',    'priority': 3},
    {'cte': 'wikidata_ror_enriched',  'model': 'stg_wikidata_fallback_targets',      'priority': 4},
    {'cte': 'wikidata_name_enriched', 'model': 'stg_wikidata_names_fallback_targets','priority': 5},
] %}

with

{% for src in enrichment_sources %}
{{ src.cte }} as (
    select
        canonical_segment_id,
        email,
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
    canonical_segment_id,
    email,
    researcher_id,
    snid,
    raw_inst_name as original_raw_name,
    enrichment_source,
    standardized_institution_name,
    ror_id,
    ror_country
from unioned
qualify row_number() over (
    partition by canonical_segment_id
    order by priority
) = 1