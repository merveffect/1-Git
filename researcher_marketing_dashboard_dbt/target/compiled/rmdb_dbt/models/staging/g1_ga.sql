

WITH
  -- Step 1: Prepare base GA4 data with cleaned dimensions
  base_data AS (
SELECT
  * EXCEPT(SOURCE,
    medium),
  LOWER(SOURCE) AS SOURCE,
  LOWER(medium) AS medium,
  LOWER(ad_content) AS ad_content,
  LOWER(google_ad_network) AS google_ad_network_b
FROM
  `snproject-cbb9ca25`.`dev_rmdb_dbt_staging`.`googleanalytics_and_marbl`
  
  
  WHERE date BETWEEN DATE('2024-01-01')
                  AND DATE('2025-11-09')



  ),
  -- Step 2: Get channel groupings with lowercase fields for join
  channel_groupings AS (
SELECT
  LOWER(SOURCE) AS SOURCE,
  LOWER(medium) AS medium,
  LOWER(adnetwork) AS adnetwork,
  sub_channels
FROM
  `snproject-cbb9ca25`.`ga4_ria_researcher_report`.`channel_groupings` ),
  -- Step 3: Join and aggregate metrics
  aggregated_metrics AS (
SELECT
  a.* EXCEPT(google_ad_network_b,
    ad_content,
    Sessions___GA4_event_based__Google_Analytics,
    ga4_click_submit_manuscript,
    ga4_reach_fta,
    ga4_reach_submission_guidelines,
    ga4_reach_about_page,
    ga4_reach_books_contact_editor_page,
    ga4_reach_books_publishing_guidelines,
    ga4_submit_your_book_idea_click,
    Engaged_sessions___GA4__Google_Analytics,
    ga4_engagement_leading_to_submission,
    ga4_reach_b2c_blog_page,
    ga4_snapp_submission_complete,
    ga4_content_consumption,
    ga4_reach_india_apc_thankyou,
    ga4_reach_oa_general,
    ga4_ta_file_download,
    ga4_snapp_submission_start,
    ga4_click_submit_manuscript_all_old_events,
    ga4_reach_b2c_blog_page_old_events,
    ga4_submit_your_book_idea_click_old_events,
    ga4_ta_file_download_all_old_events,
    ga4_reach_books_contact_editor_old_events,
    ga4_reach_full_text_article_old_events,
    ga4_reach_journal_about_old_events,
    ga4_reach_journal_submission_guidelines_old_events,
    ga4_journal_engagement,
    ga4_research_article_readership,
    ga4_source_readership,
    ga4_ejp_submission_start,
    ga4_ejp_submission_complete,
    ga4_nav_sign_up_for_alerts ),
  COALESCE(b.sub_channels,
    CASE
      WHEN REGEXP_CONTAINS(a.source, r"^(?:[^.]+\.)?(chatgpt|perplexity|claude|mistral|copilot|blackbox|felo|andisearch|komo|waldo|deepseek|scienceos|consensus|jasper|gemini\.google|chat\.openai|meta|search.jina)\.(?:ai|com|fyi|app)$") THEN "ai seo"
      WHEN a.medium = 'external_display' THEN 'other - external display'
      WHEN a.medium = 'paid_social' THEN 'other - paid social'
      WHEN a.medium = 'internal_display' THEN 'other - internal display'
      WHEN a.medium = 'affiliate' THEN 'main affiliate'
      WHEN a.medium = 'organic_social' THEN 'other - organic social'
      WHEN a.source LIKE '%toc%' AND a.medium='email' THEN 'etocs'
      WHEN a.medium = 'email' THEN 'email'
      WHEN a.medium = 'organic' THEN 'traditional seo'
      WHEN a.medium = 'referral' THEN 'referral'
      ELSE 'other channels'
  END
    ) AS sub_channels,
  SUM(IFNULL(Sessions___GA4_event_based__Google_Analytics,0)) AS Sessions,
  SUM(IFNULL(ga4_click_submit_manuscript,0)) AS ga4_click_submit_manuscript,
  SUM(IFNULL(ga4_reach_fta,0)) AS ga4_reach_fta,
  SUM(IFNULL(ga4_reach_submission_guidelines,0)) AS ga4_reach_submission_guidelines,
  SUM(IFNULL(ga4_reach_about_page,0)) AS ga4_reach_about_page,
  SUM(IFNULL(ga4_reach_books_contact_editor_page,0)) AS ga4_reach_books_contact_editor_page,
  SUM(IFNULL(ga4_reach_books_publishing_guidelines,0)) AS ga4_reach_books_publishing_guidelines,
  SUM(IFNULL(ga4_submit_your_book_idea_click,0)) AS ga4_submit_your_book_idea_click,
  SUM(IFNULL(Engaged_sessions___GA4__Google_Analytics,0)) AS EngagedSessions,
  SUM(IFNULL(ga4_engagement_leading_to_submission,0)) AS ELS,
  SUM(IFNULL(ga4_reach_b2c_blog_page,0)) AS ga4_reach_b2c_blog_page,
  SUM(IFNULL(ga4_snapp_submission_complete,0)) AS snapp_submission_complete,
  SUM(IFNULL(ga4_content_consumption,0)) AS content_consumption,
  SUM(IFNULL(ga4_reach_india_apc_thankyou,0)) AS reach_india_apc_thankyou,
  SUM(IFNULL(ga4_reach_oa_general,0)) AS reach_oa_general,
  SUM(IFNULL(ga4_ta_file_download,0)) AS ga4_ta_file_download,
  SUM(IFNULL(ga4_snapp_submission_start,0)) AS snapp_submission_start,
  SUM(IFNULL(ga4_click_submit_manuscript_all_old_events,0)) AS ga4_click_submit_manuscript_all_old_events,
  SUM(IFNULL(ga4_reach_b2c_blog_page_old_events,0)) AS ga4_reach_b2c_blog_page_old_events,
  SUM(IFNULL(ga4_submit_your_book_idea_click_old_events,0)) AS ga4_submit_your_book_idea_click_old_events,
  SUM(IFNULL(ga4_ta_file_download_all_old_events,0)) AS ga4_ta_file_download_all_old_events,
  SUM(IFNULL(ga4_reach_books_contact_editor_old_events,0)) AS ga4_reach_books_contact_editor_old_events,
  SUM(IFNULL(ga4_reach_full_text_article_old_events,0)) AS ga4_reach_full_text_article_old_events,
  SUM(IFNULL(ga4_reach_journal_about_old_events,0)) AS ga4_reach_journal_about_old_events,
  SUM(IFNULL(ga4_reach_journal_submission_guidelines_old_events,0)) AS ga4_reach_journal_submission_guidelines_old_events,
  SUM(IFNULL(ga4_journal_engagement,0)) AS journal_engagement,
  SUM(IFNULL(ga4_research_article_readership,0)) AS research_article_readership,
  SUM(IFNULL(ga4_source_readership,0)) AS source_readership,
  -- added below 4 new events in the pipeline after quarterly channel grouping changes
  SUM(IFNULL(ga4_ejp_submission_start,0)) AS ejp_submission_start,
  SUM(IFNULL(ga4_ejp_submission_complete,0)) AS ejp_submission_complete,
  SUM(IFNULL(ga4_nav_sign_up_for_alerts,0)) AS nav_sign_up_for_alerts
FROM
  base_data a
LEFT JOIN
  channel_groupings b
ON
  a.source = b.source
  AND a.medium = b.medium
  AND (a.google_ad_network_b IS NULL
    OR a.google_ad_network = b.adnetwork)
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
  20 ),
  -- Step 4: Calculate combined KPIs and enrich with derived fields
  final_output AS (
SELECT
  * EXCEPT(ga4_click_submit_manuscript_all_old_events,
    ga4_click_submit_manuscript,
    ga4_reach_fta,
    ga4_reach_full_text_article_old_events,
    ga4_reach_submission_guidelines,
    ga4_reach_journal_submission_guidelines_old_events,
    ga4_reach_about_page,
    ga4_reach_journal_about_old_events,
    ga4_reach_books_contact_editor_page,
    ga4_reach_books_contact_editor_old_events,
    ga4_submit_your_book_idea_click,
    ga4_submit_your_book_idea_click_old_events,
    ga4_reach_b2c_blog_page,
    ga4_reach_b2c_blog_page_old_events,
    ga4_ta_file_download,
    ga4_ta_file_download_all_old_events),
  (ga4_click_submit_manuscript_all_old_events + ga4_click_submit_manuscript) AS kpi_submit_click,
  (ga4_reach_fta + ga4_reach_full_text_article_old_events) AS pi_reach_fta,
  (ga4_reach_submission_guidelines + ga4_reach_journal_submission_guidelines_old_events) AS kpi_reach_submission_guideline_pages,
  (ga4_reach_about_page + ga4_reach_journal_about_old_events) AS kpi_reach_about_pages,
  (ga4_reach_books_contact_editor_page + ga4_reach_books_contact_editor_old_events) AS pi_contact_an_editor,
  (ga4_submit_your_book_idea_click + ga4_submit_your_book_idea_click_old_events) AS kpi_submit_your_book_idea,
  (ga4_reach_b2c_blog_page + ga4_reach_b2c_blog_page_old_events) AS reach_b2c_blog_page,
  (ga4_ta_file_download + ga4_ta_file_download_all_old_events) AS ta_file_download,
  CASE
    WHEN sub_channels LIKE "%- sea%" THEN "sea"
    WHEN sub_channels LIKE "%paid social%" THEN "paid social"
    WHEN sub_channels IN ("email", "etocs") THEN "email"
    WHEN sub_channels LIKE "%external display%" THEN "external display"
    WHEN sub_channels LIKE "%internal display%" THEN "internal display"
    WHEN sub_channels LIKE "%affiliate%" THEN "affiliate"
    WHEN sub_channels IN ("ai seo", "traditional seo") THEN "seo"
    ELSE "other channels"
END
  AS main_channels,
  CASE
    WHEN REGEXP_CONTAINS(Hostname___GA4__Google_Analytics, r"(www.springernature.com)") THEN "springernature"
    WHEN REGEXP_CONTAINS(Hostname___GA4__Google_Analytics, ".biomedcentral.") THEN "bmc"
    WHEN REGEXP_CONTAINS(Hostname___GA4__Google_Analytics, r"(www.springer.com)") THEN "springer"
    WHEN REGEXP_CONTAINS(Hostname___GA4__Google_Analytics, ".springeropen.") THEN "springeropen"
    WHEN REGEXP_CONTAINS(Hostname___GA4__Google_Analytics, "link.springer.") THEN "springerlink"
    WHEN REGEXP_CONTAINS(Hostname___GA4__Google_Analytics, r"(www.nature.com)") THEN "nature"
    WHEN REGEXP_CONTAINS(Hostname___GA4__Google_Analytics, r"(www.natureasia.com)") THEN "natureasia"
    WHEN REGEXP_CONTAINS(Hostname___GA4__Google_Analytics, r"(www.palgrave.com.)") THEN "palgrave"
    WHEN REGEXP_CONTAINS(Hostname___GA4__Google_Analytics, r"(www.apress.com.)") THEN "apress"
END
  AS imprint
FROM
  aggregated_metrics )
SELECT
  *
FROM
  final_output