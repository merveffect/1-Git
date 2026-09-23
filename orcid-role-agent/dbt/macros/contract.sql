{#-
    BRAZE DATA CONTRACT YARDIMCILARI
    --------------------------------
    role_inferred / role_detailed_inferred / role_inferred_data_source /
    ..._last_updated dizileri POZISYONEL olarak hizali olmak zorunda.

    Bu yuzden dortu de TEK bir siralanmis kaynaktan turetilir. Ayri ayri
    ARRAY_AGG yapmak sessiz hizalama hatasi uretir - contract'in en buyuk
    riski budur.
-#}

{#- role_key -> contract'taki gorunen ad -#}
{% macro role_display_name_expr(col='role_key') %}
    CASE {{ col }}
    {%- for k in role_keys() %}
        WHEN '{{ k }}' THEN '{{ role(k).display_name }}'
    {%- endfor %}
        ELSE {{ col }}
    END
{% endmacro %}


{#- role_key -> detail boyutu ('bucket' | 'setting' | 'org_type' | 'none') -#}
{% macro role_detail_dimension_expr(col='role_key') %}
    CASE {{ col }}
    {%- for k in role_keys() %}
        WHEN '{{ k }}' THEN '{{ role(k).get("detail_dimension", "none") }}'
    {%- endfor %}
        ELSE 'none'
    END
{% endmacro %}


{#- kaynak anahtari -> contract'taki gorunen ad -#}
{% macro source_display_name_expr(col='role_source') %}
    CASE {{ col }}
    {%- for k, v in var('sources').items() %}
        WHEN '{{ k }}' THEN '{{ v.display_name }}'
    {%- endfor %}
        ELSE {{ col }}
    END
{% endmacro %}


{#- Aktif kaynak anahtarlari -#}
{% macro source_keys() %}
    {%- set keys = [] -%}
    {%- for k, v in var('sources').items() -%}
        {%- if v.get('enabled', true) -%}{%- do keys.append(k) -%}{%- endif -%}
    {%- endfor -%}
    {{ return(keys) }}
{% endmacro %}


{#-
    Dizi siralama anahtari. 4 dizinin de ayni ORDER BY'i kullanmasi sart.
    contract.array_order: 'alphabetical' | 'score'
-#}
{% macro contract_array_order() %}
    {%- if var('contract').array_order == 'score' -%}
        role_final_score DESC, role_inferred ASC
    {%- else -%}
        role_inferred ASC
    {%- endif -%}
{% endmacro %}


{#- contract.consent_basis -> WHERE yuklemi -#}
{% macro consent_predicate() %}
    {%- set basis = var('contract').consent_basis -%}
    {%- if basis == 'marketing_opt_in' -%}
        is_marketable
    {%- elif basis == 'legitimate_interest' -%}
        in_cdp
    {%- elif basis == 'both' -%}
        in_cdp
    {%- else -%}
        {{ exceptions.raise_compiler_error("Bilinmeyen consent_basis: " ~ basis) }}
    {%- endif -%}
{% endmacro %}
