{#-
    VERTEX AI WRAPPERS
    ------------------
    Model names and connections live only in dbt_project.yml.
    Switching models is a one-line var change.
-#}

{% macro judge_model_name() %}
    {{ return('remote_' ~ var('judge_model') | replace('-', '_') | replace('.', '_')) }}
{% endmacro %}


{#-
    LLM JUDGE - TWO ROUTES

    There are two ways to call an LLM from BigQuery and both use the
    SAME Vertex connection. Only the SQL syntax differs:

      'ai_generate_bool'  AI.GENERATE_BOOL(...)  scalar, concise,
                          newer function, regional support varies

      'ml_generate_text'  ML.GENERATE_TEXT(...)  table function,
                          older and available everywhere (safe harbour)

    Run setup/03_test_access.sql to find out which one works here, then
    set dbt_project.yml -> judge_function accordingly.

    Both routes return (title_key, role_key, judge_accepted,
    judge_status), so models never see the difference.
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
        -- the model answers 'YES' / 'NO'; cast to bool
        upper(trim(ml_generate_text_llm_result)) like 'YES%'  as judge_accepted,
        nullif(ml_generate_text_status, '')                   as judge_status
    from ML.GENERATE_TEXT(
        MODEL `{{ var('target_project') }}.{{ target.schema }}.{{ judge_model_name() }}`,
        (select *, {{ prompt_col }} as prompt from {{ source_relation }}),
        STRUCT(
            0.0   AS temperature,      -- deterministic
            8     AS max_output_tokens,
            TRUE  AS flatten_json_output
        )
    )

{%- else -%}
    {{ exceptions.raise_compiler_error("Unknown judge_function: " ~ fn) }}
{%- endif -%}

{% endmacro %}
