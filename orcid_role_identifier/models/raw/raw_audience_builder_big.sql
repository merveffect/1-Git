{{ config(materialized='view') }}

/*
    RAW LAYER - audience_builder_big  (CDP)

    Only the columns this pipeline actually consumes.

    WHY THESE FOUR:
      snid                identity - the join key to ORCID
      email               contact_email in the Braze contract
      mkt_pref_opt_in     consent to be contacted for marketing
      advertising_opt_in  consent to be targeted via paid channels

    Presence in this table is itself the signal for "in_cdp" - the
    downstream LEFT JOIN derives that, so it is not a column here.

    WHY NOT MORE:
    The Phase-2 behavioural signals (subject labels, submission imprint,
    eTOC engagement, OA article counts) live in CDP too, but this
    pipeline does not score behaviour yet. When it does, add the columns
    then - guessing now would carry cost for nothing.

    Country is deliberately NOT taken from here: ORCID gives us a
    per-employment country (organisation_address_country_code), which is
    more accurate than a profile-level one. A person can have a German
    profile and a UK post.

    !! VERIFY: the dataset holding this table. It is currently declared
       under researcher_profiles in models/raw/_sources.yml, taken from
       the Phase-2 document rather than from the schema.
*/

/*
    ONE ROW PER PERSON. The source carries 11 duplicate snids, which the
    unique test on this model caught. Eleven rows is nothing by volume,
    but a duplicate here fans a person out in every downstream join and,
    worse, leaves two conflicting answers to "may we contact them".

    Consent is collapsed with logical_and, not logical_or: a person counts
    as consented only if EVERY row for them says so. When the source
    disagrees with itself we do not get to pick the permissive reading -
    under-sending is recoverable and sending without consent is not.

    The email is taken with min() purely so the result is deterministic.
*/
select
    snid,
    min(email)                      as email,
    logical_and(coalesce(mkt_pref_opt_in, false))    as mkt_pref_opt_in,
    logical_and(coalesce(advertising_opt_in, false)) as advertising_opt_in
from {{ source('prod_audience_explorer_analytics_dbt_presentation', 'audience_builder_big') }}
where snid is not null
group by snid
