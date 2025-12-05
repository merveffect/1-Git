{{ config(
    materialized = "table",
    partition_by = {"field": "date"},
    
 )}}


SELECT *,
CASE
when regexp_contains(marmind_channels_details, '- sea') then "sea"
when regexp_contains(marmind_channels_details, 'paid social') then "paid social"
when regexp_contains(marmind_channels_details, 'email') then "email"
when regexp_contains(marmind_channels_details, 'external display') then "external display"
when regexp_contains(marmind_channels_details, 'internal display') then "internal display"
else "6. other channels"
end as marmind_channels

FROM

(SELECT *,
CASE
when data_source_type = "adwords" and google_ad_network in  ('content','youtube','google_owned_channels','discover','gmail') THEN "google - external display"
when data_source_type = "criteo" then "criteo - external display"
when data_source_type = "yahoo_japan_ydn" THEN "yahoo - external display"
when data_source_type = "yahoo_japan_search" then "yahoo - sea"
when data_source_type = "adwords" and (google_ad_network != "content" OR google_ad_network!='youtube') then "google - sea"
when data_source_type = "adwords" and google_ad_network is null then "google - sea"
when data_source_type = "bing" then "bing - sea"
when data_source_type = "facebookads" then "facebook - paid social"
when data_source_type = "twitter" then "twitter - paid social"
when data_source_type = "linkedin_api" then "linkedin - paid social"
else null
end as marmind_channels_details

FROM
(
SELECT * except (cost, clicks, impressions, source, medium, Network_with_search_partners__AdWords, month, year, currency, Data_Source_name, Data_Source_id, account_ID,CampaignID,Data_Origin_Identifier),
lower(source) as source,
lower(medium) as medium,
lower(Network_with_search_partners__AdWords) as google_ad_network,
lower(Data_Source_name) as data_source_name,
account_ID,
"" as ad_content,
sum(cost) as cost,
sum(clicks) as clicks,
sum(impressions) as impressions

FROM {{source('RM_adspend','rm_adspend_static')}}
where  DATE  between '2025-01-01' and '2025-03-21'
group by date, source, medium, google_ad_network, country, campaign, Data_Source_type,data_source_name,account_ID
)
)