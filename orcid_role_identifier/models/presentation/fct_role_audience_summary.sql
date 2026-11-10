{{ config(materialized='table') }}

/*
    THE HEADLINE. One row per role.

    "We found 47,000 people" is misleading on its own, so every row ends
    with what the business actually acts on: how many of them can be
    contacted.

    Deliberately NOT grouped by country. An earlier version was, which
    turned a five-row headline into roughly a thousand rows and meant you
    could not answer "how many HCPs do we have" without summing. Country
    is a drill-down, not a headline: it sits as a plain column on
    fct_role_audience, so anyone who wants German oncologists can filter
    there.
*/

select
    role_key,
    role_label,
    count(*)                                            as identified,
    countif(in_cdp)                                     as in_cdp,
    countif(is_marketable)                              as marketable,
    countif(is_advertisable)                            as advertisable,
    countif(is_legitimate_interest)                     as legitimate_interest,
    countif(is_book_author)                             as book_author,
    /*
        REACHABLE IS ANY OF THE FOUR, from 2026-11-10. It was the two
        opt-ins until 16 October, then three when legitimate interest was
        added, and book-author consent makes four - a decision Merve had
        already taken, against a column that was in the source and simply
        not selected.
    */
    countif(is_marketable or is_advertisable
            or is_legitimate_interest or is_book_author) as reachable,
    safe_divide(countif(in_cdp), count(*))              as cdp_coverage,
    safe_divide(countif(is_marketable or is_advertisable or is_legitimate_interest
                        or is_book_author),
                count(*))                               as reachable_rate,
    round(avg(role_final_score), 3)                     as avg_score,
    max(scored_date)                                    as scored_date
from {{ ref('fct_role_audience') }}
group by role_key, role_label
order by identified desc
