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

    TWO GUARDS, both needed:
      source side  titles shorter than 2 or longer than 200 characters are
                   skipped - they normalise to junk and the model returns
                   an empty vector for them
      model side   rows whose embedding came back empty are dropped

    Without these, a single empty vector breaks the entire VECTOR_SEARCH
    run with "Array inputs are not equal in length". Measured on the real
    data before this was added.
*/

with titles_to_embed as (

    select title_key, title, frequency
    from {{ ref('int_title_distinct') }}
    where length(title) between 2 and 200

    {% if is_incremental() %}
      and title_key not in (select title_key from {{ this }})
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
where array_length(ml_generate_embedding_result) > 0
