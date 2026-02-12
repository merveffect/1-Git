SELECT
    a.*,
    COALESCE(b.sub_channels,
      CASE
      WHEN REGEXP_CONTAINS(a.session_source, r"^(?:[^.]+\.)?(chatgpt|perplexity|claude|mistral|copilot|blackbox|felo|andisearch|komo|waldo|deepseek|scienceos|consensus|jasper|gemini\.google|chat\.openai|meta|search.jina)\.(?:ai|com|fyi|app)$") THEN "ai seo" -- classified SEO into traditional seo vs ai seo

        /*  FIX: Google CPC + (not set) campaigns that should not fall into Other Channels */
        WHEN LOWER(a.session_source) = 'google'
          AND LOWER(a.session_medium) = 'cpc'
          AND LOWER(COALESCE(a.session_google_ads_ad_network_type, '(not set)')) = '(not set)'
          AND REGEXP_CONTAINS(LOWER(COALESCE(a.session_campaign, '')), r'(^|[_\-\s])gdn($|[_\-\s])')
        THEN 'google - external display'

        WHEN LOWER(a.session_source) = 'google'
          AND LOWER(a.session_medium) = 'cpc'
          AND LOWER(COALESCE(a.session_google_ads_ad_network_type, '(not set)')) = '(not set)'
          AND REGEXP_CONTAINS(LOWER(COALESCE(a.session_campaign, '')), r'(^|[_\-\s])sea($|[_\-\s])')
        THEN 'google - sea'

        WHEN a.session_medium = 'external_display' THEN 'other - external display'
        WHEN a.session_medium = 'paid_social' THEN 'other - paid social'
        WHEN a.session_medium = 'internal_display' THEN 'other - internal display'
        WHEN a.session_medium = 'affiliate' THEN 'main affiliate'
        WHEN a.session_medium = 'organic_social' THEN 'other - organic social'
        when a.session_source like '%toc%' and a.session_medium='email' then 'etocs' -- updated etocs grouping to not include protocols.io
        WHEN a.session_medium = 'email' THEN 'email'
        WHEN a.session_medium = 'organic' THEN 'traditional seo' -- seo is upgraded to main channels and seo as a subchannel reclassified into ai seo vs traditional seo
        WHEN a.session_medium = 'referral' THEN 'referral'
        ELSE 'other channels'
    END
      ) AS sub_channels, --checks and categorises any left out sources for a medium into 'others'
  FROM
    {{ref('core')}} a
  LEFT JOIN
    {{ref('channel_groupings')}} b
  ON
    a.session_source = LOWER(b.source)
    AND a.session_medium = LOWER(b.medium)
    AND (a.session_google_ads_ad_network_type IS NULL
      OR a.session_google_ads_ad_network_type = LOWER(b.adnetwork) )