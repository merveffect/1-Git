# The rules this pipeline applies to a job title

**Reference for the AI doing the audience review. Paste this ahead of the rows.**

You are auditing a system that reads free text people typed into ORCID and
decides which marketing audience they belong to. This file is the complete set
of rules that system applies, plus the decisions that have been made about
edge cases, plus the mistakes it has actually been caught making.

Read the **Known failure modes** and **Where to mark UNSURE** sections before
you judge anything. They are the reason this file exists: most of what looks
like a wrong answer is one of a small number of named, already-understood
failures, and naming the right one is more useful than the verdict.

---

## 1. How a title gets its group

Every distinct job title is mapped to exactly one **title group**. Three
mechanisms, in strict order of precedence:

| Source | What it is | Score |
| --- | --- | --- |
| **HUMAN** | A reviewer decided this title by hand. Always wins. | 1.0 (ACCEPT) or 0.0 (REJECT) |
| **PATTERN** | The title literally contains a listed string. No similarity, no threshold. | 1.0 |
| **VECTOR** | The embedding's nearest anchor group, by cosine similarity. | graded, see below |

**The VECTOR score is graded, not binary.** A title must reach **0.65**
similarity to be assigned at all. Above that the score runs
`0.70 + (similarity − 0.65) / 0.35 × 0.30`, so a title at 0.65 scores 0.70 and
a title at 1.00 scores 1.00. A title below 0.65 gets **no group** and the
person is not in any audience through that title.

**What this means for your judgement.** A `decision_source` of PATTERN or HUMAN
means somebody wrote a rule naming this title. A VECTOR assignment is the
embedding's guess, and a low `score` means a weak guess. The lower the score,
the more sympathetic you should be to UNSURE.

### The title groups

`practitioner` · `trainee_clinical` · `researcher` · `teaching_academic` ·
`leadership` · `pharmacist` · `librarian` · `student` · `support_technical`

**`support_technical` and `student` feed no audience today.** A title in either
produces nobody. That is deliberate, not a gap.

---

## 2. The three axes a score is built from

A person is scored per audience on up to three independent signals.

| Axis | Source | What it answers |
| --- | --- | --- |
| **title** | the job title's group | what is this person's profession |
| **organisation** | the employer's ROR type — Education, Healthcare, Company, Facility, Nonprofit, Government, Funder, Archive, Other, UNKNOWN | what kind of place do they work |
| **department** | the department's **discipline** | what field are they in |

The twelve disciplines: `health_clinical` · `life_biomedical` ·
`earth_agriculture` · `humanities_law_edu` · `physical_chemistry` ·
`engineering` · `social_behavioural` · `pharmacy` · `business_public` ·
`computing_data` · `mathematics_statistics` · `non_academic`

**The principle behind the score: certainty is two independent signals
agreeing, not one signal scoring highly.** That is why there are three axes
rather than one. Where an audience requires both a title and a field, a person
confirmed in it is corroborated twice over — and where it requires only a
title, there is nothing to catch a wrong one.

**Above an audience's threshold a person is CONFIRMED, below it PROBABLE.**
Only CONFIRMED is ever delivered. You are only ever shown CONFIRMED rows.

---

## 3. The nine audiences and what each one requires

| Audience | Needs | Field | Threshold |
| --- | --- | --- | --- |
| `researcher` | a research title | **none — any field** | 0.60 |
| `lecturer` | a teaching / academic title | none | — |
| `librarian` | a library word in the title | none | — |
| `pharmacist` | a pharmacist title (**mandatory**) | pharmacy adds score | 0.60 |
| `hcp_broad` | a clinical title (**mandatory**) | health_clinical | 0.60 |
| `hcp_practitioner` | a clinical title **AND** a health department | health_clinical | 0.70 |
| `hcp_researcher` | a **research** title **AND** a health department | health_clinical | 0.70 |
| `hcp_administrator` | a **leadership** title **AND** a health department | health_clinical | 0.70 |
| `faculty_head` | a faculty-level leadership title | none — the title is the only axis | 0.65 |

Three things in that table are the most common source of a wrong verdict.

**`researcher` has NO field check.** A plant pathologist, an astrophysicist and
a medieval historian are all correctly in Researcher. Do not mark `field_wrong`
on a Researcher row — the field is not part of the rule.

**`hcp_researcher` and `hcp_administrator` do not require patient contact.** A
clinical trials statistician in an oncology department is correctly in
`hcp_researcher`. Somebody running a cardiology unit is correctly in
`hcp_administrator`. Neither has to see a patient.

**`faculty_head` is scored on the title and the employer only** — there is no
department check, so a leadership title at an educational institution has
nothing contradicting it. This is the audience with the most room for error
and it is why its accuracy is the lowest.

### The roll-up

`hcp_practitioner`, `hcp_researcher`, `hcp_administrator` and `pharmacist` all
**roll up into `hcp_broad`**. A person confirmed in any of them also appears in
`hcp_broad`, carrying their child score, relabelled at `hcp_broad`'s own 0.60
threshold.

**So an `hcp_broad` row is not always judged by the `hcp_broad` rule.** The
`reached_via` column tells you: empty means the person qualified for
`hcp_broad` in their own right, a value means they arrived through that child
role — and it is **that child's rule** that has to hold for the row to be
correct.

---

## 4. The organisation rule that matters most

**`faculty_head` scores every ROR organisation type except Education at
exactly 0.00**, including an unresolved one. With a 0.65 threshold that means
**nobody is confirmed as a Head of Faculty without a verified educational
employer** — no hospitals, no research institutes, no companies, no national
laboratories, nobody whose employer could not be identified.

Two decisions produced that: hospital-based leaders were removed on 29 October
(about 2,000 people, including 294 heads of department and 17 deans whose
record names a hospital), and research institutes, nonprofits, government
bodies and archives on 5 November (1,968 people — every bare Director at Max
Planck, Fraunhofer, Helmholtz and the national labs).

**So if you see a `faculty_head` row, the employer is already known to be
educational.** Do not mark it wrong for the organisation. The open question
there is the *title*, never the employer.

---

## 5. Decisions already made — these change what "correct" means

Do not mark a row wrong for any of these. They were decided deliberately, and
most of them were measured first.

| Decision | Answer | Size |
| --- | --- | --- |
| Are teaching assistants in Lecturer? | **Yes.** If they teach, they are a lecturer, doctoral student or not. | 178,205 records |
| Are doctoral students who research in Researcher? | **Yes**, but the **title has to say so**. Being a doctoral student is not the qualification; a title naming research is. `phd fellow` names neither and is out. | 197,895 records in, 19,424 out |
| Should retired and emeritus people be in live audiences? | **No.** `emeritus professor`, `retired professor`, `honorary researcher` are rejected outright. | 17,277 records removed |
| Should a past role still count? | **Yes, for seven of the nine audiences.** A researcher in 2010 who works in a bank today is still in Researcher — a researcher is a profession you have, not a post you hold. **`faculty_head` and `librarian` are the exceptions** and count current posts only, because a former dean is not a dean. | — |
| Can someone be a healthcare professional with no clinical job title? | **No.** The job title is mandatory for `hcp_broad`. An administrator in a cardiology department is out. | 6,115 people removed |
| Is a named chair a leadership post? | **No, it is a professorship.** `endowed chair`, `chair professor of X`, `canada research chair`, `research chair` are teaching, not leadership. But `vice chair for research`, `dean and chair professor`, `department chair` ARE leadership. | 223 people moved |
| Is a pharmacology academic a pharmacist? | **No.** A professor, lecturer or head of pharmacology or any pharmaceutical science is an academic. Nobody becomes a pharmacist by working in a pharmacy department. | 252 of 2,304 confirmed |
| Are archivists librarians? | **No, deliberately excluded** — the word pulled in archaeologists, glaciologists and clerks. | — |
| Is "information specialist" a librarian? | **No, deliberately excluded** — it pulled in every IT job in the data. | — |
| Should the second confidence tier be delivered? | **No.** Only CONFIRMED ships. | 45,054 people never delivered |
| Are biomedical researchers healthcare professionals? | **Yes** — a biomedical department now counts for `hcp_researcher`, and they reach `hcp_broad` through the roll-up. **Check with Merve whether the build you are reading includes this.** | 15,588 people |
| Can a title name two professions? | **Yes** — a title naming two jobs puts the person in both audiences. `professor and director` is in Lecturer AND Head of Faculty. **Check with Merve whether the build you are reading includes this.** | ~115,000 records |

### One structural rule worth understanding

**Leadership words are modifiers, not professions.** `head of X`, `dean`,
`director` attach to any job, so a rule matching them would override the
profession word standing beside them. Measured: an unconditional leadership
pattern would have swept ~14,500 records out of eight groups that have nothing
to do with faculty leadership — `head of department of cardiology` would have
stopped being a clinician, and `cluster pharmacy manager & head of department`
would have stopped being a pharmacist.

So the profession word wins, and a leadership promotion only happens where the
only other profession word is a generic academic rank.

---

## 6. Known failure modes — look for these first

These are not hypotheticals. Each one was found in real data and each one has
a reason code.

### Word fragments matching inside other words → `field_wrong`

The clearest class, and it is always a substring that is not a word:

```
ecolog   matched gynECOLOGy          374 people
astro    matched gASTROenterology    269 people
plant    matched transPLANTation      35 people
```

If a row looks wrong on the field, check whether the field word is a fragment
of a longer, unrelated word.

### `consultant` means two different jobs → `ambiguous_word`

A hospital specialist grade in Britain, Ireland and much of the Commonwealth.
A business adviser everywhere else. Measured by the share of consultants with
a clinical department: **0.88 in Qatar, 0.83 in Singapore and Hong Kong, 0.68
in Britain, against 0.20 in the United States, 0.08 in Brazil, 0.03 in Peru.**

**Use the `country_code` column.** A `consultant` in the US with no clinical
department is probably a business adviser. A `consultant` in the UK is probably
a hospital specialist.

### `fellow` means two different jobs → `ambiguous_word`

In an American teaching hospital, a physician in subspecialty training. In a
British university, a researcher. A title that is the single word `Fellow`
carries nothing that separates them — it is the largest single uncertainty in
the clinical researcher audience and it is an open question.

### A department that names a building, not a field → `field_wrong`

`faculty of medicine` and `school of medicine` are four words of which two
carry no field at all, so they attracted every department that mentioned a
faculty or a school. 108,587 records of non-clinical departments were reading
as clinical. 85% of it is fixed, but **two field errors are known to remain**
and nothing addresses them: `Institute of Vertebrate Paleontology and
Paleoanthropology`, and `Photometry and radiometry group`.

### A verbose title dilutes every anchor it contains → low `score`

A long descriptive string scores lower than the same job stated briefly, not
because it is ambiguous but because it is long:

```
professor head of school director of japan pacific ict centre    0.649
endowed professor in nursing associate dean for research         0.642
```

A low score on a long title is usually not a wrong answer. Judge the words.

### A short foreign word attracts its spelling, not its meaning

`farmaceutico` attracted anything ending in `-ico` or `-ica`. `bibliotecario`
did the same. If a non-English title looks misplaced and the only thing it
shares with its group is a word ending, that is this failure — and
**`language` is the right code if you cannot read it with confidence.**

### An uninformative title → `uninformative`

`dr` carries 96,676 records and `md` 50,189. Together 9.1% of the clinical
group. Neither says anything about a profession beyond holding a doctorate,
and both are resolved entirely by the department.

---

## 7. Where to mark UNSURE rather than guess

These are **open questions marketing has not answered**. A row that turns on
one of them is not a wrong answer and it is not a right one. Mark UNSURE, give
the reason code, and say in the reason which question it is.

| What you will see | Why it is open |
| --- | --- |
| A title that is only `director`, `chair` or `head`, with no faculty word beside it | We cannot tell whether they head a faculty, a research centre, a hospital unit or an administrative office. **15% of `faculty_head`.** Use `ambiguous_word` |
| `statistician`, `medical statistician`, `economist` | The role library treats them as the same job as `research statistician` and `research economist`, which ARE in Researcher. 2,177 records in no audience. Unanswered |
| A veterinary department in a healthcare audience | Veterinary medicine is medicine and the word carries. Nobody decided whether a vet is a healthcare professional. Use `field_wrong` and say it is the vet question |
| `Faculty of Sport Sciences`, `Sports Medicine`, `Faculty of Sport and Health Sciences` | Splits down the middle of its own vocabulary. A sports physician treats patients, a sport scientist studies performance, and the third group names both. Unanswered |
| `honorary professor` | The role library files Honorary Researcher under "former or inactive", but in ORCID *honorary* is very often an unpaid university title held by somebody actively employed elsewhere. Both readings defensible. 6,651 records |
| `visiting scholar`, `visiting fellow`, `visiting research scholar` | Counted as teaching staff because of the word *visiting*. A visiting scholar may teach or may only research. 81,749 records |
| A psychologist in a clinical audience | All six psychologist titles match our `psychiatrist` example. A clinical psychologist is a regulated healthcare professional in most countries; an educational psychologist arguably is not. ~4,500 records |
| A `dr` or `md` with a clinical department | Decided yes for now, but it rests on the department alone |

---

## 8. How to behave as a reader

**UNSURE is a real verdict, not a failure.** It is reported separately and
excluded from the accuracy percentage. In `faculty_head` a third of the first
sample was unsure, and that third is precisely what marketing has to decide.
Do not guess to avoid it.

**Judge what the person typed, not what they probably do.** "Probably a
doctor" is not evidence. A job title naming a clinical role is.

**Whether the person still holds the job is not being judged.** Only use
`ended_role` when the title itself says the post has ended.

**The reason code matters more than the verdict.** "11 wrong out of 100" says
almost nothing. "7 of the 11 are `field_wrong`, all in veterinary departments"
says exactly what to fix — and a breakdown like that, not a percentage, found
the department bug that moved one audience by five points.

**Do not spread your verdicts to look balanced.** If 95 of 100 are correct,
say so. If 40 are unsure, say so.

**One thing this system is NOT claiming**, so do not mark a row wrong for it:
it does not claim the person still works there, or that the data is current. It
claims the job title was read correctly.
