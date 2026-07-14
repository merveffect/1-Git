-- Phase 5 combination: main attributed SNAPP table (Colab mis_2_subs_all_inter_4).
-- Combines manual RM/Collections GA flags with the Google auto-tag apportionment,
-- trackable flag, power author, country and RG traffic, at one row per submission.
-- RM activity 1+/3+ include Google external_display/sea and RG journal-home traffic.

{{ config(materialized='table', tags=['ga']) }}

select
    month_start_date,
    sub.internal_submission_id,
    case when sub.email_rm + sub.external_display_rm + sub.internal_display_rm + sub.paid_social_rm + sub.sea_rm + ifnull(sub.rg_journal_home, 0) + ifnull(gg.external_display_rm, 0) + ifnull(gg.sea_rm, 0) > 0 then 1 else trck.trackable_sub end as trackable_sub,
    source_system,
    sub.imprint_code,
    business_model,
    main_group,
    portfolio,
    flag_power_author,
    cty.author_country,
    is_in_collection,
    case when sub.email_rm + sub.external_display_rm + sub.internal_display_rm + sub.paid_social_rm + sub.sea_rm + ifnull(sub.rg_journal_home, 0) + ifnull(gg.external_display_rm, 0) + ifnull(gg.sea_rm, 0) >= 1 then 1 else 0 end as rm_activity_1plus,
    case when sub.email_rm + sub.external_display_rm + sub.internal_display_rm + sub.paid_social_rm + sub.sea_rm + ifnull(sub.rg_journal_home, 0) + ifnull(gg.external_display_rm, 0) + ifnull(gg.sea_rm, 0) >= 3 then 1 else 0 end as rm_activity_3plus,
    case when ifnull(sub.email_col, 0) + ifnull(sub.external_display_col, 0) + ifnull(sub.internal_display_col, 0) + ifnull(sub.paid_social_col, 0) + ifnull(sub.sea_col, 0) + ifnull(gg.external_display_col, 0) + ifnull(gg.sea_col, 0) >= 1 then 1 else 0 end as collections_activity,
    email_rm,
    internal_display_rm,
    paid_social_rm,
    seo,
    organic_social,
    email_col,
    internal_display_col,
    paid_social_col,
    organic_social_col,
    case when email_rm > 0 then 1 else 0 end as email_rm_flag,
    case when sub.external_display_rm + ifnull(gg.external_display_rm, 0) > 0 then 1 else 0 end as external_display_rm_flag,
    case when internal_display_rm > 0 then 1 else 0 end as internal_display_rm_flag,
    case when paid_social_rm > 0 then 1 else 0 end as paid_social_rm_flag,
    case when sub.sea_rm + ifnull(gg.sea_rm, 0) > 0 then 1 else 0 end as sea_rm_flag,
    case when seo > 0 then 1 else 0 end as seo_flag,
    case when organic_social > 0 then 1 else 0 end as organic_social_flag,
    case when email_col > 0 then 1 else 0 end as email_col_flag,
    case when sub.external_display_col + ifnull(gg.external_display_col, 0) > 0 then 1 else 0 end as external_display_col_flag,
    case when internal_display_col > 0 then 1 else 0 end as internal_display_col_flag,
    case when paid_social_col > 0 then 1 else 0 end as paid_social_col_flag,
    case when sub.sea_col + ifnull(gg.sea_col, 0) > 0 then 1 else 0 end as sea_col_flag,
    case when organic_social_col > 0 then 1 else 0 end as organic_social_col_flag,
    seo_no_journal,
    case when sub.sea_rm_no_journal + ifnull(gg.sea_rm_no_journal, 0) > 0 then 1 else 0 end as sea_rm_no_journal_flag,
    case when seo_no_journal > 0 then 1 else 0 end as seo_no_journal_flag,
    sub.external_display_rm + ifnull(gg.external_display_rm, 0) as external_display_rm,
    sub.sea_rm + ifnull(gg.sea_rm, 0) as sea_rm,
    sub.sea_rm_no_journal + ifnull(gg.sea_rm_no_journal, 0) as sea_rm_no_journal,
    sub.external_display_col + ifnull(gg.external_display_col, 0) as external_display_col,
    sub.sea_col + ifnull(gg.sea_col, 0) as sea_col,
    ifnull(sub.rg_organic, 0) as rg_organic,
    case when ifnull(sub.rg_organic, 0) > 0 then 1 else 0 end as rg_organic_flag,
    ifnull(sub.rg_journal_home, 0) as rg_journal_home,
    case when ifnull(sub.rg_journal_home, 0) > 0 then 1 else 0 end as rg_journal_home_flag
from {{ ref('int_subs_ga_combined') }} sub

left join {{ ref('int_trackable_subs') }} trck
    on sub.internal_submission_id = trck.internal_submission_id

left join {{ ref('int_country') }} cty
    on sub.internal_submission_id = cty.internal_submission_id

left join {{ ref('int_google_auto_final') }} gg
    on sub.internal_submission_id = gg.internal_submission_id

where sub.source_system = "SNAPP"
