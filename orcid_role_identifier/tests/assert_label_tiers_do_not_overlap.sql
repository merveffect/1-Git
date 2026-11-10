/*
    Within one role, no PROBABLE row may score at or above the lowest
    CONFIRMED row. The labels come from per-role thresholds, so this holds
    by construction - which is the point. It breaks when a score is
    recomputed after the label is attached, or a label after a score.

    Catches: the roll-up. fct_researcher_roles unions parent roles whose
    score is inherited from a child, so the label has to be recomputed
    AFTER the union, not carried over from before it. That is what the
    relabelled CTE does, and nothing else proves it is still wired up.
*/

with bounds as (
    select
        role_key,
        max(case when role_label = 'PROBABLE'  then role_final_score end) as highest_probable,
        min(case when role_label = 'CONFIRMED' then role_final_score end) as lowest_confirmed
    from {{ ref('fct_researcher_roles') }}
    group by role_key
)

select *
from bounds
where highest_probable >= lowest_confirmed
