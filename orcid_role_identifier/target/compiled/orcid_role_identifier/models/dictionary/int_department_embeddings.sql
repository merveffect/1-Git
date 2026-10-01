

/*
    Every distinct department embedded once, with the same model as the
    titles and the anchors. A different model would make the similarity
    scores meaningless.
*/

with to_embed as (

    select department_key, department, frequency
    from `dat-analytics-eng-ec869189`.`dev_orcid_role_identifier_dictionary`.`int_department_distinct`

    

)

select
    department_key,
    department,
    frequency,
    ml_generate_embedding_result    as embedding,
    'datasn-rm-live.institution_disambiguation.embedding_model'  as model_name,
    current_timestamp()             as embedded_at
from ml.generate_embedding(
    model `datasn-rm-live.institution_disambiguation.embedding_model`,
    (select department_key, department, frequency, department as content from to_embed)
)
where array_length(ml_generate_embedding_result) > 0