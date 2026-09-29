{{ config(materialized='table') }}

-- Long-format (snid, keyword_id) pairs, mirroring users_and_journal_ids.sql.
-- keyword_id = MD5(keyword), matching distinct_keywords/keyword_embeddings.

with parsed as (

    select
        snid,
        -- custom \term\,\term\ format (not JSON) — see users_with_content_signal
        regexp_extract_all(keywords_last_60d, r'\\([^\\]+)\\') as keywords
    from {{ ref('users_with_content_signal') }}
    where keywords_last_60d is not null

)

select distinct
    snid,
    to_hex(md5(keyword)) as keyword_id
from parsed, unnest(keywords) as keyword
where keyword is not null and trim(keyword) != ''
