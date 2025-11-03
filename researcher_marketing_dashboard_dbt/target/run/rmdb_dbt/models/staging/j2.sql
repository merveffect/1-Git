-- back compat for old kwarg name
  
  
        
    

    

    merge into `snproject-cbb9ca25`.`dbt_dev_ga4_ria_researcher_report`.`j2` as DBT_INTERNAL_DEST
        using (

WITH
  step3 AS (
  SELECT
    date,
    campaign,
    SOURCE,
    medium,
    sub_channels,
    main_channels,
    journal_title,
    journal_id,
    business_model,
    main_discipline,
    main_group,
    portfolio,
    isoalphatwo,
    world_region,
    imprint,
    SUM(kpi_marbl_leads) AS kpi_marbl_leads,
    SUM(Sessions) AS Sessions,
    SUM(ga4_reach_books_publishing_guidelines) AS pi_publishing_guidelines,
    SUM(EngagedSessions) AS EngagedSessions,
    SUM(ELS) AS ELS,
    SUM(snapp_submission_complete) AS snapp_submission_complete,
    SUM(content_consumption) AS content_consumption,
    SUM(reach_india_apc_thankyou) AS reach_india_apc_thankyou,
    SUM(reach_oa_general) AS reach_oa_general,
    SUM(snapp_submission_start) AS snapp_submission_start,
    SUM(kpi_submit_click) AS kpi_submit_click,
    SUM(pi_reach_fta) AS pi_reach_fta,
    SUM(kpi_reach_submission_guideline_pages) AS kpi_reach_submission_guideline_pages,
    SUM(kpi_reach_about_pages) AS kpi_reach_about_pages,
    SUM(pi_contact_an_editor) AS pi_contact_an_editor,
    SUM(kpi_submit_your_book_idea) AS kpi_submit_your_book_idea,
    SUM(reach_b2c_blog_page) AS reach_b2c_blog_page,
    SUM(ta_file_download) AS ta_file_download,
    SUM(search_volume) AS search_volume,
    SUM(journal_engagement) AS journal_engagement,
    SUM(research_article_readership) AS research_article_readership,
    SUM(source_readership) AS source_readership,
    SUM(ejp_submission_start) AS ejp_submission_start,
    SUM(ejp_submission_complete) AS ejp_submission_complete,
    SUM(nav_sign_up_for_alerts) AS nav_sign_up_for_alerts
  FROM
    `snproject-cbb9ca25`.`dbt_dev_ga4_ria_researcher_report`.`j1_ga`
    
  
  
  WHERE date BETWEEN 
    
      DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY)
    
    AND
    
      DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY)
    

  GROUP BY
    date,
    campaign,
    SOURCE,
    medium,
    sub_channels,
    main_channels,
    journal_title,
    journal_id,
    business_model,
    main_discipline,
    main_group,
    portfolio,
    isoalphatwo,
    world_region,
    imprint ),
  cost AS (
  SELECT
    SUM(cost) AS cost,
    SUM(clicks) AS clicks,
    SUM(impressions) AS impressions,
    date AS cost_date,
    campaign AS cost_campaign,
    SOURCE AS cost_source,
    medium AS cost_medium,
    sub_channels AS cost_sub_channels,
    main_channels AS cost_main_channels,
    isoalphatwo AS cost_isoalphatwo,
    world_region AS cost_world_region
  FROM
    `snproject-cbb9ca25`.`dbt_dev_ga4_ria_researcher_report`.`j1_mktp`
    
  
  
  WHERE date BETWEEN 
    
      DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY)
    
    AND
    
      DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY)
    

  GROUP BY
    cost_date,
    cost_campaign,
    cost_source,
    cost_medium,
    cost_sub_channels,
    cost_main_channels,
    cost_isoalphatwo,
    cost_world_region ),
  joined_data AS (
  SELECT
    *
  FROM
    step3
  FULL JOIN
    cost
  ON
    step3.date = cost.cost_date
    AND step3.campaign = cost.cost_campaign
    AND step3.source = cost.cost_source
    AND step3.medium = cost.cost_medium
    AND step3.sub_channels = cost.cost_sub_channels
    AND step3.main_channels = cost.cost_main_channels
    AND step3.isoalphatwo = cost.cost_isoalphatwo ),
  exclude_columns AS (
  SELECT
    * EXCEPT( date,
      cost_date,
      campaign,
      cost_campaign,
      SOURCE,
      cost_source,
      medium,
      cost_medium,
      isoalphatwo,
      cost_isoalphatwo,
      world_region,
      cost_world_region,
      sub_channels,
      cost_sub_channels,
      main_channels,
      cost_main_channels ),
    COALESCE(date, cost_date) AS date,
    COALESCE(campaign, cost_campaign) AS campaign,
    COALESCE(SOURCE, cost_source) AS SOURCE,
    COALESCE(medium, cost_medium) AS medium,
    COALESCE(main_channels, cost_main_channels) AS main_channels,
    COALESCE(sub_channels, cost_sub_channels) AS sub_channels,
    COALESCE(isoalphatwo, cost_isoalphatwo) AS isoalphatwo,
    COALESCE(world_region, cost_world_region) AS world_region
  FROM
    joined_data ),
  aggregations AS (
  SELECT
    date,
    campaign,
    SOURCE,
    medium,
    main_channels,
    sub_channels,
    journal_title,
    journal_id,
    business_model,
    main_discipline,
    main_group,
    portfolio,
    isoalphatwo,
    world_region,
    imprint,
    SUM(cost) AS cost,
    SUM(kpi_marbl_leads) AS kpi_marbl_leads,
    SUM(Sessions) AS Sessions,
    SUM(pi_publishing_guidelines) AS pi_publishing_guidelines,
    SUM(EngagedSessions) AS EngagedSessions,
    SUM(ELS) AS ELS,
    SUM(snapp_submission_complete) AS snapp_submission_complete,
    SUM(content_consumption) AS content_consumption,
    SUM(reach_india_apc_thankyou) AS reach_india_apc_thankyou,
    SUM(reach_oa_general) AS reach_oa_general,
    SUM(snapp_submission_start) AS snapp_submission_start,
    SUM(kpi_submit_click) AS kpi_submit_click,
    SUM(pi_reach_fta) AS pi_reach_fta,
    SUM(kpi_reach_submission_guideline_pages) AS kpi_reach_submission_guideline_pages,
    SUM(kpi_reach_about_pages) AS kpi_reach_about_pages,
    SUM(pi_contact_an_editor) AS pi_contact_an_editor,
    SUM(kpi_submit_your_book_idea) AS kpi_submit_your_book_idea,
    SUM(reach_b2c_blog_page) AS reach_b2c_blog_page,
    SUM(ta_file_download) AS ta_file_download,
    SUM(search_volume) AS search_volume,
    SUM(journal_engagement) AS journal_engagement,
    SUM(clicks) AS clicks,
    SUM(impressions) AS impressions,
    SUM(research_article_readership) AS research_article_readership,
    SUM(source_readership) AS source_readership,
    SUM(ejp_submission_start) AS ejp_submission_start,
    SUM(ejp_submission_complete) AS ejp_submission_complete,
    SUM(nav_sign_up_for_alerts) AS nav_sign_up_for_alerts
  FROM
    exclude_columns
  GROUP BY
    date,
    campaign,
    SOURCE,
    medium,
    main_channels,
    sub_channels,
    journal_title,
    journal_id,
    business_model,
    main_discipline,
    main_group,
    portfolio,
    isoalphatwo,
    world_region,
    imprint ),
  sort_rows AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY date, campaign, SOURCE, medium, sub_channels, isoalphatwo ORDER BY Sessions DESC ) AS ROW
  FROM
    aggregations )
SELECT
  * EXCEPT(cost,
    clicks,
    impressions),
  CASE
    WHEN ROW = 1 AND isoalphatwo IS NOT NULL THEN cost
    WHEN isoalphatwo IS NULL THEN cost
    ELSE 0
END
  AS cost,
  CASE
    WHEN ROW = 1 AND isoalphatwo IS NOT NULL THEN clicks
    WHEN isoalphatwo IS NULL THEN clicks
    ELSE 0
END
  AS clicks,
  CASE
    WHEN ROW = 1 AND isoalphatwo IS NOT NULL THEN impressions
    WHEN isoalphatwo IS NULL THEN impressions
    ELSE 0
END
  AS impressions
FROM
  sort_rows
        ) as DBT_INTERNAL_SOURCE
        on (FALSE)

    

    when not matched then insert
        (`date`, `campaign`, `SOURCE`, `medium`, `main_channels`, `sub_channels`, `journal_title`, `journal_id`, `business_model`, `main_discipline`, `main_group`, `portfolio`, `isoalphatwo`, `world_region`, `imprint`, `kpi_marbl_leads`, `Sessions`, `pi_publishing_guidelines`, `EngagedSessions`, `ELS`, `snapp_submission_complete`, `content_consumption`, `reach_india_apc_thankyou`, `reach_oa_general`, `snapp_submission_start`, `kpi_submit_click`, `pi_reach_fta`, `kpi_reach_submission_guideline_pages`, `kpi_reach_about_pages`, `pi_contact_an_editor`, `kpi_submit_your_book_idea`, `reach_b2c_blog_page`, `ta_file_download`, `search_volume`, `journal_engagement`, `research_article_readership`, `source_readership`, `ejp_submission_start`, `ejp_submission_complete`, `nav_sign_up_for_alerts`, `ROW`, `cost`, `clicks`, `impressions`)
    values
        (`date`, `campaign`, `SOURCE`, `medium`, `main_channels`, `sub_channels`, `journal_title`, `journal_id`, `business_model`, `main_discipline`, `main_group`, `portfolio`, `isoalphatwo`, `world_region`, `imprint`, `kpi_marbl_leads`, `Sessions`, `pi_publishing_guidelines`, `EngagedSessions`, `ELS`, `snapp_submission_complete`, `content_consumption`, `reach_india_apc_thankyou`, `reach_oa_general`, `snapp_submission_start`, `kpi_submit_click`, `pi_reach_fta`, `kpi_reach_submission_guideline_pages`, `kpi_reach_about_pages`, `pi_contact_an_editor`, `kpi_submit_your_book_idea`, `reach_b2c_blog_page`, `ta_file_download`, `search_volume`, `journal_engagement`, `research_article_readership`, `source_readership`, `ejp_submission_start`, `ejp_submission_complete`, `nav_sign_up_for_alerts`, `ROW`, `cost`, `clicks`, `impressions`)


    