/*
    ============================================================================
    50. THE 11 NOVEMBER BUILD - what to run, before and after
    ============================================================================
    Three decisions land in one build, because Merve asked for one build rather
    than three: "surekli build etmek istemiyorum her seyi ekle sonra kontrol
    edelim."

      A  biomedical researchers join hcp_researcher, and hcp_broad by roll-up
         (dbt_project.yml, one word)
      B  a title may name TWO jobs      (seeds/title_group_second.csv, new)
      C  the scientific-officer family joins researcher - PROPOSED, flagged
         (seeds/title_group_patterns.csv, one row, delete to reverse)

    RUN ORDER
      Queries 1 and 2 on the CURRENT build, before anything is rebuilt.
      Then:  dbt build --select title_group_second+ title_group_patterns+ \
                               discipline_anchors+ role_title_overrides+
      Then queries 3, 4, 5 and 6 on the new build.

    WHY THAT BUILD COMMAND AND NOT `dbt build`. The two embedding models are
    the expensive part - int_title_embeddings over 317,302 titles and
    int_department_embeddings over 459,123 departments. Neither seed above is
    upstream of them, so naming the seeds keeps both out. role_title_overrides
    is named separately because it is NOT downstream of discipline_anchors and
    a `+` on one does not reach the other - that mistake cost a build on
    2026-11-10, where the log said "1 seed" and the fix never reached BigQuery.

    WHAT CANNOT BE FORECAST, stated so nobody treats query 2 as a prediction.
    Queries 1 and 2 count RECORDS at title grain. The audiences are counted in
    PEOPLE, and a person has several employment records - so somebody whose
    title gains `teaching_academic` may already be in Lecturer through a second
    post. The record figure is an upper bound on the people figure and the two
    are not comparable. Query 5 is the only honest answer and it needs the
    build.
*/


-- ----------------------------------------------------------------------------
-- 1. BEFORE - A. the biomedical population, and what it will actually add.
--
--    15,588 is a FOUND figure from analyses/17 query 8a, not a CONFIRMED one.
--    hcp_researcher requires title AND field and confirms at 0.70, so this
--    query asks how many of them clear it. The answer is what goes in the
--    document, not 15,588.
-- ----------------------------------------------------------------------------
with scored as (
    select
        s.snid,
        d.discipline,
        round(d.discipline_score, 3)                    as discipline_score,
        t.title_group,
        round(t.group_score, 3)                         as title_score
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_staging.stg_role_records` s
    left join `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group` t
           on s.title_key = t.title_key and t.is_assigned
    left join `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_department_discipline` d
           on to_hex(md5(s.department)) = d.department_key and d.is_assigned
    where t.title_group = 'researcher'
      and d.discipline  = 'life_biomedical'
)
select
    count(*)                                            as records,
    count(distinct snid)                                as people,
    round(avg(title_score), 3)                          as avg_title_score,
    round(avg(discipline_score), 3)                     as avg_discipline_score,
    /*  hcp_researcher weights are role 0.40 / org 0.20 / dept 0.40 and it
        confirms at 0.70. Without the org term the floor is
        0.40*title + 0.40*dept, so this is the share that could not possibly
        confirm however good their employer is, and the share that confirms
        on the two axes alone.  */
    countif(0.40 * title_score + 0.40 * discipline_score >= 0.70)
                                                        as confirms_without_org,
    countif(0.40 * title_score + 0.40 * discipline_score + 0.20 < 0.70)
                                                        as cannot_confirm_at_all
from scored
;


-- ----------------------------------------------------------------------------
-- 2. BEFORE - B. what each second-group rule will claim, at record weight.
--
--    Reproduces the join in dim_title_group's second_hits against the CURRENT
--    dictionary, so it reads the state the rules will actually see. A rule
--    returning zero here is a dead rule and the decision behind it has not
--    happened - that is also what assert_second_group_rules_all_match_something
--    tests, at warn severity.
-- ----------------------------------------------------------------------------
with dict as (
    select title_key, title, frequency, title_group, is_assigned
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
    where is_assigned
),
rules as (
    select applies_when_title_group, name_pattern, second_title_group, unless_pattern
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_seeds.title_group_second`
)
select
    r.applies_when_title_group                          as from_group,
    r.second_title_group                                as gains_group,
    count(*)                                            as distinct_titles,
    sum(d.frequency)                                    as records,
    string_agg(d.title order by d.frequency desc limit 8) as biggest_titles
from dict d
join rules r
     on regexp_contains(d.title, r.name_pattern)
    and d.title_group = r.applies_when_title_group
    and r.second_title_group != d.title_group
    and (r.unless_pattern is null or r.unless_pattern = ''
         or not regexp_contains(d.title, r.unless_pattern))
group by from_group, gains_group
order by records desc
;


-- ----------------------------------------------------------------------------
-- 2a. BEFORE - and what the VETO is holding back on the student rule.
--
--    The one rule where the veto is the whole risk. `postdoctoral researcher`
--    is not a doctoral student, and `research professor phd` carries phd as a
--    credential rather than a status - the finding that scoped 1.17 to the
--    early end of the group. If this returns something that looks like a real
--    doctoral student, the veto is too wide.
-- ----------------------------------------------------------------------------
with dict as (
    select title, frequency, title_group
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
    where is_assigned and title_group = 'researcher'
),
rule as (
    select name_pattern, unless_pattern
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_seeds.title_group_second`
    where second_title_group = 'student'
)
select
    d.title,
    d.frequency,
    'vetoed - stays researcher only'                    as outcome
from dict d
cross join rule r
where regexp_contains(d.title, r.name_pattern)
  and regexp_contains(d.title, r.unless_pattern)
order by d.frequency desc
limit 60
;


-- ----------------------------------------------------------------------------
-- 2b. BEFORE - THE TAIL OF EACH RULE, because query 2 only shows its head.
--
--     WHY THIS QUERY EXISTS. Query 2 ran on 2026-11-11 and two of the five
--     rules came back around EIGHT TIMES the forecast written beside them:
--     researcher -> teaching_academic was put at ~120,000 records and measured
--     384,699, and researcher -> student was put at ~48,000 and measured
--     344,285. The forecasts were built from the half-dozen titles I could
--     name, and 5,647 distinct titles cannot be judged from eight of them.
--
--     So this draws the top 5 of each rule plus roughly 25 more spread evenly
--     down its frequency distribution, and prints the rank so it is obvious
--     which part of the tail each row comes from. What you are reading for is
--     ONE thing: does the title name a SECOND JOB, or does it name a subject,
--     a grade or a department? `research professor` names two jobs.
--     `professor of research methods` names a subject and must not be here.
-- ----------------------------------------------------------------------------
with dict as (
    select title_key, title, frequency, title_group
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
    where is_assigned
),
rules as (
    select applies_when_title_group, name_pattern, second_title_group, unless_pattern
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_seeds.title_group_second`
),
matched as (
    select
        r.applies_when_title_group                      as from_group,
        r.second_title_group                            as gains_group,
        d.title,
        d.frequency,
        row_number() over (partition by r.applies_when_title_group,
                                        r.second_title_group
                           order by d.frequency desc)   as rank_in_rule,
        count(*)    over (partition by r.applies_when_title_group,
                                       r.second_title_group)
                                                        as titles_in_rule
    from dict d
    join rules r
         on regexp_contains(d.title, r.name_pattern)
        and d.title_group = r.applies_when_title_group
        and r.second_title_group != d.title_group
        and (r.unless_pattern is null or r.unless_pattern = ''
             or not regexp_contains(d.title, r.unless_pattern))
)
select
    from_group,
    gains_group,
    rank_in_rule,
    titles_in_rule,
    title,
    frequency
from matched
/*  The top 5 always, then every (n/25)th title the rest of the way down, so
    a rule with 5,647 titles and a rule with 1,571 both come back at about
    thirty rows and the sample is spread rather than piled at the top.  */
where rank_in_rule <= 5
   or mod(rank_in_rule,
          greatest(1, cast(floor(titles_in_rule / 25) as int64))) = 0
order by from_group, gains_group, rank_in_rule
;


-- ----------------------------------------------------------------------------
-- 2c. BEFORE - AND THE SAME THING IN PEOPLE, WHICH IS WHAT AN AUDIENCE IS.
--
--     Query 2 counts records at title grain and the header of this file warns
--     that the two are not comparable. This is the comparable number: how many
--     PEOPLE hold a record the rule matches, and how many of them are not
--     already CONFIRMED in the audience that second group feeds.
--
--     `could_be_new` IS NOT A CEILING FOR TWO OF THE THREE AUDIENCES, and that
--     is the finding that makes this query worth running before the build. The
--     second group carries a FLAT score of 1.0, because it is a literal
--     pattern match - the same reasoning pattern_hits already uses. Lecturer
--     weights the role axis 0.75 and confirms at 0.60, so 0.75 x 1.0 = 0.75
--     clears the threshold on the title ALONE, with no help from the employer;
--     Researcher is weighted and thresholded identically. So for those two,
--     `could_be_new` is not an upper bound on new members, it is close to the
--     count of them, and they arrive as CONFIRMED rather than PROBABLE.
--
--     faculty_head is the exception and the arithmetic is worth stating: role
--     0.60 x 1.0 = 0.60 against a 0.65 threshold, so a second-group entry
--     CANNOT confirm on its title. It needs the 0.40 organisation term, which
--     org_type_scores gives only to Education - and the role is current-only.
-- ----------------------------------------------------------------------------
with dict as (
    select title_key, title, title_group
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
    where is_assigned
),
rules as (
    select applies_when_title_group, name_pattern, second_title_group, unless_pattern
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_seeds.title_group_second`
),
hits as (
    select distinct
        s.snid,
        r.applies_when_title_group                      as from_group,
        r.second_title_group                            as gains_group,
        /*  Which audience that group actually feeds. student and
            support_technical feed none, which is why the student rule is the
            largest one in query 2 and the least consequential.  */
        case r.second_title_group
            when 'teaching_academic' then 'lecturer'
            when 'researcher'        then 'researcher'
            when 'leadership'        then 'faculty_head'
            else null
        end                                             as target_audience
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_staging.stg_role_records` s
    join dict d on s.title_key = d.title_key
    join rules r
         on regexp_contains(d.title, r.name_pattern)
        and d.title_group = r.applies_when_title_group
        and r.second_title_group != d.title_group
        and (r.unless_pattern is null or r.unless_pattern = ''
             or not regexp_contains(d.title, r.unless_pattern))
),
already as (
    select distinct snid, role_key
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles`
    where role_label = 'CONFIRMED'
)
select
    h.from_group,
    h.gains_group,
    coalesce(h.target_audience, 'none - feeds no audience') as target_audience,
    count(distinct h.snid)                              as people_matching_rule,
    count(distinct if(a.snid is not null, h.snid, null))  as already_in_target,
    count(distinct if(a.snid is null,     h.snid, null))  as could_be_new
from hits h
left join already a
       on a.snid = h.snid
      and a.role_key = h.target_audience
group by from_group, gains_group, target_audience
order by could_be_new desc
;


-- ----------------------------------------------------------------------------
-- 2d. BEFORE - THE BARE-DIRECTOR RISK, which query 2 showed in its own top 8.
--
--     `course director` came back as one of the eight biggest titles in the
--     teaching_academic -> leadership rule. A course director runs a programme;
--     they are not faculty management, and faculty_head is the audience on the
--     other side of that rule.
--
--     THIS IS 1.3's LESSON ARRIVING FROM A NEW DIRECTION. A leadership WORD is
--     not a leadership JOB. We already know bare `director`, `chair` and `head`
--     with no faculty word beside them are about 15% of faculty_head and are
--     the first row of the UNSURE table in the reviewer rules. The LEAD_JOB
--     list takes bare `director`, so this rule WIDENS that known ambiguity
--     rather than inheriting it.
--
--     AND BARE DIRECTOR CANNOT SIMPLY BE DROPPED FROM THE LIST: `professor &
--     director` is bare director, and it is the exact title that motivated the
--     rule. So the question this query answers is how big the narrow-director
--     half is, and whether it can be vetoed by compound instead.
--
--     The classifier below is a NEW regex, not a copy of LEAD_JOB - it asks
--     only whether a faculty-level word is present, and it carries the same
--     languages LEAD_JOB does, because an English-only veto beside a
--     multilingual name pattern has now failed four times.
-- ----------------------------------------------------------------------------
with dict as (
    select title, frequency
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
    where is_assigned and title_group = 'teaching_academic'
),
rule as (
    select name_pattern, unless_pattern
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_seeds.title_group_second`
    where applies_when_title_group = 'teaching_academic'
      and second_title_group       = 'leadership'
),
matched as (
    select
        d.title,
        d.frequency,
        regexp_contains(d.title,
            r'\b(dean|dekan|decano|decana|doyen|rector|rektor|rectora|provost|chancellor|vice chancellor|pro vice chancellor|head of (the )?(department|school|faculty|division|institute)|hod|department chair|chair of (the )?(department|division|school|faculty)|chairman|chairperson|chairwoman|b[aö][sş]kan)\b')
                                                        as has_faculty_word
    from dict d
    cross join rule r
    where regexp_contains(d.title, r.name_pattern)
      and (r.unless_pattern is null or r.unless_pattern = ''
           or not regexp_contains(d.title, r.unless_pattern))
)
select
    if(has_faculty_word, 'faculty-level word present',
                         'DIRECTOR OR CHAIR ALONE')     as kind,
    count(*)                                            as distinct_titles,
    sum(frequency)                                      as records
from matched
group by kind
order by records desc
;

-- 2d-ii. And the narrow half itself, biggest first, so the veto can be written
--        from what is actually there rather than from the three compounds I can
--        name. Read it for titles where the director word runs a COURSE, a
--        CLINIC or a PROJECT rather than a faculty.
with dict as (
    select title, frequency
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
    where is_assigned and title_group = 'teaching_academic'
),
rule as (
    select name_pattern, unless_pattern
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_seeds.title_group_second`
    where applies_when_title_group = 'teaching_academic'
      and second_title_group       = 'leadership'
)
select d.title, d.frequency
from dict d
cross join rule r
where regexp_contains(d.title, r.name_pattern)
  and (r.unless_pattern is null or r.unless_pattern = ''
       or not regexp_contains(d.title, r.unless_pattern))
  and not regexp_contains(d.title,
        r'\b(dean|dekan|decano|decana|doyen|rector|rektor|rectora|provost|chancellor|vice chancellor|pro vice chancellor|head of (the )?(department|school|faculty|division|institute)|hod|department chair|chair of (the )?(department|division|school|faculty)|chairman|chairperson|chairwoman|b[aö][sş]kan)\b')
order by d.frequency desc
limit 60
;


-- ----------------------------------------------------------------------------
-- 2e. BEFORE - RECONCILE THE RECORD COUNTS AGAINST THE SOURCE, because query 2
--     and query 2c do not agree and one of them is wrong.
--
--     Query 2  : researcher -> student, 344,285 records.
--     Query 2c : the same rule,          19,927 people.
--
--     Seventeen employment records per person is not credible. And the two
--     cannot be measuring different populations by design: frequency is
--     `count(*)` over stg_role_records in int_title_distinct line 27, which is
--     the same view 2c counts distinct snid from. Query 1 reconciles perfectly
--     on the same join - 86,240 records over 63,767 people, 1.35 each - so the
--     fault is not in the join shape.
--
--     THE LIKELIEST EXPLANATION, AND WHY IT MATTERS FAR BEYOND THIS BUILD:
--     stg_role_records is a VIEW, and int_title_distinct is a TABLE. If the
--     ORCID source has been reloaded smaller since the dictionary was last
--     built, every frequency in dim_title_group describes a corpus that no
--     longer exists - and then every record figure quoted from frequency is
--     stale, including the ones written into seed notes and the status
--     document. If that is what this shows, the dictionary needs rebuilding
--     before any of those figures are quoted again.
-- ----------------------------------------------------------------------------
with named as (
    select title
    from unnest([
        'graduate research assistant',
        'phd researcher',
        'dottorandi',
        'research assistant professor',
        'research professor',
        'professor & director'
    ]) as title
)
select
    n.title,
    t.frequency                                         as dict_frequency,
    sum(if(s.title_key is null, 0, 1))                  as source_records,
    count(distinct s.snid)                              as source_people,
    round(safe_divide(t.frequency,
                      sum(if(s.title_key is null, 0, 1))), 2)
                                                        as stale_ratio
from named n
left join `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group` t
       on t.title = n.title
left join `dat-analytics-eng-ec869189.dev_orcid_role_identifier_staging.stg_role_records` s
       on s.title_key = t.title_key
group by n.title, t.frequency
order by dict_frequency desc
;

-- 2e-ii. The same question as ONE number, for the whole corpus. int_title_distinct
--        stored the total it was built from, so this compares that stored total
--        against the live view. Equal means the dictionary is current and the
--        fault is somewhere in query 2 or 2c; different means the dictionary is
--        stale and says by how much.
select
    (select max(corpus_size)
     from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.int_title_distinct`)
                                                        as corpus_when_dictionary_built,
    (select count(*)
     from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_staging.stg_role_records`
     where role_title is not null)                      as corpus_now
;


-- ----------------------------------------------------------------------------
-- 2f. BEFORE - THE DECISIVE QUERY. 2e ruled out the explanation 2e was written
--     to test, so the cause has to be named rather than guessed at again.
--
--     WHAT 2e SHOWED. The corpus is NOT stale: 1,764,535 records when the
--     dictionary was built against 1,767,500 live, a 0.17% difference. But
--     every named title is 14 to 30 times larger in the dictionary than the
--     live view, and the ratio is different for each title - 14.5 for
--     `graduate research assistant`, 29.5 for `professor & director`. A stale
--     corpus would have moved the total and would have moved every title by
--     the same factor. Neither happened.
--
--     SO THE RECORDS HAVE NOT GONE: THE KEYS HAVE MOVED. title_key is
--     md5(role_title) where role_title is the NORMALISED title, built by
--     macros/normalize.sql. If that macro's output changed after the
--     dictionary was built, the same record now hashes to a different key -
--     the corpus total is untouched, the dictionary still holds the old string
--     with its old frequency, and a join between the live view and the old
--     dictionary silently finds only the fraction of records whose
--     normalisation happens to be unchanged. Varying per-title ratios are
--     exactly what that produces.
--
--     WHY IT MATTERS MORE THAN THIS BUILD. If that is the answer, then EVERY
--     query in this project that joins stg_role_records to the dictionary is
--     undercounting right now - including query 1 above, whose 86,240 records
--     and 63,767 people I reported this morning, and query 2c's people
--     figures. The queries that read the dictionary ALONE are unaffected,
--     which is queries 2, 2b and 2d, so the tail reading and the
--     bare-director sizing both stand.
-- ----------------------------------------------------------------------------
select
    count(*)                                            as live_records,
    countif(t.title_key is not null)                    as matched_to_dictionary,
    round(100 * countif(t.title_key is not null) / count(*), 1)
                                                        as pct_records_matched,
    count(distinct s.title_key)                         as live_distinct_titles,
    count(distinct if(t.title_key is not null, s.title_key, null))
                                                        as matched_distinct_titles
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_staging.stg_role_records` s
left join `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group` t
       using (title_key)
;

-- 2f-ii. And the biggest live titles the dictionary has never seen. If the
--        normalisation moved, the cause is readable straight off this list -
--        these will be near-spellings of titles the dictionary already holds,
--        and the difference between the two strings IS the change.
select
    s.role_title,
    count(*)                                            as records
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_staging.stg_role_records` s
left join `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group` t
       using (title_key)
where t.title_key is null
group by s.role_title
order by records desc
limit 30
;


-- ----------------------------------------------------------------------------
-- 2g. BEFORE - WHERE THE INFLATED frequency COMES FROM, and the last place it
--     can be. Third hypothesis; the first two were both wrong and both were
--     wrong in the same way, by reasoning from a shape instead of measuring.
--
--     RULED OUT SO FAR
--       2e   the corpus is not stale - 1,764,535 built against 1,767,500 live.
--       2f   the keys have not moved - 99.8% of live records join the
--            dictionary, and the 2,969 titles that do not are junk: `other`,
--            `无`, `-`, single letters, under 105 records each.
--       code frequency is not fanned out in the dictionary chain.
--            int_title_group_match carries it as a GROUP BY key (line 46) and
--            never sums it, and dim_title_group selects r.frequency unchanged.
--
--     WHAT THAT LEAVES. The join is sound and the dictionary is current, so
--     the fault is in the frequency COLUMN itself - the number
--     int_title_distinct stored when it was built is not the number the view
--     returns now, while the TOTAL of those numbers still is. This asks the
--     two models the same question side by side and then sums both, which is
--     the only arrangement that can say which one moved.
--
--     THE CORRECTION THIS FORCES, and it reverses what 2f's comment says.
--     Because the join is 99.8% sound, the queries that count from the LIVE
--     VIEW are the trustworthy ones - query 1's 86,240 records and 63,767
--     people, and every people figure in 2c. The suspect number is `frequency`
--     in the dictionary, which is exactly what the `records` columns of
--     queries 2, 2b and 2d are built from. So it is the RECORD figures that
--     cannot be quoted, not the people figures. Distinct-title counts are
--     unaffected either way, so 2d's 2,447 against 615 titles stands.
-- ----------------------------------------------------------------------------
with live as (
    select title_key, count(*) as live_records
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_staging.stg_role_records`
    where role_title is not null
    group by title_key
)
select
    d.title,
    d.frequency                                         as int_title_distinct_freq,
    g.frequency                                         as dim_title_group_freq,
    l.live_records,
    round(safe_divide(d.frequency, l.live_records), 2)   as dict_over_live
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.int_title_distinct` d
join `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group` g
     using (title_key)
left join live l using (title_key)
where d.title in ('graduate research assistant', 'research assistant professor',
                  'research professor', 'dottorandi', 'professor & director',
                  'phd researcher')
order by d.frequency desc
;

-- 2g-ii. The same three models summed, and counted. If the two frequency sums
--        agree with each other and with the live count, then no column is
--        inflated in aggregate and the distortion is a RESHUFFLE - frequency
--        sitting against the wrong title - which is a different and worse
--        defect than a stale table, because it has no uniform correction.
select
    (select sum(frequency) from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.int_title_distinct`)
                                                        as sum_int_title_distinct,
    (select sum(frequency) from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`)
                                                        as sum_dim_title_group,
    (select count(*) from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_staging.stg_role_records`
     where role_title is not null)                      as live_records,
    (select count(*) from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.int_title_distinct`)
                                                        as rows_int_title_distinct,
    (select count(*) from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`)
                                                        as rows_dim_title_group,
    (select count(distinct title_key) from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`)
                                                        as keys_dim_title_group
;


-- ----------------------------------------------------------------------------
-- 3. AFTER - did the second group land at all?
--
--    The first thing to look at. If title_group_2 is null everywhere, the
--    seed did not reach BigQuery and the build command missed it - which is
--    exactly what happened on 2026-11-10 when the log said "1 seed".
-- ----------------------------------------------------------------------------
select
    title_group                                         as primary_group,
    coalesce(title_group_2, '(none)')                   as second_group,
    count(*)                                            as distinct_titles,
    sum(frequency)                                      as records,
    string_agg(title order by frequency desc limit 6)   as biggest_titles
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
where is_assigned
group by primary_group, second_group
having second_group != '(none)'
order by records desc
;


-- ----------------------------------------------------------------------------
-- 4. AFTER - C. the two pattern families, so the flagged row can be judged.
--
--    research officer / analyst / executive should now read PATTERN with
--    group_score 1.000 in `researcher`. So should the scientific-officer
--    family, and if Merve says no to it, this is the list that leaves again.
-- ----------------------------------------------------------------------------
select
    case
        when regexp_contains(title, r'\bresearch (officer|analyst|executive)\b')
            then '1 research-officer family (decided)'
        else '2 scientific-officer family (NO - pattern row deleted 11 Nov)'
    end                                                 as family,
    title_group,
    decision_source,
    round(group_score, 3)                               as group_score,
    count(*)                                            as distinct_titles,
    sum(frequency)                                      as records
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
where regexp_contains(title, r'\bresearch (officer|analyst|executive)\b')
   or regexp_contains(title, r'\bscien[a-z]*\s+(project\s+)?officer\b')
group by family, title_group, decision_source, group_score
order by family, records desc
;


-- ----------------------------------------------------------------------------
-- 5. THE ONLY FIGURE THAT GOES IN A DOCUMENT - AND RUN IT BEFORE THE BUILD TOO.
--
--    IT WAS ONLY RUN AFTER, ON 2026-11-12, AND THAT WAS A MISTAKE. The only
--    baseline left to compare against was the table in setup/audiences.py,
--    measured 5 November - a week and several builds earlier, including the
--    1.17 student rule and the pharmacology fix on 10 November. So every delta
--    read off that comparison carries three builds' worth of change, not this
--    one's, and faculty_head going DOWN by 324 while gaining members cannot be
--    attributed to anything in particular. Run this query before and after,
--    every time.
--
--    People, per audience, with the reachable count beside it. Compare against
--    the 10 November state:
--
--      lecturer           400,445 confirmed    319,291 reachable
--      researcher         322,266              237,391
--      hcp_broad          126,270               93,377
--      hcp_practitioner    60,083               46,450
--      hcp_researcher      50,590               39,758
--      faculty_head        20,222               11,962
--      hcp_administrator    6,855                5,949
--      pharmacist           2,335                1,531
--      librarian              666                  384
--
--    EXPECT lecturer, researcher, faculty_head and hcp_researcher to move and
--    nothing else. If pharmacist or librarian moves, a rule is firing where it
--    should not and the second-group word lists are too wide.
-- ----------------------------------------------------------------------------
select
    role_key,
    countif(role_label = 'CONFIRMED')                   as confirmed_people,
    countif(role_label = 'CONFIRMED'
            and (is_marketable or is_advertisable
                 or is_legitimate_interest or is_book_author)) as reachable
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_presentation.fct_role_audience`
group by role_key
order by confirmed_people desc
;


-- ----------------------------------------------------------------------------
-- 6. AFTER - who arrived through the SECOND group, per audience.
--
--    THE FIRST VERSION OF THIS QUERY WAS WRONG AND ITS ANSWER WAS BELIEVABLE,
--    which is the dangerous combination. It filtered on `title_group_2 is not
--    null`, which keeps every row whose TITLE names two jobs regardless of
--    which group actually carried the role. So a person in faculty_head whose
--    title is `professor and director` was counted as having arrived through
--    the second group when their PRIMARY group, leadership, is what put them
--    there. It reported 8,116 people for faculty_head against a rule that
--    covers 4,144 records in the whole dictionary - more people than there are
--    records, which is what gave it away.
--
--    Its second column was worse: countif(title_group_2 is not null) inside a
--    WHERE that already requires it non-null, so it could only ever equal
--    count(*), and it duly printed the same number as the people column on
--    every row.
--
--    THE CORRECT TEST. int_employment_scored emits title_group_matched AS
--    title_group - the group that carried this role - alongside title_group_2.
--    The seed forbids a second group from restating the primary, so
--    `title_group = title_group_2` is true exactly when the SECOND group is
--    what matched. Anything else means the primary carried it.
--
--    AND THE QUESTION WORTH ASKING IS NARROWER STILL: not who has a second
--    group, but who would NOT BE IN THE AUDIENCE WITHOUT IT. A person with
--    several posts may reach the role on one record's primary group and
--    another record's second, and they are not new. only_via_second is the
--    figure the next reading has to sample.
-- ----------------------------------------------------------------------------
with scored as (
    select snid, role_key, title_group, title_group_2
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.int_employment_scored`
    /*  role_score > 0 stands in for "this record matched this role at all".
        A matched record can still score 0 if its group was REJECTED, so this
        is marginally conservative and never the other way.  */
    where role_score > 0
),
per_person as (
    select
        snid,
        role_key,
        countif(title_group_2 is null or title_group != title_group_2) as via_primary,
        countif(title_group_2 is not null and title_group = title_group_2) as via_second
    from scored
    group by snid, role_key
)
select
    f.role_key,
    count(distinct f.snid)                              as confirmed_people,
    count(distinct if(p.via_second > 0 and p.via_primary = 0, f.snid, null))
                                                        as only_via_second,
    count(distinct if(p.via_second > 0 and p.via_primary > 0, f.snid, null))
                                                        as both_routes,
    round(100 * safe_divide(
        count(distinct if(p.via_second > 0 and p.via_primary = 0, f.snid, null)),
        count(distinct f.snid)), 1)                     as pct_only_via_second
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles` f
join per_person p
     on p.snid = f.snid
    and p.role_key = f.role_key
where f.role_label = 'CONFIRMED'
group by f.role_key
order by only_via_second desc
;
