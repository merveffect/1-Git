{{ config(materialized='table', cluster_by=['role_key']) }}

/*
    AUDIENCE OUTPUT - the table the agent and the marketing team read.

    Consent flags are joined here. Measured on the real data:
    1.76M people carry an SNID, 96% of them exist in CDP, but only 24%
    have marketing consent and 19% advertising consent. So the number
    that matters is not "how many did we find" but "how many can we
    actually reach".
*/

with roles as (

    select * from {{ ref('fct_researcher_roles') }}

),

cdp as (

    select
        snid,
        mkt_pref_opt_in,
        advertising_opt_in,
        true as in_cdp
    from {{ ref('raw_audience_builder_big') }}

)

select
    r.snid,
    r.role_key,
    r.role_detail,
    r.role_label,
    r.role_final_score,
    r.country_code,
    r.is_current,
    r.source_key,
    r.source_last_updated,
    r.derived_from_role,

    -- evidence chain: WHY this person is in the list
    r.evidence_title,
    r.evidence_org,
    r.evidence_dept,

    -- reachability
    coalesce(c.in_cdp, false)               as in_cdp,
    coalesce(c.mkt_pref_opt_in, false)      as is_marketable,
    coalesce(c.advertising_opt_in, false)   as is_advertisable,

    r.scored_date
from roles r
left join cdp c using (snid)
