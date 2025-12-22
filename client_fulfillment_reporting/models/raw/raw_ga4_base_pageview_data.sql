Select * from 
    {{ source('rm_bc_client_fulfillment_reporting', 'bc_all_ga4_base_pageview_data') }}