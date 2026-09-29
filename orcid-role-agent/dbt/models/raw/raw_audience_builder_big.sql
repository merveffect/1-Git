{{ config(materialized='view') }}

/*
    RAW LAYER - audience_builder_big
    The CDP population: consent flags and contact_email come from here.
*/

select * from {{ source('researcher_profiles', 'audience_builder_big') }}
