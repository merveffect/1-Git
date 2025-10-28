
{% macro get_columns_except_excluded(table_name, column_field, exclude_columns) %}
    {% set column_values = dbt_utils.get_column_values(
        table=ref(table_name),
        column=column_field
    ) %}

    {% set included_columns = [] %}

    {% for col in column_values %}
        {% if col not in exclude_columns %}
             {% do included_columns.append(col) %}
        {% endif %}
    {% endfor %}

    {{ return(included_columns) }}
{% endmacro %}
