{{ config(
    enabled      = var('use_llm_judge', false),
    materialized = 'incremental',
    unique_key   = ['title_key', 'role_key']
) }}

/*
    DICTIONARY STEP 6 - LLM JUDGE  (OPTIONAL)

    Disabled by default: this project has no Vertex connection
    (setup/03_test_access.sql Test 3). The pipeline runs on vectors alone.
    Set use_llm_judge: true once a connection exists.

    Only (title, role) pairs marked NEEDS_JUDGE are sent to Gemini.

    Economics: distinct titles x roles is a large number of pairs, but
    only the ambiguous band reaches the model. Everything else is decided
    for free by vector similarity.

    Incremental: a pair is never sent to the model twice.
*/

with to_judge as (

    select
        m.title_key,
        m.title,
        m.role_key,
        m.frequency,
        m.include_similarity,
        m.matched_anchors
    from {{ ref('int_title_role_match') }} m
    where m.match_decision = 'NEEDS_JUDGE'

    {% if is_incremental() %}
      and not exists (
          select 1 from {{ this }} t
          where t.title_key = m.title_key and t.role_key = m.role_key
      )
    {% endif %}

),

role_definitions as (
    {%- for k in role_keys() %}
    select
        '{{ k }}'                                           as role_key,
        '''{{ role(k).label }}'''                           as role_label,
        '''{{ role(k).description | replace("'", "") | replace("\n", " ") | trim }}'''
                                                            as role_description
    {% if not loop.last %}union all{% endif %}
    {%- endfor %}
),

prompted as (

    select
        j.*,
        d.role_label,
        concat(
            'You are an occupation classification expert. ',
            'ROLE DEFINITION: ', d.role_label, ' - ', d.role_description, ' ',
            'QUESTION: does a person with the job title "', j.title, '" ',
            'belong to this role? Judge the title alone; if unsure answer NO. ',
            'Management or consulting titles outside the relevant field are NO. ',
            'Answer with YES or NO only, nothing else.'
        )                                                   as judge_prompt
    from to_judge j
    join role_definitions d using (role_key)

),

judged as (

    {{ judge_titles(source_relation='prompted', prompt_col='judge_prompt') }}

)

select
    title_key,
    title,
    role_key,
    frequency,
    include_similarity,
    matched_anchors,
    judge_prompt,
    judge_accepted,
    judge_status,
    '{{ var("judge_model") }}'      as model_name,
    current_timestamp()             as judged_at
from judged
