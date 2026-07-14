-- Phase 7 presentation: aggregated Collections dashboard table (Colab
-- mis_2_subs_coll_2). Counts in-collection submissions by dimension and channel, with
-- the collection-email-type pivots. author_country is a literal "skip" (as in Colab).
--
-- SN-REVIEW (E1): dashboard contract; confirm before promotion.

{{ config(materialized='table', tags=['ga', 'presentation']) }}

select
    month_start_date,
    source_system,
    imprint_code,
    business_model,
    main_group,
    portfolio,
    flag_power_author,
    "skip" as author_country,
    is_in_collection,
    rm_activity_1plus,
    rm_activity_3plus,
    collections_activity,
    email_rm,
    external_display_rm,
    internal_display_rm,
    paid_social_rm,
    sea_rm,
    seo,
    rg_organic,
    rg_journal_home,
    organic_social,
    email_col,
    external_display_col,
    internal_display_col,
    paid_social_col,
    sea_col,
    organic_social_col,
    coll_algo_canto,
    coll_optin_etoc,
    coll_retain_and_gain,
    coll_referral,
    coll_optin_other,
    count(distinct internal_submission_id) as n_subs
from {{ ref('int_subs_coll') }}
group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32
