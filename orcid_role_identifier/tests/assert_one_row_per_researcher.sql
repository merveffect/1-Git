/*
    raw_orcid_researchers must hold exactly one row per SNID.

    The source keeps every version of a profile - about fourteen rows per
    person - and nothing in the column names says so. Before the dedup,
    every downstream count was inflated by that factor, and the numbers
    still looked plausible enough to quote. A person-level table is the
    one place a duplicate cannot be noticed by eye, so it is asserted
    rather than trusted.
*/

select
    snid,
    count(*) as rows_for_this_snid
from {{ ref('raw_orcid_researchers') }}
group by snid
having count(*) > 1
