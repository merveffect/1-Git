/*
    ============================================================================
    25. QUERIES TO RUN IN THE MEETING
    ============================================================================
    Written 2026-10-22 for the marketing session. These are NOT review queries.
    Every one of them is picked to be fast, to return something that fits on a
    screen, and to answer a question somebody in the room will actually ask.

    Dataset prefix throughout:
        dat-analytics-eng-ec869189.dev_orcid_role_identifier_

    THE THREE TO SHOW IF THERE IS ONLY TIME FOR THREE:
        Q1   the headline - what you can pull today
        Q3   why is THIS person in THIS audience - the answer to "can we trust it"
        Q6   what switching on PROBABLE would add - the decision we need

    Q7 and Q8 size the other two decisions. Run them before the meeting and
    bring the numbers rather than the queries: they scan more than the rest.

    NOTE ON LABELS. fct_role_audience and its summary carry BOTH labels, so
    every query below that counts people filters role_label explicitly. Leaving
    the filter off silently doubles the audience.
*/


/* ===========================================================================
   Q1  THE HEADLINE - what you can pull today
   ---------------------------------------------------------------------------
   One row per audience. `identified` is who we found; `reachable` is who you
   can contact. For planning a campaign only the second column matters.
   Say out loud: do not add the column, people hold 1.59 roles on average.
   =========================================================================== */
select
    role_key,
    identified,
    in_cdp,
    reachable,
    round(cdp_coverage,  3) as cdp_coverage,
    round(reachable_rate, 3) as reachable_rate,
    avg_score
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_presentation.fct_role_audience_summary`
where role_label = 'CONFIRMED'
order by identified desc;


/* ===========================================================================
   Q2  WHY YOU CANNOT ADD THE COLUMN
   ---------------------------------------------------------------------------
   The distribution of roles per person, and the sum against the true total.
   This is the single most common misreading of Q1.
   =========================================================================== */
with per_person as (
    select snid, count(distinct role_key) as roles_held
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_presentation.fct_role_audience`
    where role_label = 'CONFIRMED'
    group by snid
)
select
    roles_held,
    count(*)                                                  as people,
    round(count(*) / sum(count(*)) over (), 3)                as share,
    sum(count(*)) over ()                                     as people_total,
    sum(roles_held * count(*)) over ()                        as sum_of_the_column
from per_person
group by roles_held
order by roles_held;


/* ===========================================================================
   Q3  WHY IS THIS PERSON IN THIS AUDIENCE?   *** the trust demo ***
   ---------------------------------------------------------------------------
   There is no accuracy percentage and there never will be one, so this is what
   we offer instead: for any person, the complete reasoning. The three
   sub-scores are the arithmetic; the three evidence columns are the raw text
   the researcher typed.

   Paste a SNID. The second query underneath picks one example per audience, so
   it is safe to run cold if nobody hands you an ID.
   =========================================================================== */
select
    role_key,
    role_label,
    role_score,
    org_score,
    dept_score,
    role_final_score,
    title_group,
    discipline,
    evidence_title,
    evidence_org,
    evidence_dept,
    country_code,
    is_current
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles`
where snid = 0            -- <<< paste a SNID here
order by role_final_score desc;

-- same thing, but it picks its own examples: one per audience, taken from the
-- middle of the score range so the evidence is interesting rather than exact.
select
    role_key,
    role_final_score,
    title_group,
    discipline,
    evidence_title,
    evidence_org,
    evidence_dept,
    country_code
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles`
where role_label = 'CONFIRMED'
qualify row_number() over (
            partition by role_key
            order by abs(role_final_score - 0.85), snid) = 1
order by role_key;


/* ===========================================================================
   Q4  IT IS NOT AN ENGLISH KEYWORD LIST
   ---------------------------------------------------------------------------
   The old system matched English words, so it could not see any of these. The
   regex finds every high-frequency title containing a non-ASCII character, so
   this is a discovery rather than a cherry-picked list - run it live.
   Read the nearest_anchor column: an English anchor is carrying a title in
   another language, which is the whole point.
   =========================================================================== */
select
    title,
    frequency,
    title_group,
    round(similarity, 3)      as similarity,
    matched_anchors[offset(0)] as nearest_anchor,
    decision_source
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
where is_assigned
  and frequency >= 500
  and regexp_contains(title, r'[^\x00-\x7F]')
order by frequency desc
limit 25;


/* ===========================================================================
   Q5  WHO DECIDED - the machine, a person, or the word itself
   ---------------------------------------------------------------------------
   The honest answer to "is this just AI guessing". Three sources, in
   precedence order. HUMAN covers 348 hand-written decisions; note that a human
   REJECT also shows as HUMAN - the column records WHO decided, not what.
   REJECTED means the model found nothing above the 0.65 floor and left the
   title unassigned, which is a real outcome rather than a failure.
   =========================================================================== */
select
    decision_source,
    count(*)                                                   as distinct_titles,
    sum(frequency)                                             as records,
    round(sum(frequency) / sum(sum(frequency)) over (), 4)     as share_of_records
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
group by decision_source
order by records desc;


/* ===========================================================================
   Q6  DECISION 1 - what would switching on PROBABLE add?   *** needed today ***
   ---------------------------------------------------------------------------
   Today only CONFIRMED ships. The answer is different for every audience,
   which is why this is a per-audience decision and not one switch.
   =========================================================================== */
select
    role_key,
    sum(if(role_label = 'CONFIRMED', identified, 0))  as confirmed,
    sum(if(role_label = 'PROBABLE',  identified, 0))  as probable,
    sum(if(role_label = 'CONFIRMED', reachable,  0))  as confirmed_reachable,
    sum(if(role_label = 'PROBABLE',  reachable,  0))  as probable_reachable
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_presentation.fct_role_audience_summary`
group by role_key
order by confirmed desc;

-- AND THE REASSURANCE, because it sounds riskier than it is: switching PROBABLE
-- on mostly adds a SECOND LABEL to people we already hold, rather than bringing
-- in strangers. This counts how many of the PROBABLE healthcare people are
-- already confirmed in some other audience.
with prob as (
    select distinct snid
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_presentation.fct_role_audience`
    where role_key = 'hcp_broad' and role_label = 'PROBABLE'
),
conf as (
    select distinct snid
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_presentation.fct_role_audience`
    where role_label = 'CONFIRMED'
)
select
    count(*)                        as probable_people,
    countif(c.snid is not null)     as already_in_another_audience,
    countif(c.snid is null)         as genuinely_new
from prob p
left join conf c using (snid);


/* ===========================================================================
   Q7  DECISION 2 - are biomedical researchers healthcare professionals?
   ---------------------------------------------------------------------------
   They research disease, drugs and human biology but do not treat patients.
   Today they are NOT in Healthcare - hcp_researcher requires a health_clinical
   department and these sit in life_biomedical. They are not lost: they are
   already in the Researcher audience. This counts what the word change moves.
   =========================================================================== */
select
    discipline,
    count(distinct snid) as people
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles`
where role_key   = 'researcher'
  and role_label = 'CONFIRMED'
  and discipline in ('life_biomedical', 'health_clinical', 'pharmacy')
group by discipline
order by people desc;


/* ===========================================================================
   Q8  DECISION 3 - is a "Director" at a university a head of faculty?
   ---------------------------------------------------------------------------
   Some are deans. Some run administration, a building, or an IT department.
   The data says only "Director" and the organisation is a university. We
   cannot tell them apart, so this is a definition question, not a scoring bug.
   =========================================================================== */
select
    role_label,
    count(distinct snid)                as people,
    round(avg(role_final_score), 3)     as avg_score
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles`
where role_key = 'faculty_head'
  and lower(trim(evidence_title)) = 'director'
group by role_label
order by people desc;


/* ===========================================================================
   Q9  WHERE THE NEXT HOUR OF WORK SHOULD GO
   ---------------------------------------------------------------------------
   The review queue, ordered by how many records each title decides. The
   distributions are so skewed that reading the top few hundred values settles
   millions of records - that is the whole reason a human review is affordable.
   A small margin means the model nearly chose the runner_up instead.
   =========================================================================== */
select
    value        as title,
    assigned_group,
    runner_up,
    frequency,
    similarity,
    margin
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_presentation.rpt_title_review_queue`
where axis = 'title'
order by frequency desc
limit 20;
