-- Can distance be used as a confidence threshold across users?
--
-- The concern: a user vector is the average of their signals. Averaging
-- many vectors pulls the result towards the centre of the space, where
-- distances to everything grow. A user with a single keyword, by contrast,
-- has a vector sitting exactly on that keyword, which can land very close
-- to an SNT.
--
-- If that holds, a small distance can mean "one thin signal" rather than
-- "strong evidence", and thresholding on distance would systematically
-- favour the least-informed users — the opposite of the intent.
--
-- This query tests it directly. Read the two columns together:
--   - avg_rank1_distance falling as n_signals rises  -> distance is NOT a
--     usable cross-user filter; it mostly measures how thin the input was.
--   - rank1_hit_rate_pct rising as n_signals rises   -> signal count IS the
--     real confidence variable, so that is what should gate a
--     recommendation, not distance.
-- If instead distance and hit rate move together regardless of n_signals,
-- distance is safe to threshold on after all.

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

-- How many of the three channels does each user actually have?
signals as (

    select snid, count(*) as n_signals
    from (
        select snid from {{ ref('user_journal_snt_vector') }}
        union all
        select snid from {{ ref('user_keyword_vector') }}
        union all
        select snid from {{ ref('user_collection_vector') }}
    )
    group by snid

),

rank1 as (
    select snid, inferred_snt_id, distance
    from {{ ref('favorite_snt_predictions') }}
    where favorite_rank = 1
),

mapped as (

    select distinct
        r.snid,
        r.distance,
        coalesce(
            cast(direct_map.marketing_preference_id as string),
            cast(fallback_map.marketing_preference_id as string)
        ) as mpc_id
    from rank1 r

    left join {{ source('subject_based_segmentation', 'snts_mktps_mapped_final') }} direct_map
        on r.inferred_snt_id = direct_map.marketing_preference_id

    left join {{ source('subject_based_segmentation', 'snts_mktps_mapped_final') }} fallback_map
        on r.inferred_snt_id in unnest(
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

per_user as (

    select
        m.snid,
        s.n_signals,
        any_value(m.distance) as distance,
        logical_or(m.mpc_id in unnest(g.actual)) as is_hit
    from mapped m
    join gt g using (snid)
    join signals s on s.snid = m.snid
    group by m.snid, s.n_signals

)

select
    n_signals,
    count(*) as users,
    round(avg(distance), 4) as avg_rank1_distance,
    round(100 * safe_divide(countif(is_hit), count(*)), 2) as rank1_hit_rate_pct
from per_user
group by n_signals
order by n_signals
