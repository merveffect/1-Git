

WITH
  main AS (
  SELECT
    *
  FROM
    `snproject-cbb9ca25`.`dbt_dev_ga4_ria_researcher_report`.`j2`
     
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

    ),
  countries AS (
  SELECT
    DISTINCT LOWER(isoalphatwo) AS country_isoalphatwo,
    country
  FROM
    `snproject-cbb9ca25`.`dbt_dev_ga4_ria_researcher_report`.`countries` ),
  joined_data AS (
  SELECT
    *
  FROM
    main
  LEFT JOIN
    countries
  ON
    main.isoalphatwo = countries.country_isoalphatwo ),
  required_data AS (
  SELECT
    date,
    campaign,
    SOURCE,
    medium,
    main_channels,
    sub_channels,
    country,
    isoalphatwo,
    world_region,
    journal_title,
    journal_id,
    business_model,
    main_discipline,
    main_group,
    portfolio,
    imprint,
    kpi_marbl_leads,
    Sessions,
    pi_publishing_guidelines,
    EngagedSessions,
    ELS,
    snapp_submission_complete,
    content_consumption,
    reach_india_apc_thankyou,
    reach_oa_general,
    snapp_submission_start,
    kpi_submit_click,
    pi_reach_fta,
    kpi_reach_submission_guideline_pages,
    kpi_reach_about_pages,
    pi_contact_an_editor,
    kpi_submit_your_book_idea,
    reach_b2c_blog_page,
    ta_file_download,
    search_volume,
    journal_engagement,
    research_article_readership,
    source_readership,
    ejp_submission_start,
    ejp_submission_complete,
    nav_sign_up_for_alerts,
    cost,
    clicks,
    impressions
  FROM
    joined_data),
  transformation_one AS (
  SELECT
    *,
    SUBSTRING(campaign, INSTR(campaign, '_', 1, 3) + 1) AS campaign_name_cleaned
  FROM
    required_data ),
  transformation_two AS (
  SELECT
    * EXCEPT(campaign_name_cleaned),
    CASE
      WHEN NOT REGEXP_CONTAINS(campaign,r'.*[a-zA-Z]{4}_[a-zA-Z0-9]{5}_[a-zA-Z0-9]{4}_[a-zA-Z0-9]{2}_[a-zA-Z0-9]{4}_[a-zA-Z0-9]{5}_.+$') THEN campaign
      WHEN REGEXP_CONTAINS(campaign, r'^[a-zA-Z]{4}_[a-zA-Z0-9]{5}_[a-zA-Z0-9]{4}_[a-zA-Z0-9]{2}_[a-zA-Z0-9]{4}_[a-zA-Z0-9]{5}_.+$')THEN campaign
      ELSE campaign_name_cleaned
  END
    AS clean_campaign
  FROM
    transformation_one ),
  transformation_three AS (
  SELECT
    *,
    -- this code splits the campaign naming convention into components which are later used in groupings
    REGEXP_EXTRACT(LOWER(clean_campaign),r'([A-z]{4})_[A-z0-9]{5}_[A-z0-9]{4}_.._[A-z0-9]{4}_[A-z0-9\-]{5}.*') AS audience_code,
    REGEXP_EXTRACT(LOWER(clean_campaign),r'[A-z]{4}_([A-z0-9]{5})_[A-z0-9]{4}_.._[A-z0-9]{4}_[A-z0-9\-]{5}.*') AS product_code,
    REGEXP_EXTRACT(LOWER(clean_campaign),r'[A-z]{4}_[A-z0-9]{5}_([A-z0-9]{4})_.._[A-z0-9]{4}_[A-z0-9\-]{5}.*') AS goal_code,
    REGEXP_EXTRACT(LOWER(clean_campaign),r'[A-z]{4}_[A-z0-9]{5}_[A-z0-9]{4}_.._[A-z0-9]{4}_([A-z0-9\-]{5}).*') AS campaign_code,
    --- China inclusion of old naming convention campaigns
    CASE
      WHEN REGEXP_CONTAINS(LOWER(clean_campaign), 'bscn_|srcn_|ddcn_|jrcn_') THEN "cn"
      ELSE REGEXP_EXTRACT(LOWER(clean_campaign),r'[A-z]{4}_[A-z0-9]{5}_[A-z0-9]{4}_(..)_[A-z0-9]{4}_[A-z0-9\-]{5}.*')
  END
    AS geo_code,
    CASE
      WHEN REGEXP_CONTAINS(LOWER(clean_campaign), 'bscn_|srcn_|ddcn_|jrcn_') THEN "cnpl"
      ELSE REGEXP_EXTRACT(LOWER(clean_campaign),r'[A-z]{4}_[A-z0-9]{5}_[A-z0-9]{4}_.._([A-z0-9]{4})_[A-z0-9\-]{5}.*')
  END
    AS team_code,
    --- China end
    -- campaing name split end
  FROM
    transformation_two )
    -- final table
SELECT
  *,
  CASE
    WHEN REGEXP_CONTAINS(product_code,'(discv|hybrd|jrnls|najrn|natoa|oajrn|pf001|pf002|pf018|pf023|pf030|pf032|scirp|sproa|sprin)') OR product_code IN ( SELECT CAST(journal_id AS string) FROM `snproject-cbb9ca25`.`dbt_dev_ga4_ria_researcher_report`.`journalids` WHERE journal_id IS NOT NULL) THEN '1. journals'
    WHEN REGEXP_CONTAINS(product_code,'[0-9]{5}') THEN '1. journals'
    WHEN REGEXP_CONTAINS(product_code,'(books|mrefw|obook|pf006|pf007|pf008|pf009|pf010|pf014|pf021|pf027|print|sbook|tbook|gbook)') THEN '2. books'
    WHEN product_code IS NOT NULL THEN "3. mixed"
    -- groups China old naming convention campaigns into products (China team can't rename campaigns AND they are still running)
    WHEN REGEXP_CONTAINS(clean_campaign, '(ddcn|bscn|jrcn|srcn)') AND EXTRACT (year FROM date) = 2022 THEN '1. journals'
    ELSE '4. n/a'END products
FROM
  transformation_three