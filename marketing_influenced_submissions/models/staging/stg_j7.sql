-- GA4 RIA researcher report j7 (dataform build): sessions by campaign x channel.
-- Used to compute SEA / External Display session shares for Google auto-tagged
-- campaigns. Sessions column is PascalCase in the source (aliased to sessions).

with source as (

    select * from {{ source('ga4_ria_researcher_report_dataform', 'j7') }}

)

select
    date,
    clean_campaign,
    main_channels,
    sub_channels,
    Sessions as sessions
from source
