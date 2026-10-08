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


{#- Title groups that support a role, as a SQL IN list -#}
{% macro role_title_groups(role_key) %}
    {{ return(role(role_key).get('title_groups', [])) }}
{% endmacro %}


{#- Disciplines that support a role. Empty means "any field". -#}
{% macro role_disciplines(role_key) %}
    {{ return(role(role_key).get('disciplines', [])) }}
{% endmacro %}


{#-
    Does this role care about the discipline at all?
    researcher, lecturer and faculty_head do not - that is what
    "all fields" means, and their dept weight is 0 to match.
-#}
{% macro role_is_field_agnostic(role_key) %}
    {{ return(role_disciplines(role_key) | length == 0) }}
{% endmacro %}


{#-
    How the two axes combine for this role.

      'any'  (the default) - the TITLE or the DISCIPLINE is enough. A wide
             net. Everything built before 2026-10-08 behaves this way.
      'all'  - BOTH must match. A record with a clinical department and no
             title does not qualify, and neither does a researcher title
             with no clinical department.
      'title' - the TITLE is required and the discipline is optional. A
             record with no matching title cannot enter the role at all;
             a matching discipline only adds score. This is the rule for
             any role where the occupation IS the title - nobody becomes
             a pharmacist by working in a pharmacy department.

    'all' exists because 'any' cannot express a precise role. Give
    hcp_researcher the researcher title groups and the health_clinical
    discipline under 'any' and the title arm alone admits every researcher
    on earth - a physics postdoc scores 0.35 + 0.25*org and confirms with
    no clinical signal at all. That is the exact mistake the Phase-1 regex
    made, and 'all' is what forbids it.

    The cost of 'all' is deliberate: it drops everyone missing either
    field. hcp_broad keeps the wide net, so nobody is lost from the
    audience as a whole - they just do not enter a precise sub-role.
-#}
{% macro role_match_mode(role_key) %}
    {{ return(role(role_key).get('match', 'any')) }}
{% endmacro %}
