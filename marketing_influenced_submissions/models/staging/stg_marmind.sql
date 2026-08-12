-- Marmind campaign metadata (datasn-rm-live.prod_marmind_presentation):
-- campaign code -> workspace_category. Joined on UPPER(marmind_code) to GA
-- activity to classify RM vs Collections workspaces.
--
-- Source swap (Giorgia 2026-08 / Colab Jul refresh):
--   was: marmind_fnd.marmind_data (discontinued; included channels_categories)
--   now: prod_marmind_presentation.marmind_analytics (workspace only)

with source as (

    select * from {{ source('prod_marmind_presentation', 'marmind_analytics') }}

)

select
    marmind_campaign_code,
    workspace_category
from source
