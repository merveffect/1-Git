

  create or replace view `dat-analytics-eng-ec869189`.`dev_orcid_role_identifier_raw`.`raw_audience_builder_big`
  OPTIONS(
      description="""CDP contacts, narrowed to the four columns this pipeline consumes: snid, email, mkt_pref_opt_in, advertising_opt_in. Presence in this table is what \"in_cdp\" means downstream. Phase-2 behavioural columns are deliberately left out until behaviour is scored.\n"""
    )
  as 

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

select
    snid,
    email,
    mkt_pref_opt_in,
    advertising_opt_in
from `dat-analytics-eng-ec869189`.`prod_audience_explorer_analytics_dbt_presentation`.`audience_builder_big`
where snid is not null;

