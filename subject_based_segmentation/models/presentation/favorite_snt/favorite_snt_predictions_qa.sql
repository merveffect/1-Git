{{ config(materialized='table') }}

-- QA table for manually eyeballing whether the top-5 SNT predictions make
-- sense, given the user's actual reading-behaviour inputs: which journals
-- they're linked to, those journals' own SNTs, and their keywords.

with predicted as (

    select
        snid,
        string_agg(snt_name, ', ' order by distance) as predicted_snt_names
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

)

select
    p.snid,
    j.journal_ids,
    js.journal_snt_names,
    k.keywords,
    p.predicted_snt_names
from predicted p
left join journals j using (snid)
left join journal_snts js using (snid)
left join keywords k using (snid)
