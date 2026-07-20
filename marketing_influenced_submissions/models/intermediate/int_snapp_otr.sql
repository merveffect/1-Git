-- Phase 5 OTR: out-to-review proxy per SNAPP submission (Colab snapp_otr). A
-- submission is "out to review" if it reached stage 5 in the articles-pipeline stage
-- history OR its final decision is 'accepted'.
--
-- SN-REVIEW: OTR is a proxy (stage_id = 5 OR final_decision = 'accepted'). Confirm
-- this is the intended acceptance/OTR definition. Non-GA model, safe to materialise.

with snapp as (

    select distinct submission_id
    from {{ ref('stg_snapp_submission_funnel') }}
    where snapp_process = 'snapp_success'
      and full_date >= '2024-07-01'
      and full_date <= date('{{ var("mis_end_date") }}')

),

stage_history as (

    select distinct internal_submission_id, stage_id
    from {{ ref('stg_rpt_stage_history') }}
    where stage_id = 5

),

submissions as (

    select distinct internal_submission_id, final_decision
    from {{ ref('stg_submissions') }}
    where final_decision = 'accepted'
      and submission_date >= '2024-07-01'
      and submission_date <= date('{{ var("mis_end_date") }}')

)

select
    snapp.submission_id,
    case when submissions.final_decision = 'accepted' then 1 else 0 end as stage_9_accepted_flag,
    case when stage_history.stage_id = 5 then 1 else 0 end as stage_5_flag,
    case when stage_history.stage_id = 5 or submissions.final_decision = 'accepted' then 1 else 0 end as out_to_review
from snapp
left join stage_history on snapp.submission_id = stage_history.internal_submission_id
left join submissions on snapp.submission_id = submissions.internal_submission_id
