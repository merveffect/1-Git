{{ config(
    materialized='table',
    database='poc-gbq',
    schema='permutive_sn_dev',
    alias='orcid_behaviour'
) }}


Select * from {{ref('hcp_permutive_audiences')}}