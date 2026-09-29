{{ config(
    materialized     = 'incremental',
    unique_key       = 'title_key',
    on_schema_change = 'append_new_columns'
) }}

/*
    Every distinct title is embedded ONCE.

    Uses the existing remote model (provisioned in another project):
        {{ var('embedding_model') }}
    No new Vertex connection is needed - only read access to that project.

    Incremental: when new data lands, only NEW titles are embedded.
    Existing titles never cost anything again.
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
    '{{ var("embedding_model") }}'  as model_name,
    current_timestamp()             as embedded_at
from ml.generate_embedding(
    model `{{ var('embedding_model') }}`,
    (select title_key, title, frequency, title as content from titles_to_embed)
)
