-- Phase 1B identity: combined email -> client_id (Colab mis_2_email_clientid_v3).
-- Union of the enabled identity branches. Each branch is toggled by an
-- identity_include_* var (see dbt_project.yml + docs/assumptions-register.md).
--
-- SN-REVIEW (A1-A7): defaults keep the ACTIVE branches (cdp_new, ga4_sap, braze) and
-- DROP the deprecated ones (cdp_legacy frozen 2025-09-04, cdp_user_traits frozen
-- 2025-02-05, snid path) — verified stale on BigQuery. Enable a branch by flipping
-- its var. Conflict handling is 'keep_all' (Colab behaviour: keep every distinct
-- email/client_id pair). A 'priority' strategy is not implemented until SN defines
-- the precedence order.

{% if var('identity_conflict_strategy') != 'keep_all' %}
    {{ exceptions.raise_compiler_error("identity_conflict_strategy='" ~ var('identity_conflict_strategy') ~ "' is not implemented. SN must define the precedence order before a 'priority' union can be built.") }}
{% endif %}

{% set selects = [] %}
{% if var('identity_include_cdp_new') %}
    {% do selects.append("select author_email as email, clientid as client_id from " ~ ref('int_email_clientid_cdp_new')) %}
{% endif %}
{% if var('identity_include_ga4_sap') %}
    {% do selects.append("select author_email as email, clientid as client_id from " ~ ref('int_ga4_sap_clientid')) %}
{% endif %}
{% if var('identity_include_braze') %}
    {% do selects.append("select author_email as email, client_id from " ~ ref('int_braze_email_clientid')) %}
{% endif %}
{% if var('identity_include_cdp_legacy') %}
    {% do selects.append("select author_email as email, clientid as client_id from " ~ source('mis_prod', 'mis_2_email_clientid')) %}
{% endif %}
{% if var('identity_include_cdp_user_traits') %}
    {% do selects.append("select author_email as email, clientid as client_id from " ~ source('mis_prod', 'mis_2_email_clientid_cdp')) %}
{% endif %}
{% if var('identity_include_snid') %}
    {% do selects.append("select email, client_id from " ~ source('mis_prod', 'mis_1_email_clientid')) %}
{% endif %}

{% if selects | length == 0 %}
    {{ exceptions.raise_compiler_error("No identity branches enabled: set at least one identity_include_* var to true.") }}
{% endif %}

select email, client_id
from (
    {{ selects | join('\n    union all\n    ') }}
)
where email is not null
  and client_id is not null
group by 1, 2
