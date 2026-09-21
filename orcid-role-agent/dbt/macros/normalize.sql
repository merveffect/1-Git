{#-
    METIN NORMALIZASYONU
    --------------------
    Unvan / kurum / departman metinleri ayni boru hattindan gecer.
    Tek kaynak: burasi. Model icinde elle LOWER()/TRIM() YAZILMAZ.
-#}

{#- Unicode katla, kucuk harf, aksan/isaret temizle, bosluklari sikistir -#}
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


{#- dbt_project.yml:vars.abbreviations listesinden ic ice REGEXP_REPLACE uretir -#}
{% macro expand_abbreviations(col) %}
    {%- set expr = col -%}
    {%- for a in var('abbreviations', []) -%}
        {%- set expr = "REGEXP_REPLACE(" ~ expr ~ ", r'" ~ a['from'] ~ "', '" ~ a['to'] ~ "')" -%}
    {%- endfor -%}
    {{ expr }}
{% endmacro %}


{#- Tam boru hatti: temizle -> kisaltmalari ac -> tekrar sikistir -#}
{% macro normalize_title(col) %}
    NULLIF(TRIM(REGEXP_REPLACE(
        {{ expand_abbreviations(clean_text(col)) }},
        r'\s+', ' '
    )), '')
{% endmacro %}
