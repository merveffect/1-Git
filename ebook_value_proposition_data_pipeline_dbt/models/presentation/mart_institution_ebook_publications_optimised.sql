{{ config(
    materialized = "table",
    partition_by = {
        "field": "pub_year",
        "data_type": "int64",
        "range": {
            "start": 2000,
            "end": 2030,
            "interval": 1
        }
    },
    cluster_by = ["publisher_name", "publication_type", "pub_year"]
) }}

SELECT 
    grid_id,
    pub_id,
    pub_year,
    publication_type,
    publisher_name,
    grid_name,
    Bk_Series_Title,
    Bk_eBook_cat,
    Bk_Subj_Coll,
    oa,
    source_title
FROM 
    {{ ref('int_institution_ebook_publications_base') }}