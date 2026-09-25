{{ config(materialized='table') }}

-- Rolls up each user's top-10 predicted SNTs to MPC (marketing preference
-- center, 46-subject) ids via the SNT->MKTP mapping table, purely to enable
-- evaluation against the MPC-level ground truth we actually have (no
-- SNT-level ground truth exists — see evaluation_metrics.sql in this
-- folder). Uses the same direct/fallback matching logic as
-- favorite_mpc_subject/snid_to_mktps_step1.sql.

with predictions as (
    select snid, snt_id
    from {{ ref('favorite_snt_predictions') }}
),

mapped as (
    select
        p.snid,
        coalesce(
            cast(direct_map.marketing_preference_id as string),
            cast(fallback_map.marketing_preference_id as string)
        ) as mpc_id
    from predictions p

    left join {{ source('subject_based_segmentation', 'snts_mktps_mapped_final') }} direct_map
        on p.snt_id = direct_map.marketing_preference_id

    left join {{ source('subject_based_segmentation', 'snts_mktps_mapped_final') }} fallback_map
        on p.snt_id in unnest(
            array_concat(
                ifnull(fallback_map.level_1_id, []),
                ifnull(fallback_map.level_2_id, []),
                ifnull(fallback_map.level_3_id, []),
                ifnull(fallback_map.level_4_id, []),
                ifnull(fallback_map.level_5_id, []),
                ifnull(fallback_map.level_6_id, [])
            )
        )
)

select
    snid,
    array_agg(distinct mpc_id ignore nulls) as predicted_mpc_subjects
from mapped
group by snid
