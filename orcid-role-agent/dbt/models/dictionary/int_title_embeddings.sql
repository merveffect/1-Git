{{ config(
    materialized = 'incremental',
    unique_key   = 'title_key',
    on_schema_change = 'append_new_columns'
) }}

/*
    SOZLUGUN 3. ADIMI - EMBEDDING
    Her benzersiz unvan BIR KEZ embed edilir.

    incremental: yeni ORCID verisi geldiginde sadece YENI unvanlar
    embed edilir. Eski 50.000 unvan tekrar para harcatmaz.
*/

with titles_to_embed as (

    select title_key, title, frequency
    from {{ ref('int_title_distinct') }}

    {% if is_incremental() %}
    where title_key not in (select title_key from {{ this }})
    {% endif %}

)

select
    title_key,
    title,
    frequency,
    ml_generate_embedding_result    as embedding,
    ml_generate_embedding_status    as embedding_status,
    current_timestamp()             as embedded_at
from ml.generate_embedding(
    model `{{ var('gcp_project') }}.{{ target.schema }}.{{ embedding_model_name() }}`,
    (select *, title as content from titles_to_embed),
    struct(true as flatten_json_output, 'SEMANTIC_SIMILARITY' as task_type)
)
