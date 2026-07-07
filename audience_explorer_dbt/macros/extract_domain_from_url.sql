{% macro extract_domain_from_url(url_column) %}
    -- https://www.uav.ro/index.html -> uav.ro
    regexp_extract(
        lower(trim({{ url_column }})),
        r'^(?:https?://)?(?:www\.)?([^/:?#]+)'
    )
{% endmacro %}