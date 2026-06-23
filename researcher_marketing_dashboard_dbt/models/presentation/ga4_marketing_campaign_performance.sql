
{{config(
    
    project = 'snproject-cbb9ca25',
    schema = 'ae_data_products',
    materialized='view'
)}}


SELECT * except(responsible_person) from {{ref('j7')}}

