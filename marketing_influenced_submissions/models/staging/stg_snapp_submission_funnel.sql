-- SNAPP submission funnel (e2e_b2c_researcher_dev.snapp_submission_funnel_new):
-- GA-observed successful SNAPP submissions, mapping submission_id to the GA
-- user_pseudo_id. Feeds int_subs_clientids_ga and int_snapp_otr.

with source as (

    select * from {{ source('e2e_b2c_researcher_dev', 'snapp_submission_funnel_new') }}

)

select
    submission_id,
    user_pseudo_id,
    journal_id,
    journal_title,
    snapp_process,
    cast(full_date as date) as full_date
from source
