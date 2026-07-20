-- Phase 7 presentation: master SNAPP dashboard table (Colab mis_2_subs_all). One row
-- per submission; overlays the collections-specific email_col / collections_activity
-- from int_subs_coll onto the main attributed table.
--
-- SN-REVIEW (E1): this is the dashboard contract. Column set is column-for-column with
-- the current prod mis_2_subs_all; confirm before any promotion.

{{ config(materialized='table', tags=['ga', 'presentation']) }}

select
    m2.month_start_date,
    m2.internal_submission_id,
    m2.trackable_sub,
    m2.source_system,
    m2.imprint_code,
    m2.business_model,
    m2.main_group,
    m2.portfolio,
    m2.flag_power_author,
    m2.author_country,
    m2.is_in_collection,
    m2.rm_activity_1plus,
    m2.rm_activity_3plus,
    case when m2.collections_activity + ifnull(col.collections_activity, 0) > 0 then 1 else 0 end as collections_activity,
    m2.email_rm,
    m2.external_display_rm,
    m2.internal_display_rm,
    m2.paid_social_rm,
    m2.sea_rm,
    m2.seo,
    m2.organic_social,
    m2.rg_organic,
    m2.rg_organic_flag,
    m2.rg_journal_home,
    m2.rg_journal_home_flag,
    col.email_col,
    m2.external_display_col,
    m2.internal_display_col,
    m2.paid_social_col,
    m2.sea_col,
    m2.organic_social_col,
    m2.email_rm_flag,
    m2.external_display_rm_flag,
    m2.internal_display_rm_flag,
    m2.paid_social_rm_flag,
    m2.sea_rm_flag,
    m2.seo_flag,
    m2.organic_social_flag,
    case when col.email_col > 1 then 1 else col.email_col end as email_col_flag,
    m2.external_display_col_flag,
    m2.internal_display_col_flag,
    m2.paid_social_col_flag,
    m2.sea_col_flag,
    case when col.organic_social_col > 1 then 1 else col.organic_social_col end as organic_social_col_flag,
    m2.sea_rm_no_journal,
    m2.seo_no_journal,
    m2.sea_rm_no_journal_flag,
    m2.seo_no_journal_flag
from {{ ref('int_subs_all_inter') }} m2

left join {{ ref('int_subs_coll') }} col
    on m2.internal_submission_id = col.internal_submission_id
