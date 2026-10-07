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
    /*
        Scaled by similarity, not by margin. A value that sits right on the
        0.65 floor scores 0.70; an exact anchor match scores 1.00.
    */
    case
        when match_decision != 'ACCEPTED' then 0.0
        else least(1.0, 0.70 + (similarity - {{ var('sim_floor') }})
                               / (1.0 - {{ var('sim_floor') }}) * 0.30)
    end                                         as discipline_score
from {{ ref('int_discipline_match') }}
