{#-
    SOURCE REGISTRY
    ---------------
    Sources that carry role information. The ONLY guaranteed fields are
    snid + role_title. Everything else is optional: if a source does not
    carry a field it is emitted as NULL and that source's scoring weights
    are renormalised.
-#}

{#- Common schema: the columns produced for every source, with types -#}
{% macro role_record_schema() %}
    {{ return([
        {'name': 'role_title_raw',      'type': 'string',    'required': false},
        {'name': 'organisation_raw',    'type': 'string',    'provides': 'organisation'},
        {'name': 'organisation',        'type': 'string',    'provides': 'organisation'},
        {'name': 'department_raw',      'type': 'string',    'provides': 'department'},
        {'name': 'department',          'type': 'string',    'provides': 'department'},
        {'name': 'org_id',              'type': 'string',    'provides': 'org_id'},
        {'name': 'org_id_source',       'type': 'string',    'provides': 'org_id'},
        {'name': 'country_code',        'type': 'string',    'provides': 'country_code'},
        {'name': 'start_date',          'type': 'date',      'provides': 'dates'},
        {'name': 'end_date',            'type': 'date',      'provides': 'dates'},
        {'name': 'ordering',            'type': 'int64',     'provides': 'dates'},
        {'name': 'source_last_updated', 'type': 'timestamp', 'required': false}
    ]) }}
{% endmacro %}


{% macro source_keys() %}
    {{ return(var('sources').keys() | list | sort) }}
{% endmacro %}


{% macro source_config(key) %}
    {%- set s = var('sources').get(key) -%}
    {%- if s is none -%}
        {{ exceptions.raise_compiler_error("Unknown source: " ~ key) }}
    {%- endif -%}
    {{ return(s) }}
{% endmacro %}


{% macro source_provides(key) %}
    {{ return(source_config(key).get('provides', [])) }}
{% endmacro %}


{#-
    A source's SELECT block mapped onto the common schema.
    Fields the source does not carry are emitted as typed NULLs, so the
    UNION ALL works and the source model is not required to have them.
-#}
{% macro role_record_select(key) %}
    {%- set cfg = source_config(key) -%}
    {%- set has = source_provides(key) -%}

    select
        '{{ key }}'                                     as source_key,
        snid,
        role_title,
        {%- for col in role_record_schema() %}
        {%- set needs = col.get('provides') %}
        {%- if needs is none or needs in has %}
        {{ col.name }}{{ "," if not loop.last }}
        {%- else %}
        cast(null as {{ col.type }}) as {{ col.name }}{{ "," if not loop.last }}
        {%- endif %}
        {%- endfor %}
    from {{ ref(cfg.staging_model) }}
    where snid is not null
      and role_title is not null
{% endmacro %}


{#-
    Currency rule: a source with no dates is treated as current.
    (Web scraping reads today's page - current by definition.)
-#}
{% macro is_current_expr(key) %}
    {%- if 'dates' in source_provides(key) -%}
        end_date is null
    {%- else -%}
        true
    {%- endif -%}
{% endmacro %}
