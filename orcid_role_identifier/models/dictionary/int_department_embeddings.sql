{{ config(
    materialized     = 'incremental',
    unique_key       = 'department_key',
    on_schema_change = 'append_new_columns'
) }}

/*
    Every distinct department embedded once, with the same model as the
    titles and the anchors. A different model would make the similarity
    scores meaningless.
*/

with to_embed as (

    select department_key, department, frequency
    from {{ ref('int_department_distinct') }}

    {% if is_incremental() %}
    where department_key not in (select department_key from {{ this }})
    {% endif %}

)

select
    department_key,
    department,
    frequency,
    ml_generate_embedding_result    as embedding,
    '{{ var("embedding_model") }}'  as model_name,
    current_timestamp()             as embedded_at
from ml.generate_embedding(
    model `{{ var('embedding_model') }}`,
    (select department_key, department, frequency, department as content from to_embed)
)
where array_length(ml_generate_embedding_result) > 0
