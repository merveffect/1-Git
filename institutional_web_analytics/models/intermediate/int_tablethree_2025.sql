{{ config(
    materialized = 'view',
    schema = 'Institutional_analysisGA4_EU'
) }}

WITH reference_table AS (
    SELECT
        CAST(BP_ID AS STRING) AS MBP,
        CAST(BP_Name AS STRING) AS Institution,
        CAST(SF_Acc_ID AS STRING) AS SF_Acc_ID,
        CAST(SF_Acc_Name AS STRING) AS SF_Acc_Name,
        CAST(SF_Customer_Type AS STRING) AS SF_Customer_Type,
        CAST(SF_Peer_Group AS STRING) AS SF_Peer_Group
    FROM
        {{ source('reference_data', 'bpid_sfid_new') }}
),

joined_and_enriched AS (
    SELECT
        RAW.*,
        B.MBP,
        B.Institution,
        B.SF_Acc_ID,
        B.SF_Acc_Name,
        B.SF_Customer_Type,
        B.SF_Peer_Group
        
    FROM 
        {{ ref('int_flat_March') }} RAW
        
    LEFT JOIN
        reference_table B
        
    ON B.MBP = RAW.bpid

)

SELECT * FROM joined_and_enriched