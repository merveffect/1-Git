select * from 
    {{ source('rm_bc_client_fulfillment_reporting', 'bc_workfront_collections_pipeline_raw') }}