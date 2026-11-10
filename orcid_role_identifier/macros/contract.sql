{#-
    BRAZE DATA CONTRACT HELPERS
    ---------------------------
    role_inferred / role_detailed_inferred / role_inferred_data_source /
    ..._last_updated must stay POSITIONALLY aligned.

    That is why all four are derived from ONE ordered source. Writing
    four independent ARRAY_AGGs would silently drift - the single
    biggest risk in this contract.
-#}

{#- role_key -> the display name used in the contract -#}
{% macro role_display_name_expr(col='role_key') %}
    CASE {{ col }}
    {%- for k in role_keys() %}
        WHEN '{{ k }}' THEN '{{ role(k).display_name }}'
    {%- endfor %}
        ELSE {{ col }}
    END
{% endmacro %}


{#- role_key -> detail dimension ('bucket' | 'setting' | 'org_type' | 'none') -#}
{% macro role_detail_dimension_expr(col='role_key') %}
    CASE {{ col }}
    {%- for k in role_keys() %}
        WHEN '{{ k }}' THEN '{{ role(k).get("detail_dimension", "none") }}'
    {%- endfor %}
        ELSE 'none'
    END
{% endmacro %}


{#-
    Array ordering key. All four arrays MUST use this same ORDER BY.
    contract.array_order: 'alphabetical' | 'score'
-#}
{% macro contract_array_order() %}
    {%- if var('contract').array_order == 'score' -%}
        role_final_score DESC, role_inferred ASC
    {%- else -%}
        role_inferred ASC
    {%- endif -%}
{% endmacro %}


{#-
    contract.consent_basis -> the WHERE predicate that decides who is in
    the delivered table.

    'any_basis' is the setting from 2026-10-16: a person qualifies if ANY
    of the three flags is true. Two of them are explicit opt-ins and the
    third is processing under legitimate interest where the author has not
    objected. They are three separate legal bases, so requiring all of
    them, or only one of them, would both be wrong.

    The older settings are kept because they are stricter, not because
    they are better. Note what 'legitimate_interest' used to mean here:
    in_cdp, which claimed that legal basis from CDP membership alone.
    There is now an explicit flag for it, so it reads that instead.
-#}
{% macro consent_predicate() %}
    {%- set basis = var('contract').consent_basis -%}
    {%- if basis == 'any_basis' -%}
        (is_marketable or is_advertisable or is_legitimate_interest)
    {%- elif basis == 'marketing_opt_in' -%}
        is_marketable
    {%- elif basis == 'any_opt_in' -%}
        (is_marketable or is_advertisable)
    {%- elif basis == 'legitimate_interest' -%}
        is_legitimate_interest
    {%- else -%}
        {{ exceptions.raise_compiler_error("Unknown consent_basis: " ~ basis) }}
    {%- endif -%}
{% endmacro %}
