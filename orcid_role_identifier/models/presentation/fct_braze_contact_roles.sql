{{ config(materialized='table', cluster_by=['snid']) }}

/*
    ⭐ BRAZE DATA CONTRACT OUTPUT
    One row = one contact. The final schema delivered to Braze / MPC.

    ─────────────────────────────────────────────────────────────────────
    CRITICAL: THE FOUR ARRAYS MUST STAY POSITIONALLY ALIGNED

        role_inferred[0]                          <-> Healthcare Professional
        role_detailed_inferred[0]                 <-> Healthcare Professional - Practitioner
        role_inferred_data_source[0]              <-> Orcid
        role_inferred_data_source_last_updated[0] <-> 2026-09-29 10:00:00

    All four are derived from the SAME ordered CTE with the SAME ORDER BY.
    Writing four independent ARRAY_AGGs would drift silently, and Braze
    CANNOT detect it - the wrong person would land in the wrong role
    segment and nobody would notice.

    To change the ordering: dbt_project.yml -> contract.array_order
    ─────────────────────────────────────────────────────────────────────
*/

with audience as (

    select * from {{ ref('fct_role_audience') }}
    where role_label in ({{ sql_in_list(var('contract').include_labels) }})
      and {{ consent_predicate() }}

),

/*
    The same role can be asserted by several sources (ORCID + web
    scraping). Collapse to one row per role and join the sources.
*/
per_role as (

    select
        snid,
        role_key,
        {{ role_display_name_expr('role_key') }}    as role_inferred,

        -- "Healthcare Professional - Practitioner"
        concat(
            {{ role_display_name_expr('role_key') }},
            if(role_detail is null, '', concat('{{ var("contract").detail_separator }}', role_detail))
        )                                           as role_detailed_inferred,

        -- Source display name. One source today; when web scraping
        -- arrives, add a WHEN branch and switch this to a STRING_AGG so
        -- a role asserted by both reads 'Orcid + Web scraping'.
        max(case source_key when 'orcid' then 'Orcid' else source_key end)
                                                    as role_inferred_data_source,

        max(source_last_updated)                    as role_inferred_data_source_last_updated,
        max(role_final_score)                       as role_final_score,
        any_value(role_detail)                      as role_detail,
        any_value(country_code)                     as country_code,
        any_value(contact_email)                    as contact_email,
        any_value(is_marketable)                    as is_marketable,
        any_value(is_advertisable)                  as is_advertisable,
        any_value(in_cdp)                           as in_cdp
    from audience
    group by snid, role_key, role_detail

),

/*
    ONE ordered source. Every array is built from it.
    role_inferred is unique within a person, so the ordering is TOTAL -
    no ties, therefore alignment is guaranteed.
*/
ordered as (

    select * from per_role
    -- ORDER BY lives inside the ARRAY_AGGs below, identical in each

),

contact as (

    select
        snid,

        -- ── contract fields ──────────────────────────────────────────
        array_agg(role_inferred                             order by {{ contract_array_order() }})
            as role_inferred,
        array_agg(role_detailed_inferred                    order by {{ contract_array_order() }})
            as role_detailed_inferred,
        array_agg(role_inferred_data_source                 order by {{ contract_array_order() }})
            as role_inferred_data_source,
        array_agg(role_inferred_data_source_last_updated    order by {{ contract_array_order() }})
            as role_inferred_data_source_last_updated,

        -- ── internal: the canonical form that cannot drift ───────────
        array_agg(
            struct(
                role_key,
                role_inferred,
                role_detailed_inferred,
                role_inferred_data_source              as data_source,
                role_inferred_data_source_last_updated as last_updated,
                round(role_final_score, 3)             as confidence
            )
            order by {{ contract_array_order() }}
        )                                           as roles_struct,

        any_value(country_code)                     as country_code,
        any_value(contact_email)                    as contact_email,
        max(is_marketable)                          as is_marketable,
        max(is_advertisable)                        as is_advertisable,
        max(in_cdp)                                 as in_cdp
    from ordered
    group by snid

)

select
    /*
        contact_email comes from CDP (audience_builder_big.email), not
        from ORCID. ORCID emails are mostly PRIVATE and would be the
        wrong source even where they exist.
    */
    c.contact_email,
    c.snid,
    c.role_inferred,
    c.role_detailed_inferred,
    c.role_inferred_data_source,
    c.role_inferred_data_source_last_updated,

    -- outside the contract, for us
    c.roles_struct,
    c.country_code,
    array_length(c.role_inferred)                   as role_count,
    case
        when c.is_marketable then 'marketing_opt_in'
        when c.in_cdp        then 'legitimate_interest'
    end                                             as consent_basis,
    c.is_marketable,
    c.is_advertisable,
    current_date()                                  as contract_date
from contact c
