-- Phase 1 presentation: SNAPP power-author dashboard table (Colab `repeated_author_flag`).
-- Confirmed by Giorgia (2026-07-16) as one of the direct dashboard outputs, alongside
-- mis_2_subs_all and mis_3_..._4_v8. Thin contract layer over int_repeated_author_flag.
--
-- Contract = prod snproject-cbb9ca25.RM_Submissions_mktg_infl.repeated_author_flag:
--   internal_submission_id STRING, source_system STRING, month DATE, repeated_author INTEGER
-- One row per (submission, source_system) — the intermediate already collapses submissions
-- that re-enter with the same id / multiple submission_dates to a single flag (the
-- "multiple flags per internal_submission_id" issue Giorgia flagged). The full-history
-- lookback is controlled upstream by repeated_author_full_history.
--
-- NOTE: this model is identity/GA-independent, so it carries no `ga` tag (unlike the other
-- presentation models) and can be materialised without the GA extracts.

{{ config(materialized='table', tags=['presentation']) }}

select
    internal_submission_id,
    source_system,
    month,
    repeated_author
from {{ ref('int_repeated_author_flag') }}
