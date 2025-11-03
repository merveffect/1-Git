
{{ config(
    materialized = "incremental",
    tags= ["daily", "transposed_nurture", "transposed_views"],
    partition_by = {"field": "date"},
    cluster_by = ["campaign", "sub_channels", "journal_title"]
 )}}

SELECT
  *
FROM (
  SELECT
    -- those are the once kept as columns
    date,
    world_region,
    country,
    main_channels,
    sub_channels,
    imprint,
    researchER_marketing_activity,
    research_marketing_activity,
    journal_title,
    journal_id,
    business_model,
    main_group,
    portfolio,
    campaign,
    campaign_code,
    goal_code,
    oatype,
    status,
    campaign_category,
    workspace_category,
    workspace_name,
    -- those are the once unpivoted and but into one column
    CAST(sessions AS FLOAT64) AS Sessions,
    ELS,
    kpi_reach_submission_guideline_pages AS VisitSubmissionGuidelinesPage,
    kpi_submit_click AS SubmitClick,
    kpi_reach_about_pages AS ReachAboutPages,
    cost AS Cost,
    clicks AS Clicks,
    impressions AS Impressions
  FROM
    {{ref('j7')}}
    {% if is_incremental() %}
  {% set backfill_start = var("backfill_start_date", none) %}
  {% set backfill_end = var("backfill_end_date", none) %}
  WHERE date BETWEEN 
    {% if backfill_start %}
      DATE('{{ backfill_start }}')
    {% else %}
      DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY)
    {% endif %}
    AND
    {% if backfill_end %}
      DATE('{{ backfill_end }}')
    {% else %}
      DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY)
    {% endif %}
{% else %}
  WHERE date BETWEEN DATE('{{ var("start_date", "2024-01-01") }}')
                  AND DATE('{{ var("end_date", "2025-12-31") }}')
{% endif %}
    )
UNPIVOT
  (numbers FOR metric IN (sessions,
      ELS,
      VisitSubmissionGuidelinesPage,
      SubmitClick,
      ReachAboutPages))
