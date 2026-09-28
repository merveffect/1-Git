{#-
    KAYNAK KAYIT DEFTERI
    --------------------
    Rol bilgisi tasiyan kaynaklar. TEK garanti alan: snid + role_title.
    Geri kalan her sey opsiyonel; kaynak tasimiyorsa NULL gelir ve
    o kaynagin skor agirliklari yeniden normalize edilir.
-#}

{#- Ortak sema: her kaynak icin uretilen kolonlar (tip bilgisiyle) -#}
{% macro role_record_schema() %}
    {{ return([
        {'name': 'role_title_raw',      'type': 'string',    'required': false, 'fallback': 'role_title'},
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
        {{ exceptions.raise_compiler_error("Bilinmeyen kaynak: " ~ key) }}
    {%- endif -%}
    {{ return(s) }}
{% endmacro %}


{% macro source_provides(key) %}
    {{ return(source_config(key).get('provides', [])) }}
{% endmacro %}


{#-
    Bir kaynagin ortak semaya cevrilmis SELECT blogu.
    Kaynak bir alani tasimiyorsa o kolon NULL olarak uretilir - boylece
    UNION ALL calisir ve kaynak modelin o kolonu olmak zorunda kalmaz.
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
    is_current mantigi: kaynak tarih tasimiyorsa "guncel" kabul edilir.
    (Web scraping bugunun sayfasini kazir - tanimi geregi guncel.)
-#}
{% macro is_current_expr(key) %}
    {%- if 'dates' in source_provides(key) -%}
        end_date is null
    {%- else -%}
        true
    {%- endif -%}
{% endmacro %}
