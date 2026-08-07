{% macro cdp_domain_targets() %}

    cdp as (

        select
            canonical_segment_id,
            email,
            researcher_id,
            snid,
            institution_name
        from {{ source('prod_audience_explorer_analytics_dbt_presentation', 'audience_builder_big') }}
        where (mkt_pref_opt_in = true or is_legitimate_interest_author_opted_in = true)
          and (institution_name is null or trim(institution_name) = '')
          and email is not null

    ),

    with_domain as (

        select
            *,
            {{ extract_email_domain('email') }} as email_domain
        from cdp

    )

{% endmacro %}