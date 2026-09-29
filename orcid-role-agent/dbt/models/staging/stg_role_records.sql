{{ config(materialized='view') }}

/*
    ⭐ THE SINGLE POINT WHERE ALL SOURCES MEET

    GUARANTEED FIELDS - MANDATORY in every source:
        snid, role_title
    Everything else is OPTIONAL. If a source does not carry a field it
    arrives as NULL and that source's scoring weights are renormalised
    (see macros/scoring.sql -> normalized_weights).

    This is what lets a source carrying only (snid, role) - web scraping,
    for example - enter the pipeline and still cross the threshold.

    ADDING A SOURCE:
      1. stg_<source>__role_records.sql - produce at least snid + role_title
      2. dbt_project.yml -> vars.sources: add a block
      3. dbt run
    Nothing else changes, including this file.

    Active sources: {{ source_keys() | join(', ') }}
*/

with unioned as (

    {%- for key in source_keys() %}

    -- ── {{ key }} ({{ source_config(key).display_name }}) ──
    -- carries: {{ source_provides(key) | join(', ') or 'snid + role_title only' }}
    {{ role_record_select(key) }}

    {% if not loop.last %}union all{% endif %}
    {%- endfor %}

),

with_currency as (

    select
        *,
        case source_key
        {%- for key in source_keys() %}
            when '{{ key }}' then {{ is_current_expr(key) }}
        {%- endfor %}
        end                                         as is_current
    from unioned

)

select
    *,
    to_hex(md5(role_title))                         as title_key,
    row_number() over (
        partition by snid, source_key
        order by is_current desc,
                 start_date desc nulls last,
                 end_date   desc nulls last,
                 ordering   asc  nulls last
    )                                               as recency_rank
from with_currency
