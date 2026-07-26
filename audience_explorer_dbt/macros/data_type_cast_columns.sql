{% macro data_type_cast_columns() %}

  {%- if not execute -%}{{ return('*') }}{%- endif -%}

  {% set keep_query %}
    select distinct lower(column_names) as col
    from {{ ref('stg_user_traits_column_names') }}
  {% endset %}
  {% set keep_cols = run_query(keep_query).columns[0].values() %}

  {% set type_map = {} %}
  {% for c in adapter.get_columns_in_relation(ref('raw_identifies')) %}
    {% do type_map.update({ c.name | lower: c.dtype | upper }) %}
  {% endfor %}

  {% set bq_type = {
      'STRING':'STRING','BOOL':'BOOL','BOOLEAN':'BOOL',
      'INT64':'INT64','INTEGER':'INT64','INT':'INT64',
      'FLOAT64':'FLOAT64','FLOAT':'FLOAT64','NUMERIC':'NUMERIC',
      'TIMESTAMP':'TIMESTAMP','DATE':'DATE','DATETIME':'DATETIME'
  } %}

  {% set replacements = [] %}
  {% for col in keep_cols %}
    {% set dtype = type_map.get(col) %}
    {% if dtype is none %}
      {% do log("raw_identifies'ta yok, STRING kaldi: " ~ col, info=True) %}
    {% elif dtype != 'STRING' %}
      {% set target = bq_type.get(dtype, dtype) %}
      {% do replacements.append(
          "safe_cast(`" ~ col ~ "` as " ~ target ~ ") as `" ~ col ~ "`") %}
    {% endif %}
  {% endfor %}

  {% if replacements | length == 0 %}{{ return('*') }}{% endif %}

  {{ return('* replace (\n      ' ~ replacements | join(',\n      ') ~ '\n    )') }}

{% endmacro %}