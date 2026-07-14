-- Phase 6 collections: in-collection submissions with collection-email pivots merged
-- in (Colab mis_2_subs_coll). collections_activity and email_col are boosted by any
-- collection-email activity that was not otherwise tagged as Collections.

{{ config(materialized='table', tags=['ga']) }}

select
    month_start_date,
    sub.internal_submission_id,
    case when rm_activity_1plus >= 1 then 1 else trackable_sub end as trackable_sub,
    source_system,
    imprint_code,
    business_model,
    main_group,
    portfolio,
    flag_power_author,
    author_country,
    is_in_collection,
    rm_activity_1plus,
    rm_activity_3plus,
    case when collections_activity + total_collection_email > 1 then 1 else collections_activity + total_collection_email end as collections_activity,
    email_rm,
    external_display_rm,
    internal_display_rm,
    paid_social_rm,
    sea_rm,
    seo,
    organic_social,
    rg_organic,
    rg_journal_home,
    case when sub.email_col + col.total_collection_email > 1 then 1 else sub.email_col + col.total_collection_email end as email_col,
    external_display_col,
    internal_display_col,
    paid_social_col,
    sea_col,
    organic_social_col,
    sea_rm_no_journal,
    seo_no_journal,
    col.* except (internal_submission_id)
from {{ ref('int_subs_all_inter') }} sub

left join {{ ref('int_coll_email_pivot') }} col
    on sub.internal_submission_id = col.internal_submission_id

where sub.is_in_collection = 1
