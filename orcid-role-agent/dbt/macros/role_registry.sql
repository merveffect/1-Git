{#-
    ROL KAYIT DEFTERI ERISIM KATMANI
    ---------------------------------
    Butun modeller rollere SADECE bu makrolar uzerinden erisir.
    dbt_project.yml disinda hicbir yerde rol adi hard-code EDILMEZ.
-#}

{% macro all_roles() %}
    {{ return(var('roles')) }}
{% endmacro %}


{% macro role(role_key) %}
    {%- set r = var('roles').get(role_key) -%}
    {%- if r is none -%}
        {{ exceptions.raise_compiler_error("Bilinmeyen rol: " ~ role_key) }}
    {%- endif -%}
    {{ return(r) }}
{% endmacro %}


{#- Aktif (enabled) rol anahtarlari, alfabetik. Tum donguler bunu kullanir. -#}
{% macro role_keys() %}
    {%- set keys = [] -%}
    {%- for k, v in var('roles').items() -%}
        {%- if v.get('enabled', true) -%}{%- do keys.append(k) -%}{%- endif -%}
    {%- endfor -%}
    {{ return(keys | sort) }}
{% endmacro %}


{#- current_only = true olan roller -#}
{% macro current_only_role_keys() %}
    {%- set keys = [] -%}
    {%- for k in role_keys() -%}
        {%- if role(k).get('current_only', false) -%}{%- do keys.append(k) -%}{%- endif -%}
    {%- endfor -%}
    {{ return(keys) }}
{% endmacro %}


{#- parent tanimli roller: (cocuk, ebeveyn, ebeveyn_bucket) uclulerı -#}
{% macro roles_with_parent() %}
    {%- set out = [] -%}
    {%- for k in role_keys() -%}
        {%- set r = role(k) -%}
        {%- if r.get('parent') and r.get('parent') in role_keys() -%}
            {%- do out.append({
                'child':  k,
                'parent': r.get('parent'),
                'bucket': r.get('parent_bucket', 'UNSPECIFIED')
            }) -%}
        {%- endif -%}
    {%- endfor -%}
    {{ return(out) }}
{% endmacro %}


{#- SQL IN (...) listesi: {{ sql_in_list(role_keys()) }} -> 'a','b','c' -#}
{% macro sql_in_list(items) %}
    {%- if items | length == 0 -%}''{%- else -%}
    {%- for i in items %}'{{ i }}'{% if not loop.last %}, {% endif %}{% endfor -%}
    {%- endif -%}
{% endmacro %}
