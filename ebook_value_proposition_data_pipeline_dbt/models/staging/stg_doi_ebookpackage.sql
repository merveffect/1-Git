{{ config(
    materialized = "table",
    tags= ["monthly"]
)}}

SELECT DISTINCT
  COALESCE(NULLIF(Item_DOI, ''), NULLIF(DOI, '')) AS Item_DOI, 
  Bk_eBook_ISBN,
  Bk_eBook_Pack as eBook_package,
  Bk_eBook_Pack_R0 AS eBook_package_R0,
  Bk_Series_No,
  Bk_Series_Title, 
  Bk_Subj_Coll,
  Bk_Cat
FROM
  {{source('PROD_IFM_Usage_C51','tbl_mat_monthly')}}
WHERE
  (Item_DOI IS NOT NULL OR DOI IS NOT NULL)
  AND (Bk_eBook_Pack IS NOT NULL OR Bk_eBook_Pack_R0 IS NOT NULL)
  
  {% if is_incremental() %}
    AND Cal_Date >= date_trunc(date_sub(current_date(), INTERVAL 1 MONTH), MONTH)
    AND Cal_Date < date_trunc(current_date(), MONTH)

   {% else %}
   
   AND Cal_Date >= '{{ var("start_date", "2005-01-01") }}'
   AND Cal_Date <= '{{ var("end_date", "2026-03-31") }}'
    
  {% endif %}
   