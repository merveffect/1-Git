/*
    ============================================================================
    40. WHAT THE 1.17 STUDENT PATTERN WILL DO, WRITTEN BEFORE THE BUILD
    ============================================================================
    Merve closed 1.17 on 2026-11-10 with the loose reading:

        "gevsek okuma olsun research gecenleri elemeyelim illa researcher
         kelimesi harfi harfiyen olmasi gerekmiyor"

    One row was added to seeds/title_group_patterns.csv. It moves a title
    from researcher_early to student when the title names a student and the
    veto does not fire.

    THE FORECAST. From analyses/35 query 1, measured on 2026-11-10 with a
    regex close to but not identical to the one actually written:

        records moved          about 55,646 plus a little
        titles moved           about 993 plus a little

    "plus a little" because the two research groups were MERGED into one on
    the same day, so this row's scope widened from the early half to the
    whole of researcher. The 3,202 records in the old established half are
    now in scope. 23 of its 25 largest titles are already vetoed as
    credentials - phd scientist, group leader phd - and `specialist` and
    `staff` were added to the veto for the one that was not. `senior
    doctoral scholar` is the remaining one and it SHOULD move, because it
    is a doctoral student.

    Queries 1 and 2 use the EXACT regexes from the seed, so their answer is
    the real forecast and the number above is only where it came from. Run
    them BEFORE the build. If query 1 is far from 55,646 the regex does not
    say what it was measured to say, and the seed is wrong.

    EVERY QUERY HERE MATCHES ALL THREE GROUP NAMES - `researcher` and the
    two halves it was made from. The merge is in the seeds and not yet in
    the data, so a forecast written against the post-merge name alone
    matches nothing and returns a confident row of zeros, which is what the
    first version of this file did. Matching all three makes the file run
    correctly on either side of the build, which is what a forecast has to
    do: it is written before and checked after.

    THE TWO WAYS THIS CAN BE WRONG, both checked here:

      too wide   it takes a senior person whose title carries phd as a
                 CREDENTIAL - phd scientist, group leader phd, senior
                 consultant/md phd. This risk GREW when the groups merged,
                 because every one of those titles was out of scope before
                 and is in scope now, protected by the veto alone rather
                 than by the group boundary. Query 3 lists what moves,
                 longest titles first, because a long title is where a
                 credential hides behind other words.
      too narrow the veto fires on a real student - query 4 lists what the
                 veto spared, which should be research students and
                 postdocs and nothing else.
    ============================================================================
*/


-- ----------------------------------------------------------------------------
-- 0. WHAT ARE THE GROUP NAMES, ACTUALLY. Run this first.
--
--    Query 1 returned a confident row of zeros twice. The second time it
--    was matching all three spellings of the group name, so the name is
--    not the problem and guessing a third time is not a method.
--
--    This prints both columns side by side. title_group is the resolved
--    answer, after overrides and patterns. model_title_group is the
--    model's own choice before either, and it is the one the forecast
--    filters on, because a pattern is conditioned on what the model
--    thought.
--
--    Three things it can show, and each means something different:
--      - model_title_group is NULL or empty on most rows
--            the column exists but is not populated in the built table,
--            so the forecast must filter on title_group instead
--      - the names are spelled differently from the seed
--            read them off this output and stop guessing
--      - researcher_early is simply absent
--            the merge is already built, and the forecast is a check
--            rather than a forecast
-- ----------------------------------------------------------------------------
select
    coalesce(title_group, '(null)')         as title_group,
    coalesce(model_title_group, '(null)')   as model_title_group,
    count(*)                                as titles,
    sum(frequency)                          as records
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
group by title_group, model_title_group
order by records desc
limit 60
;


-- ----------------------------------------------------------------------------
-- 1. THE FORECAST. One row.
--
--    titles_moved and records_moved are the change. researcher_early keeps
--    everything else.
--
--    not_accepted_moved is the quiet one. The pattern layer deliberately
--    does NOT require the model to have accepted its own guess, so this
--    row can also claim titles that were sitting unassigned. Those are a
--    gain, not a loss - they reach `student` instead of nothing - but they
--    are counted separately so they cannot be mistaken for a loss.
-- ----------------------------------------------------------------------------
with t as (
    select
        title,
        model_title_group,
        model_is_assigned,
        frequency,
        regexp_contains(title, r'\b(student|students|studente|studenti|estudiante|estudiantes|etudiant|etudiante|ogrenci|doctoral|doctorate|doctorand\w*|doktorand\w*|doutorando|doutoranda|candidate|candidato|candidata|phd|ph d|dphil|predoc\w*|pre doctoral|pre-doctoral|graduand\w*|postgraduate|post graduate)\b') as names_a_student,
        regexp_contains(title, r'research|investigador\w*|investigadora|investigator|chercheur\w*|forscher\w*|arastirmaci|ricercator\w*|scientist|scientific|post[\s-]*doc|postdoc|pos[\s-]*doc|p[oó]s[\s-]*dout|post[\s-]*ph[\s.]*d|post[\s-]*doctorate|\b(professor|lecturer|reader|director|head|leader|consultant|adviser|advisor|principal|chief|dean|supervisor|coordinator)\b') as veto_fires
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
    where model_title_group in ('researcher', 'researcher_early', 'researcher_established')
),
moved as (
    select * from t where names_a_student and not veto_fires
)
select
    (select count(*)        from moved)                             as titles_moved,
    (select count(*)        from moved) - 993                       as titles_vs_forecast,
    (select sum(frequency)  from moved)                             as records_moved,
    (select sum(frequency)  from moved) - 55646                     as records_vs_forecast,
    (select count(*)        from moved where not model_is_assigned) as titles_not_accepted_moved,
    (select sum(frequency)  from t where names_a_student and veto_fires) as records_the_veto_spared,
    (select sum(frequency)  from t)                                 as researcher_records_total
;


-- ----------------------------------------------------------------------------
-- 2. WHAT IT COSTS THE AUDIENCES, as an UPPER BOUND.
--
--    Why an upper bound and not a number. fct_researcher_roles keeps ONE
--    record per person per role, the most recent one. A person whose most
--    recent record says `phd fellow` may hold an older record saying
--    `research associate`, and that person keeps their place in Researcher
--    after the build. This query cannot see the older record, so it counts
--    everyone whose CURRENT evidence title moves, which is the most that
--    can leave.
--
--    The build will come in under this. If it comes in ABOVE it, something
--    other than this pattern moved.
-- ----------------------------------------------------------------------------
with moving_titles as (
    select title
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
    where model_title_group in ('researcher', 'researcher_early', 'researcher_established')
      and regexp_contains(title, r'\b(student|students|studente|studenti|estudiante|estudiantes|etudiant|etudiante|ogrenci|doctoral|doctorate|doctorand\w*|doktorand\w*|doutorando|doutoranda|candidate|candidato|candidata|phd|ph d|dphil|predoc\w*|pre doctoral|pre-doctoral|graduand\w*|postgraduate|post graduate)\b')
      and not regexp_contains(title, r'research|investigador\w*|investigadora|investigator|chercheur\w*|forscher\w*|arastirmaci|ricercator\w*|scientist|scientific|post[\s-]*doc|postdoc|pos[\s-]*doc|p[oó]s[\s-]*dout|post[\s-]*ph[\s.]*d|post[\s-]*doctorate|\b(professor|lecturer|reader|director|head|leader|consultant|adviser|advisor|principal|chief|dean|supervisor|coordinator)\b')
)
select
    r.role_key,
    count(distinct r.snid)                                   as confirmed_now,
    count(distinct if(lower(r.evidence_title) in
          (select title from moving_titles), r.snid, null))  as most_that_can_leave
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles` r
where r.role_label = 'CONFIRMED'
group by r.role_key
order by most_that_can_leave desc
;


-- ----------------------------------------------------------------------------
-- 3. IS IT TOO WIDE. The titles that move, LONGEST FIRST.
--
--    Sorted by length on purpose rather than by frequency. A credential
--    hiding behind other words is what this row is most likely to get
--    wrong, and a long title is where that happens - `profesor
--    universitario beca de formacion predoctoral` is the shape to look for.
--    Frequency sorting would show `phd fellow` twenty times and hide it.
-- ----------------------------------------------------------------------------
select
    title,
    frequency,
    length(title) as len
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
where model_title_group in ('researcher', 'researcher_early', 'researcher_established')
  and regexp_contains(title, r'\b(student|students|studente|studenti|estudiante|estudiantes|etudiant|etudiante|ogrenci|doctoral|doctorate|doctorand\w*|doktorand\w*|doutorando|doutoranda|candidate|candidato|candidata|phd|ph d|dphil|predoc\w*|pre doctoral|pre-doctoral|graduand\w*|postgraduate|post graduate)\b')
  and not regexp_contains(title, r'research|investigador\w*|investigadora|investigator|chercheur\w*|forscher\w*|arastirmaci|ricercator\w*|scientist|scientific|post[\s-]*doc|postdoc|pos[\s-]*doc|p[oó]s[\s-]*dout|post[\s-]*ph[\s.]*d|post[\s-]*doctorate|\b(professor|lecturer|reader|director|head|leader|consultant|adviser|advisor|principal|chief|dean|supervisor|coordinator)\b')
order by len desc, frequency desc
limit 120
;


-- ----------------------------------------------------------------------------
-- 4. IS IT TOO NARROW. What the veto spared, biggest first.
--
--    Every row here should be a research student or a postdoc. Anything
--    else is the veto firing on a word it should not own - the seniority
--    words are the risk, because `phd student supervisor` is a student in
--    name and not in fact, while `student coordinator` is neither.
-- ----------------------------------------------------------------------------
select
    title,
    frequency,
    case
        when regexp_contains(title, r'(post[\s-]*doc|postdoc|pos[\s-]*doc|p[oó]s[\s-]*dout|post[\s-]*ph[\s.]*d|post[\s-]*doctorate)')
            then 'postdoc'
        when regexp_contains(title, r'research|investigador|investigator|chercheur|forscher|arastirmaci|ricercator|scientist|scientific')
            then 'says research'
        else 'spared by a SENIORITY word only - check these'
    end as why_spared
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
where model_title_group in ('researcher', 'researcher_early', 'researcher_established')
  and regexp_contains(title, r'\b(student|students|studente|studenti|estudiante|estudiantes|etudiant|etudiante|ogrenci|doctoral|doctorate|doctorand\w*|doktorand\w*|doutorando|doutoranda|candidate|candidato|candidata|phd|ph d|dphil|predoc\w*|pre doctoral|pre-doctoral|graduand\w*|postgraduate|post graduate)\b')
  and regexp_contains(title, r'research|investigador\w*|investigadora|investigator|chercheur\w*|forscher\w*|arastirmaci|ricercator\w*|scientist|scientific|post[\s-]*doc|postdoc|pos[\s-]*doc|p[oó]s[\s-]*dout|post[\s-]*ph[\s.]*d|post[\s-]*doctorate|\b(professor|lecturer|reader|director|head|leader|consultant|adviser|advisor|principal|chief|dean|supervisor|coordinator)\b')
order by
    case when regexp_contains(title, r'(post[\s-]*doc|postdoc|pos[\s-]*doc|p[oó]s[\s-]*dout|post[\s-]*ph[\s.]*d|post[\s-]*doctorate)') then 2
         when regexp_contains(title, r'research|investigador|investigator|chercheur|forscher|arastirmaci|ricercator|scientist|scientific') then 1
         else 0 end,
    frequency desc
limit 80
;
