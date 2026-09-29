{{ config(
    materialized = 'incremental',
    unique_key   = 'anchor_key'
) }}

/*
    The target vectors we search against. Must use the SAME model as
    int_title_embeddings - a different model makes the similarity
    scores meaningless.
*/

with anchors as (

    select anchor_key, role_key, anchor_term, polarity, language_code
    from {{ ref('int_anchor_terms') }}

    {% if is_incremental() %}
    where anchor_key not in (select anchor_key from {{ this }})
    {% endif %}

)

select
    anchor_key,
    role_key,
    anchor_term,
    polarity,
    language_code,
    ml_generate_embedding_result    as embedding,
    current_timestamp()             as embedded_at
from ml.generate_embedding(
    model `{{ var('embedding_model') }}`,
    (select anchor_key, role_key, anchor_term, polarity, language_code,
            anchor_term as content
     from anchors)
)
