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
    stripped in stg_orcid__employment - abbreviation expansion was removed
    on 2026-11-27 because it had never run), so
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
    /*
        A POST WITH AN END DATE IN THE FUTURE IS A POST SOMEBODY HOLDS.
        Merve, 2026-11-27.

        This was `end_date is null` alone until today, and that is not what
        current means. ORCID lets people record an EXPECTED end date, which
        is normal for a funded studentship or a fixed-term contract, and a
        doctoral student whose record says `ends 2027` is a student now.
        Reading any end date as 'has left' dropped every one of them from
        the three current_only audiences - faculty_head, librarian and
        students - because current_only_predicate refuses a role when
        is_current is false.

        MEASURED BEFORE THE CHANGE, 2026-11-27. 25,489 of 1,808,514 records
        (1.4%) carry an end date in the future, across 24,139 people. Of
        those, the ones whose title lands in a current_only group:

            students        4,922 people, 4,646 of them NOT already in the
                            audience through another record - on 102,702,
                            so up to +4.5%
            faculty_head      729 people, 679 new - on 17,566, up to +3.9%
            librarian           6 people, 4 new - on 717

        Those are CEILINGS, not forecasts: the title group gets the record
        past current_only, but org_score and dept_score still have to clear
        the role's threshold, so the build will come in under them.

        >= AND NOT >, which is a one-day difference from the figures above.
        The measurement used `> current_date()`; a post whose end date IS
        today has not ended during today, so the model is the more generous
        of the two. The gap is a handful of records and is the only reason
        the build will not match the numbers above exactly in that
        direction.

        THE RECENCY WINDOW ALREADY AGREED WITH THIS. recency_predicate asks
        for `end_date is null or end_date >= date_sub(current_date(),
        interval 6 month)`, which a future date satisfies, so these records
        were never filtered out of the pipeline - they were present and
        then refused a role. Only is_current disagreed.
    */
    (end_date is null or end_date >= current_date())  as is_current,
    to_hex(md5(role_title))                         as title_key,
    row_number() over (
        partition by snid
        -- SAME CORRECTION, AND IT HAS TO BE HERE TOO. This ordering picks
        -- which single record represents a person, and `(end_date is null)
        -- desc` alone ranked an undated OLD post above a future-dated
        -- CURRENT one - so a person holding both was represented by the job
        -- they had left. Fixing is_current without fixing this would have
        -- let the record through the gate and then described it with the
        -- wrong row.
        order by (end_date is null or end_date >= current_date()) desc,
                 start_date desc nulls last,
                 end_date   desc nulls last,
                 ordering   asc  nulls last
    )                                               as recency_rank
from orcid
