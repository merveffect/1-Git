{{ config(
    materialized = 'incremental', 
    schema = 'Institutional_analysisGA4_EU',
    description = 'Incrementally loads daily partitions of GA4 data into a cleaned base table.'
) }}

with raw_events as (

    select *
    from {{ source('ga4_exports', 'events') }}

    where 
        user_pseudo_id is not null

        {% if is_incremental() %}
        AND _TABLE_SUFFIX = FORMAT_TIMESTAMP('%Y%m%d', TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 2 DAY))
        {% else %}
        AND _TABLE_SUFFIX >= FORMAT_TIMESTAMP('%Y%m%d', TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY))
        {% endif %}
)

SELECT
    TIMESTAMP_MICROS(event_timestamp) AS event_timestamp,
    user_pseudo_id,
    event_name,
    
    device.web_info.hostname AS hostname,
    geo.city,
    geo.country,
    geo.continent,
    geo.sub_continent,
    
    traffic_source.medium AS medium1,
    traffic_source.source AS source1,
    collected_traffic_source.manual_source AS source2,
    collected_traffic_source.manual_medium AS medium2,
    session_traffic_source_last_click.manual_campaign.medium AS medium,
    session_traffic_source_last_click.manual_campaign.source AS source,
    
    event_params,
    user_properties,
    
    CURRENT_TIMESTAMP() AS dbt_loaded_at

FROM
    raw_events