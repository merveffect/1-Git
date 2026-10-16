{{ config(materialized = 'table') }}

/*
    The target vectors we search against. Must use the SAME model as
    int_title_embeddings - a different model makes the similarity
    scores meaningless.

    A TABLE, NOT INCREMENTAL, AND THE REASON MATTERS.

    This was incremental on unique_key = 'anchor_key' until 2026-10-16.
    Incremental only ever inserts, so an anchor deleted from the seed kept
    its row here and stayed a live search target for ever. Anchors are the
    only hand-written input in the project and the thing we edit most, and
    they were sitting in the one table that could not shrink. Removing an
    anchor did nothing, silently.

    It cost us twice.

    Once on librarian, where 11 translation anchors were removed for
    matching on morphology rather than meaning - bibliotecario pulling
    biólogo and catedrática - and the next build came back WORSE, 69.4% to
    72.8% of records below 0.75 similarity, because the old anchors were
    still searched alongside the 19 new ones.

    And once before that, on leadership, which is the expensive one. When
    chief executive officer, founder, president, vice president, executive
    director and managing director were removed from that group, corporate
    titles kept arriving, and the note left on the 'dean' anchor concluded
    that the embedding generalises to them regardless and the organisation
    score would have to enforce 'academic'. That conclusion was wrong. The
    removal had simply never taken effect. The org-score veto in
    org_name_patterns was built to work around this bug without knowing it
    was a bug.

    Cost of rebuilding every run: 299 short strings. It is nothing, and it
    buys back the ability to change our mind.

    The guard below stays: an anchor that fails to embed would break
    VECTOR_SEARCH for every title, so a zero-length vector is dropped -
    and assert_anchors_all_embedded fails the build if that happens.
*/

with source_terms as (

    select
        axis,
        group_key,
        anchor_term,
        language_code
    from {{ ref('int_anchor_terms') }}
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
    model `{{ var('embedding_model') }}`,
    (select anchor_key, axis, group_key, anchor_term, language_code,
            anchor_term as content
     from anchors)
)
where array_length(ml_generate_embedding_result) > 0
