{% macro extract_email_domain(email_column) %}

lower(trim(split({{ email_column }}, '@')[safe_offset(1)]))

{% endmacro %}