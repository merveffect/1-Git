SELECT 
snid,
all_snt_labels
FROM 
{{ source('prod_subject_based_segmentation_presentation','snid_to_mktps_step2') }}
WHERE snid IS NOT NULL
AND all_snt_labels IS NOT NULL

