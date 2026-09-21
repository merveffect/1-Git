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
    LLM hakem cagrisi. Prompt'u cagiran model kurar.
    Cikti kolonu: judge_result (BOOL), judge_status (STRING)
-#}
{% macro ai_generate_bool(prompt_expr) %}
    AI.GENERATE_BOOL(
        {{ prompt_expr }},
        connection_id => '{{ var("vertex_connection") }}',
        endpoint      => '{{ var("judge_model") }}'
    )
{% endmacro %}
