


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
    `snproject-cbb9ca25`.`dbt_dev_ga4_ria_researcher_report`.`j7`
     
  WHERE date BETWEEN 
        COALESCE(
          DATE('2025-01-01') ,
          DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY)
        )
        AND
        COALESCE(
          DATE('2025-01-05') ,
          DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY)
        )

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