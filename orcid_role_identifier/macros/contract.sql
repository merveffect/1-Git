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


{#- contract.consent_basis -> WHERE predicate -#}
{% macro consent_predicate() %}
    {%- set basis = var('contract').consent_basis -%}
    {%- if basis == 'marketing_opt_in' -%}
        is_marketable
    {%- elif basis == 'legitimate_interest' -%}
        in_cdp
    {%- elif basis == 'both' -%}
        in_cdp
    {%- else -%}
        {{ exceptions.raise_compiler_error("Unknown consent_basis: " ~ basis) }}
    {%- endif -%}
{% endmacro %}
