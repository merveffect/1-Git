{{ config(materialized='table') }}

-- QA table for manually eyeballing whether the top-10 SNT predictions make
-- sense, given every signal actually used across all 3 channels: journal
-- ids + titles + their own SNT names, keywords, collection titles + their
-- own SNT names, and the predicted top-10 SNT names — all side by side as
-- comma-separated strings.

with predicted as (

    select
        snid,
        string_agg(snt_name, ', ' order by favorite_rank) as predicted_snt_names
    from {{ ref('favorite_snt_predictions') }}
    group by snid

),

journals as (

    select
        snid,
        string_agg(distinct journal_id, ', ') as journal_ids
    from {{ ref('users_and_journal_ids') }}
    group by snid

),

journal_titles as (

    select
        uj.snid,
        string_agg(distinct jm.Journal_Title, ', ') as journal_titles
    from {{ ref('users_and_journal_ids') }} uj
    join {{ source('ae_metadata', 'journal_metadata') }} jm
        on uj.journal_id = CAST(jm.journal_id AS STRING)
    group by uj.snid

),

journal_snts as (

    select
        uj.snid,
        string_agg(distinct sfl.snt_name, ', ') as journal_snt_names
    from {{ ref('users_and_journal_ids') }} uj
    join {{ ref('journal_snt_codes') }} jsc on uj.journal_id = jsc.journal_id
    join {{ ref('snts_full_list') }} sfl on jsc.snt_id = sfl.snt_id
    group by uj.snid

),

keywords as (

    select
        snid,
        array_to_string(
            regexp_extract_all(keywords_last_60d, r'\\([^\\]+)\\'),
            ', '
        ) as keywords
    from {{ ref('users_with_content_signal') }}
    where keywords_last_60d is not null

),

collection_titles as (

    select
        uc.snid,
        string_agg(distinct dc.title, ', ') as collection_titles
    from {{ ref('users_and_collections') }} uc
    join {{ ref('distinct_collections') }} dc on uc.collection_id = dc.collection_id
    group by uc.snid

),

collection_descriptions as (

    select
        uc.snid,
        string_agg(distinct dc.description_clean, ' | ') as collection_descriptions
    from {{ ref('users_and_collections') }} uc
    join {{ ref('distinct_collections') }} dc on uc.collection_id = dc.collection_id
    where dc.description_clean is not null
    group by uc.snid

),

collection_snts as (

    select
        uc.snid,
        string_agg(distinct cc.nearest_snt_name, ', ') as collection_snt_names
    from {{ ref('users_and_collections') }} uc
    join {{ ref('collection_snt_confidence') }} cc on uc.collection_id = cc.collection_id
    group by uc.snid

)

select
    p.snid,
    j.journal_ids,
    jt.journal_titles,
    js.journal_snt_names,
    k.keywords,
    ct.collection_titles,
    cd.collection_descriptions,
    cs.collection_snt_names,
    p.predicted_snt_names
from predicted p
left join journals j using (snid)
left join journal_titles jt using (snid)
left join journal_snts js using (snid)
left join keywords k using (snid)
left join collection_titles ct using (snid)
left join collection_descriptions cd using (snid)
left join collection_snts cs using (snid)
