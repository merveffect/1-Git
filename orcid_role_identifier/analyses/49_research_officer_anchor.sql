/*
    ============================================================================
    49. THE RESEARCH-OFFICER FAMILY - measured before the change lands
    ============================================================================
    Merve 2026-11-11: "Research Officer'i support_technical'in capasi yapmisiz
    ama bu capayi direkt cikartalim. Research Officer vektorden gelsin. Research
    Officer ailesi Researcher'a girsin."

    WHAT WAS WRONG, AND IT WAS NOT THE MODEL. `research officer` was itself an
    ANCHOR of support_technical in seeds/title_group_anchors.csv. So 34,376
    records sat in a group that feeds no audience because the vector matched its
    own anchor at similarity 1.000. The vector did exactly what it was built to
    do. The anchor was the mistake, and we wrote it.

    The same group holds `analyst` and `data analyst` as anchors, which is why
    `research analyst` has to be checked rather than assumed - the claim that it
    is already in the Researcher audience comes from analyses/27 and has never
    been verified against the built dictionary.

    WHAT LANDED IN THIS COMMIT
      - seeds/title_group_anchors.csv: the `research officer` anchor is removed
      - seeds/title_group_patterns.csv: one pattern row, `\bresearch
        (officer|analyst|executive)\b` -> researcher, SCOPED to support_technical

    WHY BOTH AND NOT JUST THE REMOVAL. 2.12's lesson, measured on the department
    dictionary: ADDING a rule puts a value where we chose, REMOVING one sends it
    wherever happens to be second. Removing the anchor alone would move
    `research officer` somewhere we have not named, and would also move every
    OTHER title that currently reaches support_technical through that anchor.
    Query 2 is the size of that second effect and it is the one number that can
    still reverse this change.

    RUN ORDER
      1 and 2 on the CURRENT build, before touching anything.
      Then build:  dbt build --select title_group_anchors+ title_group_patterns+
      Then 3 and 4 on the new build.

    THE BUILD IS NOT THE CHEAP ONE. Both seeds sit upstream of
    int_title_group_match, which runs VECTOR_SEARCH over 317,302 distinct
    titles. int_anchor_embeddings is materialized as a table (not incremental),
    so the removal does reach the search targets - that was broken until
    2026-10-16 and a removal silently did nothing.
*/


-- ----------------------------------------------------------------------------
-- 1. BEFORE. Where the two families sit today, by record weight.
--
--    Record weight, not distinct titles: `research officer` is one title and
--    34,376 records, and a count of titles would make it look like one row of
--    the problem.
-- ----------------------------------------------------------------------------
with records as (
    select role_title, title_key
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_staging.stg_role_records`
),
dict as (
    select title_key, title_group, is_assigned, group_score, decision_source,
           array_to_string(matched_anchors, ' / ')      as anchors
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
)
select
    case
        when regexp_contains(r.role_title, r'\bresearch (officer|analyst|executive)\b')
            then '1 research-officer family'
        when regexp_contains(r.role_title, r'\b(bio)?statistician\b|\bmedical statistician\b|\bstatisticien|\bestadistic')
            then '2 statistician family'
        when regexp_contains(r.role_title, r'\beconomist\b|\becononomist\b')
            then '3 economist family'
        else '4 other'
    end                                                 as family,
    coalesce(d.title_group, '(no group)')               as title_group,
    coalesce(d.is_assigned, false)                      as is_assigned,
    count(*)                                            as records,
    count(distinct r.role_title)                        as distinct_titles,
    round(avg(d.group_score), 3)                        as avg_group_score,
    string_agg(distinct r.role_title order by r.role_title limit 6) as example_titles
from records r
left join dict d using (title_key)
where regexp_contains(r.role_title,
        r'\bresearch (officer|analyst|executive)\b|\b(bio)?statistician\b|\bmedical statistician\b|\bstatisticien|\bestadistic|\beconomist\b')
group by family, title_group, is_assigned
order by family, records desc
;


-- ----------------------------------------------------------------------------
-- 2. THE BLAST RADIUS OF REMOVING THE ANCHOR - the one number that can still
--    reverse this change.
--
--    Every title whose support_technical match was carried by the `research
--    officer` anchor. Once the anchor is gone each of these goes to whatever
--    its next-best group is, which we have NOT chosen. A title that genuinely
--    is support work - `research support officer`, `research grants officer` -
--    moving into researcher is a new error, not a fix.
--
--    matched_anchors holds the top THREE anchors per group, so a title appears
--    here if `research officer` was among its three best support_technical
--    matches - deliberately wider than "was the single best", because the top
--    three are what the similarity was built from.
--
--    READ IT LIKE THIS. The `\bresearch (officer|analyst|executive)\b` rows are
--    the intended target and the new pattern catches them whatever happens.
--    Any OTHER title in this list is collateral. If the collateral is large,
--    put the anchor back and let the pattern alone do the work - the pattern
--    does not need the anchor gone to fire, because PATTERN beats VECTOR.
-- ----------------------------------------------------------------------------
with records as (
    select role_title, title_key
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_staging.stg_role_records`
),
dict as (
    select title_key, title_group, runner_up, similarity, margin,
           array_to_string(matched_anchors, ' / ')      as anchors
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
    where title_group = 'support_technical'
),
weighted as (
    select
        r.role_title,
        d.anchors,
        d.runner_up,
        round(d.similarity, 3)                          as similarity,
        round(d.margin, 3)                              as margin,
        count(*)                                        as records
    from records r
    join dict d using (title_key)
    where regexp_contains(d.anchors, r'research officer')
    group by r.role_title, d.anchors, d.runner_up, d.similarity, d.margin
)
select
    case
        when regexp_contains(role_title, r'\bresearch (officer|analyst|executive)\b')
            then 'INTENDED TARGET'
        else 'COLLATERAL - where does this go now?'
    end                                                 as classification,
    role_title,
    records,
    similarity,
    margin,
    runner_up                                           as next_best_group,
    anchors
from weighted
order by classification, records desc
limit 200
;


-- ----------------------------------------------------------------------------
-- 2a. The same thing as ONE number, so the decision does not rest on reading
--     200 rows. Run it with query 2.
-- ----------------------------------------------------------------------------
with records as (
    select role_title, title_key
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_staging.stg_role_records`
),
dict as (
    select title_key, runner_up,
           array_to_string(matched_anchors, ' / ')      as anchors
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
    where title_group = 'support_technical'
)
select
    case
        when regexp_contains(r.role_title, r'\bresearch (officer|analyst|executive)\b')
            then 'INTENDED TARGET'
        else 'COLLATERAL'
    end                                                 as classification,
    coalesce(d.runner_up, '(none)')                      as next_best_group,
    count(*)                                            as records,
    count(distinct r.role_title)                        as distinct_titles
from records r
join dict d using (title_key)
where regexp_contains(d.anchors, r'research officer')
group by classification, next_best_group
order by classification, records desc
;


-- ----------------------------------------------------------------------------
-- 3. AFTER THE BUILD. Query 1 again - run it unchanged and compare.
--
--    WHAT SUCCESS LOOKS LIKE
--      - the research-officer family sits in `researcher` with is_assigned
--        true, decision_source PATTERN, group_score 1.000
--      - `research analyst` is in `researcher` too, which settles the claim
--        analyses/27 made and nobody verified
--      - the statistician and economist families have NOT moved: they are a
--        marketing question, not part of this change
-- ----------------------------------------------------------------------------
with records as (
    select role_title, title_key
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_staging.stg_role_records`
),
dict as (
    select title_key, title_group, is_assigned, group_score, decision_source
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
)
select
    r.role_title,
    coalesce(d.title_group, '(no group)')               as title_group,
    coalesce(d.is_assigned, false)                      as is_assigned,
    d.decision_source,
    round(d.group_score, 3)                             as group_score,
    count(*)                                            as records
from records r
left join dict d using (title_key)
where regexp_contains(r.role_title, r'\bresearch (officer|analyst|executive)\b')
group by r.role_title, title_group, is_assigned, d.decision_source, group_score
order by records desc
limit 60
;


-- ----------------------------------------------------------------------------
-- 4. WHAT IT DID TO THE AUDIENCE - the only figure that matters to marketing.
--
--    The Researcher audience before this change: 322,266 CONFIRMED,
--    237,391 reachable. Records are not people: 34,376 records of `research
--    officer` is an unknown number of people, and some of them are already in
--    Researcher through a second employment record. This query gives the
--    people figure, which is the one that goes in a document.
-- ----------------------------------------------------------------------------
select
    role_key,
    countif(role_label = 'CONFIRMED')                   as confirmed_people,
    countif(role_label = 'CONFIRMED'
            and (is_marketable or is_advertisable
                 or is_legitimate_interest or is_book_author)) as reachable
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_presentation.fct_role_audience`
where role_key in ('researcher', 'hcp_researcher', 'lecturer')
group by role_key
order by role_key
;
