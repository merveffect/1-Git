{{ config(
    materialized='table'
) }}


select *
from {{ source('rm_bc_client_fulfillment_reporting', 'gsheet_wf_metadata_view_version') }}

