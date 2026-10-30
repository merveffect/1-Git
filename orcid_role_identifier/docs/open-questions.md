# Open questions, limitations and known errors

**A register, not the document.** It is the raw material for the stakeholder
presentation, kept here so nothing is lost between builds and so every claim
in the eventual document has a number and a source behind it. Appended to as
work continues. Figures are from the build of **2026-10-20** unless stated;
anything marked ⟳ moves with the next build and must be re-read before it is
quoted.

Sources are named for every number. Where a figure has no source it is not
yet measured and says so.

## The four figures at the top

| | |
| --- | --- |
| **673,553** | people with a confirmed professional role |
| **501,522** | of them reachable - in the CDP and opted in (74.5%) |
| **9** | audiences, up from one |
| **1.6** | roles per person |

*Source: analyses/15 query 8, build 2026-10-20.* They cannot be added across
audiences: a professor who publishes is both a Lecturer and a Researcher, so
the per-role Reachable column sums far above 501,522.

---

## Part 1 — Questions only marketing can answer

Each one is a definition, not a technical problem. None can be settled from
the data, and each changes who receives a campaign.

### 1.1 Should the second confidence tier be switched on? ⟳

Only `CONFIRMED` is delivered today (`vars.contract.include_labels`). A
`PROBABLE` tier exists for people where the evidence points one way without
being confirmed from both axes. It is not evenly useful.

| Audience | Confirmed today | Adding Probable | Change |
| --- | --- | --- | --- |
| Healthcare professional (broad) | 126,270 | 236,418 | **+87%** |
| Pharmacist | 2,335 | 4,889 | **+109%** |
| Head of faculty | 20,222 | 30,678 | **+52%** |
| Clinical administrator | 6,855 | 8,781 | +28% |
| Practitioner | 60,083 | 63,113 | +5% |
| Clinical researcher | 50,590 | 52,767 | +4% |
| Researcher | 322,266 | 323,062 | +0.2% |
| Lecturer | 400,445 | 400,763 | +0.1% |
| Librarian | 666 | 666 | none possible |
| **Unique people** | **673,553** | **718,607** | **+6.7%** |

It mostly adds a second LABEL to people we already hold rather than new
people - the unique total rises only 6.7% while healthcare nearly doubles -
so switching it on is less about reach than about how finely an existing
audience can be segmented.

*Source: analyses/15 query 1.* Librarian has no Probable tier at all — it is
decided by pattern, so its score is always exactly 1.000.

**A precondition we did not know before 2026-10-20.** For the healthcare
roles, a country rule has to land first. `consultant` is a hospital
specialist grade in the UK, Ireland and much of the Commonwealth and an
adviser everywhere else, and the share of its records carrying a clinical
department splits cleanly by country: 0.88 Qatar, 0.83 Singapore and Hong
Kong, 0.68 Britain, against 0.20 United States, 0.08 Brazil, 0.03 Peru.
About **1,613 people** in low-share countries are held in Probable on a
consultant-family title alone, and the department axis is the only thing
holding them there. *Source: analyses/22 query 7.*

### 1.2 Are biomedical researchers healthcare professionals?

**15,588 people.** They research disease, drugs and human biology but do not
treat patients. They are already in the Researcher audience. We kept
healthcare clinical; one word of configuration reverses it.

### 1.3 Which leadership titles count as a head of faculty?

Asked originally as "is a Director at a university a head of faculty?", worth
**~2,900 people**. Reading the leadership group on 2026-10-21 showed the
question is much larger than that, and that it splits cleanly in two.

**Titles that are never academic — 53,599 records.**

| Title | Records | | Title | Records |
| --- | --- | --- | --- | --- |
| `ceo` | 15,918 | | `founder & ceo` | 1,882 |
| `founder` | 6,952 | | `founder and ceo` | 1,443 |
| `managing director` | 5,568 | | `managing partner` | 1,305 |
| `general manager` | 3,513 | | `founder and director` | 864 |
| `owner` | 3,395 | | `gerente` | 751 |
| `chief executive officer` | 2,912 | | `branch manager` | 671 |
| `executive` | 2,003 | | `founder & director` | 678 |

**Titles that could be either — 172,611 records.**

| Title | Records | Why it is ambiguous |
| --- | --- | --- |
| `director` | **144,252** | the original question, and the single biggest title in the group |
| `president` | 11,625 | a university president IS its most senior leader |
| `vice president` | 6,324 | Vice President for Research is an academic post |
| `principal` | 5,482 | the principal of a college, or a principal investigator |
| `board member` | 1,706 | governance rather than management |

*Source: analyses/23 queries 3 and 3a.*

**What already happens, so the decision is narrower than the numbers look.**
The organisation axis is doing most of this work: faculty_head scores a
company at 0.00, so a corporate title at a company cannot confirm.
analyses/17 measured `ceo` at 879 people with only **55 confirmed**, `founder`
411 with 31, `owner` 188 with 2.

So the real question is not "should a CEO be a head of faculty" - almost none
are. It is whether those 55, and the equivalent residue on every other title,
should be excluded outright by name. Our view is that the never-academic list
should be, and that the ambiguous list must stay, because excluding
`president` would lose real university presidents. But the call belongs to
marketing.

Two measured notes for that conversation. `editor-in-chief`, 5,172 records
with the hyphenated and unhyphenated spellings together, was in this group
until 2026-10-21 - an editorial role reading as institutional leadership,
which for a publisher is a distinction worth getting right. And `jefe de
servicio`, 2,090 records, is a Spanish clinical head of service: correctly in
leadership, and it reaches hcp_administrator through the department axis
rather than faculty_head.

**A third part of this question, measured 2026-10-29.** About 2,000 people reach
faculty_head through an organisation that reads as a hospital rather than a
university. Some of that is right - medical school departments are frequently
based in teaching hospitals - and some is not. `medical director` (95 people)
is clearly not a faculty head and is recorded as an accepted residue in 2.8a.
But `head of department` (294), `chief` (213) and `head` (225) on the hospital
path are genuinely ambiguous, and the same decision covers all of them.

### 1.4 Are psychologists healthcare professionals?

**~4,500 records across six titles**, currently all matched to the
`psychiatrist` anchor and therefore in the clinical practitioner group.

| Title | Records | Note |
| --- | --- | --- |
| `psicóloga` | 1,426 | bare "psychologist", could be academic |
| `psicólogo` | 1,232 | same |
| `psicóloga clínica` | 751 | explicitly clinical |
| `forensic psychologist` | 390 | clinical, in a legal setting |
| `consultant clinical psychologist` | 381 | clinical |
| `educational psychologist` | 367 | works in schools |

*Source: analyses/22 query 2.* A psychologist is not a psychiatrist - no
medical degree - but a clinical psychologist is a regulated healthcare
professional in most countries. An educational psychologist arguably is not.

**There is a third answer, and it may be the right one.** Merve raised it on
2026-10-20: these titles do not have to be labelled at all. The mechanism
already exists - a REJECT override leaves a title unassigned, which is what
already happens to any title the model cannot place above 0.65 similarity.

The argument for using it here is the one Merve made about `consultant`:
these people receive email. `psicóloga clínica` in a psychiatry department is
CONFIRMED today and would receive a clinical campaign. If marketing does not
count psychologists as healthcare professionals, a wrong inclusion costs more
than a temporary exclusion, and either direction is one row to reverse.

The argument against: a rejection removes them from everything, including a
psychologist audience we might open later.

So this is really two questions - are they healthcare professionals, and if
the answer is not yet known, should they be held unlabelled until it is.

### 1.5 Three smaller versions of the same question

| Question | Records | Currently |
| --- | --- | --- |
| Are mental health support workers healthcare professionals? | 326 | yes, in practitioner |
| Are medical physicists / clinical scientists? | 346 | yes, in practitioner |
| Are genetic counsellors? | 866 | yes, in practitioner |
| Are counsellors? (`counselor` 882 + `counsellor` 323) | 1,205 | yes, in practitioner |

All three are regulated health roles in some countries and support roles in
others.

### 1.6 Should a past role still count?

Seven of the nine roles count past employment: someone who was a researcher
in 2010 and works in a bank today is still in the Researcher audience, on the
reasoning that "researcher" is a profession you have rather than a post you
hold. `faculty_head` and `librarian` are the exceptions and count current
posts only — a former dean is not a dean.

If marketing wants the others to behave the same way, it is one line per role.
**The size of that change is not measured** and should be before it is made.

### 1.7 Which audiences should exist that do not? — DEPRIORITISED

**Not now.** Merve, 2026-10-21: *"şuanda hedeflediğimiz meslekleri
onaylayabilsek yeter. başka gruba gerek yok"* - getting the nine audiences we
already target approved and correct is the job, and no new group is wanted.

Kept here because the measurement stands and the opportunity does not go
away, but it is off the agenda and should not be raised again until marketing
asks. The practical consequence is that `support_technical` and `student` are
**out of scope**: neither feeds a role, so `support_technical` being the
dirtiest group in the project at 36.19% is now irrelevant rather than
alarming, and it is also where we park titles that belong nowhere.

The original measurement follows.

Coverage, not consent, is now the ceiling — see 2.2. Two groups are
classified and feed nothing:

| Group | Records | |
| --- | --- | --- |
| `student` | 1,914,587 | doctoral and medical students, the largest expansion available |
| `support_technical` | 1,416,277 | technicians, administrators, research support |

*Source: analyses/19 query 3.* The structure already supports both; this is a
decision, not a build.

### 1.8 Two deliberate exclusions from Librarian, either reversible in one row

**Archivists are not included.** `archivist` as an anchor pulled
`archaeologist`, `glaciologist` and `clerk`, and archivists are a separate
call from the one marketing made. **"Information specialist" is not
included** — it pulled every IT title in the corpus. Either can be added as
one pattern row or one override, as a decision rather than a guess.

### 1.9 Is an uninformative title acceptable evidence?

`dr` carries **96,676 records** and `md` **50,189** — together 9.1% of the
practitioner group. Neither says anything about a profession beyond holding a
doctorate, and both are resolved entirely by the department axis. A clinical
department confirms them; otherwise they stay Probable. The question is
whether that is acceptable or whether a title carrying no occupational
information should be excluded outright. *Source: analyses/22 query 2.*

### 1.10 Should a job title be allowed in more than one group?

This is new on 2026-10-20 and it is the largest thing the review has turned
up that is not a defect.

A title belongs to exactly one title group today. Measured: **463,603
records contain the word "professor" and sit OUTSIDE teaching_academic** -
and almost all of them belong where they are.

| Title | Records | Group | Match |
| --- | --- | --- | --- |
| `research assistant professor` | 71,785 | researcher_early | 0.911 |
| `research professor` | 48,609 | researcher_established | 0.886 |
| `research associate professor` | 12,374 | researcher_established | 0.917 |
| `professor and director` | 4,601 | leadership | 0.835 |
| `professor of neurology` | 1,815 | practitioner | 0.860 |

*Source: analyses/22 queries 11 and 11a.* These are not errors. A research
assistant professor really is a research post; a professor of neurology
really is a neurologist. The matches sit at 0.80-0.92, so the model is
confident and correct.

But a research assistant professor also **teaches**, and the Lecturer
audience - 400,445 people - does not contain them. So Lecturer undercounts
professors by some part of those 463,603 records, and the only way to fix it
is to let one title carry two groups, which is a design change rather than a
tuning one.

Worth recording how this was found: I expected the opposite. I thought
"professor of X" titles outside teaching_academic were a defect and was
about to write a rule moving them. The measurement killed it - that rule
would have pulled 71,785 research professors out of the Researcher audience.

### 1.10a A title stays in ONE profession — DECIDED, 2026-10-30

Merve, after seeing the measured size of it: a person who writes both jobs into
one title stays where they are. No change, and 1.10 does not need opening.

| What they wrote | Records | Decision |
| --- | --- | --- |
| teaching AND research — `lecturer and researcher`, `teaching and research`, `assistant professor research`, `personal docente e investigador`, `enseignant-chercheur` | **~47,000** | **Stay in Lecturer** |
| teaching AND leadership — `professor and chair`, `professor and head`, `professor & director`, `professor and dean` | **~31,000** | **Stay in Lecturer** |

That is 78,000 records that would otherwise have argued for letting one title
carry two professions. It closes the practical case for 1.10 without a model
change, and it is recorded here so the argument is not re-made.

**One thing it does NOT settle, found the same day.** The compound titles are
currently split between teaching_academic and leadership by **word order**,
which is indefensible either way:

    professor and director   4,601  leadership
    professor & director     2,185  teaching_academic
    professor director       2,140  teaching_academic
    director professor       1,110  leadership
    director/professor       2,033  leadership
    professor/director       1,256  teaching_academic

Same two words, different separator, different audience, margins of 0.004 to
0.016. About 68,000 records in total - 44,000 in teaching, 24,000 in
leadership. One rule has to apply to all of them, and the choice has a cost
either way: sending them all to teaching removes 24,000 records from
faculty_head, which is already the weakest audience we have; sending them all
to leadership removes 44,000 from lecturer, which is 0.4% of a group of twelve
million. Open.

### 1.11 Is "healthcare professional" about the work or the subject?

Several questions in 1.4 and 1.5 are really this one question asked about
different jobs. A psychologist, a medical physicist, a mental health support
worker, a genetic counsellor and a clinical embryologist all work in health
without practising medicine. One answer settles all of them and several that
have not come up yet.
### 1.12 Is a teaching assistant in the Lecturer audience? — DECIDED, YES

**Merve, 2026-10-21: if they teach, assign them to Lecturer, doctoral
student or not.** No change is made; this is recorded so the reasoning
exists and so the Thursday document can state it as a decision rather than
an open question.

**178,205 records** turn on it, found on the first read of teaching_academic.

| Title | Records | Similarity | Runner-up |
| --- | --- | --- | --- |
| `teaching assistant` | 134,143 | 0.827 | researcher_early |
| `graduate teaching assistant` | 32,994 | 0.809 | **student** |
| `assistant teacher` | 5,558 | 0.840 | support_technical |
| `teacher assistant` | 5,510 | 0.793 | support_technical |

They do teach, so the group is not obviously wrong. But most are doctoral
students who teach as part of their funding, and the model itself put
`student` as the runner-up for the clearest of them.

**Why this one cannot wait for a quiet moment.** `lecturer` is
title_required with no field requirement, so there is nothing to filter
them: every one of these reaches the audience as soon as the organisation
resolves. Where a wrong clinical title needs a clinical department to agree
with it, a wrong teaching title needs nothing.

And that is the answer: they teach, so they belong in the audience. A
teaching assistant is plausibly a *better* target than a professor for
textbook and course-material campaigns, which is the same conclusion from
the other direction.

### 1.13 Are visiting scholars and fellows teaching staff?

**81,749 records** sitting in teaching_academic on the word 'visiting':
`visiting scholar` 60,561, `visiting fellow` 15,832, `visiting research
scholar` 5,356.

A visiting scholar may teach, or may only do research. `visiting scientist`
at 32,662 records was clear enough to move to researcher_established without
asking - a scientist does not teach - but these three are genuinely
ambiguous and the word 'scholar' leans academic.

### 1.14 Is an honorary professor active?

**6,651 records.** We rejected `honorary researcher`, `emeritus professor`
and `retired professor` outright at marketing's request on 2026-10-16, on the
grounds that a retired professor is not a researcher. `honorary professor`
survived, and it is not obviously different - though an honorary professor is
often an active practitioner holding a university title rather than a retired
one, which is the opposite case.

An inconsistency either way, and small enough to settle in one sentence.

**New evidence, 2026-10-29.** The Market Intelligence role library puts
`Honorary Researcher` on the same line as `Emeritus Researcher` and
`Emeritus Scientist`, under "Former or inactive", describing all three as "a
retired researcher honoured for prior contributions". That supports rejecting
it — but the library is a curated vocabulary rather than a reading of ORCID,
and in ORCID "honorary" is frequently an unpaid university affiliation held by
somebody actively employed elsewhere. One word, two meanings. Worth putting
both readings in front of marketing rather than taking the library's.

### 1.15 A question we measured and are NOT asking

Is a school teacher in the Lecturer audience? `teacher` is one of our
fifteen anchors, so they do land here, and we flagged this as potentially
large before measuring it.

**It is 0.2% of the group.** All school-related titles together are 877
titles and 24,718 records out of 12,065,457, and most of those are academic
anyway - `medical school affiliates assistant professor` 639 records,
`professor and head of school` 287, `professor school of risk and disaster
management` 131, where 'school' means School of Engineering. Genuine
school-level teaching is roughly 5,000 records.

Recorded here rather than deleted, because the prediction was wrong in a
useful direction: we sized it before adding it to this list, and a decision
list that includes negligible items is worse than one that does not.

### 1.16 Researcher could be split into early-career and senior — RECORDED AS POSSIBLE, NOT PROPOSED

Merve asked on 2026-10-21 whether this is feasible, and decided the same day
not to pursue it now. It is written down so the option is known, not because
anyone is asking for it. Nothing has changed in the pipeline. We already classify every research title into
one of two groups, and both of them feed the same single `researcher`
audience - so the distinction is carried and never used. Splitting it into
two audiences is **a configuration change and nothing else**:

```yaml
researcher_early:   { title_groups: ['researcher_early'] }
researcher_senior:  { title_groups: ['researcher_established'] }
```

No code. This would be the live demonstration of "adding an audience is a
config change rather than a project".

**Can we tell them apart today? Partly, and only from words.** The split is
made entirely by job title. It works where the title states a rank -
`principal investigator` to senior, `postdoctoral fellow` to early - and it
fails where the title does not, which is a large share.

The clearest failure is structural: bare **`researcher`** is an early-career
anchor and bare **`scientist`** is a senior one. So a thirty-year veteran who
typed only "researcher" is classified early career, and someone who typed
only "scientist" is classified senior. From the person's side that is
arbitrary.

It shows in the sizes: `researcher_early` carries 8,341,542 records against
`researcher_established` at 1,878,051, a 4.4x gap driven largely by bare
`researcher` and the postdoc family sitting in early.

**And the track record is poor.** `junior researcher`, 42,949 records, sat in
the SENIOR group for the entire life of the project and was found on
2026-10-21. 125,112 records carry a senior modifier while sitting in early -
mostly correctly, since a senior postdoc is still a postdoc, but we only
established that the same day.

**The better route is dates, and the data is already in the pipeline.**
Merve's own suggestion. `employments[].full_start_date` and the end dates are
already read, for `is_current` and `recency_rank` - no new source field is
needed. Career length as "today minus earliest employment start" is a
seniority measure INDEPENDENT of what someone called their job, and it is
what the external role library's MORE4 R1-R4 career stages are built on,
anchored to PhD completion year.

So if it is ever wanted, the order would be measure first and split second:
find out whether dates can carry seniority before shipping an audience that
rests on job-title words. Shipping the word-based split as it stands would
repeat the mistake we found on 2026-10-21 rather than fix it.

### 1.17 Are doctoral students doing research in the Researcher audience?

**197,895 records**, found 2026-10-21 on the first read of researcher_early.

| Title | Records | Model's runner-up |
| --- | --- | --- |
| `graduate research assistant` | 106,438 | **student** |
| `phd researcher` | 49,317 | **student** |
| `phd fellow` | 19,424 | **student** |
| `predoctoral researcher` | 15,368 | researcher_established |
| `undergraduate research assistant` | 7,348 | support_technical |

All sit in researcher_early today, and the model itself offered `student` as
the runner-up for the three largest.

**Merve's own precedent answers it.** On 1.12 the decision was: if a teaching
assistant teaches, they go in the Lecturer audience, doctoral student or not.
The parallel reads straight across - if they research, they go in the
Researcher audience, doctoral student or not - and that is what currently
happens, so no change is needed.

Recorded as a question only to confirm the precedent extends, and because the
alternative is not unreasonable: an undergraduate research assistant on a
summer placement is a weaker target than a postdoc.

A mechanism note worth keeping, separate from the decision.
`predoctoral researcher` reached the **POST**doctoral anchor at 0.908. Pre
and post are two ends of one axis, so the embedding places them close - the
same blind spot as `junior` against `senior` in 2.4e. Here it happens to
produce the right answer, which is why it is evidence rather than a defect.


---

## Part 2 — Limitations to state plainly

### 2.1 There is no accuracy percentage and there will not be one

ORCID has no profession field. The job title is free text the researcher
typed, so there is no correct answer anywhere to compare against. The
predecessor pipeline is not a reference either: of the people it called
healthcare professionals and we do not, roughly **53,000 work in engineering,
earth science, mathematics or humanities departments**.

What exists instead, for every classification: how far it stretched from the
example terms that define each group, and whether a human or the model
decided. **158 human decisions are pinned** as of 2026-10-21, each carrying
the measured reason it was made.

### 2.2 Coverage is the ceiling, not consent

| | People | |
| --- | --- | --- |
| ORCID profiles with an SNID | 1,812,702 | 100% |
| …with a usable employment record | 849,370 | 46.9% |
| …we can name a profession | 673,553 | 37.2% |
| …also present in the CDP | 646,233 | 35.7% |
| …and opted in under any basis | 501,522 | 27.7% |

*Sources: analyses/13 query 1, analyses/15 query 8.* **1,139,149 people get
no audience at all**,
most of it the deliberate absence of a student or support-staff audience
(1.7). Opening a new audience is worth far more than opting more people in.

### 2.3 "Reachable" means opted in, not deliverable

Three consent bases are read and any one of them counts a person in:
marketing preference, advertising, and legitimate interest. The CDP holds no
bounce or suppression state at all, so there is nothing for us to factor in.
Treat the figure as the opted-in population rather than a delivery estimate.

Worth knowing: legitimate interest is author-based, and it tracks how much a
group publishes. For Librarian it reaches 40.4% of the audience against 71.9%
for Lecturer, which is why Librarian's reachable rate is 54% where every
other role is 70–78%. Any future non-academic audience should be expected to
behave the same way.

### 2.4 Healthcare is the weakest group, and we know why ⟳

`practitioner` carries **33.80%** of its 1,646,932 records below 0.75
similarity, down from **40.64%** at the start of 2026-10-20 - and the group
GREW by 186,928 records over the same day, so it became cleaner and wider at
once.

Only one group is now worse: `support_technical` at 36.64%, which feeds no
audience and is where rejected titles are parked, so it gets dirtier by
design. `teaching_academic` is 6.74%, the lowest share of any group - but
read 2.4b before comparing those two numbers to each other.

The 6.37 points came from two things measured that day: 31 specialty anchors
for professions that had none of their own - 2,684 veterinarians were
matching DENTIST - and 40 human overrides for titles that were never
clinical. Every override landed to the record: researcher_established
+13,743, support_technical +5,445, teaching_academic +5,145, each one exactly
the predicted figure.

Clinical job titles are the least standardised vocabulary in the data:
Resident, Registrar, Facharzt, Interno, Jefe de Servicio and Senior House
Officer describe overlapping things and share no common stem, so only a
meaning-based match can connect them. *Source: analyses/19 query 3.*

### 2.4a "Reviewed" means read in part, and coverage is not confidence

**Coverage is not confidence, and the distinction matters more than the
number.** "62% coverage" means a list of titles carrying 62% of the group's
records was READ - looked at, and not objected to. It does not mean 62% is
verified, because there is nothing to verify against (2.1). And the other
38% was not looked at in any form.

Coverage of the three groups read so far, as a share of all the group's
records rather than of one similarity band:

| Group | Read | Feeds |
| --- | --- | --- |
| `leadership` | ~62% | faculty_head, hcp_administrator |
| `researcher_established` | ~62% | researcher, hcp_researcher |
| `practitioner` | ~38% | hcp_broad and hcp_practitioner |

Note which one is lowest. practitioner is the least read of the three because
clinical vocabulary is the most scattered - 150 titles reached only 52% of
its high-similarity records against 71% for leadership.

A correction worth making here, since it was stated wrongly more than once:
`practitioner` and `trainee_clinical` each feed TWO roles, not four.
hcp_broad and hcp_practitioner draw on both of those groups; hcp_researcher
draws on the two researcher groups and hcp_administrator on leadership. One
consequence is that moving a title between `practitioner` and
`trainee_clinical` changes no audience at all - which is why the UK trainee
grades were left alone - while a non-clinical title entering either of them
does reach the audience, because hcp_broad is title_or_field and can confirm
on a title alone at the edge.

### 2.4a (continued) What the gap contained, and why reading alone cannot close it

Added 2026-10-21 after Merve asked how we had established that
researcher_established was finished. We had not, and the claim was wrong.

What the review of that group actually read: about **150 titles of 27,963**,
carrying ~70,000 records against 304,478 below 0.75 similarity and 1,950,686
in the group. So roughly **23% of the low-confidence records and 3.6% of the
group**.

And every query was filtered `similarity < 0.75`, which means **1,646,208
records - 84% of the group - were never examined in any form**. That filter
looked reasonable until you remember where it came from: we found
`business consultant` at **0.843**, `independent consultant` at 0.867 and
`medical director` at 0.821, all wrong, and wrote at the time that "the wrong
ones score higher than the right ones". Then every query since excluded
exactly that range.

The same correction applies to practitioner, also called reviewed.

**WHAT THE GAP ACTUALLY CONTAINED, measured 2026-10-21.** The largest single
error in the project to date was sitting in it: `junior researcher`, **42,949
records**, classified as researcher_ESTABLISHED. With `junior group leader`
and `junior scientist` that is **52,279 records** in the group that means the
opposite. It reached the `senior researcher` anchor at 0.870 because
'researcher' dominates the phrase and the embedding places junior and senior
close together - two ends of one axis rather than opposites. No review query
could see it, because every one of them filtered `similarity < 0.75`.

**AND HAND-READING IS NOT A COMPLETE METHOD, which is a structural answer
rather than a defect.** Query 1 measured it for researcher_established:
reading the top 100 titles by frequency covers 23.65% of the records below
0.75. Reaching half needs 1,150 titles; reaching 80% needs 3,800. So a
top-60 list is a way of fixing the loudest quarter, and calling that a review
is the mistake - not the reading itself, which is still the only way to judge
a title.

What follows is that completeness has to come from computable tests, and
hand-reading is for the loud cases and for judging what a test flags.

analyses/24 closes the gap in two ways. It measures whether hand-reading is
even a viable method for a given group, by bucketing the problem by
frequency - if most of it sits in titles appearing twice, no top-60 list
will ever reach it. And it adds a test that needs no similarity threshold at
all: for each compound anchor, name the stem that makes it distinctive, and
flag any title that reached it WITHOUT containing that stem. Such a title
cannot have matched on meaning - it matched the word the anchor shares with
the labour market. That is the shape of every failure of this kind we have
found: `library manager` attracting `manager`, `senior scientist` attracting
`senior manager`, `medical officer` attracting `education officer`.

It does not catch `business consultant`, which contains the distinctive stem
and is simply the right word from the wrong domain. Nothing computable
catches that one.

And it over-flags, which is worth stating since the next person will run it.
Of the 80 titles it surfaced, most were CORRECT - `principal scientist` at
0.893, `biologist` at 0.825, `senior investigator` at 0.917, `physicist`,
`geologist`, `staff researcher`. The stems were written too narrowly: a
principal scientist really is a principal investigator. Read it as a
shortlist to judge, not a list of errors. It earned its place anyway, by
finding five real ones above 0.75 that nothing else could reach - `officer`
1,998 records, `staff member` 1,759, `leader` 1,707, `academic director`
1,382, `staff specialist` 1,644.

### 2.4b share_below_075 is partly a measure of title LENGTH

Found on 2026-10-21 while reading `head of laboratory`, which carries 5,203
distinct titles and 37.19% of its records below 0.75 - the worst anchor in
researcher_established. Almost everything arriving there is CORRECT: head of
phycology research group, head of national reference laboratory NRL for
bovine tuberculosis, head of textile metrology laboratory since 2014,
director of metal materials research institute.

They score low because they are LONG. The embedding averages over the whole
string, so a nine-word title can only ever sit so close to a two-word anchor.
`head of national reference laboratory nrl for bovine tuberculosis` reaches
0.711; `librarian` reaches 1.000 because it is one word that matches one word.

So a group that attracts long, specific, one-off titles will always look
dirtier than a group whose vocabulary is short, whatever its accuracy. That
is a reason to read the metric alongside the titles rather than on its own,
and it is the second time the same caution has come up - `dr` and `md` carry
146,865 records of honest low confidence in the clinical group, and the
sciences carry about 14,000 more in researcher_established, all correct, all
leaning on the single word `scientist`.

It also means the number is NOT comparable between groups. teaching_academic
at 6.74% and researcher_established at 15.95% are not 2.4x apart in quality;
part of that gap is that one group's vocabulary is `professor` and the
other's is `head of national reference laboratory for bovine tuberculosis`.

### 2.4c share_below_075 is not a quality metric, and here is the proof

On 2026-10-21 we removed 70,977 wrong records from researcher_established -
`junior researcher` and its family, sitting in the group that means the
opposite of what they say - and the metric got **worse**: 0.1561 -> 0.1620.

`records_below_075` was 304,478 before and 304,478 after, identical, because
everything removed had scored ABOVE 0.75. The denominator shrank, the
numerator did not, so the share rose.

The group became more correct and the number deteriorated. Read
share_below_075 as what it is - a measure of how much of a group the model
was unsure about - and never as a measure of how much of it is wrong. Those
are different quantities and this is the cleanest demonstration we have that
they can move in opposite directions.

### 2.4d Reading is viable where titles are common, and not where they are not

Measured both halves of researcher_established on 2026-10-21.

**Below 0.75**, the top 100 titles by frequency reach 23.65% of the records,
half needs 1,150 titles and 80% needs 3,800. Long, specific, one-off titles -
`head of national reference laboratory nrl for bovine tuberculosis` - and
there are thousands of them.

**Above 0.75**, 40 titles reach about 69% of the records. Short common
vocabulary - `senior researcher` alone is 152,430 records - so the
distribution is concentrated enough to read.

Which gives a method rather than a feeling. Read the high-similarity region
by hand, because it is concentrated and because that is where errors are
invisible to every other check. Use computable tests for the long tail, and
accept the remainder as unreviewed with a number attached rather than a
claim.

Coverage for researcher_established after both passes: roughly **62% of its
records have now been looked at**, against 3.6% when it was first called
finished.

### 2.4e A modifier that reverses a title barely moves it in the space

The structural blind spot behind the largest error we have found, and worth
stating on its own because it is not about any one group.

The embedding places `junior` and `senior` CLOSE together, because they are
two ends of one axis rather than opposites. So a word that reverses what a
title means barely moves it. `junior researcher` reached the
`senior researcher` anchor at 0.870 and sat in researcher_established -
42,949 records in the group that means the opposite.

analyses/24 query 5 looks for the whole class on purpose rather than by
accident. Measured 2026-10-21:

| Mismatch | Titles | Records |
| --- | --- | --- |
| senior-ish modifier in researcher_**early** | 2,311 | 125,112 |
| junior-ish modifier in researcher_**established** | 759 | 23,150 |
| junior-ish in leadership | 246 | 4,541 |
| senior-ish in student | 222 | 4,524 |

**And most of the largest row is CORRECT**, which is the part worth
remembering. `senior postdoc` at 0.951, `senior research associate` at
0.933, `senior research assistant` at 0.938 all sit in researcher_early and
belong there: 'senior' grades you WITHIN the postdoc rank, it does not lift
you out of it, and every career framework including the MORE4 R1-R4 stages
puts postdocs at early career. The exceptions are the genuinely senior
grades - `principal research fellow` 4,487 records, `distinguished
researcher` 1,274, `chief research fellow` 924 - perhaps 9,000 of the
125,112.

**It also caught me making the model's mistake.** On 2026-10-20 I moved
`junior group leader`, 5,943 records, out of researcher_established and into
researcher_early. That was wrong: a Nachwuchsgruppenleiter runs their own
group on their own funding and is an independent researcher. The evidence
was already in the data - `junior research group leader` and `head of junior
research group` were both left in established by the vector, and my own
override contradicted them. I read the word 'junior' and reacted, exactly as
the embedding had. The override is withdrawn.

So the lesson is not "distrust the modifier" but "the modifier is a question
about the GROUP, not about the title". It matters only where the group
itself encodes seniority.

### 2.4f Short foreign anchors attract their spelling, not their meaning

Four instances now, enough to call it a rule rather than an incident.

| Anchor | Attracted | Why |
| --- | --- | --- |
| `bibliotecario` | `biologo`, `catedratica`, `nutricionista` | Spanish occupational nouns of similar shape |
| `dozent` | `doutoranda`, `uzm dr`, `docotor`, `doctoor` | anything beginning 'do' |
| `dozent` | **`zitna 25`** | a street address in Prague |
| `dirigente medico` | 2,078 titles at 0.717 average | one Italian word serving every Romance clinical rank |

The mechanism is the same each time: a short word in a sparsely populated
part of the embedding has weak, diffuse neighbours, so orthographic
similarity starts to outweigh meaning. It is why the librarian translations
were removed and why none have been added since.

`zitna 25` deserves its own line. A street address, entered in the job title
field, reaching a teaching anchor at 0.655 on its letters. It is the
clearest single illustration of what free-text entry produces, and it is now
rejected by hand.

And the counter-example matters as much: `docente`, also a short foreign
word, carries 499,135 records across 9,350 titles and almost all of it is
correct - Spanish, Italian, Portuguese and Turkish academic ranks on one
Italian word. The difference is that the region around `docente` is densely
populated with real academic vocabulary, where the region around `dozent` is
nearly empty. Density, not length, is what decides.

### 2.4g An accent splits a title into two groups

Found 2026-10-21 in researcher_early:

| Title | Records | Group |
| --- | --- | --- |
| `científico titular` | 2,153 | researcher_**early** |
| `cientifico titular` | 402 | researcher_**established** |

The same Spanish job title - a CSIC tenured scientist - in two different
groups, because one spelling carries its accents and the other does not.
clean_text uses NFKC, which preserves accents, so the two normalise to
different strings, get different embeddings and land wherever each happens
to fall.

It changes no audience today, since both groups feed `researcher` and
`hcp_researcher` identically. It would matter immediately if 1.16 were ever
acted on, because the same person would be early career or senior depending
on whether they typed an accent.

Related to the decision recorded in `macros/normalize.sql` about HTML
entities: that one was measured at 19 titles and left alone. This is the
same class of problem and the same reasoning applies - but it is worth
knowing that normalisation differences do not only duplicate a title, they
can also split it between groups.

### 2.4h A word being generic in English does not predict it being generic in ORCID

Four times now I have predicted which generic anchor would misbehave, and
four times the prediction has been wrong in the same way.

| Anchor | I predicted | It measured |
| --- | --- | --- |
| `audiologist` | the worst -ologist magnet | 0.326, pulled nothing |
| `researcher` | the most generic word we use | 0.081, clean |
| `resident` | someone who lives somewhere | **0.032, the cleanest anchor in its group** |
| `intern` | risky | **0.230 across 3,925 distinct titles** |

The pattern in the misses: I was reasoning about how ambiguous the word is in
the English language. What decides is whether people in OTHER professions
actually type it into a job-title field.

Nobody outside medicine writes "resident" as their job - 164,130 records and
only 490 distinct titles. Everybody outside medicine writes "intern" -
3,925 distinct titles, carrying engineering intern, data scientist intern,
machine learning intern, management trainee, industrial trainee.

So the test for a risky anchor is not "is this word ambiguous" but "do people
in other jobs use it to describe themselves". That is a question about
vocabulary in the wild, and it can only be answered by measuring - which is
the fourth argument in this document for measuring before reasoning.

### 2.4i Record frequency and audience membership are different orderings

Every review in this project has been prioritised by `dim_title_group.frequency`,
on the reasoning that a title carrying more records decides more. For finding
classification errors that is right. For finding **people who are in an audience
wrongly** it is the wrong sort order, and the retirement work measured the gap.

| | |
| --- | --- |
| Records still assigned under a retirement title | 15,317 |
| People those records actually put in an audience | **1,065** |

A ratio of fourteen to one. The reason is that roles are computed over a
person's whole employment history: rejecting one title only removes somebody
if that title was their *only* qualifying record. Most people who typed
"Professor Emeritus" also have "Professor, 1990-2020" behind it, and that
record keeps them in Lecturer regardless.

So the two orderings disagree, and they disagree badly. Ranked by records the
largest remaining title was `professor retired` at 459; ranked by people it was
bare `emeritus` at 31, carrying 383 records. A title can be large in the
dictionary and move nobody.

**The rule:** when the question is "is the dictionary wrong", rank by
`dim_title_group.frequency`. When the question is "who is in the audience
wrongly", rank by `count(distinct snid)` over
`fct_researcher_roles.evidence_title`. Using the first to answer the second
over-states the problem by an order of magnitude, which is how this one nearly
got a model change it did not need.

### 2.5 About 1,008 people are confirmed on a title alone ⟳

Healthcare professional is the one role that accepts a title without a
department agreeing, and only at the very edge: confirming that way requires
an exact anchor match **and** a fully resolved organisation, which comes to
exactly the 0.60 threshold. Every such title measured is a genuine clinical
one; around 22 are a bare "consultant" in a country that does not use it as a
hospital grade. *Source: analyses/22 queries 1 and 6.*

### 2.6 Librarian's quality figures do not mean what they look like

845 titles, 21,828 records, and `share_below_075` reads 0.81 — which measures
nothing. The group has no anchors; it is decided by the word in the title, so
its similarity column records how far those titles sit from the *other*
groups' anchors. Every assignment is exact and every score is 1.000. Judge it
by reading the titles, not by the metric. *Source: analyses/19 query 3,
analyses/21 query 2.*

### 2.7 The education signal is not used at all

`educations` is pulled into the raw layer and consumed by nothing — no
staging model, no scoring. It carries `degree`, `department_name`,
`organisation_name`, `disambiguated_organisation_id` and both dates. A degree
is a far more standardised vocabulary than a job title (MD, MBBS, BDS,
PharmD, MLIS mean one thing worldwide), so it is the most promising unused
signal in the project and would speak directly to the `dr`/`md` problem in
1.9.

Constraint on any design: a degree is evidence of **training, not current
occupation**. Someone with an MD now working in venture capital still has an
MD. Education should raise confidence in a role the employment already
suggests, or supply a missing field — never assign a role on its own.

### 2.8 One measured defect left in deliberately

HTML entities survive normalisation: a title stored as `R&amp;D Manager`
becomes a different dictionary entry from `R&D Manager`. Measured at **19
titles / 1,752 records** and 2 departments / 42 records, with three provable
pairs — all three landing in the same group, so no classification is wrong.
Fixing it would re-key and re-embed the entire dictionary. Left alone on
purpose; recorded in `macros/normalize.sql`. *Source: analyses/22 queries 9
and 9a.*

### 2.8a `medical director` reaches Head of Faculty, and we are leaving it there

**145 people**, 0.7% of faculty_head. Measured 2026-10-29, the day after the move
that caused it.

**How it happened, and it is a design fact rather than a mistake.** Moving
`medical director` from practitioner to leadership on 2026-10-29 was right for
hcp_administrator. But `leadership` is the only title group feeding BOTH
hcp_administrator and faculty_head, and nothing in the system can say "this
title must not feed that audience" — the only veto available works on the
organisation NAME, in `org_name_patterns`, not on the job title.

The arithmetic lets them straight through, because a human override forces the
title score to full marks:

    0.60 x 1.000  (the title, forced by the override)
    0.40 x 0.500  (a hospital)
                   0.800   against a 0.65 threshold

**Worse, faculty_head is the EASIER of the two to enter for this title.**
hcp_administrator is title_and_field and needs a clinical department;
faculty_head is title_required and needs nothing. Many medical directors have
no department recorded, so they miss the audience they belong in and reach the
one they do not. That is the opposite of what "PRECISION ONLY" was meant to
produce.

**Who they are.** Overwhelmingly clinical directors at hospitals - Brigham and
Women's, Cleveland Clinic, Children's Hospital of Philadelphia, Chi Mei Medical
Center - in Ophthalmology, Neonatology, Radiology, Burns, Critical Care. They
are not faculty heads. The handful at universities are running health units,
which is not a faculty either.

**Why we are not fixing it.** The only available lever is the Healthcare
organisation score for faculty_head, currently 0.50. To block an
override-forced title it would have to fall below 0.125, and that removes
EVERY faculty head whose record names a hospital. Measured, that path carries:

| Title | People |
| --- | --- |
| `director` | 826 |
| `head of department` | 294 |
| `head` | 225 |
| `chief` | 213 |
| `deputy director` | 125 |
| **`medical director`** | **95** |
| `chair` | 77 |
| `dean` | 17 |

Removing 95 medical directors would cost 294 heads of department and 17 deans.
Merve's call on 2026-10-29: accept the 145 and record it. The proper fix is a
title-level exclusion, which is a model change plus a test, and 145 people do
not justify it.

**The larger question this turned up.** Roughly 2,000 people reach faculty_head
through the hospital path at all. `medical director` is unambiguous, but
`head of department` at a teaching hospital is not - medical school departments
are often based in hospitals, so some of those 294 are genuinely academic. That
is a definition question and belongs with 1.3 rather than here.

**The pattern worth remembering.** A correction that is right for one audience
can be wrong for another, because they share a title group. Nothing in the
current design separates them, and this will come up again.

### 2.8b `doç dr` is an academic rank, not a medical one — measured

Merve raised it on 2026-10-30: in Turkish, `Doç. Dr.` is what physicians put
before their name, so should it be a practitioner rather than a teaching title?

In a hospital, yes. In ORCID, no. Measured across the records we could resolve
a discipline for:

| Discipline | People |
| --- | --- |
| health_clinical | 16 |
| humanities_law_edu | 12 |
| engineering | 7 |
| social_behavioural | 7 |
| everything else | 7 |

**Two thirds are not clinical.** The title means "associate professor holding a
doctorate" and every faculty uses it — literature, engineering, law. Moving it
to practitioner would make engineering associate professors into healthcare
professionals.

And nothing is lost by leaving it: hcp_broad matches on title OR field, so a
`doç dr` in a clinical department already reaches the healthcare audience
through the department, which is the right route for them.

Recorded because the intuition was reasonable and the measurement was not
obvious. *Source: the teaching_academic review of 2026-10-30.*

### 2.9 Retired and emeritus titles: the rule, and the floor it hits

**The rule, set by marketing on 2026-10-16 and reaffirmed 2026-10-29:** a title
whose plain meaning is that the person has retired does not qualify them for any
audience. A retired professor is not a lecturer. Recorded as REJECT overrides,
so it is reversible in a seed edit if an emeritus audience is ever wanted.

**How far the rule got, measured 2026-10-29:**

| | Titles | Records |
| --- | --- | --- |
| Already rejected | 95 | 17,277 |
| Still assigned | 878 | 15,317 |

**What the remainder actually costs**, by 2.4i's ordering: **1,065 people**
across all nine audiences — 692 in Lecturer, which is **0.17%** of that
audience. Librarian has the highest rate at 0.30%, and that is two people.

**Why we stopped there.** The remaining distribution is flat in a way nothing
else in this project is. Ranked by people, the largest title is 31 and the
fortieth is 2; the top forty together account for about 264 of the 1,065. There
is no leverage to exploit: 40 override rows would buy a quarter of it, and
clearing the rest would take roughly 800 more. The cause is visible in the
titles themselves — people write their whole career into the field, so almost
every spelling is unique: `honorary and visiting academic, emeritus professor`,
`retired, full professor, full professor (emeritus)`,
`dvip-emeritus, associate professor emeritus`.

**The alternative we considered and rejected.** A pattern that UNASSIGNS would
catch all of it and stay correct as new spellings arrive. The pattern layer
cannot currently do this - `dim_title_group` sets `is_assigned` to true for any
pattern hit - so it is a model change plus a new collision test, roughly half a
day. Not justified for 1,065 people, and recorded here so the next person does
not re-derive it.

**If that change is ever made, two things are already known.** First, `emerit`
and `émérit` are safe stems but **`retir` is not**: it would reject researchers
who STUDY retirement. The Survey of Health, Ageing and Retirement in Europe
alone contributes five titles and about 60 records, plus
`specialist adviser retirement and income modelling unit` (36) and
`retirement fund manager` (11). `head of retiro mental health service` (15)
matches on a Madrid district. This is the `library manager` → `manager` failure
in a new costume: a stem match catches the subject, not the employment status.
Second, `librarian emeritus` (11) and `principal librarian emeritus` (4) are
currently assigned by the librarian PATTERN, so an unassigning pattern would
need a precedence rule against an assigning one.

**What is deliberately still in.** Titles that say the person remains active -
`emeritus professor with formal duties` (107), `emeritus professor remain
active` (46), `researcher and professor - now retired but active` (27),
`full professor of public health sciences emeritus supervisor of 2 phd
students` (26). The Market Intelligence role library agrees these are not
simply inactive: it classes emeritus under "Former or inactive" but describes
them as people who "may remain intellectually active", with publications and
mentoring among their typical outputs. Blanket rejection would take these too.

*Source: analyses/27 and the retirement sweep of 2026-10-29. See also 1.14,
which asks the same question about honorary professors and is still open.*

---

## Part 2b — How we find the next problem, and what is left

One diagnostic turned out to generalise, and it is worth stating because it
replaces guesswork. **A neighbouring anchor carrying a high share of records
below 0.75 is the signature of a MISSING anchor, not of a bad one.** The
titles arriving there are usually correct and merely unconfident, because the
nearest available anchor is the closest thing we gave the model.

Read from analyses/22 query 3 on 2026-10-20:

| Anchor | Share below 0.75 | What was actually reaching it | Records |
| --- | --- | --- | --- |
| Anchor | Before | What was reaching it | After |
| --- | --- | --- | --- |
| `paramedic` | 0.633 | emergency medicine, 2,998 records, no anchor at all | **0.226** |
| `anaesthetist` | 0.436 | intensivist, 1,198 | **0.122** |
| `haematologist` | 0.442 | rheumatologist, 1,761 | **0.208** |
| `gynaecologist` | 0.591 | geriatrician, 500 | 0.557 — barely moved |

Six anchors were added from that reading and five of the six behaved exactly
as the diagnostic predicted, which is the evidence that the method works
rather than that the guesses were lucky. `gynaecologist` did not collapse,
so something other than geriatrician is arriving there and we do not yet
know what. analyses/22 query 10 asks, rather than guessing.

The same query also settled a prediction worth recording because it was
wrong. Before building, I flagged `audiologist` as the most likely magnet
on the grounds that the -ologist suffix attracts other -ologists. It came
back at 0.326 and pulled nothing. `pathologist` was the problem instead,
and the lesson is that the suffix does not predict a magnet - how crowded
the neighbouring region is, does. `audiologist` sits beside nothing;
`pathologist` sits beside every science ending in -ologist.

**Two promises kept on 2026-10-20, with results that went against my own
hypothesis both times.**

The faculty_head company veto - three rows in org_name_patterns written to
stop corporate executives reaching the audience - was suspected of being
dead weight, because we later found the real cause of those executives
arriving was the incremental anchor table. Measured: it catches **79
people**, all of them PROBABLE at 0.505, where without it an
academically-named company could lift them over the line. Small, but exactly
the job it was written for. It stays. *analyses/23 query 1.*

And the "professor of X" rule I was about to write would have been the worst
change in the project's history. See 1.10.

**What is left is a long tail.** practitioner has moved 40.64% -> 35.55%
and each further batch now recovers a few thousand records rather than tens
of thousands. Three titles remain unresolved not because they are hard but
because they are marketing's call, listed in 1.4 and 1.5. The next material
gain is not in this group at all - it is the education signal in 2.7, which
is the only thing that can speak to the 146,865 records where the title is
just `dr` or `md`.

---

## Part 3 — Errors found and corrected, with counts

Useful for the presentation because it shows the review working rather than
the system being clean. All 2026-10-20 unless noted.

| What was wrong | Records | Fix |
| --- | --- | --- |
| Librarian built on anchors put 69–73% of its records in the wrong place | — | abandoned anchors for patterns; group rebuilt from 0 |
| 11 non-clinical professions pulled in by new clinical anchors, `epidemiologist` 7,779 of them | ~17,200 | moved back by override |
| 19 titles naming no clinical occupation (`advisor`, `expert`, `designer`, `business consultant` …) | ~24,800 | rejected |
| 3 academic ranks read as physicians (`doç dr`, `ayudante doctor`, `nursing tutor`) | 5,145 | moved to teaching |
| 4 medical-writing and pharma-commercial titles | 1,990 | moved to support |
| 7 more unrelated professions (`lawyer`→dentist, `minister`, `personal trainer`, `asesor` …) | 3,216 | moved or rejected |
| 3 more (`methodologist`→pathologist, `expert evaluator`, `economic advisor`) | 965 | moved |
| 8 dental specialties had no anchor; everything leaned on `dentist` | — | anchors added |
| 3 with them (`attorney`→dentist, dental researcher, course coordinator) | 393 | moved |
| 13 sciences pulled by `pathologist`, third round (`biologo`, `field geologist`, `anatomist` …) | 2,078 | moved |
| `horticulturist` → **gynaecologist** at 0.659 | 229 | moved |
| 13 "senior X" titles pulled by `senior scientist` (`senior manager`, `senior software developer` …) | 10,073 | moved |
| 9 writing and software titles on `scientist` / `scientific director` (`author`, `scientific editor`, `journalist` …) | 4,126 | moved |
| 22 directing roles on `head of laboratory` / `scientific director` (`head of innovation`, `vice president r&d` …) | 3,907 | moved |
| Retired and emeritus titles counted as working researchers | 14 titles | rejected, at marketing's request |
| "Library" in the molecular-biology sense (lentiviral, chemical) | 89 | rejected |

### Silent defects, each of which had already produced wrong numbers

These matter more than the mis-tags, because none of them failed visibly.

- **Anchor embeddings were incremental**, so deleting an anchor did nothing at
  all. It had been wrongly diagnosed once already: a note on the `leadership`
  group concluded the embedding simply generalises to corporate titles, when
  in fact the removal of `chief executive officer`, `founder` and `president`
  had never taken effect. The organisation-score veto was built to work
  around it.
- **The override join** was on `(title_key, title_group)`, so an override
  could only match when it already named the group the model had chosen —
  which made every reassignment, the entire purpose of the mechanism, dead
  code.
- **`\buniversit\b`** cannot match "university". The two most valuable
  organisation patterns never fired once.
- **The source holds ~14 versions per profile** and nothing in the column
  names says so. Every downstream count was inflated until it was
  deduplicated.
- **`analyses/13` reported 210,730 reachable** against a headline of 497,798 —
  a 2.4x contradiction inside the repo, because it still read two consent
  flags and joined the raw CDP source rather than our deduplicated model.

Ten tests now cover these classes, chosen from this history rather than from
a checklist. They are listed in `tests/`.
