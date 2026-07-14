-- Phase 5 combination: trackable-submission flag (Colab mis_2_trackable_subs_2). A
-- submission is trackable if any of its GA users passes the genuine-researcher filter.

{{ config(materialized='table', tags=['ga']) }}

select
    subs.internal_submission_id,
    max(case when us1.user_pseudo_id is not null then 1 else 0 end) as trackable_sub
from (
    select *
    from {{ ref('int_sub_details') }}
    where submission_date_min >= date('{{ var("mis_start_date") }}')
      and submission_date_min <= date('{{ var("mis_end_date") }}')
) subs
left join {{ ref('int_genuine_users') }} us1
    on subs.user_pseudo_id = us1.user_pseudo_id
group by 1
