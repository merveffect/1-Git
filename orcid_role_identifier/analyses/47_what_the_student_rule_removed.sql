/*
    ============================================================================
    47. READ WHAT THE STUDENT RULE TOOK OUT, NOT WHAT IS LEFT IN
    ============================================================================
    Merve asked whether researcher is safe now, and whether to read another
    300 people from it.

    THE ANSWER TO THE SECOND HALF IS NO, AND HERE IS THE ARITHMETIC.
    researcher was read on 5 November at 99.0% correct of the decided, on
    400 people - the largest sample in this project. Another 300 would find
    about 3 errors and narrow the interval from +/-1.1 to +/-0.8. That is a
    lot of reading for a number we already have.

    THE RISK THAT IS ACTUALLY UNMEASURED RUNS THE OTHER WAY. An audience
    sample can only ever find people who should not be IN it. The 1.17
    student rule took 1,400 people OUT of researcher and 444 out of
    hcp_researcher, and no sample of either audience can see them - they
    have no row left to draw. Same shape as the dud query in analyses/36:
    int_employment_scored only emits a row when somebody qualifies, so the
    people who leave are invisible everywhere downstream.

    AND THE RIGHT GRAIN IS THE TITLE, NOT THE PERSON. The rule was decided
    per title, 1,078 of them. If it is wrong about one title, every person
    holding that title is gone, so reading 300 people would sample the same
    few large titles over and over. Reading the titles by record weight
    covers the whole decision instead.

        titles moved    1,078
        records moved  68,317
        people lost     1,400 from researcher, 444 from hcp_researcher

    Query 1 is the reading list, heaviest first. Query 2 is the arithmetic
    on how much of the decision a given number of titles covers, so the
    reading can stop at a defensible point rather than an arbitrary one.
    ============================================================================
*/


-- ----------------------------------------------------------------------------
-- 1. THE TITLES THE RULE TOOK, HEAVIEST FIRST.
--
--    Every row is a decision to read: does this job title name a doctoral
--    student rather than a researcher. `phd fellow` at 19,424 records is
--    the one the whole rule turns on.
--
--    decided_by says who moved it. PATTERN is the 1.17 rule. HUMAN would
--    be an override that happens to agree, and VECTOR would mean the model
--    had already put it in student before the rule existed - those two are
--    not the rule's doing and are shown so they are not read as such.
-- ----------------------------------------------------------------------------
select
    t.title,
    t.frequency                     as orcid_records,
    t.decision_source               as decided_by,
    round(t.similarity, 3)          as similarity,
    t.runner_up,
    array_to_string(t.matched_anchors, ' | ')  as matched_anchors
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group` t
where t.is_assigned
  and t.title_group = 'student'
  and t.model_title_group in ('researcher', 'researcher_early', 'researcher_established')
order by t.frequency desc
limit 150
;


-- ----------------------------------------------------------------------------
-- 2. HOW FAR DOES READING N TITLES GET YOU.
--
--    The same question analyses/35 query 2 asked of practitioner, which
--    found the top 500 titles covering 53% of records and made the reading
--    worth doing. Here the distribution should be far more skewed, because
--    `phd fellow` and its spellings are most of it - which would mean the
--    whole decision can be checked by reading a few dozen rows.
-- ----------------------------------------------------------------------------
with moved as (
    select
        title,
        frequency,
        row_number() over (order by frequency desc) as rn,
        sum(frequency) over ()                      as total
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
    where is_assigned
      and title_group = 'student'
      and model_title_group in ('researcher', 'researcher_early', 'researcher_established')
),
cuts as (
    select n from unnest([10, 25, 50, 100, 200, 500]) as n
)
select
    c.n                                                  as read_the_top,
    count(*)                                             as titles_in_reach,
    sum(m.frequency)                                     as records_covered,
    round(100 * sum(m.frequency) / max(m.total), 1)      as pct_of_the_decision,
    min(m.frequency)                                     as records_at_the_last_one
from cuts c
join moved m on m.rn <= c.n
group by c.n
order by c.n
;
