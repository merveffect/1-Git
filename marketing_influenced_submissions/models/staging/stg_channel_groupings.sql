-- Raw passthrough of the RM Channel Groupings reference (native table refreshed
-- from the Drive-backed sheet). No normalisation here: the Colab applies the
-- join-specific rules (lower/trim, email source nulling with researchgate/
-- chatgpt/etoc/peeref/letpub/growkudos exceptions, google+cpc External Display
-- exclusion) at the GA4 join step, which will live in the Layer 3 intermediate.

with raw_channel_groupings as (

    select * from {{ source('ae_metadata', 'channel_groupings') }}

),

renamed as (

    select
        source,
        medium,
        adnetwork,
        sub_channels,
        main_channels,
        ga4_console_grouping
    from raw_channel_groupings

)

select * from renamed
