 SELECT *,
  CASE
    WHEN sub_channels LIKE "%sea%" THEN "sea"
    WHEN sub_channels LIKE "%paid social%" THEN "paid social"
    WHEN sub_channels = "email" OR sub_channels = "etocs" THEN "email"
    WHEN sub_channels LIKE "%external display%" THEN "external display"
    WHEN sub_channels LIKE "%internal display%" THEN "internal display"
    WHEN sub_channels LIKE "%affiliate%" THEN "affiliate"
    WHEN sub_channels IN ("ai seo", "traditional seo") THEN "seo" -- SEO is upgraded and included in the main channel list
    ELSE "other channels"
  END
  AS main_channels

  FROM (
      SELECT
      a.*,
      COALESCE(b.sub_channels,
        CASE
        WHEN REGEXP_CONTAINS(a.c_source, r"^(?:[^.]+\.)?(chatgpt|perplexity|claude|mistral|copilot|blackbox|felo|andisearch|komo|waldo|deepseek|scienceos|consensus|jasper|gemini\.google|chat\.openai|meta|search.jina)\.(?:ai|com|fyi|app)$") THEN "ai seo" -- classified SEO into traditional seo vs ai seo
        WHEN LOWER(a.c_source) = 'google'
          AND LOWER(a.c_medium) = 'cpc'
          AND LOWER(COALESCE(a.ad_network, '(not set)')) = '(not set)'
          AND REGEXP_CONTAINS(LOWER(COALESCE(a.campaign, '')), r'(^|[_\-\s])gdn($|[_\-\s])')
        THEN 'google - external display'

        WHEN LOWER(a.c_source) = 'google'
          AND LOWER(a.c_medium) = 'cpc'
          AND LOWER(COALESCE(a.ad_network, '(not set)')) = '(not set)'
          AND REGEXP_CONTAINS(LOWER(COALESCE(a.campaign, '')), r'(^|[_\-\s])sea($|[_\-\s])')
        THEN 'google - sea'

          WHEN a.c_medium = 'external_display' THEN 'other - external display'
          WHEN a.c_medium = 'paid_social' THEN 'other - paid social'
          WHEN a.c_medium = 'internal_display' THEN 'other - internal display'
          WHEN a.c_medium = 'affiliate' THEN 'main affiliate'
          WHEN a.c_medium = 'organic_social' THEN 'other - organic social'
          WHEN a.c_source LIKE '%toc%' and a.c_medium='email' then 'etocs' -- updated etocs grouping to not include protocols.io
          WHEN a.c_medium = 'email' THEN 'email'
          WHEN a.c_medium = 'organic' then 'traditional seo' -- seo is upgraded to main channels and seo as a subchannel reclassified into ai seo vs traditional seo
          WHEN a.c_medium = 'referral' THEN 'referral'
          ELSE 'other channels'
      END
      ) AS sub_channels, --checks and categorises any left out sources for a medium into 'others'
  FROM
    {{ ref('funnel_exports_joined') }} a
  LEFT JOIN
    {{ source('ae_metadata', 'channel_groupings') }} b
  ON
    a.c_source = LOWER(b.source)
    AND a.c_medium = LOWER(b.medium)
    AND (a.ad_network IS NULL
      OR a.ad_network = LOWER(b.adnetwork))
  )

