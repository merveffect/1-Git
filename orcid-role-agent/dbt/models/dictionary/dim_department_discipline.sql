{{ config(materialized='table') }}

/*
    ⭐ DICTIONARY 2 — department to discipline

    One row per distinct department name. Same shape as dim_title_group,
    for the other axis.
*/

select
    department_key,
    department,
    frequency,
    discipline,
    similarity,
    margin,
    runner_up,
    matched_anchors,
    needs_human_review,
    match_decision = 'ACCEPTED'                 as is_assigned,
    case
        when match_decision != 'ACCEPTED' then 0.0
        else least(1.0, 0.70 + (margin - {{ var('sim_min_margin') }}) * 2)
    end                                         as discipline_score
from {{ ref('int_discipline_match') }}
