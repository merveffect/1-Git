-- ============================================================================
-- 57. THE HEALTHCARE VALIDATION EXTRACT SENT TO SPRINGER MEDICINE
--
--     WHAT THIS FILE IS FOR. It is the record of exactly what was shared,
--     with whom, under which permission and why those columns and no others.
--     The governance conversation that led to it is explicit about purpose, so
--     the answer to "what did you send" should be a committed file rather than
--     somebody's memory of an email.
--
--     THE PERMISSION, from the chain of 11-26 November 2026. Springer
--     Medicine holds the OAD healthcare dataset. Handing that dataset TO us
--     would be a new processing purpose under the SN Intra Group Transfer
--     Guidelines and would need documentation and approval. The alternative
--     agreed instead: Springer Medicine already has a documented purpose to
--     use the health data in their own sandbox for the Insight Engine work,
--     so they run the matching there and return the ANALYSIS RESULTS. We send
--     the population to be matched - no OAD data moves to us.
--
--     ONE THING THAT IS NOT YET COVERED AND IS NOT A BLOCKER TODAY. That
--     permission covers the ANALYSIS. Using what comes back to change
--     delivered audiences and then market to those people is productive use
--     and needs its own documented purpose on our side. Worth remembering at
--     the point the results arrive, which is when productive use begins.
--
--     WHY A TABLE RATHER THAN A FILE. Access is granted and logged, nothing
--     travels by email, and the shared object can be revoked. The same
--     reasoning that removed validation_samples/ from this repository on
--     2026-11-05 applies to an attachment.
--
--     WHY THESE SIX COLUMNS AND NOTHING ELSE. The match runs on the email
--     address, so snid, contact_email and country_code are the minimum that
--     makes it possible. The four flags are ours, not theirs to validate -
--     they are in the file so that whatever comes back is segmented by our
--     own labels rather than arriving as one undifferentiated percentage.
--     Job title, organisation and department are deliberately ABSENT: they do
--     not help an email match, and title plus a small employer is the
--     combination that can point at one person.
--
--     WHY DACH AND NOT GERMANY ALONE. Merve, 2026-11-26: let them validate
--     whatever they can and we will narrow afterwards. Austria and
--     Switzerland are in because their data is DACH. Everything beyond DACH
--     is out because it cannot match and sending it would enlarge a transfer
--     that was negotiated on scope.
--
--     ⭐ HOW TO READ THE RESULT WHEN IT ARRIVES, WRITTEN BEFORE IT DOES so
--     that the reading is not fitted to the number.
--
--     1. 63% of this extract carries the RESEARCHER flag and 26% the
--        PRACTITIONER flag. Our healthcare audience is deliberately broad and
--        includes biomedical researchers, which marketing ruled in on 11
--        November. If OAD is a physician dataset, most of the researchers
--        SHOULD fail to match, and that is a difference in definition rather
--        than an error. A single match rate over the whole extract is not
--        interpretable. Per-flag rates are.
--     2. A non-match is not evidence of a wrong classification unless OAD
--        coverage is high. The only prior figure we have is Springer
--        Medicine's own: around 24% of Research Marketing HCPs were found in
--        OAD in summer 2026. At that overlap most non-matches mean "not in
--        OAD" rather than "not a clinician". The covering letter asks for the
--        coverage alongside the results for exactly this reason.
--     3. We asked whether OAD covers physicians only or also nurses,
--        physiotherapists, dietitians and midwives. We hold those people. If
--        OAD is physicians only, their non-match is definitional and must not
--        be read as an error.
--
--     AND WHAT WAS DELIBERATELY NOT FIXED BEFORE SENDING. The temptation was
--     to clean the healthcare audience first. Five things stay in on purpose,
--     because this is the only external check the project has ever had and
--     correcting them from our own guesses would spend the chance to have
--     those guesses tested. A bare `md` with no clinical department. The four
--     part-regulated roles - mental health support workers, genetic
--     counsellors, counsellors, clinical scientists. The 3,840 people in the
--     0.60-0.70 roll-up band. The `dr` decision, which we took ourselves and
--     nobody outside has ever checked. And allied health.
-- ============================================================================

--      THE SELECT ONLY. It was run wrapped in
--      CREATE OR REPLACE TABLE <presentation>.hcp_validation_dach_2026_11_26
--      on 2026-11-26, returning 9,089 rows. The wrapper is not kept here
--      because the destination is not a dbt model and setup/check_analyses.py
--      cannot resolve it - the definition of WHAT was shared is this query,
--      and that is the part worth keeping under review.
-- ----------------------------------------------------------------------------
with hcp as (

    /*  Filtered BEFORE the grouping, not after. Two reasons. A HAVING on an
        aggregate that the select list has already aliased is an aggregation
        of an aggregation and BigQuery refuses it. And the flags should
        describe the person's DACH roles: somebody who practises in Germany
        and researches in the United States should carry the practitioner
        flag alone here.

        It also changes the count. Filtering after the grouping picked one
        country per person with ANY_VALUE and lost 22 people who hold records
        in two countries - 9,067 against the 9,089 this produces. The letter
        quotes the table, not the earlier estimate.  */

    select snid, contact_email, country_code, role_key
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_presentation.fct_role_audience`
    where role_label = 'CONFIRMED'
      and role_key in ('hcp_broad', 'hcp_practitioner', 'hcp_researcher',
                       'hcp_administrator', 'pharmacist')
      and country_code in ('DE', 'AT', 'CH')
      and contact_email is not null

)

select
    snid,
    /*  MIN rather than ANY_VALUE so the table is reproducible. It is shared,
        and a re-run that silently returns different values for the same
        person is the kind of thing nobody checks until it matters.  */
    min(contact_email)                          as contact_email,
    min(country_code)                           as country_code,
    logical_or(role_key = 'hcp_practitioner')   as is_practitioner,
    logical_or(role_key = 'hcp_researcher')     as is_researcher,
    logical_or(role_key = 'hcp_administrator')  as is_administrator,
    logical_or(role_key = 'pharmacist')         as is_pharmacist
from hcp
group by snid
;


-- ----------------------------------------------------------------------------
-- 57.1 THE FIGURES QUOTED IN THE COVERING LETTER.
--
--      Computed from the SAME source and filters as the extract above rather
--      than from the shared table, so this runs whether or not that table
--      exists and stays checkable by setup/check_analyses.py - it references
--      only real models. A number in a letter to another team has to match
--      the object it describes, and the earlier per-country estimate did not.
--
--      RESULT 2026-11-26, and these are the figures the covering letter
--      quotes:
--
--        people            9,089
--        pct_researcher     62.0
--        pct_practitioner   26.0
--
--      The letter went out saying 63% rather than 62%. It changes nothing in
--      the argument it supports - most of this extract is researchers, so a
--      low overall match rate is a definition difference and not an error -
--      and no correction was sent. Recorded here so the follow-up quotes the
--      table rather than the letter.
-- ----------------------------------------------------------------------------
with hcp as (

    select snid, role_key
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_presentation.fct_role_audience`
    where role_label = 'CONFIRMED'
      and role_key in ('hcp_broad', 'hcp_practitioner', 'hcp_researcher',
                       'hcp_administrator', 'pharmacist')
      and country_code in ('DE', 'AT', 'CH')
      and contact_email is not null

),

per_person as (

    select
        snid,
        logical_or(role_key = 'hcp_practitioner')   as is_practitioner,
        logical_or(role_key = 'hcp_researcher')     as is_researcher,
        logical_or(role_key = 'hcp_administrator')  as is_administrator,
        logical_or(role_key = 'pharmacist')         as is_pharmacist
    from hcp
    group by snid

)

select
    count(*)                                            as people,
    countif(is_practitioner)                            as practitioner,
    countif(is_researcher)                              as researcher,
    countif(is_administrator)                           as administrator,
    countif(is_pharmacist)                              as pharmacist,
    countif(not (is_practitioner or is_researcher
                 or is_administrator or is_pharmacist)) as broad_only,
    round(100 * countif(is_researcher)   / count(*))    as pct_researcher,
    round(100 * countif(is_practitioner) / count(*))    as pct_practitioner
from per_person
;
