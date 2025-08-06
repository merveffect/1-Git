{% macro get_null_flag_expression(columns) %}
    {% set null_checks = [] %}

    {% for col in columns %}
        {% do null_checks.append(col ~ ' IS NULL') %}
     
    {% endfor %}

    {{ return(null_checks | join(' AND ')) }}
{% endmacro %}


