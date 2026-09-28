{#-
    VERTEX AI SARMALAYICILARI
    -------------------------
    Model adi / connection sadece dbt_project.yml'de durur.
    Model degistirmek = tek satir var degisikligi.
-#}

{#- Bir kolonu embed eder. Girdi CTE'sinde kolon adi 'content' OLMALI. -#}
{% macro generate_embedding(source_relation, content_col='content') %}
    SELECT
        *,
        ml_generate_embedding_result AS embedding
    FROM ML.GENERATE_EMBEDDING(
        MODEL `{{ var('gcp_project') }}.{{ target.schema }}.{{ embedding_model_name() }}`,
        (SELECT *, {{ content_col }} AS content FROM {{ source_relation }}),
        STRUCT(TRUE AS flatten_json_output, 'SEMANTIC_SIMILARITY' AS task_type)
    )
{% endmacro %}


{% macro embedding_model_name() %}
    {{ return('remote_' ~ var('embedding_model') | replace('-', '_')) }}
{% endmacro %}


{% macro judge_model_name() %}
    {{ return('remote_' ~ var('judge_model') | replace('-', '_') | replace('.', '_')) }}
{% endmacro %}


{#-
    LLM HAKEM CAGRISI - IKI YOL

    BigQuery'de LLM cagirmanin iki yolu var ve ikisi de AYNI Vertex
    baglantisini kullanir. Fark sadece SQL sozdiziminde:

      'ai_generate_bool'  AI.GENERATE_BOOL(...)  - skaler, sade
                          yeni fonksiyon, bolge destegi degisken

      'ml_generate_text'  ML.GENERATE_TEXT(...)  - tablo fonksiyonu
                          eski ve her yerde calisir, guvenli liman

    Hangisinin calistigini setup/03_test_access.sql ile test et,
    sonucu dbt_project.yml -> judge_function'a yaz.

    Iki yol da (title_key, role_key, judge_accepted, judge_status)
    donduruyor - modeller farki gormuyor.
-#}

{% macro judge_titles(source_relation, prompt_col='judge_prompt') %}

{%- set fn = var('judge_function', 'ai_generate_bool') -%}

{%- if fn == 'ai_generate_bool' -%}

    select
        *,
        judge_struct.result     as judge_accepted,
        judge_struct.status     as judge_status
    from (
        select
            *,
            AI.GENERATE_BOOL(
                {{ prompt_col }},
                connection_id => '{{ var("vertex_connection") }}',
                endpoint      => '{{ var("judge_model") }}'
            )                   as judge_struct
        from {{ source_relation }}
    )

{%- elif fn == 'ml_generate_text' -%}

    select
        * except (ml_generate_text_llm_result, ml_generate_text_status),
        -- model 'YES' / 'NO' donuyor; bool'a cevir
        upper(trim(ml_generate_text_llm_result)) like 'YES%'  as judge_accepted,
        nullif(ml_generate_text_status, '')                   as judge_status
    from ML.GENERATE_TEXT(
        MODEL `{{ var('gcp_project') }}.{{ target.schema }}.{{ judge_model_name() }}`,
        (select *, {{ prompt_col }} as prompt from {{ source_relation }}),
        STRUCT(
            0.0   AS temperature,      -- deterministik olsun
            8     AS max_output_tokens,
            TRUE  AS flatten_json_output
        )
    )

{%- else -%}
    {{ exceptions.raise_compiler_error("Bilinmeyen judge_function: " ~ fn) }}
{%- endif -%}

{% endmacro %}
