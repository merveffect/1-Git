/*
    Every anchor term must have exactly one embedding, and the embedding
    table must hold nothing that is not a current anchor.

    The second half is the one that was missing. int_anchor_embeddings was
    incremental on anchor_key, which only inserts, so an anchor deleted
    from the seed kept its vector and stayed a live search target. Anchors
    are the only hand-written input in this project and the thing we
    iterate on hardest; they were in the one table that could not shrink,
    and removing one did nothing at all.

    It went unnoticed through two separate investigations. On librarian the
    next build came back worse rather than better. On leadership it was
    worse than that: the removal of chief executive officer, founder,
    president and the rest appeared to have no effect, and we concluded
    that the embedding generalises to corporate titles regardless - then
    built the organisation-score veto to contain a problem that was really
    this.

    The model is a table now, so the two sides match by construction and
    the only way this fails is an anchor whose vector came back empty.
    That is worth failing on by itself: the model drops those rows, so the
    group quietly searches against fewer anchors than the seed declares.
*/

with declared as (
    select
        to_hex(md5(concat(axis, '||', group_key, '||', anchor_term, '||',
                          coalesce(language_code, '')))) as anchor_key,
        group_key,
        anchor_term
    from {{ ref('int_anchor_terms') }}
    where length(anchor_term) between 2 and 200
),

embedded as (
    select anchor_key, group_key, anchor_term
    from {{ ref('int_anchor_embeddings') }}
)

select
    coalesce(d.group_key,   e.group_key)   as group_key,
    coalesce(d.anchor_term, e.anchor_term) as anchor_term,
    case
        when e.anchor_key is null then 'declared in the seed but never embedded'
        when d.anchor_key is null then 'embedded but no longer in the seed'
    end                                    as failure
from declared d
full outer join embedded e using (anchor_key)
where d.anchor_key is null or e.anchor_key is null
