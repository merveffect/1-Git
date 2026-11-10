{#-
    TEXT NORMALISATION
    ------------------
    Job titles, organisation names and department names all go through
    the same pipeline. This file is the single source of truth - never
    write a bare LOWER()/TRIM() inside a model.
-#}

{#-
    Unicode-fold, lowercase, strip punctuation, collapse whitespace.

    HTML ENTITIES ARE DELIBERATELY NOT DECODED. MEASURED AND CLOSED
    2026-10-20, so please do not reopen it without new numbers.

    '&' is a legal character here and the semicolon is stripped, so a
    source value of 'R&amp;D Manager' normalises to 'r&amp d manager' and
    becomes a different dictionary entry from 'r&d manager'. Real, and the
    reason it is left alone is the size: analyses/22 query 9 measured 19
    affected titles carrying 1,752 records, and 2 departments carrying 42.

    Query 9a then looked for the pairs that prove a split - an escaped
    value whose decoded twin exists as its own entry - and found three.
    All three land in the SAME title group, so not one classification is
    wrong. The entire cost is a split frequency on three titles.

    Against that, decoding would change every normalised value, so every
    title_key md5 changes and the whole dictionary re-embeds; and because
    the embedding models are incremental, the old keys would stay behind
    inflating dim_title_group and every quality metric read off it, the way
    the anchor table did until 2026-10-16. It needs --full-refresh on
    int_title_embeddings and int_department_embeddings.

    IF A NORMALISATION CHANGE EVER BECOMES NECESSARY for another reason,
    add entity decoding to that same rebuild. The expensive part is the
    rebuild, not the change, so it should never be paid twice.
-#}
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
