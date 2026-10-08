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
    How a record gets INTO a role. Two axes exist: the TITLE
    (employments[].role) and the FIELD (employments[].department_name).

      'title_required'   (the default) the title is required, the field
                         is optional and only adds score. No matching
                         title, no entry.
      'title_and_field'  both required.
      'title_or_field'   either is enough. A deliberately wide net.

    Why there are three, since two would be simpler:

      title_required is the rule for any role where the occupation IS the
      title. Nobody becomes a pharmacist by working in a pharmacy
      department, and under title_or_field they did - 86% of that role's
      population had no pharmacist title. It is the default because it is
      the right answer for most roles.

      title_and_field exists because title_or_field cannot express a
      precise role. Give hcp_researcher the researcher title groups and
      the health_clinical field under 'or' and the title arm alone admits
      every researcher on earth: a physics postdoc scores 0.35 + 0.25*org
      and confirms with no clinical signal at all. That is the exact
      mistake the Phase-1 regex made, on 191 physics postdocs.

      title_or_field is for one role only, hcp_broad, whose job is to be
      the wide net so that nobody clinical is lost from the audience as a
      whole. Its three precise children roll up into it.

    Every role sets this explicitly, so nobody has to know the default.
    Note that for a role with no fields listed the mode cannot change
    anything - there is no field arm to combine - which is why the three
    field-agnostic roles say title_required rather than implying a choice
    they do not have.
-#}
{% macro role_match_mode(role_key) %}
    {{ return(role(role_key).get('match', 'title_required')) }}
{% endmacro %}
