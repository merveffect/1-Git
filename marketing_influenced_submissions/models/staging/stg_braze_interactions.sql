-- Braze interactions (dat-analytics-eng-ec869189): email_click rows map the Braze
-- user_id (= GA4 cep_id) to email_address. Feeds the Braze identity branch
-- (braze_ga4_email). Filtered to email_click, the only interaction type used.

with source as (

    select * from {{ source('braze_interactions', 'interactions_datasource') }}

)

select
    user_id,
    email_address,
    interaction_type
from source
where interaction_type = 'email_click'
