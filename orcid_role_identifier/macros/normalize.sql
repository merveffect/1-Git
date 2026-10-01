{#-
    TEXT NORMALISATION
    ------------------
    Job titles, organisation names and department names all go through
    the same pipeline. This file is the single source of truth - never
    write a bare LOWER()/TRIM() inside a model.
-#}

{#- Unicode-fold, lowercase, strip punctuation, collapse whitespace -#}
{% macro clean_text(col) %}
    NULLIF(
        TRIM(
            REGEXP_REPLACE(
                REGEXP_REPLACE(
                    LOWER(NORMALIZE_AND_CASEFOLD(COALESCE({{ col }}, ''), NFKC)),
                    r'[^\p{L}\p{N}\s&/+-]', ' '
                ),
                r'\s+', ' '
            )
        ),
        ''
    )
{% endmacro %}


{#- Builds a nested REGEXP_REPLACE chain from vars.abbreviations -#}
{% macro expand_abbreviations(col) %}
    {%- set expr = col -%}
    {%- for a in var('abbreviations', []) -%}
        {%- set expr = "REGEXP_REPLACE(" ~ expr ~ ", r'" ~ a['from'] ~ "', '" ~ a['to'] ~ "')" -%}
    {%- endfor -%}
    {{ expr }}
{% endmacro %}


{#- Full pipeline: clean -> expand abbreviations -> collapse again -#}
{% macro normalize_title(col) %}
    NULLIF(TRIM(REGEXP_REPLACE(
        {{ expand_abbreviations(clean_text(col)) }},
        r'\s+', ' '
    )), '')
{% endmacro %}
