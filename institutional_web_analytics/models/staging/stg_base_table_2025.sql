{{ config(
    materialized='incremental',
    unique_key='user_pseudo_id',
    schema='Institutional_analysisGA4_EU',
    description='Incrementally flattens GA4 events_* into base table.'
) }}

with raw_events as (

    select *
    from `{{ source('ga4_exports', 'events') }}*`
    {% if is_incremental() %}
    where _TABLE_SUFFIX = format_timestamp('%Y%m%d', timestamp_sub(current_timestamp(), interval 2 day))
    {% endif %}
      and user_pseudo_id is not null

)

select
    timestamp_micros(event_timestamp) as event_timestamp,
    user_pseudo_id,
    event_name,
    device.web_info.hostname as hostname,
    traffic_source.medium as medium1,
    traffic_source.source as source1,
    collected_traffic_source.manual_source as source2,
    collected_traffic_source.manual_medium as medium2,
    session_traffic_source_last_click.manual_campaign.medium as medium,
    session_traffic_source_last_click.manual_campaign.source as source,
    geo.city,
    geo.country,
    geo.continent,
    geo.sub_continent,
    event_params,
    user_properties,
    current_timestamp() as dbt_loaded_at

from raw_events
