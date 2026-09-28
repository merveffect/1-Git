{{ config(
    materialized     = 'incremental',
    unique_key       = 'title_key',
    on_schema_change = 'append_new_columns'
) }}

/*
    Her benzersiz unvan BIR KEZ embed edilir.

    Mevcut remote model kullaniliyor (baska projede kurulu):
        {{ var('embedding_model') }}
    Yeni Vertex baglantisi kurmaya gerek yok - sadece o proje uzerinde
    okuma izni gerekiyor.

    incremental: yeni veri geldiginde sadece YENI unvanlar embed edilir.
    Mevcut unvanlar tekrar para harcatmaz.
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
