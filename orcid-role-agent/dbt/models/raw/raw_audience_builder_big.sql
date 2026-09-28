{{ config(materialized='view') }}

/*
    HAM KATMAN - audience_builder_big
    CDP populasyonu: consent bayraklari ve contact_email buradan gelir.
*/

select * from {{ source('researcher_profiles', 'audience_builder_big') }}
