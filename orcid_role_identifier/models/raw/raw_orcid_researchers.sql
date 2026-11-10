{{ config(materialized='view') }}

/*
    RAW LAYER - orcid_researchers

    Its only job: surface the source as-is, plus the VISIBILITY FILTER.

    We will never use non-public data anywhere, so the filter is applied
    once here; no model above this needs to know about visibility.

    In ORCID visibility is per RECORD: the same person can have one
    employment marked PUBLIC and another PRIVATE. So the arrays are
    rebuilt - we drop records, not people.

    Note the snid filter: the table holds 24.8M ORCID profiles but only
    ~1.76M carry an SNID. Without an SNID the person is unreachable, so
    they never enter the pipeline.
*/

{% set public_only = var('public_visibility_only', true) %}

select
    snid,
    orcid_id,
    created_at,
    last_updated_at,
    name,
    biography,
    country_codes,
    keywords,

    {% if public_only %}
    -- keep PUBLIC records only; array shape is preserved
    array(select e from unnest(employments)  e where upper(e.visibility) = 'PUBLIC') as employments,
    array(select d from unnest(educations)   d where upper(d.visibility) = 'PUBLIC') as educations,
    array(select p from unnest(publications) p where upper(p.visibility) = 'PUBLIC') as publications,
    array(select m from unnest(emails)       m where upper(m.visibility) = 'PUBLIC') as emails,
    array(select v from unnest(peer_reviews) v where upper(v.visibility) = 'PUBLIC') as peer_reviews
    {% else %}
    employments,
    educations,
    publications,
    emails,
    peer_reviews
    {% endif %}

from {{ source('researcher_profiles', 'orcid_researchers') }}
where snid is not null

/*
    ONE ROW PER PERSON. The source is versioned, not deduplicated, which
    nothing said until analyses/17 measured it:

        rows                25,132,641
        distinct orcid_id    1,781,624
        distinct snid        1,781,624
        orcid per snid            1.00   <- the match is clean
        rows per orcid           14.11   <- every profile is here ~14 times

    So "where snid is not null" above removes nothing at all, and the
    1.76M people in the baseline is a distinct count rather than what the
    pipeline was actually processing. Three consequences, all fixed by
    this one window:

      COST       every model downstream scanned 25.1M rows for 1.78M
                 people. Fourteen times the work.

      FREQUENCY  dictionary frequencies were inflated by the same factor,
                 so tier_a_min_frequency 50 was really about 3 real
                 occurrences and tier_b_min_frequency 3 was no floor at
                 all. The tiers now mean what they say.

      STALENESS  the worst of the three. Scoring picks a person's
                 best-matching employment across every row it can see, so
                 an employment someone DELETED from their ORCID profile
                 still sat in an older version and could be the record we
                 labelled them on. Keeping only the newest version means
                 we read what the person's profile says today.

    Rows sharing the maximum last_updated_at are the same profile
    unchanged between loads, so which of them wins does not matter.
    analyses/17 query 7f is the check on that assumption; if it ever fails
    the ordering needs a real ingestion timestamp, not this column.
*/
qualify row_number() over (
    partition by snid
    order by last_updated_at desc
) = 1
