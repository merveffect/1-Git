Select * from 
    {{ source('rm_bc_client_fulfillment_reporting', 'bc_all_ga4_base_pageview_data') }}
{{ config(
materialized='table',
partition_by={
"field": "evt_date",
"data_type": "date",
"granularity": "day"
},
cluster_by=["page_path"]
) }}