-- Marmind campaign metadata (datasn-rm-live.marmind_fnd): campaign code ->
-- workspace + channel categories. Joined on UPPER(marmind_code) to GA activity to
-- classify RM vs Collections and the channel category.

with source as (

    select * from {{ source('marmind_fnd', 'marmind_data') }}

)

select
    marmind_campaign_code,
    workspace_category,
    channels_categories
from source
