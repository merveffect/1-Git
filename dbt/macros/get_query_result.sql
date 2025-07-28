{% macro get_query_result(model_name, column_name) %}
  -- This check is needed as otherwise get_max_updated_at would already expect a table to exist
  -- (and would hence fail if it hasn't been created yet)
  
  {% set table_entity = adapter.get_relation(database=target.project, schema=get_full_schema_name(), identifier=model_name) %}
  
  {% if table_entity is not none %}
    {% set sql_statement %}
      select {{ column_name }} from {{ ref(model_name) }}
    {% endset %}

    {% set result = dbt_utils.get_single_value(sql_statement, default=default) %}

    {# Wrap both default and result in single quotes for SQL #}
    {% do return("'" ~ result ~ "'") %}
    
    {% do log("Running some_macro: " ~ result) %}
    
  {% else %}
    CAST(CURRENT_DATE() as STRING)
  {% endif %}

{% endmacro %}