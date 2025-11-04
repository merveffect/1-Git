
  
    

    create or replace table `snproject-cbb9ca25`.`dbt_dev_ga4_ria_researcher_report`.`j1_ga`
      
    partition by date
    

    
    OPTIONS(
      description=""""""
    )
    as (
      

WITH
  main AS (
  SELECT
    * EXCEPT(country),
    REGEXP_REPLACE(LOWER(country), '&(.)', 'and ') AS country
  FROM
    `snproject-cbb9ca25`.`dbt_dev_ga4_ria_researcher_report`.`g1_ga`
     
  WHERE date BETWEEN DATE('2024-01-01')
                  AND DATE('2025-11-01')

    ),
  regions AS (
  SELECT
    DISTINCT REGEXP_REPLACE(LOWER(country), '&(.)', 'and ') AS regions_country,
    LOWER(isoalphatwo) AS isoalphatwo,
    LOWER(world_region) AS world_region
  FROM
    `snproject-cbb9ca25`.`ga4_ria_researcher_report`.`regions` ),
  joined_data AS (
  SELECT
    *
  FROM
    main
  LEFT JOIN
    regions
  ON
    main.country = regions_country ),
  aggregations AS (
  SELECT
    * EXCEPT(regions_country,
      country,
      Hostname___GA4__Google_Analytics,
      kpi_marbl_leads,
      Sessions,
      ga4_reach_books_publishing_guidelines,
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
      journal_engagement,
      research_article_readership,
      source_readership,
      ejp_submission_start,
      ejp_submission_complete,
      nav_sign_up_for_alerts ),
    SUM(kpi_marbl_leads) AS kpi_marbl_leads,
    SUM(Sessions) AS Sessions,
    SUM(ga4_reach_books_publishing_guidelines) AS ga4_reach_books_publishing_guidelines,
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
    SUM(journal_engagement) AS journal_engagement,
    SUM(research_article_readership) AS research_article_readership,
    SUM(source_readership) AS source_readership,
    SUM(ejp_submission_start) AS ejp_submission_start,
    SUM(ejp_submission_complete) AS ejp_submission_complete,
    SUM(nav_sign_up_for_alerts) AS nav_sign_up_for_alerts,
    SUM(CASE
        WHEN main_channels = 'seo' THEN Sessions
        ELSE 0
    END
      ) AS search_volume
  FROM
    joined_data
  GROUP BY
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
    12,
    13,
    14,
    15,
    16,
    17,
    18,
    19,
    20,
    21)
    --final table
SELECT
  *
FROM
  aggregations
    );
  