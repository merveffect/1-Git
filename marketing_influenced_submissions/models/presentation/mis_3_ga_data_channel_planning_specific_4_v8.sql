-- Phase 8 presentation: channel-planning dashboard table (Colab
-- mis_3_ga_data_channel_planning_specific_4_v8). Adds out-to-review, journal metadata,
-- portfolio (from the journal portfolio reference) and region.
--
-- SN-REVIEW (E2): region / country_grouping come from snapp_regional_clusters, a
-- Google Sheets external table that SN's Drive scope blocks. The join is gated by the
-- enable_regional_clusters var (default false); until a native/seed equivalent exists,
-- region and country_grouping are null in dev.

{{ config(materialized='table', tags=['ga', 'presentation']) }}

select
    t3.month_start_date,
    t3.internal_submission_id,
    t3.trackable_sub,
    t3.source_system,
    t3.imprint_code,
    d.business_model,
    d.main_group,
    d.portfolio,
    t3.flag_power_author,
    t3.author_country,
    t3.is_in_collection,
    t3.rm_activity_1plus,
    t3.rm_activity_3plus,
    t3.collections_activity,
    t3.workspace_category,
    t3.funnel,
    t3.marmind_code,
    t3.main_channels,
    t3.sub_channels,
    t3.journal_id_submission,
    {% if var('enable_regional_clusters') %}
    region.region,
    region.country_grouping,
    {% else %}
    cast(null as string) as region,
    cast(null as string) as country_grouping,
    {% endif %}
    otr.out_to_review,
    jnl.journal_title
from {{ ref('int_channel_planning_3') }} t3

{% if var('enable_regional_clusters') %}
left join {{ source('e2e_b2c_researcher_dev', 'snapp_regional_clusters') }} region
    on lower(t3.author_country) = lower(region.country)
{% endif %}

left join {{ ref('int_snapp_otr') }} otr
    on t3.internal_submission_id = otr.submission_id

left join {{ ref('stg_journals') }} jnl
    on t3.journal_id_submission = jnl.journal_id

left join {{ ref('stg_journal_portfolio') }} d
    on cast(t3.journal_id_submission as int64) = cast(d.journal_id as int64)

where t3.source_system = "SNAPP"
