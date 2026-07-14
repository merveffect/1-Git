-- Phase 6 collections: per-submission collection-email type flag (Colab
-- mis_2_coll_email_1). Matches Email GA touchpoints to the collections-email mapping
-- on marmind_code, resolving the retain-and-gain special case, and flags email
-- activity within the attribution window.
--
-- SN-REVIEW (D4): the collections-email mapping is read from the existing native
-- table mis_input_data_collections_emails_2 (its upstream is a Drive sheet).

{{ config(materialized='table', tags=['ga']) }}

{% set win = var("attribution_window_days") %}

select
    internal_submission_id,
    collection_email_type,
    max(case when (date_diff(submission_date_min, event_date, day) > 0 and date_diff(submission_date_min, event_date, day) <= {{ win }}) and collection_email_type is not null then 1 else 0 end) as flag_collection_email
from (
    select
        *,
        case
            when flag_match_retain_gain is true then email_type
            when flag_match_retain_gain is false and email_type <> "coll_retain_and_gain" then email_type
            else null
        end as collection_email_type
    from (
        select
            ga.*,
            col.campaign_name_extract,
            col.email_details,
            col.email_type,
            col.marmind_code_upper,
            case when regexp_contains(lower(ga.clean_campaign), lower(col.campaign_name_extract)) then true else false end as flag_match_retain_gain
        from (
            select *
            from {{ ref('int_ga_activity_sub') }}
            where trim(main_channels) = "Email"
        ) ga
        inner join {{ source('mis_prod', 'mis_input_data_collections_emails_2') }} col
            on upper(ga.marmind_code) = col.marmind_code_upper
    )
)
where collection_email_type is not null
group by 1, 2
