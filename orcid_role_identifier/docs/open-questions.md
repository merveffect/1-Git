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

### 1.1 Should the second confidence tier be switched on? — CLOSED 2026-11-11

**Merve, 2026-11-11: no. The second tier stays off. Nobody we are not certain
about enters an audience.** Removed from the marketing questions document
rather than deferred. `vars.contract.include_labels` keeps `CONFIRMED` alone
and nothing in the pipeline changes — what changes is that 45,054 unique
people are now deliberately not delivered rather than pending a decision.

Two consequences worth recording. The `consultant` country rule below was a
**precondition for switching the tier on**, so it falls away with it: the 1,613
people it protected against are held in PROBABLE and never ship. And 1.9's
`dr` / `md` question narrows — a bare `dr` with no clinical department sits in
PROBABLE, so it is already excluded; what is left is whether a `dr` WITH a
clinical department is acceptable evidence on the department alone.

The principle also bears on **1.3**, where our own working answer points the
other way: the 267 bare `director` / `head` / `chair` people are CONFIRMED, not
PROBABLE, so the tier decision does not reach them — but applying the same
principle would remove them, taking the own-words defensible share of Head of
Faculty from 79.2% to 93.2% on 1,508 people instead of 1,775. Not ours to do:
it is a definition, and there is no second signal contradicting the title.

The measurement that was going to decide it is kept below.

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

**WHAT "FINISHED" MEANS FOR THIS AUDIENCE — asked by Merve 2026-11-04.**
Two questions, and they have different answers.

*Does the director decision complete Head of Faculty?* Substantially, yes.
The audience was measured on 2026-11-03 against 1,775 checkable people:
**79.2% certainly right** (223 said leadership themselves, 1,185 hold a title
naming a faculty-level post), **15.0% uncertain**, **5.7% wrong**. The 15.0%
is 267 people who hold ONLY `chair`, `director` or `head` with no faculty
word beside it — which is this question and nothing else. Whichever way
marketing answers, that 15.0% stops being uncertain: in, and they are right
by definition; out, and they leave. So the decision converts the largest
remaining unknown into a known, and after it the audience is as defensible as
this project can make one.

*Then why have we not fixed the errors we found?* Because the two populations
are different and only one of them is fixable.

The 15.0% is **not an error**, it is an undecided definition. We cannot fix
it because we do not know which way it goes — that is what makes it a
question for marketing rather than a bug for us.

The 5.7% — 102 people — IS our error, and the reason it is still there is the
most-measured lesson in this project: **the people wrongly in an audience do
not arrive through the titles you happen to review.** The roster review of
2026-10-30 is the cleanest demonstration. Merve read the full faculty_head
roster by eye and named 106 corrections; they landed across 7,126 records and
478 holders, 201 of whom left the audience. The measured error rate went from
**101 people wrong to 102**. Five separate reviews have now produced that
same shape (`associate`, Pharmacist's 91 people, the Lecturer corrections,
the compound patterns, and this).

But that is only two thirds of an honest answer. The other third is that
**`analyses/33` query 4 has not been run** — the one that reads the evidence
titles of those 102 people. It is the only remaining question that can move
the 5.7%, it costs one query, and until it is run "we cannot fix it" is a
claim rather than a finding.

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

### 1.10b `chair` cannot be a leadership signal — MEASURED AND RULED OUT, 2026-10-30

1.10a recorded the compound titles as staying in Lecturer. Later the same day
the decision was revisited - head/dean/chair compounds to leadership, so that
the people who run faculties are reachable in faculty_head - and reading the
full list before implementing it killed one third of the scope outright.

`chair` does not mean a leadership post in academic job titles often enough to
be usable. From the 150 compound titles currently in teaching_academic:

    full professor and chairholder chair of strategic entrepreneurship   227
    dean s chair associate professor                                     204
    professor canada research chair tier 1                               178
    canada research chair and full professor                             174
    professor & canada excellence research chair                         172
    assistant professor & canada research chair                          158
    professor and research chair                                         144
    full professor and canada excellence research chair                  129
    associate professor and huck chair                                   128
    professor and canada research chair                                  ...

Roughly **1,600 records** of this shape. A Canada Research Chair is a funded
research professorship. A *Dean's Chair* is an endowed chair named after the
office that endows it, not a deanship. A European *Chair of X* (Lehrstuhl) is
the professorship itself. Every one of these belongs in teaching_academic,
which is where it already is.

**Should they go to researcher instead?** No. The professorship is the certain
part of the string and it is a teaching post; moving the title to a researcher
group would trade a claim we are sure of for one that is no more certain, and
would drop a true Lecturer membership to gain a Researcher membership these
people mostly hold anyway through other records. No change.

**And the exclusion is not expressible in the pattern layer.**
`seeds/title_group_patterns.csv` is matched with `regexp_contains`, and
BigQuery's RE2 has no negative lookahead, so "contains professor and chair but
NOT research chair" cannot be written as one row. A pattern would carry the
endowed chairs with it.

**Measured the same day.** `analyses/30_leadership_compounds.sql`:

    head or dean, no chair word     1,982 titles    78,005 records
    chair word only                   968 titles    44,611 records
    both                               49 titles     1,421 records

**The endowed chairs are 8,889 records over 335 titles** - measured by query E,
against the ~1,600 that reading the visible rows had suggested. Five times
larger. (E drops the professor-word requirement bucket A applied, so its 1,073
titles are a wider set than A's 968; the two are not directly comparable.)

**The head/dean trade, measured both ways.** 3,683 people hold one of these
titles:

| | |
| --- | --- |
| Lecturer loses | at most **1,739** of 399,884 people - 0.43% |
| | the other 1,944 hold another teaching title and stay |
| faculty_head gains | up to **3,376** of 17,528 - **+19%** |
| | 3,263 reachable; 307 are already in it |

That is the best trade faculty_head has been offered. The gain is an upper
bound: it still needs the organisation to resolve, which is what already
strands ~14,600 strong leadership records. Query H decides it.

### `head` on its own cannot be trusted either

Reading the 150-title list found that the word is not always a leadership post:

    assistant professor director head and neck surgery        107   anatomy
    professor - senior consultant - head of thrombosis unit   128   clinical unit
    assistant professor head of spine center                  151   clinical centre
    professor head of allergy clinic                          102   a clinic
    associate professor - head of scientific committee        156   a committee
    assistant professor and head of quality assurance unit    130   an admin unit
    assistant professor head of echocardiography research     111   a laboratory
    dean of the sport sciences faculty 2010-2020 professor     126   ENDED in 2020
    dean 2010-2018 adjunct professor 2008-                     109   ENDED in 2018

About 1,500 records in the top 120 titles alone. `head and neck surgery`
settles it: a bare `head` match would read an anatomical term as a faculty
post.

So the rule has to name the level rather than the word - `head of department`,
`head of school`, `head of faculty`, `head of institute`, `head of division`,
`dean`. Those are positive and specific, so no negation is needed and the
`chair` problem does not recur.

### The pattern layer was the answer, and the measurement killed it

1,982 titles cannot be hand-written as overrides, and the top 120 are only 64%
of the family, so the plan was to extend the pattern layer beyond librarian for
the first time. Query F priced it first. **A pattern matches every title
containing the phrase, not only professor compounds:**

| Would leave | Records | Example |
| --- | --- | --- |
| researcher_early | 5,217 | `associate dean research` |
| researcher_established | 3,389 | `principal researcher - head of department` |
| practitioner | 2,353 | `head of department of cardiology` |
| pharmacist | 1,990 | `cluster pharmacy manager & head of department` |
| support_technical | 1,023 | |
| student | 396 | `sub-dean graduate studies` |
| trainee_clinical | 91 | `dean s clinical research fellow` |
| librarian | 14 | `associate dean of library services` |
| **total** | **~14,500** | against a gain of ~49,100 out of teaching |

1,990 records is **2.7% of the entire pharmacist group**, which has no external
check at all, and practitioner is the least-covered audience we have.

And the cause is structural rather than a regex that needs tightening:
**`head of X` and `dean` are modifiers, not professions.** They attach to any
job, so a pattern matching them overrides the profession word standing next to
them in the same string. A pattern also cannot reject, forces a score of 1.0,
and is undone one title at a time - repairing 14,500 records would take
hundreds of exclusions, which is worse than the override list it was meant to
replace.

**Which is 1.10a restated with numbers.** The decision that one title names one
profession is exactly what makes the profession word the one that has to win.
Being a head of department is an attribute of a job, not the job.

### The design that survives: a pattern that applies within one group

A pattern row that can say *only when the model already put this title in
teaching_academic*. Then:

- the 14,500-record sweep disappears by construction - practitioner, pharmacist
  and the researcher groups are never consulted;
- the three collisions query G found (`associate dean of library services`,
  `associate dean library services and archives`, `head of department of library
  and information science` - 14 records, all librarian by pattern today)
  disappear for the same reason;
- the word-order split above still closes, because a pattern matches every
  separator;
- and the profession word still wins.

Mechanically: one nullable column on `seeds/title_group_patterns`, one condition
on the join in `dim_title_group`, and the model's own pre-pattern choice exposed
as a column so `assert_title_patterns_all_match_something` and
`assert_title_patterns_do_not_collide` can still see what a conditional pattern
acted on - without it the test is circular, because once the pattern fires the
title is no longer in the group the pattern was conditioned on. Librarian rows
leave the column empty and go on working unconditionally.

### BUILT 2026-10-30. The final trade

J cleared the blocker: 1,690 of 2,364 holders are at an Education organisation
(faculty_head 1.00) and 12 at a Facility (0.60), so 1,702 of 2,364 - 72% - clear
the organisation. What strands 14,600 strong leadership records elsewhere does
not strand these, because a professor who also heads a department is at a
university and the ROR resolves. (J's own join was case-sensitive where the
model uses `upper(trim())`, so its nulls were the query's fault, not a defect.)

K then gave the exact trade on the scope that shipped - 1,706 titles, 48,995
records, 2,354 holders:

| | |
| --- | --- |
| Lecturer | 399,884 -> 398,858, **-0.26%** (1,026 leave, 1,328 stay) |
| faculty_head | 17,528 -> **19,026**, **+8.5%** (1,498 new, 280 already in, 543 no ROR) |

The earlier +19% was on the wider regex that allowed a bare `head`, and is
superseded.

**Why the trade is defensible, and it is not that faculty_head is small.** Under
one-title-one-profession something has to be dropped from `professor and head of
department`, and the two readings are not equal: heading a department at a
university entails being an academic there, while being a professor entails
nothing about leading anything. The leadership reading keeps both facts; the
teaching reading throws one away.

**Shipped:** ten patterns scoped to `teaching_academic`; ten HUMAN exclusions
for the possessives; one HUMAN correction where query I's regex flagged a real
deanship (`... vice dean/ acting dean/ dean s advisor`); three HUMAN decisions on
the collision titles, all to librarian. `assert_title_patterns_do_not_collide`
now skips titles a human decided, because `min()` never surfaces where a
reviewer has named the group.

**One flaw found and fixed before pushing.** The scope has to mean the model
*assigned* that group, not merely that it was nearest: `m.title_group` is
populated even for a title rejected below `sim_floor`, so conditioning on it
would have promoted those titles with a score of 1.0 - rescuing exactly what the
floor exists to hold back, and making the shipped behaviour differ from what K
measured. `dim_title_group` now also exposes `model_is_assigned` so both pattern
assertions ask the model's question rather than a different one. Query M sizes
what the condition holds back.

**Known residual: 26 titles, 604 records, 1.2% of scope.** They carry their own
dates and a date is not a rule - `dean 2010-2018` ended, `dean 2014-` and `head
of department 1997-pres` have not, and one carries both with the headship on the
open side. Query L lists all 26 to be read rather than regexed.

**Two things only the build can settle,** both small: a title that is teaching by
human decision rather than by the model will not be claimed (there are 26 human
decisions in that group and none is a head/dean compound, so this should be nil);
and the four smallest patterns - `dekan` 2 titles, `head of dept` 4, `decano` 4,
`head of faculty` 6 - would fail `assert_title_patterns_all_match_something` if
even one of those few turns out to be a human decision. That failure is the
guard working, and the fix is `[pre-emptive]` in the note.

**Query H was a dud and the fault was in the query.** It returned "no
faculty_head row at all" for all 1,667 people, which says nothing about
organisations: `int_employment_scored` only emits a row for a role when the
title group qualifies for it, so a teaching_academic person has no faculty_head
row by construction. J asks it properly, through the org type on their existing
teaching row.

### CLOSED 2026-10-30. What the two builds actually did

| | |
| --- | --- |
| the 37 ended-post titles, rejected | 37 / 37 |
| verbose titles the patterns now reach | 33 / 34, worth 31 records |
| `teaching_academic` | 11,946,079 - moved by zero |
| the other eight groups | moved by zero, **in both builds** |
| faculty_head | 17,528 -> **33,242** |
| lecturer | 404,367, unchanged |

**Only 1,715 of faculty_head's growth is this work**, against a forecast of
1,778 - within 4%. The rest is ~14,600 records with strong leadership titles
whose employers finally resolved. Two findings in one build, reported as two.

**A fourth instance of the project's most useful lesson.** 37 titles rejected
and 33 added, and the audience moved by **one person** - 33,241 to 33,242. The
people holding an expired deanship almost always hold a current leadership title
too. Measured now on `associate`, on pharmacist (91 people), on the Lecturer
corrections (one person) and here.

### And the accuracy, asked properly

Of 1,775 checkable people in faculty_head:

| | people | |
| --- | --- | --- |
| said leadership themselves | 223 | |
| a title names a faculty-level post | 1,186 | head of department, dean, rector, chancellor |
| **UNCERTAIN** | 270 | only `chair`, `director` or `head` |
| **our error** | 101 | no leadership word in any title |

**79.4% certainly right, 15.2% uncertain, 5.7% wrong** - so about 94%
defensible, not the 12.6% that straight agreement suggested. The first version
of this check said ~14% wrong because its word list counted `chair` as
leadership and had no `chancellor`: wrong in both directions at once. Worth
remembering before quoting any figure that rests on a hand-written word list.

**The 270 put a price on question 1.3.** What to do with the `director` family
has been open since October with no cost attached. It now has one: 15.2% of this
audience is there on nothing but `chair`, `director` or `head`. Whichever way
marketing answers, that is the number that moves.

### CLOSED 2026-11-03. The roster was read by hand, and the error rate did not move

Merve read all 33,000 faculty_head matches and named two families that must not
be in the audience: fellowships and assistant roles, and strings that are noise.
106 corrections went in over 7,126 records - 47 rejections, 23 to
researcher_early, 21 to support_technical, 14 to teaching_academic, 1 to
student. **201 people left the audience and 277 stayed**, holding a real
leadership title as well as the one removed.

| | before | after |
| --- | --- | --- |
| a title names a faculty-level post | 1,186 | 1,185 |
| UNCERTAIN - only `chair`/`director`/`head` | 270 | 267 |
| **our error - no leadership word at all** | **101** | **102** |

**The fifth measurement of the same thing, and the clearest.** The people
wrongly in this audience are not there through the titles that were reviewed -
they are there through some *other* title, and the reviewed ones were mostly
held by people who also hold a genuine leadership post. Cleaning the dictionary
and cleaning an audience are different jobs. Measured now on `associate`, on
Pharmacist (91 people), on the Lecturer corrections (one person), on the
compound patterns (one person) and here.

The review was still worth doing **for the dictionary rather than for this
number**: 7,126 records are read correctly that were not before, permanently,
and every audience built from here inherits it. To move the 5.7% we have to ask
what those 102 people are in the audience *for* - their evidence record, not the
titles we happened to review. `analyses/33` query 4 asks that, and it is the
only question left that can change the figure.

### Two guards earned their keep

**`assert_title_patterns_do_not_collide` failed a build, correctly.** `associate
dean for library operations` - 1 record - was claimed by `librar` and by the
scoped `\bdean\b` at once, and `min(title_group)` would have resolved it
alphabetically and silently. Settled by human decision as `librarian`, the same
reading as the three before it: the library is the job, the deanship is the
grade. Query G had listed every title matching both pattern sets on 30 October
and found three, not four; the likeliest reason this one is new is that the
source grew between builds, which the same build showed independently when
lecturer gained 4,483 people from no change of ours.

**And `assert_overrides_take_effect` caught 2 of 108 rows that matched nothing.**
Both spelling rather than judgement - `vice-chancellors fellow` exists but the
unhyphenated `vice chancellors fellow` does not - and both deleted rather than
re-guessed. **98.1% of a list written by eye was exact**, which prices the
method: reading a roster and writing overrides from it is reliable enough to be
worth doing, and not reliable enough to do without a check.

### A fourth sighting of the one-word failure, in the possessive

`dean s chair`, `dean s clinical prize`, `dean s clinical research fellow`,
`dean s research assistant` - an award or a post **named after** the dean, which
a `dean` match reads as a deanship.

Same shape as `member` (23,157 records, 9 Oct), `fellow` (48,777, 29 Oct) and
`associate` (6,631, 30 Oct): a word that means something only in company. This
is the first time it was caught before shipping rather than after.

### 2.15 An anchor removal measured and reverted, and three figures retracted — 2026-11-11

Merve: *"Research Officer'i support_technical'in capasi yapmisiz ama bu capayi
direkt cikartalim. Research Officer vektorden gelsin."* Both halves were
written — the anchor removed and a pattern row added — and then
`analyses/49` ran. **The anchor is back. The pattern stays and does the whole
job.**

**Query 2's own headline was wrong first.** It asked whether `research officer`
was among a title's top THREE anchors, which over-counted the exposure by about
five times: 22,157 records of "collateral". Removing one of three anchors
changes nothing unless that anchor carried the maximum similarity, and
`matched_anchors` is ordered descending, so only `matched_anchors[0]` matters.
`research technician` (1,430 records, similarity 1.000 against its OWN anchor)
sat at the top of that list and was never at risk. Query 2b is the corrected
version and is the one to run before removing any anchor.

**Query 2b then measured it properly, and the cost is double my estimate.**
Titles whose TOP anchor is `research officer`, grouped by where they would go
instead:

| would go to | records | the ones that matter |
| --- | --- | --- |
| researcher | ~1,900 | fine - same destination. `scientific officer` alone is **763** |
| **practitioner** | **~800** | `program officer` 157, `programme officer` 79, `monitoring and evaluation officer` 52, `policy officer` 36, `statistical officer` 28, `field officer` 27, `conservation officer` 18, `gis officer` 14, `procurement officer` 8, `public relations officer` 9, plus a tail of ~250 records in 1-2 record titles |
| leadership | ~150 | `development officer` 17, `deputy dean for research` 4 |
| trainee_clinical | ~90 | `library officer` 7, `relationship officer` 5, `intelligence officer` 4 |
| teaching_academic | ~60 | `senior programme officer` 15, `professor of operational research` 6 |
| pharmacist | ~25 | `chief knowledge officer` 3, `regulatory executive` 2 |
| student | ~16 | `international student recruitment officer` |

**~1,150 records into groups we did not choose, ~800 of them into
practitioner** - the title arm of `hcp_broad` and `hcp_practitioner`. On a
clinical department a procurement officer, a PR officer and a GIS officer each
become a healthcare professional. That is the exact error class 2.12 and 1.15
were spent removing, and it would have been bought for nothing: PATTERN beats
VECTOR in `dim_title_group`, so the pattern row moves the research-officer
family whether the anchor exists or not.

**One thing the query found that IS worth having.** `scientific officer`, 763
records at similarity 0.875, has `research officer` as its top anchor and would
land in `researcher` - correctly. The grade variants are there too (`scientific
officer c/d/e/f/g/h`, the Indian BARC and DAE grades, `scientific project
officer`, `senior scientific officer`, `assistant scientific officer`). These
are research posts in every system that uses the title, and the pattern does
not catch them. **Candidate for a second pattern row, ~900 records, Merve's
call** - it is a different title from the research-officer family and not
covered by the 11 November instruction.

**2.12 restated for the title dictionary:** adding a rule puts a value where we
chose, removing one sends it wherever happens to be second. Both halves were
written on that principle and only one survived the measurement.

#### Three figures retracted

| claimed | measured | where the claim came from |
| --- | --- | --- |
| `research officer` 34,376 records | **4,829** in the whole family, **4,075** reaching no audience | `setup/build_mkt.py` only |
| statistician + economist "no audience", 12,469 records | **2,177** reaching no audience; 3,752 already in Researcher or Lecturer | `setup/build_mkt.py` only |
| `research analyst` is in Researcher | **split** | never verified |

**And my own correction was wrong in the other direction.** I replaced 12,469
with "~1,300" from query 1, whose family regex was English and Romance only. The
multilingual count in query 1b gives **2,177** - 40% higher, because the first
pass missed German, Turkish and most compound academic titles. Three figures for
one question in two days: one invented, one measured badly, one measured. The
direction matters more than the number, which is why the document now carries
all three.

**The multilingual count also found something useful.** 1,166 records of the
statistician family are already in `teaching_academic` - *professor of
biostatistics*, *lecturer in medical statistics*, *associate professor in
statistical science*. A third of the family, correctly placed, and invisible to
the English-only regex. So the marketing question is narrower than the word
*statistician* suggests: the academics are handled, and what is open is the
1,631 statistician and 546 economist records in no audience at all.

None of 34,376 / 7,094 / 4,406 / 5,894 / 1,125 / 969 / 299 is traceable to a
query in this repository. They existed only in the document builder, so they
were never measurements. Removed from the document, with the retraction stated
in it rather than quietly corrected.

**And the fourth English-only pattern failure.** Query 1's family regex reads
English and Romance spellings only, so `statistiker`, `estatístico` and
`istatistikçi` are missing and even 1,300 is a floor. Query 1b is
multilingual from its first line. The 1.17 veto failed this way three times
running; this is the fourth.

### 1.10c A TITLE MAY NAME TWO JOBS — REVERSED 2026-11-11, BUILT

**Merve, 2026-11-11:** *"eger bir kisi profesor ve lecturer yazdiysa ORCID'deki
role title'ina, o zaman ikisi de dogru ve ikisini de o audience a almamiz
gerekiyor."* Reverses 1.10a, decided 2026-10-30.

**The limit, because it is easy to over-read.** This fires only where the ORCID
title ITSELF names two jobs. Where ORCID says only `professor` and the person
told a survey they are a research scientist, ORCID still wins and they are a
lecturer. 1.10's survey gap is not what this fixes.

**Mechanism: a second column, not a second row.** Fanning `dim_title_group` out
to one row per (title, group) would multiply every record in
`int_employment_scored`, change the grain of everything downstream and break
`assert_one_row_per_researcher`. Instead `dim_title_group` gains
`title_group_2` and `group_2_score`, and each role's membership filter in
`int_employment_scored` asks about both columns. The grain never moves.

The rules live in `seeds/title_group_second.csv`, five of them, each reading
*a title already in group X whose text matches P also belongs to group Y*:

| already in | gains | what it is for |
| --- | --- | --- |
| teaching_academic | leadership | 6.1a — `professor and director`, all six spellings |
| leadership | teaching_academic | the mirror, so word order stops deciding |
| teaching_academic | researcher | 6.1 — `lecturer and researcher`, ~47,000 records |
| researcher | teaching_academic | the mirror — `research professor` 48,609, `research assistant professor` 71,785 |
| researcher | student | 6.1b — `doctoral researcher` 42,231, `postgraduate researcher` 5,427 |

Three things in the design are there because of earlier mistakes.

**The word lists name JOBS, not subjects.** `dean`, `director`, `researcher`,
`chercheur` name a post. `professor of educational leadership` and `professor
of research methods` name a SUBJECT and are deliberately not matched. That is
1.3's lesson restated — a leadership word is not a leadership job — and it is
the single thing most likely to go wrong when a row is added.

**They are multilingual from the first line.** The research list is lifted
verbatim from `title_group_patterns.csv` rather than retyped, because the 1.17
veto failed three times running on exactly this asymmetry.

**Scoped to the RESOLVED group, not the model's guess.** An override that moves
a title also moves which second-group rules can see it. The two pattern
collision tests use `model_title_group` instead, for the opposite and equally
deliberate reason, and `dim_title_group` now says why in both places.

**Three tests, two of them at warn severity.**
`assert_second_group_differs` is an error and should never fire — the join
already forbids it. `assert_second_group_rules_all_match_something` and
`assert_second_group_rules_do_not_collide` warn: a dead rule and a
three-job title are both things we want the number for, and an error on either
would skip every downstream model and turn one bad regex into a blocked build.

**Forecast and verification: `analyses/50`.** Queries 1, 2 and 2a before the
build; 3 to 6 after. Query 2a is the one that matters most — it lists what the
student rule's veto is holding back, and `postdoctoral researcher` appearing
there is the whole point of the veto existing.

### 1.2a BIOMEDICAL RESEARCHERS ARE HCPs — ANSWERED 2026-11-11, BUILT

`hcp_researcher.disciplines` gains `life_biomedical` and the label goes back to
**Clinical / Biomedical Researcher**, the name it carried for one commit in
October before being reverted because the config never matched it. 15,588
people, and they reach `hcp_broad` for free through the parent roll-up.

**The consequence, flagged to marketing rather than absorbed quietly.**
`hcp_broad` is labelled *Healthcare Professional (broad)* and now contains
people who have never seen a patient. Nothing is broken; the NAME is wrong, or
the roll-up is. That is question 1 of the marketing document now, and the
recommendation is to rename, because `hcp_practitioner` already IS the clinical
audience at 46,450 reachable people.

**15,588 is a FOUND figure, not a confirmed one.** `hcp_researcher` requires
both axes and confirms at 0.70. `analyses/50` query 1 measures how many clear
it, and that is the number that goes in the document.

### 2.15a `scientific officer` — PROPOSED, IN THE BUILD, ONE ROW TO REVERSE

763 records plus ~140 in grade variants (`scientific officer c/d/e/f/g/h`, the
Indian DAE and BARC grades; `assistant`, `junior`, `higher`, `senior`;
`scientific project officer`; `science officer` 50). All in
`support_technical`, which feeds no audience. `analyses/49` query 2b found it:
its top anchor is `research officer` and its next-best group is already
`researcher`, so the embedding agrees.

**Flagged rather than decided.** Merve's 11 November instruction covered the
research-officer family and this is a different title. It is in the build so
that one build covers it; deleting the row from
`seeds/title_group_patterns.csv` is the whole reversal. `analyses/50` query 4
is the list to judge it on.

### 1.11 Is "healthcare professional" about the work or the subject?

Several questions in 1.4 and 1.5 are really this one question asked about
different jobs. A psychologist, a medical physicist, a mental health support
worker, a genetic counsellor and a clinical embryologist all work in health
without practising medicine. One answer settles all of them and several that
have not come up yet.

**Priced on both sides, 2026-11-11**, because Merve asked what each answer
actually makes us do rather than what it means.

| If the answer is | What we change | Who moves |
| --- | --- | --- |
| **WORK** — treating patients | reject the non-clinical health titles from the four `health_clinical` audiences; the vet and sport-science anchors come out of `health_clinical` | **OUT:** medical physicists / clinical scientists 346 records, bare `psicólogo/a` 2,658 records, vets 91+ people, non-medicine sport science ~51 people. **STAYS OUT:** biomedical researchers 15,588 people |
| **SUBJECT** — medical content | widen the clinical title list to health-adjacent research titles; keep the vet and sport anchors | **IN:** biomedical researchers 15,588 people, vets 91+, all sport science ~78. Nothing leaves |

WORK costs about **3,100 records**, under 1% of the healthcare audiences, and
the biomedical researchers are not lost — `researcher` has `disciplines: []`
and already holds them. SUBJECT gains about **16,000 people** and loses
nobody, but it costs the *name*: `hcp_broad` would no longer mean a clinician,
so a clinical-practice campaign would need a narrower audience built beneath
it. That is a build, not a config line, and it is the only asymmetry between
the two answers.

Either answer is one word of configuration per audience. See 1.18 and 1.19,
which are the same question about vets and sport science and are settled by
whichever answer comes back.

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

### 1.16 Splitting Researcher into early-career and senior — CLOSED, NOT ASKING

**Merve, 2026-11-04: "1.16 ikiye bolunmesin asla. bu soruyu cikart
bolmiycez. researcherlar beraber."**

The question is withdrawn and is not going to marketing. It is recorded here
rather than deleted outright for one reason only: the option is cheap enough
to look obvious to the next person who reads the registry — two groups
already exist and both feed one audience, so splitting them looks like a
config change and nothing else. It is not, and this is why.

The split would be made **entirely from job-title words**, and bare
`researcher` is an early-career anchor while bare `scientist` is a senior
one. A thirty-year veteran who typed "researcher" lands in early career and
someone who typed "scientist" lands in senior. From the person's side that is
arbitrary. It shows in the sizes: researcher_early carries 8,341,542 records
against researcher_established at 1,878,051.

And the track record is poor. `junior researcher`, 42,949 records, sat in the
SENIOR group for the entire life of the project.

If seniority is ever wanted, the route is **dates, not words** — Merve's own
suggestion. `employments[].full_start_date` is already read for `is_current`
and `recency_rank`, so career length needs no new source field and does not
depend on what someone called their job. It is also what the external role
library's MORE4 R1–R4 career stages are built on.

Until then: **the two groups stay as internal dictionary detail and
Researcher ships as one audience.**

### 1.17 Doctoral students in the Researcher audience — DECIDED, THE TITLE DECIDES

**197,895 records**, found 2026-10-21 on the first read of researcher_early.

| Title | Records | Model's runner-up | Under the rule below |
| --- | --- | --- | --- |
| `graduate research assistant` | 106,438 | **student** | IN — says research |
| `phd researcher` | 49,317 | **student** | IN — says researcher |
| `phd fellow` | 19,424 | **student** | **OUT — says neither** |
| `predoctoral researcher` | 15,368 | researcher_established | IN — says researcher |
| `undergraduate research assistant` | 7,348 | support_technical | IN — says research |

**Merve's decision, 2026-11-04:**

> "doktora ogrencileri kendini researcher olarak tanitmadiysa icinde olmasin,
>  job title da researcher varsa katabiliriz"

A doctoral student is in the Researcher audience **only if their own job
title presents them as doing research.** Being a doctoral student is not
itself the qualification, and we do not infer it. This is the same principle
as 1.12 for teaching assistants, but stated the harder way round: there, if
you teach you are a lecturer; here, the title has to SAY so.

**The consequence is specific and it is not what we are doing today.**
`phd fellow`, **19,424 records**, carries no research word at all. It sits in
researcher_early because `fellow` reached a research anchor, and the model
itself offered `student` as the runner-up. Under this rule it does not belong
in the Researcher audience. The same applies to any
`doctoral candidate` / `phd student` / `doktorand` family that reached a
research anchor on a word that is not about research.

**NOT YET IMPLEMENTED, AND DELIBERATELY SO.** The rule is clear but its
extent is not measured: we know about `phd fellow` because it was already on
the 1.17 list, and we do not know how many other student titles reached
researcher_early without a research word. `analyses/35` query 1 sweeps for
exactly that — titles in the two researcher groups carrying a
student/doctoral/candidate word and NO research word. The overrides get
written from that list, not from this one.

A mechanism note worth keeping, separate from the decision.
`predoctoral researcher` reached the **POST**doctoral anchor at 0.908. Pre
and post are two ends of one axis, so the embedding places them close — the
same blind spot as `junior` against `senior` in 2.4e. Here it happens to
produce the right answer, which is why it is evidence rather than a defect.

---

### 1.17c THE FORECAST RAN AND THE RULE WAS WRONG TWICE — 2026-11-10

`analyses/40`, before any build. Both errors are mine and both are the
reason a forecast is written down before the thing it forecasts.

**FIRST: the forecast was 28.7% over.**

| | Forecast | Actual | Off by |
| --- | --- | --- | --- |
| titles moved | 993 | **1,258** | +265 |
| records moved | 55,646 | **71,598** | **+15,952** |

Too far out to call a near miss. The cause is that the pattern I wrote
carries `postgraduate|post graduate` and the regex that produced the 55,646
in `analyses/35` did not. **The forecast was measured against a narrower
rule than the one written.** The gap is that one word.

**SECOND, and worse: query 3 found the veto leaking, 15 times out of 15.**

Query 3 lists what moves sorted by title LENGTH rather than frequency,
because a job title hiding behind other words is the shape a word list
misses. Every one of the 15 longest wrong moves got through, and they are
all the same two blind spots — **the veto was English only, and it matched
whole words only**:

| Title | Records | What it actually is |
| --- | --- | --- |
| `professora auxiliar e coordenadora adjunta do phd…` | **136** | an assistant professor; `\bprofessor\b` refuses it over one trailing letter |
| `assessed the laboratory reports of … students` | 80 | someone marking students, not a student |
| `ed-d337e - evaluation of student achievement … teacher assistant` | 75 | a teaching assistant |
| `stage tutor … phd quantification of antiretroviral…` | 36 | a tutor |
| `coordinador de la comisión doctoral…` | 19 | a coordinator, in Spanish |
| `teacher of experimental science and microbiology phd` | 13 | a teacher |
| `tutora del internship … phd candidata` | 11 | a tutor, in Spanish |
| `postgraduate medical education **leadership** … fellow` | 7 | `\bleader\b` refuses `leadership` |
| `miembro del comité **científico**…` | 6 | a scientific committee member |
| `vice-chair of the phd program in geosciences` | 3 | a vice-chair |

438 records visible, and query 3 is sorted by length so that is a **floor**.

**The fix, and it is a rule rather than a list.** The seniority half of the
veto now matches by **prefix** instead of whole word, so `professor` catches
`professora` and `leader` catches `leadership`, and it carries Spanish,
Portuguese, French, German and transliterated Russian forms plus `tutor`,
`teacher`, `teaching`, `editor`, `chair` and `secretar` — jobs a student
does not hold. Re-tested in both directions: **0 of the 15 wrong moves
survive, and all 14 intended targets still move**, `phd fellow` and
`senior doctoral scholar` among them.

**What it costs in people, which is the number that matters.** Even at the
leaky 71,598 records, `analyses/40` query 2 put the ceiling at:

| Audience | Confirmed | At most leaving |
| --- | --- | --- |
| Researcher | 334,689 | **1,568** (0.47%) |
| HCP researcher | 54,041 | 431 (0.80%) |
| HCP broad | 124,944 | 414 |
| Lecturer | 410,504 | **0** |

Records are ORCID employment rows across 10.4 million; people are what
ships. Lecturer at zero is the useful check — this rule is scoped to
`researcher` and nothing leaked sideways.

**THIRD RUN, and the same bug a third time — one level deeper.**

The widened veto worked and reconciled exactly: 71,598 → **69,406** records
moved, 1,258 → **1,150** titles, and the 2,192 records removed turn up
exactly in `records_the_veto_spared`, 700,045 → 702,237.

Then query 3 found it again, and this time the lesson is not a word:

> **The NAME pattern has been multilingual since its first line — `studente`,
> `estudiante`, `etudiant`, `ogrenci`, `doutorando`. The VETO was English
> only. So the rule could RECOGNISE a student in six languages and could
> only EXCUSE one in English.**

That asymmetry, not any individual missing word, is the bug — and it had
produced a different symptom on each of the three runs.

| Missed | Records | Why |
| --- | --- | --- |
| `investigación`, `ricerca`, `recherche`, `Forschung`, `pesquisa` | **289** | all mean *research*; the veto carried only `research` and `investigador` (the person, not the activity) |
| `Koordinatorin`, `доцент`, `faculty member`, `responsable` | **110** | seniority words outside English |

The first row is the serious one: it **breaks Merve's own loose reading** in
whatever language the title happens to be written in. `miembro del grupo 25
de ciberesp investigación predoctoral`, 55 records, says research as plainly
as `phd researcher` does.

**The veto is now built in three named parts — RESEARCH, POSTDOC, SENIOR —
each carrying the languages the name pattern carries.** Tested both ways:
**0 of 11 that must stay escape, 0 of 17 that must move are spared.**
`assistant` is deliberately still absent — it would spare `phd assistant`
and `student assistant`, which are targets.

**One class of error cannot be fixed with a word list and is left in
knowingly.** The name pattern fires on titles that merely *mention* students
or use `candidate` scientifically: `guided tour for students of european
exchange` (22), `estudio de la competencia … en estudiantes de primaria y
secundaria` (34), `exploring a novel functional marker candidate` (21).
These are not job titles at all, they are free text in a job-title field,
and no rule conditioned on words will tell them from a job. About 77 visible
records.

**BUILT 2026-11-10, AND THE BUILD FAILED. The test caught it.**

```
PASS=70  WARN=0  ERROR=1  SKIP=29
[ERROR] assert_title_patterns_do_not_collide — got 2 results, fail if != 0
```

Nothing landed. 29 downstream nodes were skipped, so every audience count
is still the pre-build figure and `analyses/40` query 3 returns the same
list — which is correct and not a second symptom: query 3 filters on
`model_title_group`, the model's choice *before* any pattern, and that does
not change when a pattern is added.

**What collided.** The eleven `librarian` rows are the only **unscoped**
patterns in the seed — one per script, `librar`, `bibliotec`, `bibliothek`,
`библиотек`, `kütüphane`, `図書館`, `图书馆` — and they claim any title
carrying a library stem anywhere in it. The 1.17 student row is scoped to
`researcher`. A title the model put in `researcher` naming **both** a
student and a library was claimed by two groups at once, and
`dim_title_group` resolves that with `min(title_group)` — it would have
picked `librarian` alphabetically and said nothing. The test exists for
exactly that.

**The fix is the shape the seed already uses.** The pharmacist-scoped rows
veto on the competing group's own word (`pharmacist|farmac`), so the
library stems are now in the student veto. A title naming a library keeps
the model's group and the librarian pattern claims it alone. **Librarian
wins, which is right**: a librarian doing a doctorate is still reachable as
a librarian, and `student` feeds no audience at all.

`analyses/41` is the test's own query without the HAVING, so a collision is
**named** rather than counted. Query 2 prints every pattern's actual reach,
which is how the next one gets read rather than hunted.

Re-tested both ways after the fix: 0 of 5 that must stay escape, 0 of 9
that must move are spared.

**BUILT 2026-11-10, SECOND ATTEMPT. IT LANDED.**

The three iterations of the veto, each reconciling exactly against
`records_the_veto_spared`:

| Veto | Titles | Records moved | Veto spared |
| --- | --- | --- | --- |
| as first written | 1,258 | 71,598 | 700,045 |
| prefix matching + six languages | 1,150 | 69,406 | 702,237 |
| **+ library stems (built)** | **1,078** | **68,317** | **703,326** |

69,406 − 68,317 = 1,089, and 703,326 − 702,237 = 1,089. Nothing fell
between the two.

**The forecast against the result, in people, which is what ships.**

| Audience | Confirmed | Change | My stated ceiling | |
| --- | --- | --- | --- | --- |
| **Researcher** | 333,289 | **−1,400** | 1,568 | under |
| **HCP researcher** | 53,597 | **−444** | 431 | **13 OVER** |
| **HCP broad** | 124,560 | −384 | 414 | under |
| Lecturer | 410,504 | **0** | 0 | — |
| HCP practitioner | 61,935 | 0 | 0 | — |
| Head of Faculty | 15,160 | 0 | 0 | — |
| HCP administrator | 7,566 | 0 | 0 | — |
| Pharmacist | 2,065 | 0 | 0 | — |
| Librarian | 699 | 0 | 1 | — |

Six audiences unchanged to the person is the check that matters: the rule
is scoped to `researcher` and nothing leaked sideways.

**THE CEILING WAS BREACHED AND THE CAUSE IS MY QUERY, NOT THE DATA.** I
wrote that query 2 was an upper bound and that coming in above it would
mean something other than the pattern had moved. It came in 13 over, and
the reason is that I compared `lower(evidence_title)` against
`dim_title_group.title`, which is **not** the same string.
`normalize_title()` casefolds under NFKC, then replaces every character
that is not a letter, number, space, `&`, `/`, `+` or `-` with a space,
then expands an abbreviation list. So `Ph.D. Fellow` normalises to `ph d
fellow` while `lower()` leaves `ph.d. fellow`, which matches no row at all.
**Every title carrying punctuation fell out of the ceiling**, so the ceiling
ran low by construction. `analyses/40` query 2 now reproduces the first two
steps of the normalisation and says plainly that the abbreviation expansion
is still missing, because its list lives in `dbt_project.yml` as a var and
an analysis file cannot read it.

**Records were 22.8% over forecast, and that cause was already known**:
68,317 against 55,646, because the pattern carries
`postgraduate|post graduate` and the regex that produced 55,646 did not.
The people figure is the one that was predicted correctly.

### 1.16a THE SPLIT IS GONE FROM THE PIPELINE TOO — 2026-11-10

On 4 November Merve closed 1.16: Researcher ships as **one audience**. On
10 November they went further:

> "researcher early ve researcher established diye ayirmiyoruz biz. bu
> pipeline da bu ayrim hic olmasin. bu mantigi lutfen cikart. sadece
> researchers olsun."

**And the answer to "does removing it make our work easier" is yes, with one
exception that had to be handled.**

**It was already dead weight.** Only two roles in `dbt_project.yml` ever
named the two groups, and **both listed them together**:

```
researcher        title_groups: ['researcher_early', 'researcher_established']
hcp_researcher    title_groups: ['researcher_early', 'researcher_established']
```

No audience has ever read them apart. The distinction existed only in the
dictionary, where it could be got wrong — and it was: **`junior researcher`,
42,949 records, the largest single error in this project's history, was a
title landing in the wrong one of two groups that mean the same thing to
every consumer.** Merging removes that failure mode by construction, and
with it the `needs_human_review` flags raised by titles that are genuinely
ambiguous between early and senior.

What changed, all of it mechanical:

| | early | established | now |
| --- | --- | --- | --- |
| `title_group_anchors.csv` | 13 | 9 | 22 under `researcher` |
| `role_title_overrides.csv` | 114 | 81 | 195 under `researcher` |
| `title_group_patterns.csv` | 3 | 3 | 6 under `researcher` |
| `dbt_project.yml` roles | 2 | 2 | `title_groups: ['researcher']` |

There is no hardcoded list of groups anywhere: `int_title_group_registry` is
derived from the anchors seed, so the registry merged itself.
`setup/validate_registry.py` passes.

**THE ONE EXCEPTION, and it is the 1.17 pattern written an hour earlier.**
That row was scoped to `researcher_early` *on purpose*, because the
established half is full of titles carrying `phd` as a credential rather
than as a status. Merging removes the group boundary that was protecting
them, so the protection now rests on the veto alone. Re-checked against the
25 largest such titles:

- **23 were already vetoed** — `phd scientist`, `group leader phd`, `senior
  consultant/md phd`, `director of phd program in medical sciences`
- `senior specialist / ph d eng` was not, so **`specialist` and `staff` were
  added to the veto**
- `senior doctoral scholar` was not, and **should not be** — it is a
  doctoral student and moving it is correct

`analyses/40` query 3 exists to catch any that this reasoning missed, and it
sorts by title LENGTH rather than frequency because a credential hiding
behind other words is exactly the shape that survives a word list.

**Two figures in the status document could not be merged honestly.** The
anchor counts in `charts.py` add — 6 + 2 = 8 — so that bar was merged. The
human-decision shares in `charts5.py` are percentages of different
denominators and do **not** add, so the two bars are now labelled as halves
and the figure is marked as predating the merge, pending a re-measure on the
next build.

### 1.17a What the doctoral-student rule costs — measured 2026-11-10

`analyses/38` query 3, inside `hcp_researcher` CONFIRMED. The four buckets
reconcile to **54,041 exactly**, which is the audience total, so nothing
escaped the classification:

| Bucket | People | Share |
| --- | --- | --- |
| names no student at all | 35,846 | 66.33% |
| **POSTDOC — not a student, stays** | 16,816 | 31.12% |
| student AND the title says research — stays under 1.17 | 1,106 | 2.05% |
| **student, title says NO research — 1.17 removes** | **273** | **0.51%** |

The hand reading of 100 people found one such person, `Pre-Doctoral Fellow`
at a school of public health, which is 1% against a measured 0.51% — the
same answer at n=1.

**273 IS NOT THE PRICE OF THE RULE, AND MUST NOT BE QUOTED AS IT.** It is
what the rule costs inside one audience. An override moves a title out of
`researcher_early` *everywhere*, and `researcher_early` also feeds
`researcher`, which is 334,689 people and has `disciplines: []` — no field
test at all. The number that decides whether 1.17 is cheap is the
project-wide one in `analyses/35` query 1, which has not been run since the
postdoc bucket was separated out of it. Writing an override before that is
exactly the mistake [[measure-before-tuning]] exists to prevent.

Worth keeping in view: **31% of this audience are postdocs**, and the whole
reason that bucket is printed rather than filtered is that the first version
of the student regex swept every one of them in, because `post-doctoral`
contains `doctoral`.

### 1.17b CLOSED 2026-11-10 — the loose reading, and one row written

Merve, on being shown the two prices:

> "gevsek okuma olsun research gecenleri elemeyelim illa researcher kelimesi
> harfi harfiyen olmasi gerekmiyor"

| Reading | What counts as "the title says research" | Records removed |
| --- | --- | --- |
| strict | only the noun `researcher` | 132,207 |
| **loose — CHOSEN** | **any research word** | **58,848** |
| | *the decision was worth* | *73,359* |

So `phd research fellow`, `student research assistant` and `doctoral research
fellow` stay. `phd fellow` (19,424 records), `predoctoral fellow` (5,358),
`ph d fellow` (2,113) and `pre-doctoral fellow` (1,522) leave.

**Written as one pattern row, not 1,191 overrides**, using the
`unless_pattern` veto column added on 5 November. The pattern names a
student, the veto keeps anyone whose title also says research.

**SCOPED TO `researcher_early` DELIBERATELY, and this is the part worth
reading.** The same bucket exists in `researcher_established`, 198 titles and
3,202 records, and the rule must NOT be applied there. Of its 25 largest
titles, **24 carry `phd` as a credential rather than as a status**:

> `phd scientist` · `group leader phd` · `senior consultant/md phd` ·
> `phd director` · `full professor phd hdr i2m laboratory` ·
> `director of phd program in medical sciences` · `deputy group leader pi/phd`

Applying 1.17 there would demote senior researchers on the strength of their
doctorate. Those 3,202 records are left alone on purpose.

The veto also carries the **entire postdoc family**, because every
`post-doctoral` title contains the word `doctoral`. That is 498,069 records —
64% of both research groups — and the first version of this regex swept all
of them in.

`analyses/40` is the forecast, written before the build so it can be wrong in
public, and it checks the two ways the row can fail: too wide, by taking a
credential hiding in a long title, and too narrow, by the veto firing on a
real student.

### 2.14 hcp_researcher read a third time — 94.3%, and the composition is the real evidence

A fresh 100 CONFIRMED people, drawn on a different hash so the sample is
not the one my own verdicts are anchored to, `analyses/46` query 2.

| Reading | n | Correct | Wrong | Not sure | **Correct of the decided** |
| --- | --- | --- | --- | --- | --- |
| 5 November | 400 | 81.2% | 9.0% | 9.8% | **90.0%** |
| 10 November | 100 | 81 | 10 | 9 | **89.0%** |
| **10 November, third** | 100 | **82** | **5** | **13** | **94.3%** |

**The move is +5.3 points and it is NOT statistically separable at n=100.**
Standard error of the difference is 4.1 points, z = 1.27, p ≈ 0.20. Anyone
quoting 94.3% against 89.0% as a proven improvement is over-reading two
samples of a hundred.

**The composition is the evidence, and it moved the way the fix predicts:**

| Error class | 10 Nov | Third reading |
| --- | --- | --- |
| the department is not human health | **4** | **2** |
| the title is not a research role | 4 | 3 |
| other | 2 | 0 |
| **total wrong** | **10** | **5** |

And the two field errors that survived are **fields we never anchored**:
`Institute of Vertebrate Paleontology and Paleoanthropology` at the Chinese
Academy of Sciences, and `Photometry and radiometry group` at the Korea
Research Institute of Standards and Science. Neither is agriculture,
physics, humanities or life sciences — the four families the 13 anchors
addressed. The anchored families produced **no** errors in this sample.

The three title errors are the unfixed class, unchanged: `Partnerships Team
Lead` at the CDC, `Director of Postgraduate Studies in Hip and Knee
Reconstructive Surgery`, and `Nurse Coordinator for Nursing Research
Support`. A team lead, a teaching post and a support role, none of them a
researcher, and nothing we have built touches any of them.

**NOT-SURE WENT UP, 9 to 13, and that is a finding rather than noise.**
Four of the thirteen are a job title that is the single word `Fellow` — at
Pulmonary and Critical Care, Pediatrics, Otolaryngology and Neurology, all
American teaching hospitals, where it means a physician in subspecialty
training. That is 1.9, and it is now the largest single uncertainty in this
audience.

**And two are a department that is a non-word**: one person's department is
literally `Institute` and another's is `IBGA Lab`. That is the generic
container problem from 2.12 arriving on the person level — 1.9 asked of the
department axis instead of the title.

The rest: two industry researchers (Novo Nordisk, 1.2), one veterinary
institute (1.18), one sport science department (1.19), one `Collaborator`,
one `Borsisti`, one clinical subspecialty fellow. **Every one of them is an
open definition question rather than a defect**, which is the state this
audience should be in.

### 2.13 Reachable was reported at a third of its size for a month — 2026-11-10

Merve: *"ben coktan book legitimate interest ve legitimate interestlerin
alinmasi gerektigini soylemistim reachable audience a"*.

Correct, and **the pipeline had done it since 16 October**. `dbt_project.yml`
sets `consent_basis: 'any_basis'`, `consent_predicate()` unions the bases,
and `fct_role_audience_summary.reachable` counts the union — its own header
says *"REACHABLE IS ANY OF THE THREE, from 2026-10-16. It was the two
opt-ins only; legitimate interest is a third legal basis and was being
ignored."*

**The data was right and my reporting was wrong.** `analyses/37` query 2
counted `mkt_pref_opt_in` alone off the raw layer, re-deriving a narrower
number instead of reading the model built to answer the question:

| Audience | As reported | Actually reachable | |
| --- | --- | --- | --- |
| Lecturer | 109,323 | **319,291** | 2.9× |
| Researcher | 64,618 | **237,391** | 3.7× |
| HCP broad | 26,436 | **93,377** | 3.5× |
| HCP practitioner | 13,930 | **46,450** | 3.3× |
| **HCP researcher** | 9,668 | **39,758** | **4.1×** |
| Head of Faculty | 4,582 | **11,962** | 2.6× |
| HCP administrator | 2,050 | **5,949** | 2.9× |
| Pharmacist | 526 | **1,531** | 2.9× |
| Librarian | 177 | **384** | 2.2× |

Legitimate interest is the whole gap: 295,314 of Lecturer against 109,323
with marketing consent.

**And it corrected a claim that was wrong the other way.** Section 10.3 said
*"between 18% and 30% of any audience can be emailed, and that share is
falling"*. It is **71% to 79%**, and 54.9% for Librarian. The observation
that confirmed people grew while contactable people did not was measured on
the narrow column and is withdrawn rather than restated.

**Book-author consent is now the fourth legal basis** — Merve's own
decision, *"book author consent kesinlikle sayiliyor, they dont need to
confirm"* — and **26,654 people hold it**. It was in the CDP source all
along and simply not selected.

**One thing I did and should not have.** While adding it I also selected
three other consents from the same source — editor referral, editorial
board, webshop buyer — carried them through the models and put them in the
summary as counted columns. Nobody asked for them. Merve: *"bunlari hesaba
katma ben bunlari senden istemedim niye kolon olarak ekleyip kafa
karistiriyorsun?"* Removed from `raw_audience_builder_big`,
`fct_role_audience`, `fct_role_audience_summary` and `analyses/37`; the
pipeline reads five columns from that source, not eight.

The one figure worth keeping from the detour, so nobody has to go and get
it again: those three reach **251 people** that nothing else reaches, 0.033%
of the 756,093 reachable. Nothing turns on them.

`analyses/37` query 2a does the same for the four that ARE a basis, and its
`only_book_author` column decides whether marketing question 5 was ever
material: if every book author already holds another basis, the question is
moot whichever way it is answered.

### 2.12 Two anchors describe a building, not a field — 2026-11-10

`analyses/39` was written to confirm that the wrong healthcare departments
are a **missing-anchor** problem. It confirmed that for one family and found
something else for the other four.

Query 2 named the anchor holding each family inside `health_clinical`:

| Family | Visible records | From `faculty of medicine` / `school of medicine` | |
| --- | --- | --- | --- |
| sport | 46,838 | 39,149 | 84% |
| plants | 13,878 | 1,013 | 7% |
| veterinary | 8,350 | 5,497 | 66% |
| physics | 3,958 | 2,621 | 66% |
| humanities | 3,539 | 3,539 | **100%** |
| **total** | **76,563** | **51,819** | **68%** |

**Two defects wearing one symptom, and they want opposite fixes.**

**PLANTS is a field collision** and the missing-anchor diagnostic holds. 93%
of it is held by the `pathology` anchor — a real clinical field word that
`Plant Pathology` happens to contain. Query 3 says the separation is clean:
inside `health_clinical`, the **21** plant-ish pathology departments sit at
0.694 mean similarity and the **1,477** genuinely clinical ones at 0.747.
One `earth_agriculture` anchor should take the 21 and leave the 1,477.

**THE OTHER FOUR are a structural magnet.** `faculty of medicine` and
`school of medicine` are four words of which two — `faculty of` — carry no
field at all. Any department written as *Faculty of anything* sits close to
them: `Faculty of Veterinary Medicine`, `Faculty of Sport and Health
Sciences`, `Faculty of Arts and Humanities`. **Adding a plant or a physics
anchor does nothing for these**, because the magnet is not about the field,
it is about the shape of the name. Humanities is 100% this.

This is the project's own documented failure mode, one dictionary over.
2.4f: a short anchor attracts its spelling rather than its meaning. The
`pathologist` finding: how crowded the neighbouring region is predicts a
magnet, not the suffix. **Here the crowded region is every faculty in every
university.**

One more sighting worth recording: German physics institutes are held by
`klinik fur innere medizin` — 1,968 records across
`Physikalisches Institut` and its variants. Same mechanism in a second
language, and the German anchor was added for a clinical reason.

**REMOVING THE TWO ANCHORS IS NOT FREE, which is why this is a measurement
and not a commit.** Departments literally named `Faculty of Medicine` are
genuinely clinical and there are many. `analyses/42` asks the question that
decides it: of the departments held ONLY by those two anchors, how many
name medicine and would be lost, how many name something else and are the
error, and what the runner-up discipline would be — because if the
runner-up is already correct, removal alone fixes them and no new anchor is
needed.

**MEASURED 2026-11-10, AND MY CLASSIFICATION WAS WRONG — FOURTH TIME TODAY.**

`analyses/42` query 1 split the population with a regex for
`medicine|medical|clinic|klinik|surg|hospital`. The output opened its
"names something else — this is the ERROR" bucket with:

| Department | Records |
| --- | --- |
| `school of nursing` | 29,373 |
| `school of public health` | 26,227 |
| `department of neurology` | 19,903 |
| `department of psychiatry` | 18,890 |
| `department of pediatrics` | 13,519 |
| `department of radiology` | 12,016 |
| `department of cardiology` | 11,519 |

All unambiguously clinical, all in the error bucket, because none of them
contains the word *medicine*. **243,927 records in the first 28 rows alone,
every one correctly placed.** The list left out neurology, cardiology,
nursing, psychiatry, pediatrics, radiology, pathology, dentistry, oncology,
urology, epidemiology, dermatology, anesthesiology, nephrology,
rheumatology, endocrinology, geriatrics, ophthalmology, gastroenterology,
hematology and public health.

**Fourth time in one day for the same mistake**: a word list narrower than
the data it is asked about. `analyses/38` matched `ecolog` inside
*gynecology*; the 1.17 veto recognised a student in six languages and
excused one in English, twice. **The lesson is to stop classifying.**

**The number the query did get right, and it is small.** `also_held_by_others`
answers the real question without any vocabulary:

| | Departments | Also held by another anchor | **Sole support** |
| --- | --- | --- | --- |
| names medicine | 19,510 | 18,999 | **511** |
| names something else | 16,574 | 15,268 | **1,306** |
| veterinary | 100 | 73 | **27** |
| | | | **1,844** |

So those two anchors are the **sole support of 1,844 departments out of the
36,184 that match them at all**. Everything else is anchored by its own
field and cannot move whatever happens to `faculty of medicine`.

`analyses/43` uses a structural criterion that needs no vocabulary — *a
department whose only matched anchors are the two faculty/school ones has
nothing field-specific holding it, by construction* — and then **lists**
them, because 1,844 rows can be read and a regex over all clinical
vocabulary evidently cannot be written.

**One risk its query 2 exists for.** `pharmacy` was the runner-up for 7,884
departments and 629,116 records across the whole matching population.
Pharmacist is the only audience keyed on the pharmacy discipline, so a
department landing there does not merely leave healthcare — **it joins
Pharmacist.** If pharmacy is large among the 1,844, removal is not safe on
its own and the fix needs an anchor on the receiving side too.

**MEASURED 2026-11-10, `analyses/43`. THE LIST SETTLES IT: THOSE TWO
ANCHORS ARE HOLDING UP A FACULTY DIRECTORY, NOT A CLINICAL ONE.**

The 15 largest departments whose **only** support is `faculty of medicine`
or `school of medicine`:

| Records | Department | Would become |
| --- | --- | --- |
| 21,738 | `school of life sciences` | physical_chemistry |
| 9,883 | `faculty of science` | engineering |
| 3,947 | `faculty of veterinary medicine` | life_biomedical |
| 3,378 | `faculty of sciences` | engineering |
| 3,318 | `department of biomedicine` | life_biomedical |
| 2,749 | `facultad de ciencias` | physical_chemistry |
| 2,633 | `faculty of biology` | life_biomedical |
| 2,284 | `faculty of sport and health sciences` | engineering |
| 2,218 | `faculty of sport sciences` | engineering |
| 1,895 | `faculty of life sciences` | life_biomedical |

Further down: `faculty of natural sciences`, `faculty of humanities and
arts`, `faculty of arts and humanities`, `faculty of music`, `department of
musicology`, `faculté des sciences`, `doctoral school`, `facultad de
postgrado`, `academic committee of the university`, `rector's office`,
**`rektörlük`**, and `assistant professor doctor` — a job title typed into
the department field.

**Not one of the top rows is a clinical department.** The two anchors are
matching the phrase *faculty of*, exactly as predicted, and what they hold
up on their own is a directory of faculties and administrative units.

**BUT REMOVAL IS NOT THE FIX, AND THE DESTINATION COLUMN IS WHY.**

| Would become | Departments | Records | |
| --- | --- | --- | --- |
| engineering | 341 | 37,375 | feeds nothing |
| life_biomedical | 443 | 33,451 | feeds nothing |
| physical_chemistry | 125 | 32,225 | feeds nothing |
| **pharmacy** | **270** | **12,525** | **feeds Pharmacist** |
| humanities_law_edu | 96 | 5,870 | feeds nothing |
| everything else | 113 | 5,522 | feeds nothing |
| | **1,388** | **126,968** | |

90% of it lands in a discipline that feeds no audience, so the move is free.
**The other 10% does not leave healthcare — it JOINS Pharmacist.** And the
departments going there are not pharmacy by any reading: `department of
experimental medicine` (1,856), `faculty of agriculture and life sciences`
(448), `biochemistry faculty of medicine` (252), `faculty of ayurveda`
(108), `faculty of naturopathy and yogic sciences` (182). Removing the two
anchors would trade 114,443 records of correct removal for **12,525 records
of brand-new error in a live audience.**

**THE RULE THIS ESTABLISHES, which is worth more than the fix: ADDING AN
ANCHOR IS SAFER THAN REMOVING ONE.** Adding puts a department where we
chose. Removing sends it wherever happens to be second, and second is
`pharmacy` for 270 departments because the pharmacy anchors sit close to
the clinical ones. The same logic applies to every future anchor removal in
this project.

**So the proposal is to add, not remove**, and the two faculty anchors stay
until the families that collide with them are anchored on their own merit:

| Add to | Anchors |
| --- | --- |
| `life_biomedical` | `school of life sciences`, `faculty of life sciences`, `faculty of biology`, `department of biomedicine`, `biomedical sciences` |
| `earth_agriculture` | `plant pathology`, `fisheries`, `aquaculture`, `crop science` |
| `physical_chemistry` | `physikalisches institut`, `institut für theoretische physik` |
| `humanities_law_edu` | `institut für philosophie`, `faculty of arts and humanities` |

Sport and veterinary are deliberately absent — they are 1.18 and 1.19 and
belong to marketing.

**APPROVED AND WRITTEN 2026-11-10.** Merve: *"onayliyorum evet"*. 13
anchors added, 162 → 175. `faculty of medicine` and `school of medicine`
stay.

| Discipline | Added |
| --- | --- |
| `life_biomedical` | `school of life sciences`, `faculty of life sciences`, `faculty of biology`, `department of biomedicine`, `biomedical sciences` |
| `earth_agriculture` | `plant pathology`, `fisheries`, `aquaculture`, `crop science` |
| `physical_chemistry` | `physikalisches institut` [de], `institut fur theoretische physik` [de] |
| `humanities_law_edu` | `institut fur philosophie` [de], `faculty of arts and humanities` |

**The single most useful fact in this whole thread is one line of that
table.** `life sciences` has been an anchor in `life_biomedical` since the
seed was written, and `school of life sciences` — 21,738 records, the
largest single department in the problem — **still lost to the faculty
magnet at 0.809 similarity**. A correct field anchor was already present
and was beaten by the phrase `school of`. That is the proof that the magnet
is structural and not a gap in the vocabulary.

Two choices inside the batch worth stating:

- **`department of biomedicine` and `biomedical sciences` go to
  `life_biomedical`, not `health_clinical`.** 1.2 is open and marketing's
  working answer is that a biomedical researcher is not a healthcare
  professional. This follows that answer rather than pre-empting it, and
  reverses in one row if marketing says otherwise.
- **The German anchors are written without umlauts** — `institut fur
  theoretische physik`, `institut fur philosophie` — because `clean_text`
  casefolds under NFKC and strips them before matching.

`analyses/44` is the forecast, before the build, and it checks the two ways
this goes wrong. **Query 2 lists the clinical departments the new anchors
must NOT steal** — `department of pathology` at 11,640 records is the sharp
one, and `plant pathology` must separate from it on the 0.694 / 0.747 gap
measured in `analyses/39`. **Query 3 runs after the build and asks whether
each new anchor won anything at all**: an anchor holding zero departments
would mean an exact phrase does not beat `faculty of medicine`, and that
the add-not-remove approach does not work on this axis.

**BUILT 2026-11-10. IT WORKED, AND IT DID NOT DO WHAT I EXPECTED TO THE
AUDIENCE COUNTS.**

**The defensive anchors held perfectly.** Every clinical pathology
department stayed in `health_clinical`, and three of them now match at
exactly 1.000 where they sat at 0.775–0.848 before:

| Department | Records | Similarity |
| --- | --- | --- |
| `pathology` | 52,784 | 1.000 |
| `department of pathology` | 11,640 | 0.848 → **1.000** |
| `department of pathology and laboratory medicine` | 1,539 | 0.775 → **1.000** |
| `institute of pathology` | 1,411 | 0.801 → **1.000** |
| `clinical pathology` | 1,989 | 0.887 |
| `department of clinical pathology` | 142 | 0.806 → 0.952 |

Nothing clinical was lost. **And the intended departments moved:**
`school of life sciences` 21,738 records from health_clinical 0.809 to
life_biomedical **1.000**, `department of biomedicine` 3,318 to 1.000,
`faculty of biology` 2,633 to 1.000, `school of biomedical sciences`
5,102 to life_biomedical.

**85% of the wrong population is gone:**

| Family | health_clinical before | after | |
| --- | --- | --- | --- |
| life sciences and biomedicine | 79,878 | 5,920 | **−93%** |
| plants | 14,047 | 5,029 | −64% |
| fisheries | 1,803 | 242 | −87% |
| humanities and arts | 6,792 | 1,956 | −71% |
| physics | 6,067 | 3,389 | −44% |
| **total** | **108,587** | **16,536** | **−85%** |

`pharmacy` lost 4,620 records of the same families as well, which is a
gain nobody asked for — it is the one receiving discipline that feeds an
audience.

**AND NOW THE PART I DID NOT PREDICT.** The four healthcare audiences
**grew**:

| Audience | Confirmed | Change |
| --- | --- | --- |
| HCP broad | 124,982 | **+422** |
| HCP researcher | 54,016 | **+419** |
| HCP practitioner | 61,945 | +10 |
| HCP administrator | 7,563 | −3 |
| Lecturer | 410,499 | −5 |
| Researcher | 333,280 | −9 |

Removing wrong departments should shrink them. The arithmetic explains
it and it is the defensive anchors doing it:

```
discipline_score = 0.70 + (similarity − 0.65) / 0.35 × 0.30

department of pathology    sim 0.848 → dept_score 0.870
                           sim 1.000 → dept_score 1.000
```

By anchoring `department of pathology` exactly, its 11,640 records went
from 0.870 to **1.000** on the discipline axis, and that lift carried
people over thresholds who were previously below. **Two effects netted
inside one number**: wrong-field people left, and genuinely clinical
people gained confidence. The net is +419, so the second is larger than
the first.

That is a better outcome than the one forecast, but the net figure hides
both halves, and **the removal is therefore unverified at the person
level.** `analyses/38` query 1 run again would show it — the department
list inside hcp_researcher should no longer open with `Plant Pathology`.

**One question this exposes and cannot answer: there is no discipline for a
generic container.** `faculty of science`, `faculty of sciences`,
`facultad de ciencias`, `doctoral school`, `rektörlük` name no field at
all, and every one of the twelve disciplines is a field. Whatever we anchor
them to is arbitrary. It does not matter commercially today, because every
candidate except `pharmacy` feeds nothing — but it is the same shape as
1.9, *is an uninformative title acceptable evidence*, asked of the
department axis instead.

**Also unresolved and now visible:** `zoonoses` departments split almost
exactly in half between `health_clinical` (40 departments, 910 records) and
`life_biomedical` (40, 862). The same kind of department landing in two
disciplines is arbitrary either way, and only one of those two feeds an
audience.

### 1.18 Are veterinarians healthcare professionals? — ASKED 2026-11-10

Found while reading 100 CONFIRMED `hcp_researcher` people by hand. Veterinary
departments read as `health_clinical`, so vets are in the healthcare audiences
today. **Nobody decided this.** It happened because veterinary medicine is
medicine and the word carries.

| Department | People |
| --- | --- |
| `Faculty of Veterinary Medicine` | 43 |
| `School of Biodiversity, One Health and Veterinary Medicine` | 14 |
| `Veterinary Pathology` | 13 |
| `Veterinary Public Health` | 7 |
| `Veterinary Epidemiology` | 2 |
| others | 12 |

**91 is a floor.** Counted inside `hcp_researcher` CONFIRMED only, from a
truncated list. The same departments feed `hcp_broad` and `hcp_practitioner`,
so the figure across healthcare is larger and has not been measured.

For: a vet is a regulated clinician who diagnoses, prescribes and operates,
and reads clinical literature to do it. Against: every other audience here is
defined by treating people, and a campaign about patient outcomes or hospital
practice does not apply to a vet. Hard case either way: *One Health*
departments, 14 people, whose subject is by definition the intersection.

Working answer **no**, consistent with 1.11. One line to change.

### 1.19 Is sport and exercise science a healthcare field? — ASKED 2026-11-10

Same reading, same day, and this one splits down the middle of its own
vocabulary.

| Department family | People | Reads as |
| --- | --- | --- |
| `Sports Medicine`, `Institute of Sport and Exercise Medicine` | ~25 | clinical |
| `Faculty of Sport Sciences`, `Department of Sport Science` | ~45 | not clinical |
| `Physical Education and Sports` | 6 | not clinical |
| `Faculty of Sport and Health Sciences` | ~35 | both words in one name |

A sports physician treats patients; a sport scientist studies performance.
The third family names both at once, which is why this needs a line drawn
rather than a judgement per department. Working answer: **keep the ones that
say *medicine*, drop the rest** — the work, not the subject, same test as
1.11. Also a floor, same reason as 1.18.

### 1.20 A plant pathologist is a researcher — and that is not the question

Merve, on being shown the department list, 2026-11-10:

> "alan farketmeksizin bir kisi her turlu researcher olabilir ki? yani plant
> pathology alaninda research yapiyor olabilirler. bunlari neden elemek
> gerekiyor anlamadim"

**The objection is right and the project already agrees with it**, which is
worth recording because the answer is in the config rather than in anything
written down:

| | `researcher` | `hcp_researcher` |
| --- | --- | --- |
| disciplines | `[]` — none | `['health_clinical']` |
| match | `title_required` | `title_and_field` |
| weights | role 0.75, org 0.25, **dept 0.00** | role and dept equal |
| confirmed at | 0.60 | — |

A research title alone scores 0.75 against a threshold of 0.60, so **anyone
whose title says research is CONFIRMED in Researcher, in any field**. That is
the audience that does not care about the field, and it is 334,689 people.
`hcp_researcher` is not a second Researcher — it is the research arm of
`hcp_broad`, and its whole definition is a research title **and** a clinical
field.

**Measured rather than asserted**, analyses/38 query 6, on the 436 people in
the agriculture, physics and humanities themes:

| | People |
| --- | --- |
| in `hcp_researcher` on a non-health department | **436** |
| of those, also CONFIRMED in `researcher` | **436** |
| also in `lecturer` | 141 |

Every one of them keeps their place in Researcher. Correcting the department
removes nobody from anything except the healthcare family, which is where
they do not belong.

The defect is one layer below the audience: `dim_department_discipline` reads
`Plant Pathology` as `health_clinical` because `pathology` is one of the
strongest clinical words there is, and the embedding matched the word rather
than the field. The correction is to the discipline, not to the role, and it
moves `hcp_broad`, `hcp_practitioner`, `hcp_researcher` and
`hcp_administrator` together while leaving `researcher` and `lecturer`
untouched.

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

That constraint was written before anything was measured, and it was then
put to the test by a direct proposal to make an education record the gate
for the Students audience. It held, and the figures are in **2.16**.

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

### 2.10 Raising a threshold was measured and rejected — 2026-11-04

Merve asked the sharpest version of the question this project has had:

> "coverage ve cok audience olmasi onemli degil sadece emin oldugumuz
>  kisileri alalim. belki thresholdu arttirmak bunu cozer educationsa
>  bakmadan?"

Coverage is not the objective, certainty is. Measured in full by
`analyses/34_threshold_cost.sql`, and the answer is **no threshold moved**.
Three findings, in the order they overturn the idea.

**1. THE SINGLE-AXIS POPULATION IS NOT IN HEALTHCARE. IT IS IN ACADEMIA.**
For every CONFIRMED person, remove one axis at a time and ask whether they
still clear the threshold:

| Audience | One axis is enough | Two or more axes required |
| --- | --- | --- |
| lecturer | **372,841 (92.3%)** | 31,220 |
| researcher | **295,719 (89.7%)** | 34,131 |
| librarian | **687 (100%)** | 0 |
| hcp_broad | 0 | 129,373 (100%) |
| hcp_practitioner | 0 | 60,945 (100%) |
| hcp_researcher | 0 | 53,290 (100%) |
| hcp_administrator | 0 | 7,580 (100%) |
| faculty_head | 0 | 18,918 (100%) |
| pharmacist | 0 | 2,287 (100%) |

Every clinical audience is fully corroborated: not one CONFIRMED person in
hcp_broad, hcp_practitioner, hcp_researcher or hcp_administrator is carried
by a single axis. **faculty_head is structurally incapable of it** — its title
weight is 0.60 against a threshold of 0.65, so the title alone can never
confirm, and all 18,918 need the organisation as well.

Read "one axis is enough" correctly: it means the second axis is not
LOAD-BEARING, not that it is absent. A lecturer scoring 1.000 has a perfect
title AND a perfect organisation; either alone would have sufficed.

**2. AND A THRESHOLD CANNOT REACH THEM ANYWAY, because the mass sits at the
maximum.** A weighted sum of three bounded axes is discrete, not smooth:

| Audience | People at exactly 1.000 | Share |
| --- | --- | --- |
| lecturer | 250,601 | 62.0% |
| researcher | 122,895 | 37.3% |
| librarian | 687 | 100% |
| faculty_head | 6,843 | 36.2% |

There is no number between 0.60 and 1.00 that removes a person scoring 1.000.
Pushing lecturer to 0.85 drops 11.3% and to 0.95 drops 35.9%, and what it
drops is the unconfident long tail — the opposite of the target.

**librarian's threshold is completely inert.** All 687 score exactly 1.000, at
every candidate from 0.60 to 0.95, because the group is 99.9% PATTERN-decided
and the role is weighted 1.00 title / 0.00 org. Librarian quality cannot be
managed by a threshold at all; the only lever is the pattern list. This is the
mechanical explanation for 2.6.

**3. THE ONE PLACE IT WOULD HAVE WORKED, AND WHY WE STILL DID NOT.**
hcp_broad is the only `title_or_field` role, and 1.00*0.35 + 1.00*0.25 = 0.60
is exactly its confirmed threshold. On its own rows, excluding roll-ups:

| Route | People | Share | Marketable | Score range |
| --- | --- | --- | --- | --- |
| all three axes present | 31,269 | 80.2% | 6,949 | 0.680–1.00 |
| **discipline only — no clinical title at all** | **6,115** | 15.7% | 1,445 | **0.60–0.65** |
| **title + org — no department** | **1,624** | 4.2% | 313 | **exactly 0.60** |

7,739 one-legged people, all of them inside a 0.05-wide band, of whom only
1,758 are marketable — 6.3% of hcp_broad's reachable total. A threshold of
0.66 would have cut almost exactly this band. Merve's call was to leave it:
the gain is 1,758 contacts of 27,977 and the audience is `hcp_broad`, whose
entire purpose is to be the wide net. **Recorded so the next person does not
re-derive it.**

**A CORRECTION TO SOMETHING I ASSERTED BEFORE MEASURING IT.** I warned that
533 human overrides and 21 patterns force `group_score` to 1.00 and so clear
any threshold, implying the forced population was the obstacle. Measured, it
is small nearly everywhere: HUMAN and PATTERN together are **0.3%** of
teaching_academic records, 1.0% of practitioner, 3.2% of researcher_early,
7.7% of researcher_established and 7.9% of leadership. The exception is
librarian at **99.9% PATTERN**, which is the same fact as finding 2. And the
`role_score = 1.00` populations in the other audiences — 65.8% of lecturer —
are overwhelmingly VECTOR titles that match an anchor EXACTLY: `professor` is
itself an anchor, so its similarity is 1.0 by definition, not by decision.

**WHAT IS LEFT OF THE IDEA.** For lecturer and researcher the lever is not a
higher number, it is a FLOOR ON THE SECOND AXIS — declining to confirm a title
whose organisation is UNKNOWN-typed, which scores 0.25. That is a rule change,
not a threshold change, and it has not been costed. It is the only live
descendant of this question.

And `sim_floor` = 0.65 was not costed and must not move, for the reasons in
2.4b and 1.10: raising it deletes correct VERBOSE titles and keeps wrong short
ones. `junior researcher` was wrong at 0.870 while 34 titles of genuine
faculty leadership sat at 0.567–0.649.

### 2.11 The job title is now mandatory for HCP broad — 2026-11-04

**Merve, on reading analyses/34 query 5:**

> "klinik unvan yoksa asla alma iceri - job title bu projede en onemli kolon"

`hcp_broad` was the only role using `match: title_or_field`, where the title
OR the department was enough. Measured before changing anything, on its own
CONFIRMED rows excluding roll-ups:

| Route | People | Share | Marketable |
| --- | --- | --- | --- |
| all three axes present | 31,269 | 80.2% | 6,949 |
| **discipline only — no clinical title at all** | **6,115** | 15.7% | 1,445 |
| title + org — no department | 1,624 | 4.2% | 313 |

Those 6,115 were in a healthcare audience **purely because their department
read as clinical** — an administrator in a cardiology department, a lab
manager in oncology. The mode is now `title_required`, so they leave.
1,445 marketable contacts go with them.

**The 1,624 STAY, and that is deliberate.** They hold a clinical title with
no department recorded, and they all sit at exactly 0.60 because
1.00*0.35 + 1.00*0.25 is exactly the threshold. The title is the evidence and
11.6% of records carry no department at all, so requiring one would discard
people we are sure about to remove people we are not. Merve's instruction was
about the title being mandatory, not about the department becoming mandatory.

`title_or_field` is now used by no role. It is kept in the registry because
the wide-net argument may be wanted again, and because deleting it would make
the two surviving modes look like the only choices ever considered.

**BUILT 2026-11-04. THE FORECAST AGAINST THE RESULT.**

| | Forecast | Actual | Off by |
| --- | --- | --- | --- |
| hcp_broad CONFIRMED | 123,258 | **124,223** | +965 |
| hcp_broad marketable | 26,532 | **26,790** | +258 |
| rows with no clinical title | 0 | **0** | — |
| title but no department | ~1,624 | **1,808** | +184 |

The CONFIRMED forecast held to within 0.8%, and the overshoot is not ours: the
same build grew **every** audience — lecturer +2,799, researcher +2,176,
hcp_practitioner +476, hcp_researcher +331 — which is the underlying data
refreshing, not this change. Netted against ~7,080 of organic growth the
change removed what it was predicted to remove. The 1,808 that had to survive
survived, and grew with the data rather than moving.

**AND ONE THING I DID NOT FORECAST, which is the larger number of the two.**
hcp_broad's PROBABLE tier fell **107,896 to 37,031, a drop of 70,865**. The
forecast only considered CONFIRMED and should not have. The arithmetic is
obvious in hindsight: hcp_broad's probable threshold is 0.30 and a clinical
department alone scores 1.00 × 0.40 = 0.40, so **every** person with a clinical
department and no clinical title whatsoever was PROBABLE in a healthcare
audience. It costs nothing commercially — only CONFIRMED ships — but it is
two thirds of that tier and anyone reading total audience size will see it.

**WHAT QUERY 3 FOUND, WHICH IS A DIFFERENT PROBLEM THE FIELD ARM WAS HIDING.**
The people who left are not administrators. Read against the sub-audience
counts, which all went UP, three groups behave differently:

- `researcher_early` / `researcher_established` and `leadership` titles in a
  clinical department **keep their healthcare coverage** through hcp_researcher
  and hcp_administrator. `Research Fellow`, `Postdoctoral Fellow`, `Director`,
  `Head of Department`, `Dean` are retained, not lost.
- `teaching_academic` titles reach **no** healthcare audience, and this is where
  the real cost sits.
- `student` and unassigned titles reach nothing at all.

And inside teaching_academic there is a family that is unmistakably clinical,
counted from the visible top 200 alone so these are floors, not totals:

| Title | People |
| --- | --- |
| `Clinical Assistant Professor` | 706 |
| `Clinical Associate Professor` | 331 |
| `Clinical Instructor` | 311 |
| `Clinical Professor` | 245 |
| `Professor of Medicine` | 238 |
| `Assistant Professor of Medicine` | 234 |
| `Clinical Lecturer` | 148 |
| `Associate Professor of Medicine` | 122 |
| `Assistant Clinical Professor` | 95 |
| `Clinical assistant professor` | 86 |
| **at least** | **2,516** |

Plus `Medical Student` and `Medical student`, **1,979 people**, which is what
`trainee_clinical` exists for; and bare `M.D.` / `M.D`, **511 people**,
unassigned, in clinical departments at 0.88 — the `dr`/`md` problem of 1.9
appearing in person.

**THIS IS NOT AN ARGUMENT TO PUT THE FIELD ARM BACK**, which would readmit the
6,115 administrators along with them. It is an argument for a narrow
title-based fix, and it is the **strongest evidence yet for Merve's position on
1.10**: a Clinical Assistant Professor in a School of Medicine is genuinely
both a lecturer and a clinician, and one-title-one-group is what forces us to
choose. The field arm was papering over that choice; removing it made the
choice visible.

Nothing is fixed from this list yet, because the counts above are floors read
off a truncated query. Sizing it properly is the first thing to measure.

**A SECOND, LARGER PROPOSAL IS NOT IMPLEMENTED.** Merve also suggested that
hcp_broad hold nothing but its children:

> "bu kolon sadece hcp nin alt gruplari olan 3 grubu icersin bence"

That is coherent — it would make hcp_broad a pure union and remove the
one-legged question permanently — but it is bigger than it looks and has not
been sized. Two things to establish first. hcp_broad has **four** children,
not three: hcp_practitioner, hcp_researcher, hcp_administrator **and
pharmacist**, which rolls up as PRACTITIONER. And with the title now
mandatory, hcp_broad's remaining own rows overlap hcp_practitioner almost
exactly — same title groups, same discipline, different weights and
threshold — so the real question is whether hcp_broad still earns its own
matching at all, or has become a roll-up with a redundant extra arm.
`analyses/35` query 4 sizes it: how many CONFIRMED people hcp_broad would
keep on roll-ups alone, and how many exist ONLY through its own rows.

### 2.12 Every audience read by hand — 2026-11-05

The survey cannot reach Pharmacist or Librarian and cannot separate the
healthcare sub-audiences, so each audience was measured a third way: 400
CONFIRMED people at random per audience (seed `val_2026_11` on
`farm_fingerprint(snid)`, so the draw is reproducible; all 692 librarians),
each read - title, organisation, department - and marked CORRECT, INCORRECT
or NOT_SURE. NOT_SURE means one of two things only: a definition marketing has
not settled (psychologists 1.4, genetic counsellors and medical physicists
1.5, veterinarians - a new one, see below - and the bare `director` of 1.3),
or a record too thin to decide.

| Audience | Correct | Wrong | Not sure | Correct of decided | Wrong people, est. |
| --- | --- | --- | --- | --- | --- |
| Researcher | 96.8% | 1.0% | 2.3% | **99.0% ± 1.0** | ~3,300 |
| Lecturer | 98.2% | 1.2% | 0.5% | **98.7% ± 1.1** | ~5,100 |
| Librarian (all 692) | 97.1% | 1.4% | 1.4% | **98.5%** | 10 |
| HCP practitioner | 82.0% | 5.8% | 12.2% | 93.4% ± 2.6 | ~3,500 |
| HCP broad | 81.5% | 8.5% | 10.0% | 90.6% ± 3.0 | ~10,600 |
| HCP researcher | 81.2% | 9.0% | 9.8% | 90.0% ± 3.1 | ~4,800 |
| HCP administrator, before 2.15 (re-scored, see 2.15) | 80.2% | 10.0% | 9.8% | 88.9% ± 3.2 | ~760 |
| **HCP administrator, after 2.15** (fresh sample, `val_2026_11b`) | 88.0% | 4.8% | 7.2% | **94.9% ± 2.2** | ~360 |
| Head of Faculty, before 2.13 | 39.2% | 18.8% | 42.0% | 67.7% ± 6.0 | ~3,500 |
| **Head of Faculty, after 2.13** (fresh sample, `val_2026_11b`) | 56.2% | 11.2% | 32.5% | **83.3% ± 4.4** | ~1,700 |
| Pharmacist, before 2.14 | 72.0% | 16.0% | 12.0% | 81.8% ± 3.7 | ~370 |
| **Pharmacist, after 2.14** (fresh sample, `val_2026_11b`) | 82.5% | 3.8% | 13.8% | **95.7% ± 1.9** | ~80 |

What each one found:

- **Pharmacist collects pharmacologists.** 47 of 64 errors are professors of
  pharmacology, pharmacognosy or pharmaceutics, and clinical pharmacologists.
  The calibration warning from the start of the project ("Pharmacologist
  scores 0.953 against pharmacist anchors") is still live. 26 of the 48
  not-sure are professors of pharmacy practice - a definition for marketing.
- **HCP administrator confirms industry medical directors** - Pfizer,
  Novartis, GSK, UCB, 11 of 41 errors. Title + clinical department clear the
  threshold with the organisation at 0.2.
- **HCP researcher** loses 9% to fields that are not clinical: veterinary
  epidemiology, plant pathology, physics institutes, and the basic biomedical
  departments the 1.2 decision excludes.
- **HCP practitioner**: 23 errors in 400 - researchers, public-health and
  policy posts (a WHO consultant, an EPI officer, `senior consultant` at a
  government think tank - the adviser sense of 1.1's consultant problem),
  students, industry. **Veterinarians are a new definition question**:
  `veterinarian` is a practitioner anchor on purpose (2,684 vets were reaching
  DENTIST), but whether a vet is a healthcare professional was never asked.
- **Librarian's** 10 errors are the literal pattern reading a library that is
  not one: `scientist dna-encoded library technology`, `crypto library
  developer`, `game librarian`, plus two emeritus.
- **HCP broad** has no errors of its own; all arrive through its children.

**What it is not.** One reader. A second reader on ~30 rows per audience is
the step before any of these goes to marketing as a guarantee.

### 2.13 Head of Faculty is ROR Education only — DECIDED and BUILT, 2026-11-05

**Merve:** "head of faculty grubunu sadece ror da organizasyon tipi education
olanlar alinsin bence. once bu grubu olcelim."

**Measured first.** The 18,869 CONFIRMED people split three ways by how their
organisation was resolved:

| Route | People | Org score |
| --- | --- | --- |
| ROR types include Education | 11,581 | 1.00 |
| ROR resolved, not Education (Facility ~1,230, Nonprofit ~400, Government ~340, Archive ~20) | 1,968 | 0.20–0.60 |
| No ROR match - name pattern (university 3,194, college/faculty/school 540, institute only 1,403, academy only 183) | 5,320 | 1.00 |

With the title weighted 0.60 and the threshold at 0.65, **every partial
organisation score confirmed a bare Director**: Facility 0.84, Nonprofit
0.76, Government 0.72. The 2026-10-29 comment on Healthcare said "Head of
Faculty is university heads only"; the other non-education types had never
been brought into line with it. On the sample, the 58 people at ROR-typed
non-Education organisations were **2 correct, 22 wrong, 34 not sure**.

**Built (seeds only, no model change):**

- `org_type_scores`: faculty_head Facility, Nonprofit, Government, Archive →
  0.00. Only Education scores.
- `org_name_patterns`: `institut|istitut|enstitü|academ|akadem` removed from
  the faculty_head fallback. `universi`, `colleg`, `facult`, `hochschule`,
  `polytechn`, `medical school` stay. A ROR match still always wins over the
  name - the pattern only speaks where ROR has nothing.

Result: **18,869 → 15,344** (verified: Education 11,601, name pattern 3,743,
other 0). Three scenarios were compared on the sample before choosing:
today 67.7%, ROR Education only 76.0% on 11,581, **ROR Education + university
names 76.6% on ~15,300 (chosen)** - the name-pattern rows were as clean as
the ROR ones, so dropping them would have cost ~3,700 people for nothing.
Known cost: ~8 in 37 sampled institute-only rows were real deans or heads at
an Institute of Technology or Pedagogical Institute without a ROR match.

**Then the titles, because the remaining errors were titles, not
organisations.**

- **Named chairs → teaching_academic.** `endowed chair`, `research chair`,
  `personal chair`, `canada research chair`, `chair professor of x`,
  `chair in x` are professorships. Measured: 223 in faculty_head, 35 in
  hcp_administrator. This needed **a new column, `unless_pattern`, on
  `title_group_patterns`**: RE2 has no negative lookahead, so a plain pattern
  would also have taken `professor and vice chair for research` (23 people, a
  real departmental post) and `dean and chair professor`. A title that also
  names a real post - dean, head, director, vice chair, chairman, chairperson,
  department chair, rector, provost, president - keeps the model's group.
  `principal` is deliberately not in the veto: it would spare every chair
  professor who is also a principal investigator. Applied identically in
  `dim_title_group` and both pattern tests. Three `provost's chair professor`
  titles (an honorific at NUS) were caught by the provost veto and moved by
  hand with ACCEPT teaching_academic overrides.
- **48 administrative titles REJECTED from leadership** - `director of it /
  ict / information systems / international relations / international
  affairs / assessment / quality / strategy / online programs`, `chief
  information / operating / AI / advancement officer`, `deputy module
  organizer`, `department placement coordinator`, and so on. ~61 people in
  faculty_head, ~14 in hcp_administrator.
- **Four 2026-10-21 decisions reversed.** `chief scientific officer`, `chief
  technology officer`, `chief innovation officer` had been ACCEPTed into
  leadership on the reasoning that "faculty_head needs an academic
  organisation, so a company CSO stays out". At universities it does not
  stay out - 12 confirmed. Now REJECT. `director of graduate studies` (6) is
  now ACCEPT teaching_academic: a faculty member's duty, not a headship, so
  they stay in Lecturer rather than vanish.
- **Deliberately NOT touched:** `director of operations` (it is clinical
  administration in hcp_administrator), and `ceo`, `general manager` and the
  generic managers - those are 1.3's never-academic list and marketing's
  call.

**Re-measured on a second, independent sample after the build** (seed
`val_2026_11b`, so not the cases the rules were written from): **15,047
people, 56.2% correct, 11.2% wrong, 32.5% not sure - 83.3% ± 4.4 correct of
the decided**, against 67.7% before. A simulation of the new rules on the
first sample had predicted 85.0%, so the fixes generalise.

**What is left in the 11.2% and the 32.5%:**

| What | Share | Lever |
| --- | --- | --- |
| bare `director` / `head` / `chair` | 20% | marketing, 1.3 |
| administrative Director whose title is bare but whose department is an office - *Centre for Internationalization, Innovation Office, Research and Sponsored Programs, Department of Scientific Affairs* | 7% | a department-word veto; no title rule can see it |
| university-named hospitals - *...University School of Medicine Affiliated Renji Hospital* | 6% | a 0.00 `hospital` pattern in the faculty_head name fallback |
| named chairs the pattern misses - UK `chair of x`, `SARChI chair`, `ERA chair` | 1.5% | widen the pattern, sized first |
| not a leadership title at all - `asst. professor`, `trustee`, `examination proctor` | 2% | overrides |

### 2.14 Pharmacology out of Pharmacist — DECIDED and BUILT, 2026-11-05

**Merve:** "onayliyorum sonra pharmacist duzenlemesine gec".

**Measured first,** on Pharmacist's own CONFIRMED rows (no roll-ups), out of
~2,304:

| Group | Moved (no pharmacist word in the title) | Kept (a pharmacist word is there too) |
| --- | --- | --- |
| pharmacology / pharmaceutical science | **252 (11%)** | 14 |
| student / degree | 42, of which ~25 students | 10 |
| technician / assistant | 13 | 2 |
| pharmacovigilance | 31 - **not touched**, a definition | 2 |

The 2.12 sample had predicted 11.75% for the first row, so the sample was a
good guide. The 14 kept were read one by one and every one is a real
pharmacist - `hospital pharmacist / clinical pharmacologist`.

**Built: four rows in `title_group_patterns`, all scoped to the
`pharmacist` group and all using the `unless_pattern` column from 2.13.**
Each is vetoed by `pharmacist|pharmacien|clinical pharmacy|pharmacy
practice|hospital pharmacy|farmac`.

- pharmacology stem + a teaching word (`professor, lecturer, reader, head,
  dean, chair...`) → **teaching_academic** (Lecturer)
- pharmacology stem, no teaching word → **researcher_established**
  (Researcher): pharmacometrician, senior pharmacologist, pharmaceutical
  chemist, DM clinical pharmacology. Its veto also carries the teaching
  words, student and technician, so no title can be claimed twice -
  `assert_title_patterns_do_not_collide` would fail the build if it were.
- `student`, `undergraduate`, `in training`, `pharmd candidate` → **student**
- `technician`, `técnico`, `estagi…` → **support_technical**

Stems: `pharmacolog, pharmacognos, pharmaceutics, pharmacokinet,
pharmacometric, pharmacodynam, medicinal chem, pharmaceutical
chem|scien|technolog|analysis|biolog|development`. **Deliberately not
stems:** `pharmaceutical services / care / logistics` (hospital pharmacy
management - a pharmacist's job), and a bare degree (`master of pharmacy`,
`m pharm`), because a graduate may well be practising.

One trap found before building: the project's normalisation expands `pharm`
to `pharmacy`, so `m.pharm candidate` arrives as `m pharmacy candidate`. The
student pattern carries both forms.

**Result: 2,304 → 2,051** (verified: pharmacology, students and technicians
left = 0). **Re-measured on a fresh sample of 400 (`val_2026_11b`): 82.5%
correct, 3.8% wrong, 13.8% not sure - 95.7% ± 1.9 correct of the decided,
against 81.8%.** Pharmacist went from the weakest audience to above HCP
practitioner.

**What is left:** 15 wrong in 400 - a misspelling (`research pharmacolgist`),
Portuguese pharmacology doctorates (`doutorado em farmacoquímica`),
clinical chemists, Iberian technician titles (`tsdt farmácia`, `auxiliar de
servicios farmacéuticos`). Overrides, not a new rule. Of the 55 not-sure,
**29 are professors of pharmacy practice** - a definition for marketing;
in or out, the audience stays near 96%.

### 2.15 Industry out of HCP administrator — DECIDED and BUILT, 2026-11-05

**Merve:** "head of faculty i atlayalim simdilik hcp administatorlara bakalim".

**Why industry confirmed.** hcp_administrator scores 0.35 title + 0.25
organisation + 0.40 department against 0.70. A `medical director` (1.00) in a
clinical department (~0.80) is 0.67 before the organisation, so any partial
organisation score confirms: ROR *Company* was 0.25 (its own note said "a company
director is not a clinical administrator"), an unmatched organisation 0.20.

**Measured first**, recomputing every CONFIRMED score with the organisation at
zero: of 29 at ROR-typed companies, 27 drop to PROBABLE. The name side was
measured too and **changed the design**: a `ltd|inc|gmbh` veto, as faculty_head
has, also hit Klinikum Lippe GmbH, Kepler Universitätsklinikum GmbH, HMG Hospital
Ltd, Pushpanjali Hospital Pvt Ltd and *University of Medicine and Pharmacy*. In
this data a legal form does not separate a company from a hospital.

**Built:**

- `org_type_scores`: hcp_administrator **Company 0.25 → 0.00** and **Funder 0.15 →
  0.00**. The second was found after the first: Seagen, Amgen, Vertex and Ascendis
  are `company+funder` in ROR and the organisation score takes the best type.
  Universities are `education+funder` too, but Education (0.85) wins for them.
- `org_name_patterns`: an **industry-word** veto, used only when ROR has no match -
  `pharma\b` (no leading boundary: biopharma, inmunopharma; nothing after it: not
  pharmacy), `pharmaceuticals?`, `pharmaceutical co` (for run-together names like
  *ShanghaiMicurxPharmaceutical Co*), `therapeutics`, `biotech`, `biosciences`,
  `biosolutions`, `biologics`. Known edges: *Buchanan Ocular Therapeutics Unit*
  (an NHS clinical unit - it stays confirmed anyway on title and department), and
  an unmatched *... Pharmaceutical University*.
- **A code fix in `int_employment_scored`.** A veto used to return
  `org_score_ror`, which in that branch is the UNKNOWN score. For faculty_head that
  is 0.00, so it always looked right; for hcp_administrator it is 0.20, so the veto
  could never have worked here. A veto now returns 0.0. No change for faculty_head.

**Result: 7,571 → 7,528.** Three industry rows stay because title and department
alone clear 0.70 (Emergent BioSolutions, IQVIA, Millennium); *Pfizer Inc* carries
no industry word and is missed.

**A correction to 2.12, stated plainly.** The first reading marked public-health
and epidemiology leaders as wrong or not sure. Marketing's definition counts
public health as clinical, so that was the reader being wrong. Re-scored on the
right rule the *before* figure is **88.9%** (first reported 88.0%). **On a fresh
sample after the build: 94.9% ± 2.2 correct of the decided, 4.8% wrong** - so the
gain is the fix, not the re-scoring.

**What is left:** 7 non-clinical faculties read as clinical (Sport Science, Early
Childhood, School of Life Sciences) - a department-dictionary problem with no
override mechanism yet, ~1% of the audience; 5 administrative roles; 2 industry;
2 former; 17 research-centre directors not sure. And **one consequence for
marketing**: the industry directors who left hcp_administrator stay in
**hcp_broad**, whose threshold is 0.60, through the roll-up. Whether an industry
medical director is a healthcare professional in the broad sense is 1.11's
question - work or field - and is left as it is until it is answered.

**Build note.** The overrides of 2.13 (four reversed decisions, three Provost's
chairs) were committed before they were built; this sample caught it, because
`chief innovation officer` was still confirmed. Built and verified the same day:
faculty_head **15,048**, hcp_administrator **7,528**, pharmacist **2,051**.

### 2.16 An open education record is a CHECK, not a gate — DECIDED 2026-11-12

Merve, 2026-11-12, proposing the rule: *"educations i daha bitmemis yani last
date educationda girilmemis kisiler alinsin sadece."* A student is somebody
whose education has no end date.

It was measured before it was built, and the measurement refused it. Merve,
same day, on the result: *"bugünkü kural kalsın. Education'ı kapı olarak
değil, elimizdeki kişileri doğrulamak için kullanırız."*

**What the rule would have cost.** `educations[]` turns out to carry
`full_start_date` and `full_end_date` as real DATE columns, so the rule was
answerable exactly as stated — the problem is not the mechanism, it is what
a blank end date means.

| Open education record, by how long ago it started | People |
|---|---|
| **no start date either** | **99,665** |
| within 3 years | 24,924 |
| 3–6 years | 30,031 |
| 6–10 years | 20,930 |
| 10–20 years | 19,359 |
| over 20 years | 10,487 |
| *(closed, for scale)* | *575,203* |

Of 198,268 people with an open education record, **99,665 hold a record with
no dates at all** and a further 29,846 started over ten years ago — 65% of
the evidence fails before any other test. And 83% of all education records
*are* closed, which is the proof that people do fill the field in when they
finish. A blank end date in this array does not mean "ongoing". It mostly
means "not filled in".

**The two readings, in people.**

| | People |
|---|---|
| both — the strict AND | **15,254** |
| title only — INSTEAD would lose these | 107,802 |
| open education only — INSTEAD gains | 183,014 |

AND cuts the audience from 123,056 to an eighth. INSTEAD trades 107,802
certain people for 183,014 of which two thirds carry no usable date.
(123,056 = 15,254 + 107,802 reconciles exactly with the `current_only`
measurement in analyses/51, so the two queries confirm each other.)

**And AND fails for a reason that is not arithmetic.** ORCID asks for an
EXPECTED end date and people supply it, so a doctoral student who typed
2022–2026 has an end date and the strict rule refuses them. Every query up
to this point tested only `full_end_date is null` and so never counted that
group at all.

**What was decided instead.** The audience keeps the rule it has — a student
job title, a ROR Education employer, current posts only. The education
record becomes a **corroboration measure**: of the people we deliver, how
many also hold an education record that is open or ends in the future. That
is an accuracy figure, not a filter, and it is the use 2.7 argued for before
any of this was measured.

**The measure needs a baseline or it means nothing**, because a professor
who recorded their own PhD has an open education record too. analyses/52
query 10 runs the same corroboration rate against Lecturer and Researcher
beside Students; only the difference between them is evidence.

**One thing found on the way that is independent of the decision.** The
education route could not have been a config change in any case.
`int_employment_scored`'s grain is an EMPLOYMENT record, so a person with
education evidence and no employment record has no row for a role to attach
to and cannot enter any audience at all. Delivering on education evidence
would mean a new model, not a new rule. analyses/52 query 8 sizes that.

### 2.17 Students BUILT and the Education-employer rule REAFFIRMED — DECIDED 2026-11-12

**The audience is built and it reconciles three ways**, which is the first
thing worth saying because it means the figure can be quoted.

| | People | Reachable | In CDP |
|---|---|---|---|
| **students CONFIRMED** | **105,658** | **68,959** | 100,099 |
| students PROBABLE *(never delivered)* | 17,398 | 12,164 | 16,660 |

105,658 + 17,398 = **123,056 exactly**, and 123,056 is also 15,254 + 107,802
from analyses/52 query 3 and 184,265 − 61,209 from analyses/51 query 2. Three
independent routes to the same number.

**No other audience moved materially.** lecturer +600, researcher +481,
hcp_broad +213, hcp_researcher +136, hcp_practitioner +70, faculty_head +14,
hcp_administrator +8, pharmacist +1, librarian +0 against the 11 November
figures. Those are ORCID's continuous appends, not the students build — so
adding a tenth audience and rewriting two seeds disturbed nothing.

**Students is the least reachable audience but one.** 65.3% against lecturer's
77.7% and faculty_head's 78.4%; only librarian is lower at 54.9%. Marketing
should be given 68,959, not 105,658.

**The second-group rule earned its keep here.** Query 4:

| Route | CONFIRMED | avg score |
|---|---|---|
| primary group | 98,514 | 0.973 |
| **second group — a title naming two jobs** | **7,144** | **1.0** |

7,144 of the delivered students arrived through the `doctoral researcher` →
`student` rule of 2026-11-11 and would otherwise sit in Researcher alone. All
at score 1.0, because a second group is always a literal pattern match.

---

**AND THE OPEN DECISION.** The rule says a student must be at a ROR Education
employer — Merve, 2026-11-12: *"organizasyon bilgisi cozulmeyenler ogrenci
olarak atanmasin. egitim kurumunda olmalari sart."* Queries 1d, 1d-ii and
1d-iii have now read every refused population, and the two halves of that
sentence have come apart.

| Refused | People | What the titles say |
|---|---|---|
| facility | 4,018 | `phd student` 1,331, `phd candidate`, `doctoral researcher` |
| funder | 3,138 | `phd student` 718, `phd candidate` 517, `medical student` |
| healthcare | 2,370 | `student` 463, `medical student` 161, `asistan doktor` |
| government | 283 | `phd student` 54, `student` 29 |
| nonprofit | 241 | `phd student` 64, `student` 25 |
| other | 161 | `phd student` 37, `student` 18 |
| archive | 105 | `phd student` 25, `phd candidate` 13 |
| **real students refused** | **10,316** | |
| UNKNOWN | 7,442 | **Merve's named decision — stands** |
| company | 201 | **the graduate trainees — the rule's actual target** |

**The rule is refusing 10,316 people who wrote `phd student` in order to stop
201 graduate trainees. 51 to 1 against.** And 1c-iii already showed the
trainee family is 431 people with every one of them at a non-Education
employer, so refusing `company` alone stops exactly the same people.

**Why ROR is the reason, not the data.** A doctoral candidate at Max Planck,
CNRS or INSERM is a student; ROR types those bodies `facility` or `funder`. A
medical student at a teaching hospital is a student; ROR types it
`healthcare`. "Education institution" turned out to be a proxy for "a place
people study", and ROR does not use the word that way.

**The unresolved half of the rule is untouched by all of this.** UNKNOWN 7,442
refused is a separate decision Merve took by name and nothing here argues
against it.

**The change, if it is taken:** score 1.00 for facility, healthcare, funder,
government, nonprofit, other and archive in `org_type_scores.csv`, leaving
company and UNKNOWN at 0.00. Students would go from 105,658 to about
**115,974**, and every one of those people would move from PROBABLE to
CONFIRMED rather than being newly found — the evidence is already scored, it
is the employer weight that refuses them.

**One defect this would expose rather than cause.** `academic editor`, 16
people, is in the `student` title group at archive employers and is not a
student. It is a group problem, not an employer problem, and fixing the org
score would simply deliver it. It needs its own look either way.

**DECIDED: Education-only stands.** Merve, 2026-11-12, having been shown the
51-to-1 figure: *"hayir suanda education only kalsin."* So the audience is
105,658 people, 68,959 reachable, and the 10,316 are recorded here rather
than delivered.

That is the second time this measurement has gone to Merve and come back
unchanged, which makes it a decision rather than an oversight — and the
reason it stays written down in full is that the next person to read
`org_type_scores.csv` will see ten rows of zeros and wonder whether anybody
checked. Somebody did, twice. Every students row in that seed now carries its
measured people count and the titles behind it.

**What was done instead: measure the accuracy.** Merve, same message:
*"dogruluk oranini da olcelim mi cunku status dokumaninda her audience in
accuracysi var studentsin da olsun."* The other nine audiences each have a
hand-read accuracy in the status document and students had none, so it was
the one column where this audience was weaker than the rest.

The prerequisite was not the query — analyses/51 query 7 was already written
— it was that **docs/AI-REVIEWER-RULES.docx had no students section**, and a
reviewer with no rule to judge against produces a number that means nothing.
It now has one, and it says the three things a reviewer would otherwise get
wrong: never mark a students row wrong for its organisation, because the
Education-only rule already guarantees a university; current posts only, so a
finished PhD is not a student; and **nothing is read from the education
section of the profile**, so do not mark a row correct because the person
obviously studied somewhere.

Four students rows were added to the UNSURE table, each of which is a real
ambiguity rather than an error: `md phd` (an MD-PhD programme student, or a
physician listing two degrees — the credential-versus-status problem of 1.17
restated), `research scholar` (a doctoral student in India, a senior visiting
post elsewhere), a bare `student` at a school rather than a university, and
`trainee` alone at a hospital, which belongs to trainee_clinical.

---

**ROUND 1 READ, 2026-11-12 — 97.8% ± 3.6, and the interval is the honest part.**

| | Rows |
|---|---|
| correct | 88 |
| wrong | 2 |
| not sure | 10 |
| **right, of the decided** | **97.8%** (88/90) |
| counting not-sure as wrong | 88.0% |

**100 of the 400 this audience needs.** 2.12 drew 400 CONFIRMED people per
audience in a single sample, so 400 is the house figure and students is a
quarter of the way there. The
Wilson interval is ±3.6 — as wide as faculty_head's on four times the data —
so the point estimate sits with Lecturer and Researcher but cannot yet be
stated beside them. The remaining 300 bring it to about ±1.6. Query 7 now
takes an explicit position range and defaults to 101–400, so the rows
already read are not read twice and the union of the two draws is one random
sample of 400 — consecutive slices of a single hash order concatenate to
exactly what drawing 400 at once would have given.

**The two wrong rows are both nameable, which is better than a rate.**

- `Doctoral Supervisor` at a UK university, 0.906 — the **inverse** of a
  student. 2.8a's lesson in a new place: a modifier can reverse a title and
  the embedding reads the subject rather than the role.
- `employee` at a Chinese university, 0.835 — names no student at all.

**Nine of the ten not-sure rows are ONE problem: the bare degree.** `PhD`,
`Ph.D`, `Ph. D.`, `Master` and `Master's in Marketing` as the entire job
title. A degree is a **credential, not a status** — the person may be studying
for it or may have held it for twenty years, and the title does not say
which. This is 1.17's finding restated, and it is the single largest source of
doubt in this audience. The tenth was `Master's in Marketing`, which names a
degree programme rather than a post.

**`research scholar` resolved itself.** It was added to the UNSURE table as
ambiguous — a doctoral student in India, a senior visiting post elsewhere — and
12 of the 100 rows carried it. **All twelve were Indian and all twelve were
correct.** The country condition is doing the work, so the rule should stay
written as "outside India" rather than as a blanket doubt.

**And the diagnostic that is too clean to state from 100 rows.** Every one of
the 12 problems sat below score 1.0:

| | Rows | Not correct |
|---|---|---|
| score = 1.0 — PATTERN or HUMAN | 63 | **0** |
| score < 1.0 — the embedding's graded answer | 37 | **12 (32.4%)** |

A literal pattern match or a person's own decision was right 63 times out of
63. That is a story about where to spend the next reading rather than a
threshold, and **no threshold is proposed from it** — the bare-degree titles
all sat at or below 0.927, and this project has twice turned a number like
that into a rule it then had to take back out. Query 8c sizes the two bands
over the whole audience so round 2 can be drawn to test the split instead of
re-measuring the average.

**Queries 8 and 8b count the two findings exactly rather than extrapolating.**
9 of 100 reads as ~9,500 people, but the sample was drawn from CONFIRMED rows
and these titles cluster, so the real figure is whatever the query says. 8b
lists the strings themselves, because every veto this project has got wrong
was written from a guessed spelling.

**Per-person rows were not committed.** The 100 rows were read in
conversation and the verdicts computed in a scratch file; what is recorded
here is counts and reasons, for the same reason `validation_samples/` was
removed on 2026-11-05.

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

**RE-PRICED 2026-11-05, on a fresh sample after the Education-only change
(2.13).** The question is now bigger, not smaller, because the audience
around it got cleaner: of 400 people drawn at random from the 15,047 who
remain, **81 (20.3%) hold only `director`, `head` or `chair`** - roughly
3,000 people. (2026-11-03 found 267, 15.0%, but of 1,775 survey-checkable
people rather than of the whole audience, so the two are not a trend.) Measured on
that sample, answering it either way moves the audience's correct-of-decided
figure: **in → ~87%, out → ~83% on ~12,000 people.** It remains the largest
single thing between Head of Faculty and ~90%. *validation sample v2,
2026-11-05.*

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

**ADDED 2026-11-05, from the hand-read samples (2.12, 2.13).** Each of these
is ours rather than marketing's, and each is sized from a sample, not yet
from the full audience:

| Next fix | Audience | Sampled share of its errors | Mechanism |
| --- | --- | --- | --- |
| ~~Reject `pharmacolog`, `pharmacognos`, `pharmaceutic` from the pharmacist group~~ **DONE 2026-11-05, see 2.14** | Pharmacist | 47 of 64 | 81.8% → 95.7% |
| Department-word veto (*office, internationalization, sponsored programs, enrollment*) | Head of Faculty | ~7% of audience | new: a department pattern, the org-name veto's twin |
| `hospital` veto in the org-name fallback | Head of Faculty | ~6% of audience | one 0.00 row in org_name_patterns |
| ~~Company veto on the organisation for industry medical directors~~ **DONE 2026-11-05, see 2.15** | HCP administrator | 11 of 41 | 88.9% → 94.9% |
| Department override for general-science faculties read as `health_clinical` (*Faculty of Science* 35, *School of Life Sciences* 13, *Faculty of Natural Sciences* 5 ...) | HCP administrator, HCP researcher | ~1% of HCP administrator | new: a department twin of role_title_overrides |
| Non-clinical fields out of HCP researcher (veterinary, plant, physics) | HCP researcher, HCP broad | ~19 of 36 | discipline anchors - these departments reached `health_clinical` |
| Second reader, ~30 rows per audience | all | - | Merve |

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
