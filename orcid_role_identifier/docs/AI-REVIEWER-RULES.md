# Audience rules, as the pipeline applies them today

Reference for the AI reviewing audience membership. One section per audience.
For each row you are asked: **does the evidence satisfy this audience's rule?**

You are only shown CONFIRMED rows. The second confidence tier is never
delivered, so it is not what you are judging.

---

## researcher — *Researcher (all fields)*

- **Title must name** research work: researcher, scientist, postdoc, research
  fellow, research associate, principal investigator, group leader.
- **Field: ANY. There is no department check at all.** A plant pathologist, an
  astrophysicist and a medieval historian are all correct. **Never mark
  `field_wrong` on a Researcher row.**
- **Organisation:** any. University and research institute score highest,
  company lowest. Nothing is excluded.
- **Excluded:** `emeritus`, `retired`, `honorary researcher`. Also
  `phd student`, `phd candidate`, `phd fellow` — a doctoral student is only a
  researcher if the **title itself** names research, as `doctoral researcher`
  does.
- **Past posts count.** A researcher in 2010 working in a bank today is still
  correct.

## lecturer — *Lecturer / Teaching Academic*

- **Title must name** a teaching or academic post: professor, lecturer, reader,
  docent, instructor, tutor, teaching assistant.
- **Field:** no department check.
- **Organisation:** any. Education scores highest, company lowest.
- **Excluded:** `emeritus professor`, `retired professor`. School teachers are
  in by default and were measured at 0.2% of the group.
- **Past posts count.**

## librarian — *Librarian / Information Professional*

- **Title must contain** a library word. This audience is decided by literal
  pattern, not by similarity, so it is always a certain match.
- **Field:** none. **Organisation: irrelevant** — it carries zero weight here.
- **Excluded by choice:** archivists (the word pulled in archaeologists,
  glaciologists and clerks) and `information specialist` (it pulled in every IT
  job in the data).
- **CURRENT POSTS ONLY.**

## pharmacist — *Pharmacist*

- **Title must name a pharmacist. The title is the only way in** — nobody
  becomes a pharmacist by working in a pharmacy department.
- **Field:** a pharmacy department adds score but is not required.
- **Organisation:** any. Hospital highest, then company, then university.
- **Excluded:** pharmacology and pharmaceutical-science academics
  (`pharmacolog`, `pharmacognos`, `pharmaceutic`, `medicinal chem`) — a
  professor of pharmacology is an academic, not a pharmacist. Also pharmacy
  students and pharmacy technicians.
- **Past posts count.**

## faculty_head — *Head of Faculty / Department*

- **Title must name a faculty-level post:** dean, head of department, head of
  school, rector, provost, pro-vice-chancellor, chancellor.
- **Field:** none. **The title and the employer are the only two signals**, so
  there is nothing to contradict a wrong title. This is why its accuracy is the
  lowest of the nine.
- **Organisation: EDUCATION ONLY.** Every other ROR type scores zero, including
  an unresolved one — no hospitals, no research institutes, no companies, no
  national labs, nobody whose employer could not be identified. **So never mark
  a `faculty_head` row wrong for its organisation. It is already verified.**
- **Excluded:** named chairs — `endowed chair`, `chair professor of X`,
  `canada research chair` are professorships, not leadership. Also
  `editor-in-chief`.
- **CURRENT POSTS ONLY.**

## hcp_broad — *Healthcare Professional (broad)*

- **Title must name a clinical role. THE TITLE IS MANDATORY** — a clinical
  department alone is not enough. An administrator in a cardiology department
  is out.
- **Field:** a human-health department adds most of the score.
- **Organisation:** any except archive. Hospital highest.
- **ALSO CONTAINS EVERYONE WHO ROLLS UP** from hcp_practitioner,
  hcp_researcher, hcp_administrator and pharmacist. **Check `reached_via`:** if
  it names a child audience, that child's rule is the one that has to hold.
- **Past posts count.**

## hcp_practitioner — *Healthcare Practitioner*

- **Title must name a clinician who treats patients** AND
- **Field must be a human-health department.** Both are required.
- **Organisation:** any except archive. Hospital highest.
- **Past posts count.**

## hcp_researcher — *Clinical / Biomedical Researcher*

- **Title must name research** AND
- **Field must be a human-health OR a biomedical department.** Both required.
- **PATIENT CONTACT IS NOT REQUIRED.** A clinical trials statistician in an
  oncology department is correct.
- **Organisation:** any, nothing excluded.
- **Past posts count.**

## hcp_administrator — *Clinical Leadership / Administration*

- **Title must name a leadership post** AND
- **Field must be a human-health department.** Both required.
- **PATIENT CONTACT IS NOT REQUIRED.** Somebody running a cardiology unit is
  correct.
- **Organisation: company and funder score zero** — an industry medical
  director is deliberately out.
- **Past posts count.**

---

## Mark UNSURE here — these are open questions, not errors

| What you see | Code |
| --- | --- |
| A title that is only `director`, `chair` or `head` with no faculty word beside it — 15% of faculty_head | `ambiguous_word` |
| `consultant` outside Britain and Ireland — it means business adviser in the US (0.20 of them have a clinical department, against 0.68 in Britain). **Use `country_code`** | `ambiguous_word` |
| A title that is the single word `Fellow` — a trainee physician in the US, a researcher in the UK | `ambiguous_word` |
| A veterinary department in a healthcare audience | `field_wrong` |
| `Faculty of Sport Sciences` or `Sport and Health Sciences` in a healthcare audience | `field_wrong` |
| `statistician`, `medical statistician`, `economist` | `title_wrong` |
| `honorary professor` | `ended_role` |
| `visiting scholar`, `visiting fellow` in Lecturer | `ambiguous_word` |
| A psychologist in a clinical audience | `ambiguous_word` |
| `dr` or `md` alone | `uninformative` |
| A title in a language you cannot read with confidence | `language` |

## Two things that are NOT errors

- **A low score on a long title.** A verbose string dilutes every match it
  contains, so it scores lower than the same job stated briefly. Judge the
  words, not the number.
- **Whether the person still holds the job.** Only use `ended_role` when the
  title itself says the post has ended — emeritus, retired, a closed date range.

## How to behave

UNSURE is a real verdict and is excluded from the accuracy figure, so do not
guess to avoid it. Judge what the person typed, not what they probably do. Give
a reason code on every WRONG and UNSURE — **the code matters more than the
verdict**. Do not spread verdicts to look balanced: if 95 of 100 are correct,
say so.
