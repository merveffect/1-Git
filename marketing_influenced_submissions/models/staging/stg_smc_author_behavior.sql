-- SMC author behaviour (datasn-rm-live.smc_products): maps the SAP outbound id
-- (first 36 chars of interaction_source_object) to author_email. Feeds the
-- GA4 + SMC identity branch (mis_2_ga4_sap_clientid).

with source as (

    select * from {{ source('smc_products', 'smc_author_behavior_by_persona') }}

)

select
    author_email,
    interaction_source_object,
    left(interaction_source_object, 36) as sap_outbound_id_36
from source
where interaction_source_object is not null
