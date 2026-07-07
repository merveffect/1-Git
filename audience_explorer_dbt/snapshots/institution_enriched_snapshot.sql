{% snapshot institution_enriched_snapshot %}
{{
    config(
        target_schema='snapshots',
        unique_key='canonical_segment_id',
        strategy='check',
        check_cols=['standardized_institution_name', 'ror_id', 'ror_country', 'enrichment_source']
    )
}}
select * from {{ ref('institution_enriched_audience') }}
{% endsnapshot %}

