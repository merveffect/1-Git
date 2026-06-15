{{ config(
    materialized='table' 
) }}

WITH source AS (
    SELECT * from {{ source('rm_bc_client_fulfillment_reporting', 'gsheet_wf_metadata_view_version') }}
),

unique_metadata AS (
    SELECT *
    FROM source
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY page_path, collection_id 
        ORDER BY 
            -- Kalite kriterlerini buraya yazıyoruz
            (NULLIF(TRIM(collection_title), '') IS NOT NULL AND collection_title != collection_id) DESC,
            (NULLIF(TRIM(collection_title), '') IS NOT NULL) DESC
    ) = 1
)

SELECT * FROM unique_metadata

