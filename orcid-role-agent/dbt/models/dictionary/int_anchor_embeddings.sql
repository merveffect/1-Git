{{ config(
    materialized = 'incremental',
    unique_key   = 'anchor_key'
) }}

/*
    SOZLUGUN 4. ADIMI - ANCHOR EMBEDDING'LERI
    Arama yapilacak hedef vektorler. int_title_embeddings ile AYNI modeli
    kullanmak zorunlu - farkli model = anlamsiz benzerlik skoru.
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
    model `{{ var('gcp_project') }}.{{ target.schema }}.{{ embedding_model_name() }}`,
    (select *, anchor_term as content from anchors),
    struct(true as flatten_json_output, 'SEMANTIC_SIMILARITY' as task_type)
)
