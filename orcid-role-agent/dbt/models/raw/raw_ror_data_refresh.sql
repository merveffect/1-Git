{{ config(materialized='view') }}

/*
    HAM KATMAN - ror_data_refresh  (AYRI PROJE)
*/

select * from {{ source('ror', 'ror_data_refresh') }}
