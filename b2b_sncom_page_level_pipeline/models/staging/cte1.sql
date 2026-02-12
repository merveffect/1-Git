SELECT
    cte0.* EXCEPT(sn_area, page_region, funnel_stage, first_level_grouping,second_level_grouping),
    CASE
    WHEN page_location LIKE '%go.springernature.com%' THEN 'hubspot_landing'
    ELSE
    sn_area
    END AS sn_area,
    CASE
    WHEN page_location LIKE '%go.springernature.com%' THEN 'Global'
    ELSE
    page_region
    END AS page_region,
    CASE
    WHEN page_location LIKE '%go.springernature.com%' AND page_location LIKE '%int1%' THEN 'Product Interest'
    WHEN page_location LIKE '%go.springernature.com%' AND page_location LIKE '%ups1%' THEN 'Renewal / repeat / upsell'
    WHEN page_location LIKE '%go.springernature.com%' AND page_location LIKE '%awa1%' THEN 'Product Awareness'
    WHEN page_location LIKE '%go.springernature.com%' AND page_location LIKE '%att1%' THEN 'Brand Attract & Engage'
    WHEN page_location LIKE '%go.springernature.com%' AND page_location LIKE '%eva1%' THEN 'Product Evaluation'
    WHEN page_location LIKE '%go.springernature.com%' AND page_location LIKE '%onb1%' THEN 'Onboarding & Post Sale'
    WHEN page_location LIKE 'https://go.springernature.com/digital-transformation-of-r-and-d%' THEN 'Product Awareness'
    ELSE funnel_stage
    END AS funnel_stage,
    CASE
    WHEN page_location LIKE '%go.springernature.com%' THEN 'HubSpot Landing'
    ELSE first_level_grouping
    END AS first_level_grouping,
    CASE
    WHEN page_location LIKE '%go.springernature.com%' AND REGEXP_CONTAINS(page_location,'.*(adisinsight|digital-transformation-of-r-and-d|tdm|protocols-io|pf034|pf035|pf004|pf038||pf037|snexp|pf040|nindx).*') THEN 'Databases'
    WHEN page_location LIKE '%go.springernature.com%' AND REGEXP_CONTAINS(page_location,'.*(books|pf010|pf006|pf007|pf008|pf009|pf031|pf027|pf015|pf016).*') THEN 'eBooks'
    WHEN page_location LIKE '%go.springernature.com%' AND REGEXP_CONTAINS(page_location,'.*(journals|pf018|pf023|pf026|pf029|pf030|pf032|pf002|pf001|jrn).*') THEN 'Journals'
    ELSE second_level_grouping
    END AS second_level_grouping,
  FROM
  {{ref('cte0')}} cte0