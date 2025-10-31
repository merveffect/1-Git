{{ config(
    materialized = "incremental",
    partition_by = {"field": "date"},
    tags= ["daily", "transposed_awa1", "transposed_views"],
    cluster_by = ["campaign", "sub_channels", "journal_title"]
 )}}


WITH
  main AS (
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
    pi_reach_fta AS ReachFTA,
    research_article_readership AS ResearchArticleReadership,
    journal_engagement AS JournalEngagement,
    CAST(search_volume AS float64) AS SearchVolume,
    cost AS Cost,
    clicks AS Clicks,
    impressions AS Impressions
  FROM
    {{ref('j7')}}
     {% if is_incremental() %}
  WHERE date BETWEEN 
        COALESCE(
          DATE('{{ var("backfill_start_date", "") }}') ,
          DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY)
        )
        AND
        COALESCE(
          DATE('{{ var("backfill_end_date", "") }}') ,
          DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY)
        )
{% else %}
  WHERE date BETWEEN DATE('{{ var("start_date", "2024-01-01") }}')
                  AND DATE('{{ var("end_date", "2025-12-31") }}')
{% endif %}
    )
SELECT
  *
FROM
  main
UNPIVOT
  (numbers FOR metric IN (sessions,
      ReachFTA,
      JournalEngagement,
      SearchVolume,
      ResearchArticleReadership))
