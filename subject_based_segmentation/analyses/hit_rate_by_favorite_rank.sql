-- Does accuracy actually fall off after rank 3?
--
-- Answers whether "use the top 3" is the right cut-off, measured against
-- real ground truth: the MPC subjects users opted into themselves. Same
-- ground truth and same <= 6 subject filter as
-- favorite_snt_evaluation_metrics, so the numbers are comparable.
--
-- Read it like this: if the hit rate is roughly flat from rank 1 to 3 and
-- then declines, top-3 is a well-chosen cut-off. If rank 1 is far above
-- rank 2 and 3, then ranks 2-3 are diluting the recommendation. If the
-- rate is flat all the way to rank 10, the cut-off is arbitrary and could
-- just as well be wider.
--
-- avg_distance is reported per rank so it can be compared with the hit
-- rate: distance is only meaningful WITHIN a user, so the question here is
-- whether rank order and distance tell the same story.

with ground_truth as (

    select
        snid,
        array(
            select distinct subj
            from unnest(regexp_extract_all(subjects, r'"(\d+)"')) as subj
        ) as actual
    from {{ source('prod_audience_explorer_analytics_dbt_presentation', 'audience_builder_big') }}
    where advertising_opt_in = true
      and subjects is not null

),

gt as (
    select snid, actual
    from ground_truth
    where array_length(actual) <= 6
),

-- Same direct/fallback mapping as favorite_snt_predictions_rolled_up_mpc,
-- but keeping favorite_rank instead of collapsing to one array per user.
mapped as (

    select distinct
        p.snid,
        p.favorite_rank,
        p.distance,
        coalesce(
            cast(direct_map.marketing_preference_id as string),
            cast(fallback_map.marketing_preference_id as string)
        ) as mpc_id
    from {{ ref('favorite_snt_predictions') }} p

    left join {{ source('subject_based_segmentation', 'snts_mktps_mapped_final') }} direct_map
        on p.inferred_snt_id = direct_map.marketing_preference_id

    left join {{ source('subject_based_segmentation', 'snts_mktps_mapped_final') }} fallback_map
        on p.inferred_snt_id in unnest(
            array_concat(
                ifnull(fallback_map.level_1_id, []),
                ifnull(fallback_map.level_2_id, []),
                ifnull(fallback_map.level_3_id, []),
                ifnull(fallback_map.level_4_id, []),
                ifnull(fallback_map.level_5_id, []),
                ifnull(fallback_map.level_6_id, [])
            )
        )

),

-- One row per (user, rank): did the SNT at this rank roll up to any
-- subject the user actually chose?
per_rank as (

    select
        m.snid,
        m.favorite_rank,
        any_value(m.distance) as distance,
        logical_or(m.mpc_id in unnest(g.actual)) as is_hit
    from mapped m
    join gt g using (snid)
    group by m.snid, m.favorite_rank

)

select
    favorite_rank,
    count(*) as users,
    countif(is_hit) as hits,
    round(100 * safe_divide(countif(is_hit), count(*)), 2) as hit_rate_pct,
    round(avg(distance), 4) as avg_distance
from per_rank
group by favorite_rank
order by favorite_rank
