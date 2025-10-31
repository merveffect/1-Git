{{ config(
    materialized = "incremental",
    partition_by = {"field": "date"},
    tags= ["daily", "j7", "ta_j7", "transposed_awa1", "transposed_bae", "transposed_nurture"]

 )}}

WITH
  main AS (
  SELECT
    *
  FROM
    {{ref('j3')}} AS a
  LEFT JOIN
    {{ref('oatype')}} AS b
  ON
    a.journal_id = b.journalkey
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
    ),
  aggregrations AS (
  SELECT
    date,
    campaign,
    clean_campaign,
    SOURCE,
    medium,
    main_channels,
    sub_channels,
    country,
    isoalphatwo,
    world_region,
    audience_code,
    product_code,
    goal_code,
    campaign_code,
    geo_code,
    team_code,
    products,
    CASE
      WHEN REGEXP_CONTAINS(journal_title, '(not set|0|not found)') OR journal_title = "" THEN "journal title not set"
      ELSE journal_title
  END
    AS journal_title,
    -- renaming the OA type dimension values to make them more human readable
    CASE
      WHEN oatype = "openopac" THEN "OA"
      WHEN oatype = "openopch" THEN "hybrid"
      WHEN oatype = "openopsu" THEN "closed"
      ELSE oatype
  END
    AS oatype,
    journal_id,
    business_model,
    main_discipline,
    main_group,
    portfolio,
    imprint,
    journal_imprint,
    -- summing metrics from rows of different non-sensical journal title values which are all consolidated to "journal title not set";
    -- sum(kpi_about_and_submission_guidelines) as kpi_about_and_submission_guidelines,
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
    SUM(cost) AS cost,
    SUM(clicks) AS clicks,
    SUM(impressions) AS impressions,
    SUM(research_article_readership) AS research_article_readership,
    SUM(source_readership) AS source_readership,
    SUM(ejp_submission_start) AS ejp_submission_start,
    SUM(ejp_submission_complete) AS ejp_submission_complete,
    SUM(nav_sign_up_for_alerts) AS nav_sign_up_for_alerts,
    CASE
      WHEN SUM(impressions) = 0 THEN NULL
      ELSE SUM(clicks) / NULLIF(SUM(impressions), 0)
  END
    AS engagement_rate
  FROM
    main
  GROUP BY
    date,
    campaign,
    clean_campaign,
    SOURCE,
    medium,
    main_channels,
    sub_channels,
    country,
    isoalphatwo,
    world_region,
    journal_title,
    audience_code,
    product_code,
    goal_code,
    campaign_code,
    geo_code,
    team_code,
    products,
    oatype,
    journal_id,
    journal_imprint,
    business_model,
    main_discipline,
    main_group,
    portfolio,
    imprint ),
  transformations AS (
  SELECT
    * EXCEPT ( kpi_marbl_leads,
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
      impressions ),
    CASE
      WHEN kpi_marbl_leads IS NULL THEN 0
      ELSE kpi_marbl_leads
  END
    AS kpi_marbl_leads,
    CASE
      WHEN Sessions IS NULL THEN 0
      ELSE Sessions
  END
    AS Sessions,
    CASE
      WHEN pi_publishing_guidelines IS NULL THEN 0
      ELSE pi_publishing_guidelines
  END
    AS pi_publishing_guidelines,
    CASE
      WHEN EngagedSessions IS NULL THEN 0
      ELSE EngagedSessions
  END
    AS EngagedSessions,
    CASE
      WHEN ELS IS NULL THEN 0
      ELSE ELS
  END
    AS ELS,
    CASE
      WHEN snapp_submission_complete IS NULL THEN 0
      ELSE snapp_submission_complete
  END
    AS snapp_submission_complete,
    CASE
      WHEN content_consumption IS NULL THEN 0
      ELSE content_consumption
  END
    AS content_consumption,
    CASE
      WHEN reach_india_apc_thankyou IS NULL THEN 0
      ELSE reach_india_apc_thankyou
  END
    AS reach_india_apc_thankyou,
    CASE
      WHEN reach_oa_general IS NULL THEN 0
      ELSE reach_oa_general
  END
    AS reach_oa_general,
    CASE
      WHEN snapp_submission_start IS NULL THEN 0
      ELSE snapp_submission_start
  END
    AS snapp_submission_start,
    CASE
      WHEN kpi_submit_click IS NULL THEN 0
      ELSE kpi_submit_click
  END
    AS kpi_submit_click,
    CASE
      WHEN pi_reach_fta IS NULL THEN 0
      ELSE pi_reach_fta
  END
    AS pi_reach_fta,
    CASE
      WHEN kpi_reach_submission_guideline_pages IS NULL THEN 0
      ELSE kpi_reach_submission_guideline_pages
  END
    AS kpi_reach_submission_guideline_pages,
    CASE
      WHEN kpi_reach_about_pages IS NULL THEN 0
      ELSE kpi_reach_about_pages
  END
    AS kpi_reach_about_pages,
    CASE
      WHEN pi_contact_an_editor IS NULL THEN 0
      ELSE pi_contact_an_editor
  END
    AS pi_contact_an_editor,
    CASE
      WHEN kpi_submit_your_book_idea IS NULL THEN 0
      ELSE kpi_submit_your_book_idea
  END
    AS kpi_submit_your_book_idea,
    CASE
      WHEN reach_b2c_blog_page IS NULL THEN 0
      ELSE reach_b2c_blog_page
  END
    AS reach_b2c_blog_page,
    CASE
      WHEN ta_file_download IS NULL THEN 0
      ELSE ta_file_download
  END
    AS ta_file_download,
    CASE
      WHEN search_volume IS NULL THEN 0
      ELSE search_volume
  END
    AS search_volume,
    CASE
      WHEN journal_engagement IS NULL THEN 0
      ELSE journal_engagement
  END
    AS journal_engagement,
    CASE
      WHEN research_article_readership IS NULL THEN 0
      ELSE research_article_readership
  END
    AS research_article_readership,
    CASE
      WHEN source_readership IS NULL THEN 0
      ELSE source_readership
  END
    AS source_readership,
    CASE
      WHEN ejp_submission_start IS NULL THEN 0
      ELSE ejp_submission_start
  END
    AS ejp_submission_start,
    CASE
      WHEN ejp_submission_complete IS NULL THEN 0
      ELSE ejp_submission_complete
  END
    AS ejp_submission_complete,
    CASE
      WHEN nav_sign_up_for_alerts IS NULL THEN 0
      ELSE nav_sign_up_for_alerts
  END
    AS nav_sign_up_for_alerts,
    CASE
      WHEN cost IS NULL THEN 0
      ELSE cost
  END
    AS cost,
    CASE
      WHEN clicks IS NULL THEN 0
      ELSE clicks
  END
    AS clicks,
    CASE
      WHEN impressions IS NULL THEN 0
      ELSE impressions
  END
    AS impressions
    -- case when content_consumption is null then 0 else content_consumption end as content_consumption,
    -- case when pi_pdf_download is null then 0 else pi_pdf_download end as pi_pdf_download,
    -- case when pi_ealert_click is null then 0 else pi_ealert_click end as pi_ealert_click,
  FROM
    aggregrations )
SELECT
  *,
  -- researchER_marketing: boolean dimension, splitting between researchER and not researchER marketing
  CASE
    WHEN REGEXP_CONTAINS(clean_campaign, '(aexs|bbkk|bcps|bmcf|bmcs|bsch|bslb|bsng|bsph|bsps|bsss|cmtl|jftt|jjpn|jrpc|mkef|ncom|ngmt|njpn|npjs|nrcb|nrcc|nrcp|nrrj|rsdt|sbps|scdt|snaj|spsn|srbm|srcl|srcs|srep|srhs|srlf|srmt|stnl|ddcn|jrnls|sproa|sprin|natoa|najrn|discv|scirp|oajrn)') AND NOT REGEXP_CONTAINS(clean_campaign, '(conr|medr|lscr|apsr|hscr|humr|sscr|bepl|corp|acgo|acpg|mpsr|mlsr|hssr|newb)') THEN TRUE
    ELSE FALSE
    --when REGEXP_CONTAINS(audiences, '(n/a|all other campaigns)') then FALSE else TRUE
END
  AS researchER_marketing_activity,
  -- research_marketing: boolean dimension, splitting between RM and not RM traffic; RM traffic here includes e.g. eCom or B2B campaigns
  CASE
    WHEN REGEXP_CONTAINS(clean_campaign, '(acgo|acpg|apsr|bepl|conr|corp|edbm|hscr|hssr|humr|lscr|medr|mlsr|mpsr|newb|pere|reof|sscr)') OR team_code IN ( SELECT code FROM {{source('ria_researcher_report','team_codes')}}) OR REGEXP_CONTAINS(clean_campaign, '(aexs|bbkk|bcps|bmcf|bmcs|bsch|bslb|bsng|bsph|bsps|bsss|cmtl|jftt|jjpn|jrpc|mkef|ncom|ngmt|njpn|npjs|nrcb|nrcc|nrcp|nrrj|rsdt|sbps|scdt|snaj|spsn|srbm|srcl|srcs|srep|srhs|srlf|srmt|stnl|ddcn|none1|anima|award|brcon|bpdmr|cuspb|cusev|evlst|focal|focus|forsc|immrs|infog|innov|insit|postr|spotl|video|wbcas|outlk|outln|nafrc|nitly|iview|nindx|ncafe|natcf|bdjjb|bdjjl|bdjmp|jrnls|sproa|sprin|natoa|najrn|discv|scirp|oajrn|oaagr|books|gbook|obook|tbook|sbook|ncars|b2bgn)') THEN TRUE
    ELSE FALSE
END
  AS research_marketing_activity,
  -- naming convention error
  CASE
    WHEN REGEXP_CONTAINS(campaign,r'.*[a-zA-Z]{4}_[a-zA-Z0-9]{5}_[a-zA-Z0-9]{4}_[a-zA-Z0-9]{2}_[a-zA-Z0-9]{4}_[a-zA-Z0-9]{5}_.+$')THEN TRUE
    ELSE FALSE
END
  AS naming_convention_correct,
  -- Nature campaigns grouping aligned with how the Nature journals are marketed (Raj Roy is the contact for any updates or checks)
  CASE
    WHEN REGEXP_CONTAINS(product_code,'(42003|42004|42005|42949|43246|43247|43856|44172)') THEN "Communication journals"
    WHEN REGEXP_CONTAINS(product_code,'(41524|41528|41529|41534|41535|41545|41612|41699|42949|44182|44183)') THEN "NPJs MPAS"
    WHEN REGEXP_CONTAINS(product_code,'(41514|41522|41523|41525|41526|41531|41533|41536|41537|41538|41539|41540|41541|41698|41746|44184|44185)') THEN "NPJs MLS"
    WHEN REGEXP_CONTAINS(product_code,'(44220|44221|44222)') THEN "FY23 NewLaunches"
    WHEN REGEXP_CONTAINS(product_code,'(44159|44160|44161)') THEN "FY22 NewLaunches"
    WHEN REGEXP_CONTAINS(product_code,'(43016|43017|43018|43586|43587|43588)') THEN "FY20/21 NewLaunches"
    WHEN REGEXP_CONTAINS(product_code,'(41477|41556|41559|41564|41568|41569|41571|41572|41573|41574|41575|41576|41577|41579|41580|41581|41582|41583|41584|41585|41587|41588|41589|41590|41591|41592|41593|41594|41596|42255)') THEN "Established RJs MLS"
    WHEN REGEXP_CONTAINS(product_code,'(41550|41551|41557|41558|41560|41561|41563|41565|41566|41567|41570|41578|41893|41928|41929|42254|42256)') THEN "Established RJs MPAS"
    WHEN REGEXP_CONTAINS(product_code,'(41550|41551|41557|41558|41560|41561|41563|41565|41566|41567|41570|41578|41893|41928|41929|42254|42256)') THEN "Established RJs MPAS"
    WHEN REGEXP_CONTAINS(product_code,'(41562)') THEN "Established RJs HSS"
END
  nature_grp,
  -- _oax is added to campaigns to mark them as fully OA targetted campaigns
  CASE
    WHEN REGEXP_CONTAINS(campaign, "_oax") THEN TRUE
    ELSE FALSE
END
  AS is_oax,
FROM
  transformations
