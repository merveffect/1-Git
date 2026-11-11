/*
    frequency IN THE DICTIONARY MUST EQUAL frequency IN THE CORPUS.

    This test exists because that invariant was false for months and nothing
    said so. int_title_embeddings is incremental and never updates a row it
    has already embedded, so when frequency lived in that table it froze at
    the title's record count on the day it was first seen. dim_title_group's
    frequency summed to 30,488,093 against a live corpus of 1,767,500 - 17.3
    times over, and 14 to 30 times over per title, a different factor each
    time. Found by analyses/50 query 2g on 2026-11-11, and only because two
    queries counting the same rule disagreed by a factor of seventeen.

    ERROR SEVERITY, not warn. A wrong frequency silently mis-tiers the human
    review queue through tier_a_min_frequency, and it is the number every
    record figure in the seed notes and the status document is quoted from.
    A build that reintroduces it should stop.

    Ghost titles are excluded by the join: the embedding cache keeps titles
    that have since left the corpus, and those legitimately have no row in
    int_title_distinct to be compared against.
*/
select
    d.title_key,
    d.title,
    d.frequency     as dictionary_frequency,
    c.frequency     as corpus_frequency
from {{ ref('dim_title_group') }} d
join {{ ref('int_title_distinct') }} c using (title_key)
where d.frequency != c.frequency
