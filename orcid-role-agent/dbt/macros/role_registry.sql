{#-
    ROLE REGISTRY ACCESS LAYER
    --------------------------
    Every model reaches roles ONLY through these macros.
    No role key is ever hard-coded outside dbt_project.yml.
-#}

{% macro all_roles() %}
    {{ return(var('roles')) }}
{% endmacro %}


{% macro role(role_key) %}
    {%- set r = var('roles').get(role_key) -%}
    {%- if r is none -%}
        {{ exceptions.raise_compiler_error("Unknown role: " ~ role_key) }}
    {%- endif -%}
    {{ return(r) }}
{% endmacro %}


{#- Enabled role keys, alphabetical. Every loop iterates over this. -#}
{% macro role_keys() %}
    {%- set keys = [] -%}
    {%- for k, v in var('roles').items() -%}
        {%- if v.get('enabled', true) -%}{%- do keys.append(k) -%}{%- endif -%}
    {%- endfor -%}
    {{ return(keys | sort) }}
{% endmacro %}


{#- Roles configured with current_only = true -#}
{% macro current_only_role_keys() %}
    {%- set keys = [] -%}
    {%- for k in role_keys() -%}
        {%- if role(k).get('current_only', false) -%}{%- do keys.append(k) -%}{%- endif -%}
    {%- endfor -%}
    {{ return(keys) }}
{% endmacro %}


{#- Roles with a parent: (child, parent, parent_bucket) triples -#}
{% macro roles_with_parent() %}
    {%- set out = [] -%}
    {%- for k in role_keys() -%}
        {%- set r = role(k) -%}
        {%- if r.get('parent') and r.get('parent') in role_keys() -%}
            {%- do out.append({
                'child':  k,
                'parent': r.get('parent'),
                'bucket': r.get('parent_bucket', 'UNSPECIFIED'),
                'bucket_label': r.get('parent_bucket', 'UNSPECIFIED')
                                 | lower | replace('_', ' ') | title
            }) -%}
        {%- endif -%}
    {%- endfor -%}
    {{ return(out) }}
{% endmacro %}


{#- SQL IN (...) list: {{ sql_in_list(role_keys()) }} -> 'a','b','c' -#}
{% macro sql_in_list(items) %}
    {%- if items | length == 0 -%}''{%- else -%}
    {%- for i in items %}'{{ i }}'{% if not loop.last %}, {% endif %}{% endfor -%}
    {%- endif -%}
{% endmacro %}
