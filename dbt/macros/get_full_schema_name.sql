{% macro get_full_schema_name() -%}
{%- set custom_schema = config.get('schema') -%}
{%- if custom_schema != '' -%}
    {%- set final_schema = generate_schema_name(custom_schema, this) | trim  -%}
{%- else -%}
    {%- set final_schema = target.schema  -%}
{%- endif -%}
{{ final_schema }}
{%- endmacro -%}