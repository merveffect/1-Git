/*
    ============================================================================
    35. THE STUDENT RULE, THE PRACTITIONER READING LIST, AND ONE SIZING
    ============================================================================
    Three jobs from Merve's instructions of 2026-11-04, in the order they were
    given. Queries 2-5 are the main body: practitioner is the least-read group
    in the project at ~38% of its records, and the instruction was to read more
    of it before going anywhere near the education signal.

      1     the 1.17 student rule - which titles it actually catches
      2-5   practitioner: is reading viable, and what to read
      6     sizing the "hcp_broad should hold nothing but its children" idea

    ONE THING I NEED FROM YOU BEFORE WRITING ANY OVERRIDE, and query 1 is built
    to ask it rather than to assume it. The rule was:

        "job title da researcher varsa katabiliriz"

    Read strictly that means the word RESEARCHER. But `graduate research
    assistant` - 106,438 records, the largest title on the 1.17 list - says
    `research`, not `researcher`. So does `research fellow` and every
    `research assistant`. The strict reading removes all of them; the loose
    reading keeps them. That is a 100,000-record difference and it is your call,
    not a detail I should settle by choosing a regex. Query 1 splits the
    population into exactly those three buckets so you can see both prices.
    ============================================================================
*/


-- ----------------------------------------------------------------------------
-- 1. THE STUDENT RULE. Which titles in the two researcher groups name a
--    student, and what each of them says about research.
--
--    bucket_strict  SAYS RESEARCHER     the word itself, in six languages
--    bucket_loose   SAYS RESEARCH ONLY  research assistant, research fellow
--    bucket_out     SAYS NEITHER        `phd fellow`, `doctoral candidate`
--
--    Under the strict reading, bucket_loose + bucket_out leave the Researcher
--    audience. Under the loose reading, only bucket_out leaves.
--
--    decision_source is shown because a HUMAN row is already a decision and
--    must not be overwritten without reading why it was made.
-- ----------------------------------------------------------------------------
with titles as (
    select
        title,
        title_group,
        decision_source,
        similarity,
        frequency,
        matched_anchors[safe_offset(0)]     as nearest_anchor,

        regexp_contains(title, r'(post[\s-]*doc|postdoc|pos[\s-]*doc|p[oó]s[\s-]*dout|post[\s-]*ph[\s.]*d|post[\s-]*doctorate)') as is_a_postdoc,
        regexp_contains(title, r'\b(student|students|studente|studenti|estudiante|etudiant|ogrenci|doctoral|doctorate|doctorand\w*|doktorand\w*|docteur|doutorando|candidate|candidato|candidata|phd|ph d|dphil|predoc\w*|pre doctoral|graduand\w*)\b')   as names_a_student,
        regexp_contains(title, r'\b(researcher|researchers|investigador\w*|investigadora|chercheur\w*|forscher\w*|arastirmaci|ricercator\w*)\b')   as says_researcher,

        regexp_contains(title, r'\bresearch\b')              as says_research
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
    where is_assigned
      and title_group in ('researcher', 'researcher_early', 'researcher_established')
),

judged as (
    select
        *,
        case
            /*
                A POSTDOC IS NOT A DOCTORAL STUDENT, and the first version of
                this query said they were. `post-doctoral fellow` (78,093
                records), `post doctoral fellow` (55,567) and the whole postdoc
                family contain the string `doctoral`, so the student pattern
                swept all of them and put 292,253 records in the SAYS NEITHER
                bucket that have no business in this question at all.

                Exactly the pre/post blind spot recorded in 2.4e, except here it
                was my regex rather than the embedding. The family is bucketed
                separately rather than filtered out silently, so the exclusion
                can be audited instead of trusted.
            */
            when is_a_postdoc                 then 'POSTDOC - NOT A STUDENT, excluded'
            when says_researcher              then 'SAYS RESEARCHER  - in under either reading'
            when says_research                then 'SAYS RESEARCH ONLY - in only under the loose reading'
            else                                   'SAYS NEITHER      - out under either reading'
        end                                                 as bucket
    from titles
    where names_a_student
)

/*
    Two outputs in one: the bucket totals at the top of your eye, then the
    titles themselves. Read the totals first, decide the reading, then read
    only the bucket that reading removes.
*/
select
    bucket,
    title_group,
    count(*)                                                as titles,
    sum(frequency)                                          as orcid_records,
    array_agg(title order by frequency desc limit 25)       as biggest_titles
from judged
group by bucket, title_group
order by orcid_records desc;


-- ----------------------------------------------------------------------------
-- 1a. The same population, title by title, for the bucket you choose to act on.
--     Add a bucket filter before writing overrides from it.
-- ----------------------------------------------------------------------------
select
    title,
    title_group,
    decision_source,
    round(similarity, 4)    as similarity,
    frequency               as orcid_records,
    matched_anchors[safe_offset(0)] as nearest_anchor,
    regexp_contains(title, r'\b(researcher|investigador\w*|chercheur\w*|forscher\w*|ricercator\w*)\b') as says_researcher,
    regexp_contains(title, r'\bresearch\b')                                                            as says_research,
    regexp_contains(title, r'(post[\s-]*doc|postdoc|pos[\s-]*doc|p[oó]s[\s-]*dout|post[\s-]*ph[\s.]*d|post[\s-]*doctorate)') as is_a_postdoc
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
where is_assigned
  and title_group in ('researcher', 'researcher_early', 'researcher_established')
  and regexp_contains(title, r'\b(student|students|studente|studenti|estudiante|etudiant|ogrenci|doctoral|doctorate|doctorand\w*|doktorand\w*|docteur|doutorando|candidate|candidato|candidata|phd|ph d|dphil|predoc\w*|pre doctoral|graduand\w*)\b')
order by frequency desc
limit 300;


-- ----------------------------------------------------------------------------
-- 2. IS READING PRACTITIONER EVEN VIABLE? Ask before spending a day on it.
--
--    This is the test from 2.4a, which exists because we twice called a group
--    "reviewed" after reading ~150 titles. If most of the group's records sit
--    in titles that appear twice, no top-100 list will ever reach it and the
--    answer is a computable test rather than more reading.
--
--    Read pct_cumulative: how much of the group the top N titles carry.
-- ----------------------------------------------------------------------------
with t as (
    select title, frequency, similarity
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
    where is_assigned and title_group = 'practitioner'
),

ranked as (
    select
        title, frequency, similarity,
        row_number() over (order by frequency desc)                             as rn,
        sum(frequency) over (order by frequency desc
                             rows between unbounded preceding and current row)  as running,
        sum(frequency) over ()                                                   as total,
        count(*)       over ()                                                   as all_titles
    from t
),

steps as (
    select * from unnest([50, 100, 200, 500, 1000, 2000, 5000, 10000]) as top_n
)

select
    s.top_n,
    (select all_titles from ranked limit 1)                                     as titles_in_group,
    (select max(running) from ranked where rn <= s.top_n)                       as records_covered,
    (select max(total)   from ranked limit 1)                                   as records_in_group,
    round(100 * (select max(running) from ranked where rn <= s.top_n)
              / (select max(total) from ranked limit 1), 2)                     as pct_cumulative,
    (select min(frequency) from ranked where rn <= s.top_n)                     as smallest_title_at_this_depth
from steps s
order by s.top_n;


-- ----------------------------------------------------------------------------
-- 3. THE READING LIST THAT MATTERS: practitioner ABOVE 0.75 similarity.
--
--    READ THIS ONE FIRST AND READ IT PROPERLY. Every practitioner review query
--    we have ever written filtered `similarity < 0.75`, on the grounds that the
--    low band is where the doubt is. 2.4a records what that cost in the
--    researcher group: `junior researcher` at 0.870, 42,949 records, the
--    largest single error in the project, invisible to every review query
--    because they all excluded its band.
--
--    1,633,664 of practitioner's records are VECTOR decisions and the great
--    majority of them are in this band. It has never been examined.
--
--    Titles already carrying an override are excluded - those are decided.
-- ----------------------------------------------------------------------------
select
    t.title,
    round(t.similarity, 4)              as similarity,
    round(t.margin, 4)                  as margin,
    t.frequency                         as orcid_records,
    t.matched_anchors[safe_offset(0)]   as nearest_anchor,
    t.runner_up,
    t.decision_source
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group` t
left join `dat-analytics-eng-ec869189.dev_orcid_role_identifier_seeds.role_title_overrides` o
       on o.title = t.title
where t.is_assigned
  and t.title_group = 'practitioner'
  and t.similarity >= 0.75
  and t.decision_source = 'VECTOR'
  and o.title is null
order by t.frequency desc
limit 400;


-- ----------------------------------------------------------------------------
-- 4. THE LOW BAND, for completeness. practitioner BELOW 0.75.
--
--    This is the band previous reviews covered, so expect most of it to be
--    familiar. It is here so the two can be read as one list rather than one
--    being forgotten.
-- ----------------------------------------------------------------------------
select
    t.title,
    round(t.similarity, 4)              as similarity,
    round(t.margin, 4)                  as margin,
    t.frequency                         as orcid_records,
    t.matched_anchors[safe_offset(0)]   as nearest_anchor,
    t.runner_up,
    t.decision_source
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group` t
left join `dat-analytics-eng-ec869189.dev_orcid_role_identifier_seeds.role_title_overrides` o
       on o.title = t.title
where t.is_assigned
  and t.title_group = 'practitioner'
  and t.similarity < 0.75
  and t.decision_source = 'VECTOR'
  and o.title is null
order by t.frequency desc
limit 400;


-- ----------------------------------------------------------------------------
-- 5. WHERE TO POINT THE READING: the missing-anchor signature.
--
--    The one diagnostic in this project that generalised, from Part 2b: an
--    anchor carrying a high share of records below 0.75 is the signature of a
--    MISSING anchor, not a bad one. The titles arriving there are usually
--    correct and merely unconfident, because the nearest anchor we gave the
--    model is the closest thing available - `paramedic` was at 0.633 because
--    emergency medicine had no anchor of its own, and adding one took it to
--    0.226.
--
--    Five of six anchors behaved exactly as this predicted in October. Read the
--    top of this list beside query 3 and 4: an anchor high on both is where a
--    new anchor pays for itself.
-- ----------------------------------------------------------------------------
select
    matched_anchors[safe_offset(0)]                                     as nearest_anchor,
    count(*)                                                            as titles,
    sum(frequency)                                                      as orcid_records,
    countif(similarity < 0.75)                                          as titles_below_075,
    round(safe_divide(sum(if(similarity < 0.75, frequency, 0)),
                      sum(frequency)), 3)                               as share_records_below_075,
    round(avg(similarity), 4)                                           as mean_similarity,
    array_agg(title order by frequency desc limit 6)                    as biggest_titles
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
where is_assigned
  and title_group = 'practitioner'
  and decision_source = 'VECTOR'
group by nearest_anchor
having sum(frequency) >= 2000
order by share_records_below_075 desc, orcid_records desc;


-- ----------------------------------------------------------------------------
-- 6. SIZING "hcp_broad SHOULD HOLD NOTHING BUT ITS CHILDREN".
--
--    Merve's second proposal, not implemented. Run this AFTER the build that
--    makes the title mandatory, so the numbers describe the new state.
--
--    Note hcp_broad has FOUR children, not three: hcp_practitioner,
--    hcp_researcher, hcp_administrator and pharmacist, which rolls up as
--    PRACTITIONER.
--
--    A roll-up row carries the child's score and is then relabelled against
--    hcp_broad's own threshold of 0.60, so a child row at or above 0.60 would
--    survive as an hcp_broad row on roll-up alone. The question is how many
--    people exist in hcp_broad ONLY through its own matching - those are the
--    people the proposal would remove.
-- ----------------------------------------------------------------------------
with broad as (
    select distinct snid
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles`
    where role_key = 'hcp_broad' and role_label = 'CONFIRMED'
),

via_children as (
    select distinct snid
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles`
    where role_key in ('hcp_practitioner', 'hcp_researcher', 'hcp_administrator', 'pharmacist')
      and role_label in ('CONFIRMED', 'PROBABLE')
      and role_final_score >= 0.60
)

select
    (select count(*) from broad)                                        as confirmed_in_hcp_broad_today,
    (select count(*) from via_children)                                 as would_survive_on_rollup_alone,
    (select count(*) from broad b
      where not exists (select 1 from via_children c where c.snid = b.snid))
                                                                        as only_through_own_matching,
    (select count(*) from via_children c
      where not exists (select 1 from broad b where b.snid = c.snid))
                                                                        as child_qualifies_but_not_in_broad;
