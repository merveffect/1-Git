{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='ror_id',
        on_schema_change='append_new_columns'
    )
}}



with ror_raw as (

    select
        raw.id                                          as ror_id,
        (
            select n.value
            from unnest(raw.names) as n
            where 'ror_display' in unnest(n.types)
            limit 1
        )                                               as ror_display_name,

        (
            select loc.geonames_details.country_code
            from unnest(raw.locations) as loc
            limit 1
        )                                               as ror_country_iso,

        (
            select loc.geonames_details.country_name
            from unnest(raw.locations) as loc
            limit 1
        )                                               as ror_country_name
    from {{ ref('raw_ror_data') }} as raw

),

ror_mapped as (
    select
        ror_raw.ror_id,
        ror_raw.ror_display_name,
        ror_raw.ror_country_iso,
        iso.country_name                                as ror_country_name_std
    from ror_raw
    left join {{ ref('stg_iso_country_name') }} as iso
        on ror_raw.ror_country_iso = iso.iso_code
),

ror_prepared as (

    select
        ror_mapped.ror_id,
        ror_mapped.ror_display_name,
        ror_mapped.ror_country_iso,
        ror_mapped.ror_country_name_std as ror_country_name,
        if(
            ror_mapped.ror_country_name_std is null,
            ror_mapped.ror_display_name,
            concat(ror_mapped.ror_display_name, ', ', ror_mapped.ror_country_name_std)
        )                                               as content
    from ror_mapped
    where ror_mapped.ror_display_name is not null

),

ror_new as (

    select
        ror_prepared.ror_id,
        ror_prepared.ror_display_name,
        ror_prepared.ror_country_iso,
        ror_prepared.ror_country_name,
        ror_prepared.content
    from ror_prepared

    {% if is_incremental() %}
    where ror_prepared.ror_id not in (select existing.ror_id from {{ this }} as existing)
    {% endif %}

),

embedded as (

    select
        ror_id,
        ror_display_name,
        ror_country_iso,
        ror_country_name,
        content,
        ml_generate_embedding_result                as embedding,
        ml_generate_embedding_status                as embedding_status
    from ml.generate_embedding(
        model `datasn-rm-live.institution_disambiguation.embedding_model`,
        (
            select
                ror_new.ror_id,
                ror_new.ror_display_name,
                ror_new.ror_country_iso,
                ror_new.ror_country_name,
                ror_new.content
            from ror_new
        ),
        struct(
            true                  as flatten_json_output,
            'SEMANTIC_SIMILARITY' as task_type
        )
    )

)

-- just select the rows with no embedding errors
select
    embedded.ror_id,
    embedded.ror_display_name,
    embedded.ror_country_iso,
    embedded.ror_country_name,
    embedded.content,
    embedded.embedding,
    embedded.embedding_status
from embedded
where coalesce(embedded.embedding_status, '') = ''
