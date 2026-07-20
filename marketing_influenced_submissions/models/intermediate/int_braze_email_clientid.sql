-- Phase 1B identity: Braze email -> client_id (Colab braze_ga4_email). Joins GA4 CEP
-- ids to Braze email_click interactions (Braze user_id = GA4 cep_id); the GA4
-- user_pseudo_id becomes the client_id.

with ga as (

    select user_pseudo_id, cep_id
    from {{ ref('int_braze_cep_ids') }}

),

braze as (

    select user_id, email_address
    from {{ ref('stg_braze_interactions') }}

)

select
    ga.user_pseudo_id as client_id,
    braze.email_address as author_email
from ga
join braze on braze.user_id = ga.cep_id
group by 1, 2
