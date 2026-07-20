-- Phase 4 Google auto-tagged: final per-submission google SEA / External Display
-- flags (Colab mis_3_google_auto_6_final). Merges the multichannel apportionment back
-- into the channel detail.

{{ config(materialized='table', tags=['ga']) }}

select
    t1.internal_submission_id,
    t1.submission_date_min,
    case when t2.external_display_to_add is not null then t1.external_display_rm + t2.external_display_to_add else t1.external_display_rm end as external_display_rm,
    case when t2.sea_to_add is not null then t1.sea_rm + t2.sea_to_add else t1.sea_rm end as sea_rm,
    t1.sea_rm_no_journal,
    t1.external_display_col,
    t1.sea_col,
    t1.sea_col_no_journal
from {{ ref('int_google_auto_channel_detail') }} t1

left join {{ ref('int_google_auto_multi') }} t2
on t1.internal_submission_id = t2.internal_submission_id
