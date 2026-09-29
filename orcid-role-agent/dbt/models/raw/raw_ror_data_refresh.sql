{{ config(materialized='view') }}

/*
    RAW LAYER - ror_data_refresh  (SEPARATE PROJECT)
    The ROR organisation registry, not a local matching output.
*/

select * from {{ source('ror', 'ror_data_refresh') }}
