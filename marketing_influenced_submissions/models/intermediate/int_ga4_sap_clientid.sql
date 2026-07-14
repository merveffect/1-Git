-- Phase 1B identity: GA4 + SMC email -> client_id (Colab mis_2_ga4_sap_clientid).
-- Joins GA4 SAP ids to SMC author behaviour on the 36-char SAP outbound id; the GA4
-- user_pseudo_id becomes the client_id. SN-REVIEW (A2): SMC last refresh 2026-02-26,
-- Colab notes "stop from June" — branch kept ON via identity_include_ga4_sap.

with ga as (

    select user_pseudo_id, sap_outbound_id
    from {{ ref('int_ga4_sap_ids') }}

),

smc as (

    select author_email, sap_outbound_id_36
    from {{ ref('stg_smc_author_behavior') }}

)

select
    smc.author_email,
    ga.user_pseudo_id as clientid
from ga
join smc on left(ga.sap_outbound_id, 36) = smc.sap_outbound_id_36
group by 1, 2
