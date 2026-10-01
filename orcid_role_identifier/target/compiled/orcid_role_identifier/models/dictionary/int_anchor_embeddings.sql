

/*
    The target vectors we search against. Must use the SAME model as
    int_title_embeddings - a different model makes the similarity
    scores meaningless.

    Same two guards as int_title_embeddings: an anchor that fails to
    embed would break VECTOR_SEARCH for every title.
*/

with source_terms as (

    select
        axis,
        group_key,
        anchor_term,
        language_code
    from `dat-analytics-eng-ec869189`.`dev_orcid_role_identifier_dictionary`.`int_anchor_terms`
    where length(anchor_term) between 2 and 200

),

anchors as (

    select
        to_hex(md5(concat(axis, '||', group_key, '||', anchor_term, '||', coalesce(language_code, '')))) as anchor_key,
        axis,
        group_key,
        anchor_term,
        language_code
    from source_terms

    
    where to_hex(md5(concat(axis, '||', group_key, '||', anchor_term, '||', coalesce(language_code, ''))))
          not in (select anchor_key from `dat-analytics-eng-ec869189`.`dev_orcid_role_identifier_dictionary`.`int_anchor_embeddings`)
    

)

select
    anchor_key,
    axis,
    group_key,
    anchor_term,
    language_code,
    ml_generate_embedding_result    as embedding,
    current_timestamp()             as embedded_at
from ml.generate_embedding(
    model `datasn-rm-live.institution_disambiguation.embedding_model`,
    (select anchor_key, axis, group_key, anchor_term, language_code,
            anchor_term as content
     from anchors)
)
where array_length(ml_generate_embedding_result) > 0