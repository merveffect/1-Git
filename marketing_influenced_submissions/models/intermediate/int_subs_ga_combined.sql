-- Phase 5 combination: submissions joined to per-submission manual GA channel flags
-- (Colab mis_2_subs_ga_combined_2). The 180-day window is already applied upstream in
-- int_ga_activity.

{{ config(materialized='table', tags=['ga']) }}

select
    date(extract(year from sub.submission_date), extract(month from sub.submission_date), 1) as month_start_date,
    sub.*,
    ga.* except (internal_submission_id)
from {{ ref('int_subs_unique') }} sub
left join {{ ref('int_ga_activity') }} ga
    on sub.internal_submission_id = ga.internal_submission_id
where sub.submission_date >= date('{{ var("mis_start_date") }}')
  and sub.submission_date <= date('{{ var("mis_end_date") }}')
