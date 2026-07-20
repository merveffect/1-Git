-- Articles pipeline stage history (datasn-submissions-55677263): submission stage
-- transitions. Stage 5 = out-to-review. Feeds int_snapp_otr.

with source as (

    select * from {{ source('prod_articles_pipeline_reporting', 'rpt_stage_history') }}

)

select
    internal_submission_id,
    stage_id
from source
