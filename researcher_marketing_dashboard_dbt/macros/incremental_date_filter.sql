{% macro incremental_date_filter(
    date_column,
    lookback_days=2,
    include_today=false,
    default_start_date="2024-01-01",
    default_end_date="2026-12-31"
) %}

    -- Resolve backfill vars
    {% set backfill_start = var("backfill_start_date", none) %}
    {% set backfill_end   = var("backfill_end_date", none) %}
    {% set has_backfill = backfill_start is not none and backfill_end is not none %}

    -- Guardrails
    {% if execute %}
        {% if is_incremental() and not date_column %}
            {{ exceptions.raise_compiler_error(
                "incremental_date_filter requires a date column"
            ) }}
        {% endif %}

        {% if is_incremental()
              and (backfill_start is not none or backfill_end is not none)
              and not has_backfill %}
            {{ exceptions.raise_compiler_error(
                "Both backfill_start_date and backfill_end_date must be provided together"
            ) }}
        {% endif %}
    {% endif %}

    -- Incremental runs
    {% if is_incremental() %}

        WHERE {{ date_column }} BETWEEN

            {% if has_backfill %}
                DATE('{{ backfill_start }}')
            {% else %}
                DATE_SUB(CURRENT_DATE(), INTERVAL {{ lookback_days }} DAY)
            {% endif %}

        AND

            {% if has_backfill %}
                DATE('{{ backfill_end }}')
            {% else %}
                {% if include_today %}
                    CURRENT_DATE()
                {% else %}
                    DATE_SUB(CURRENT_DATE(), INTERVAL {{ lookback_days }} DAY)
                {% endif %}
            {% endif %}

    -- Full refresh / initial load
    {% else %}

        WHERE {{ date_column }} BETWEEN
            DATE('{{ var("start_date", default_start_date) }}')
        AND
            DATE('{{ var("end_date", default_end_date) }}')

    {% endif %}

{% endmacro %}
