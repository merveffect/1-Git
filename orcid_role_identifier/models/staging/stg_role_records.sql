{{ config(materialized='view') }}

/*
    The single place role records enter the pipeline.

    Today there is one source: ORCID. Everything downstream reads this
    model rather than stg_orcid__employment directly, so when web
    scraping arrives it becomes a UNION ALL here and nothing else has to
    change.

    Expected shape of a future source: snid + role_title, and little
    else. Columns it cannot supply are simply NULL - the scoring layer
    already treats a NULL organisation or department as "no evidence".

    title_key hashes the NORMALISED title (lowercased, punctuation
    stripped, abbreviations expanded in stg_orcid__employment), so
    "Prof. Dr. med." and "professor doctor medical" collapse to the
    same key and are classified once.
*/

with orcid as (

    select
        'orcid'                 as source_key,
        snid,
        role_title_raw,
        role_title,
        organisation_raw,
        organisation,
        department_raw,
        department,
        org_id,
        org_id_source,
        country_code,
        start_date,
        end_date,
        ordering,
        source_last_updated
    from {{ ref('stg_orcid__employment') }}

)

select
    *,
    end_date is null                                as is_current,
    to_hex(md5(role_title))                         as title_key,
    row_number() over (
        partition by snid
        order by (end_date is null) desc,
                 start_date desc nulls last,
                 end_date   desc nulls last,
                 ordering   asc  nulls last
    )                                               as recency_rank
from orcid
