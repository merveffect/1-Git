# -*- coding: utf-8 -*-
"""Section 6: one block per target audience, all ten the same shape.

REWRITTEN 2026-11-16. Merve: "this status document is too long. do you think
everything there is necessary?" It was 12,102 words and this section was 51%
of it, because Lecturer had four sub-sections of how we fixed it while
Students had six bullets - a record of where our attention went, not a
structure a reader can use. Every audience now gets the same four things: how
big, how accurate, how it is decided, what is open. The corrections and their
measurements live in docs/open-questions.md, which is where the history
belongs; nothing is lost by taking it out of here.
"""
from docx_lib import *
from docx.shared import Pt


def build(d, F):
    h(d, "6.  Every target audience, one by one")
    para(d, "Ten audiences, each given the same four things: how big it is, how accurate "
            "it has been shown to be, what decides it, and what is still open in it. The "
            "people figures are in section 3 and the decisions behind each rule, with the "
            "measurements they were taken on, are in the project's open-questions log.")

    # ------------------------------------------------- 6.0 READ BY HAND
    h(d, "6.0  Every audience read by hand", 2)
    para(d, "**400 CONFIRMED people per audience, drawn at random** (all 700 for "
            "Librarian), every one read - job title, employer and department - and marked "
            "**correct**, **wrong** or **not sure**. *Not sure* is used for two things "
            "only: a definition marketing has not settled, and a record that does not "
            "carry enough to decide.", space_after=6)
    table(d, ["Audience", "Correct", "Wrong", "Not sure", "Correct, of the decided", "Wrong people, est."],
     [["**Researcher**", "96.8%", "1.0%", "2.3%", "**99.0% ± 1.0**", "~3,400"],
      ["**Lecturer**", "98.2%", "1.2%", "0.5%", "**98.7% ± 1.1**", "~5,100"],
      ["**Students**", "91.8%", "1.2%", "7.0%", "**98.7% ± 1.3**", "~1,200"],
      ["**Librarian** (all 700 read)", "97.1%", "1.4%", "1.4%", "**98.5%**", "10"],
      ["**Pharmacist**", "82.5%", "3.8%", "13.8%", "**95.7% ± 1.9**", "~80"],
      ["**HCP administrator**", "88.0%", "4.8%", "7.2%", "**94.9% ± 2.2**", "~400"],
      ["HCP practitioner", "82.0%", "5.8%", "12.2%", "93.4% ± 2.6", "~3,300"],
      ["HCP broad", "81.5%", "8.5%", "10.0%", "90.6% ± 3.0", "~15,200"],
      ["HCP researcher", "81.2%", "9.0%", "9.8%", "90.0% ± 3.1", "~9,900"],
      ["**Head of Faculty**", "56.2%", "11.2%", "32.5%", "**83.3% ± 4.4**", "~1,900"]],
     widths=[1.75, 0.7, 0.65, 0.75, 1.35, 1.2], size=8.5)
    para(d, "**How to read it.** *Correct, of the decided* leaves the not-sure rows out, "
            "so it is the error rate where an answer exists; the not-sure column says how "
            "much is waiting for a definition. The ± is a 95% interval. The last column "
            "is the *Wrong* share applied to the audience size in section 3, recomputed on "
            "the 19 November build - two of its rows had been carried from an older and "
            "smaller count of the healthcare audiences and were understating the error. "
            "*Wrong people* "
            "scales the sample rate to the audience, so Lecturer's 1.2% is ~5,100 people "
            "and still a very clean audience.", space_after=4)
    para(d, "**What it is not: one reader, not two.** These are the analyst's judgements "
            "against the definitions in this document. A second reader on ~30 rows per "
            "audience is what turns them into a figure we would guarantee. Head of "
            "Faculty, Pharmacist and HCP administrator were re-read on a **second, "
            "independent sample** after their rules changed, so they are not marked "
            "against the cases the rules were written from.", space_after=10)

    para(d, "**A second measurement, against what people say about themselves**, runs in "
            "two directions and is explained in section 5. *Did we find them* fails when "
            "we miss people; *do they agree* fails when we let the wrong people in. "
            "Neither can reach Pharmacist, Librarian or Students, and neither can separate "
            "the healthcare sub-audiences.", space_after=4)
    table(d, ["Audience", "Did we find them?", "Do they agree?", "State"],
     [["**Lecturer**", "**91.1%**", "**78.2%**", "Best measured both ways"],
      ["Researcher", "74.3%", "43.9%", "Precision depressed by multi-role people"],
      ["Healthcare (broad)", "**90.9%**", "22.7%", "A wide net on purpose"],
      ["Practitioner", "—", "35.8%", "Survey cannot split the healthcare sub-audiences"],
      ["Clinical researcher", "—", "48.2%", "Same"],
      ["**Head of faculty**", "**23.8%**", "**26.3%**", "**The weak one.** Causes known"],
      ["Clinical administrator", "—", "22.5%", "71 people checked — too few"],
      ["Pharmacist, Librarian, Students", "—", "—", "**Cannot be measured** — not in the survey"]],
     widths=[1.65, 1.05, 0.9, 3.0], size=8.8)
    para(d, "", space_after=8)

    n = [0]

    def aud(title, lines):
        n[0] += 1
        h(d, f"6.{n[0]}  {title}", 2)
        for t in lines:
            bullet(d, t)
        d.paragraphs[-1].paragraph_format.space_after = Pt(10)

    aud("LECTURER — 426,449 people, 98.7% correct", [
      "**How it is decided.** Does the job title name a teaching post — professor, "
      "lecturer, reader, docent, instructor, tutor. There is no department check at "
      "all, and past posts count.",
      "**74,365 job titles, settled by fifteen example words.** 99.7% of them were "
      "decided by the machine and 26 by a person — and all 26 are foreign-language "
      "titles the machine sent towards medicine because the string contains *dr*: "
      "`dr öğr üyesi` 4,246 records, `doç dr` 2,547, `ayudante doctor` 1,861. Fifteen "
      "hand-written words classify the largest group in the project.",
      "**The structural risk.** The title is the only signal, so a wrong title goes "
      "straight through with nothing to contradict it. It scores 98.7% anyway because "
      "academic titles are the most standardised vocabulary in the data.",
      "**Settled 19 November, and not yet built.** Marketing answered both: exclude. "
      "A visiting scholar or visiting fellow is not teaching staff — the post is "
      "temporary, usually unpaid, and the title names a visit rather than a job. An "
      "honorary post is conferred rather than held, which closes the family begun on "
      "16 October when `emeritus professor`, `retired professor` and `honorary "
      "researcher` were rejected and `honorary professor` was the one nobody had "
      "looked at. Both are patterns scoped to the teaching group, so a clinical "
      "honorary post keeps its clinical group, and the titles move to the holding "
      "group rather than being deleted. **Wider than the question asked:** honorary "
      "lecturer and honorary reader go with honorary professor, because the argument "
      "is about the word *honorary* and not about the rank beside it.",
      "**Measured on the build of 20 November: the two rules cost 2,956 people.** "
      "Lecturer went from 427,256 to 426,449 while the four audiences no decision "
      "could touch grew by a median 0.503%, so the audience would have been 429,405 "
      "without the change. Counted before the build, the two rules could see 978 "
      "people on an honorary title and 1,727 on a visiting one, and neither rule "
      "reached a second audience — no clinical row, no researcher row. The scope "
      "held, measured rather than argued.",
      "**Open, and found by the same measurement: 241 honorary titles carrying "
      "1,127 records are still in the Researcher audience.** The pattern is scoped "
      "to the teaching group, so `honorary research fellow` and its family were "
      "never in its reach. That matters because marketing already rejected the "
      "exact string `honorary researcher` on 16 October — so the same reasoning now "
      "removes one title and leaves 241 of its siblings in the project's "
      "highest-scoring audience. Widening the rule is one field; whether an "
      "honorary research fellow is an active researcher is the same definition "
      "question marketing just answered for Lecturer, asked again about Researcher."])

    aud("RESEARCHER — 344,847 people, 99.0% correct", [
      "**How it is decided.** Does the job title name research work — researcher, "
      "scientist, postdoc, principal investigator, group leader. Any field: a plant "
      "pathologist and a medieval historian are both correct. Past posts count.",
      "**It is one title group, and used to be two.** `researcher_early` and "
      "`researcher_established` were merged on 10 November. No audience had ever read "
      "them apart, and the project's largest single error — `junior researcher`, 42,949 "
      "records — was a title landing in the wrong half of a split that fed one audience.",
      "**Doctoral students leave unless the title names research.** `phd research "
      "fellow` stays, `phd fellow` goes. Any research word in any language keeps them, "
      "not only the noun *researcher*.",
      "**The 43.9% agreement is mostly an artefact.** A professor who runs a research "
      "group is in both Lecturer and Researcher; the survey records one answer, so one "
      "of the two memberships is counted wrong whatever we do."])

    aud("STUDENTS — 102,026 people, 98.7% correct", [
      "**The newest audience, built and read in November, and third of the ten.** 400 "
      "records read one by one on 13 November: 367 correct, 5 wrong, 28 not sure.",
      "**Three rules, each measured before it was set.** The title must name a student. "
      "The employer must be a university — every other ROR type scores zero. And only "
      "posts a person currently holds count, which alone removed 61,209 people who are "
      "today's professors and postdocs.",
      "**The employer rule has a bill and it was paid knowingly.** It refuses 10,316 "
      "people whose titles plainly say `phd student`, because ROR types Max Planck and "
      "CNRS as a facility or a funder and teaching hospitals as healthcare. It stops 201 "
      "company and hospital trainees, so it costs 51 real students for each one. "
      "Reaffirmed on 11 November with that number in front of us.",
      "**It is one bucket, not three.** Doctoral, master's and undergraduate students are "
      "in it together. Narrowing it to doctoral candidates is one line. Nothing is read "
      "from the education section of a profile — using degrees as a second signal was "
      "measured and refused, because 65% of open education records carry no usable date.",
      "**Settled 19 November, and not yet built.** The bare qualification is excluded. "
      "6% of the sample wrote only a degree as their whole job title — `PhD`, `Master`, "
      "`Bachelor`, and one person wrote `Phd holder` — and a degree is a credential, "
      "not a status: the record cannot say whether the person is studying for it or "
      "has held it for twenty years. It was the single largest source of doubt in this "
      "audience. The rule is anchored to the whole title, so `PhD student` is "
      "untouched, and it is scoped to the student group. **`doctor` and `dr` are "
      "deliberately left out of it**, because the same day ruled that a bare doctor "
      "stays in Practitioner.",
      "**Measured on the build of 20 November: it cost 5,604 people.** Students went "
      "from 107,091 to 102,026, against an expected 107,630 had nothing changed — "
      "a 4.7% audience, and by far the most expensive of the five decisions. The "
      "rule took 26 job titles carrying 11,304 records. Counted before the build it "
      "looked like 4,241 people, and that figure was published as a floor for a "
      "stated reason: it ran on the raw title, so every spelling the cleaning "
      "changes — `Ph.D.` becomes `ph d` — was invisible to it. The floor turned out "
      "to be 76% of the real cost.",
      "**One hole left, measured at 10 records.** A bare qualification the machine "
      "reads as research is routed into this audience by a different rule, which "
      "the new exclusion is not scoped to see. Ten records today, and whatever the "
      "machine does on the next rebuild. The fix is one field on that other rule."])

    aud("HEALTHCARE (BROAD) — 178,556 people, 90.6% correct", [
      "**How it is decided.** The widest net: a clinical job title is mandatory, and "
      "everyone from Practitioner, Clinical researcher, Clinical administrator and "
      "Pharmacist rolls up into it as well.",
      "**It has no errors of its own.** Every one arrives through a child audience, so it "
      "improves when they do.",
      "**It is not weak — it is undefined.** 887 of the people in it describe themselves "
      "as professors or researchers rather than clinicians, and biomedical researchers "
      "now roll up too, which brought in 54,426 people who have never seen a patient. "
      "Whether that is right is the one question blocking us, and it is a naming "
      "question, not an accuracy one."])

    aud("PRACTITIONER and CLINICAL RESEARCHER — 57,351 and 109,854 people, "
        "93.4% and 90.0% correct", [
      "**How they are decided.** Both need the title **and** the department to agree. "
      "Practitioner wants a clinician who treats patients; Clinical researcher wants "
      "research in a human-health or biomedical department, with no patient contact "
      "required — a trials statistician in oncology is correct.",
      "**Practitioner is the least-read group in the project** — reviewed titles cover "
      "38% of its records, against 75% for researchers. Clinical vocabulary is the most "
      "scattered in the data: *Resident*, *Registrar*, *Facharzt* and *Interno* all mean "
      "a doctor in training and share no common word.",
      "**It is where the outside taxonomy cannot help.** 52 of our 58 clinical example "
      "words are absent from it — it lists Physician, Clinician and Surgeon and has no "
      "specialty list at all. That gap is what a clinical expert would fill.",
      "**19 November: every job title containing *consultant* left Practitioner.** The "
      "word is two different jobs. In Britain and Ireland a consultant is a hospital "
      "specialist; in most of the rest of the world it is a business adviser, and the "
      "record does not say which. It was the largest title in the audience. Taking "
      "them all out cost about **5,400 people** - Practitioner went from 62,141 to "
      "57,297 - and that price was accepted deliberately in exchange for an audience "
      "that does not quietly contain management consultants. The titles are not lost: "
      "they sit in a holding group and can be brought back by name once there is a "
      "rule we trust.",
      "**The 93.4% was measured before that change** and has not been re-measured on "
      "the smaller audience. The people removed included known errors, so it is more "
      "likely to understate than to overstate - but read it as out of date, not as a "
      "current figure.",
      "**Settled 19 November, and not yet built.** `medical physicist` (346 records) "
      "moves to Clinical researcher. A medical physicist does not treat patients — "
      "they plan radiotherapy doses and assure the quality of imaging equipment — so "
      "an audience defined as a clinician who treats patients is the wrong one. It is "
      "the same decision `clinical scientist` got on 29 October, for the same reason. "
      "**Two consequences accepted with it:** they enter the all-fields Researcher "
      "audience, which has no department test, and they stay in Healthcare (broad) "
      "only through Clinical researcher, which does — so a medical physicist in a "
      "physics department leaves the healthcare audiences altogether. analyses/55 "
      "query 3b measured both before the build, and the answer was better than "
      "expected: all 170 of the medical physicists this pipeline confirms work in "
      "radiotherapy, radiology or oncology departments, so every one of them "
      "re-confirms as a clinical researcher and rolls back up into Healthcare "
      "(broad). The feared case — a medical physicist in a physics department — "
      "does not exist among the people we confirm. Healthcare (broad) grew 0.513% "
      "on the build against a control median of 0.503%: the move cost it nothing.",
      "**And one thing the measurement could not do, which is worth knowing before "
      "the next small decision.** 291 people typed this title and only 170 were in "
      "any audience, so the move recruited about 121 people who were nowhere "
      "before. That gain is invisible in the Researcher audience: 291 people is "
      "0.085% of it, while the four control audiences spread across 0.455 "
      "percentage points — about 1,560 people at that size. Comparing audience "
      "counts cannot resolve a decision smaller than about half a percent of the "
      "audience. The dictionary can, and it does: one title, 354 records, moved by "
      "a named person, with no growth term in it at all.",
      "**Settled 19 November, nothing moves.** A bare `doctor` (4,465 records) stays "
      "in Practitioner, written down as a human decision so it cannot drift on the "
      "next dictionary rebuild. Unlike `consultant`, which is a hospital specialist "
      "in two countries and a business adviser everywhere else, `doctor` names a "
      "medical qualification in every language that borrowed it, and the audience "
      "already requires a human-health department beside the title. This is not the "
      "bare `dr` on the marketing list, which is a form of address and still open.",
      "**Open — with Matthew:** veterinarians (91 people) and sport and exercise "
      "science (78), both in the healthcare audiences today by accident rather than "
      "decision. Neither is an engineering call; both need somebody to say whether "
      "the field is healthcare."])

    aud("CLINICAL ADMINISTRATOR — 8,398 people, 94.9% correct", [
      "**How it is decided.** A leadership title **and** a human-health department. "
      "Patient contact is not required: somebody running a cardiology unit is correct.",
      "**88.9% → 94.9% on 5 November, re-measured on a fresh sample.** The organisation "
      "axis was confirming industry medical directors — a company scored 0.25, or 0.15 "
      "as a *funder*, which Amgen and Vertex also are in ROR, and that lifted them over "
      "the line. Company and Funder are 0.00 now, with an industry-word veto where ROR "
      "has no match.",
      "**A code fix came with it that had been wrong all along:** a veto used to fall "
      "back to the unknown-organisation score instead of zero, so it had never worked "
      "for this audience at all.",
      "**That bullet used to say the industry people simply moved next door, and on "
      "19 November we checked.** Healthcare (broad) is gentler about employers - a "
      "company scores 0.60 there against 0.00 here - so the worry was that blocking "
      "them in one audience just left them in the other. Measured on the build: of "
      "the forty employers sending the most leadership titles into Healthcare "
      "(broad), **not one is a company.** They are hospitals, medical faculties, "
      "health ministries, the NIH, Cleveland Clinic, Mayo. Forty rows cannot rule "
      "out a scattered tail of one- and two-person firms, but the leak this "
      "audience was worried about is not there.",
      "**Not a question, a caveat:** the 94.9% was read on 5 November, and on 19 November this audience "
      "gained members - `chief medical officer`, `nurse manager`, `hospital director`, `director of nursing` and the medical-director variants, taking it from "
      "8,258 to 8,377. The figure was measured on a sample that never saw them. The "
      "change is small, about 1% of the audience, so 94.9% is still the best figure "
      "we have and nothing here needs deciding - but it is older than the audience "
      "it describes, and the honest way to quote it is with its date."])

    aud("HEAD OF FACULTY — 17,421 people, 83.3% correct — PARKED", [
      "**How it is decided.** A faculty-level title — dean, head of department, rector, "
      "provost, chancellor — at an organisation ROR types as *Education*. Current posts "
      "only. It is the one audience built for precision rather than reach.",
      "**67.7% → 83.3% on 5 November**, measured on a second, independent sample. The "
      "cause was the organisation axis, not the title: Facility scored 0.60, Nonprofit "
      "0.40 and Government 0.30, so against a 0.65 line a bare *Director* scored 0.84 at "
      "Max Planck, 0.76 at a nonprofit and 0.72 at WHO. Only *Education* scores now.",
      "**It is parked and is not being delivered**, and the reason is not a bug: the job "
      "title is the only evidence it has, so a vague title has nothing to contradict it. "
      "20% of the audience holds nothing but `director`, `head` or `chair`.",
      "**Two measured faults with no title rule that can reach them.** 7% are "
      "administrative Directors identifiable only by their department — *Innovation "
      "Office*, *Research and Sponsored Programs*. 6% arrive through a university-named "
      "hospital, which the organisation-name fallback reads as a university.",
      "**And it is about to change shape.** Marketing have asked for it to be opened up "
      "beyond academia, to reach decision makers and budget holders. Section 7, item 4."])

    aud("PHARMACIST — 2,090 people, 95.7% correct", [
      "**How it is decided.** The title must name a pharmacist, and the title is the "
      "only way in — nobody becomes a pharmacist by working in a pharmacy department.",
      "**81.8% → 95.7% on 5 November**, the second figure on a fresh sample. It was the "
      "weakest audience in the project: 11% of it were pharmacologists and pharmaceutical "
      "scientists, because the embedding cannot tell pharmacology from pharmacy — "
      "*pharmacologist* scored 0.953 against the pharmacist examples.",
      "**Four patterns, each vetoed by a pharmacist word**, so `clinical pharmacologist` "
      "leaves and `hospital pharmacist` stays. Pharmacy students and technicians went "
      "out with them.",
      "**Open:** Portuguese and Spanish forms the English stems miss, and clinical "
      "chemists. Overrides, not a new rule."])

    aud("LIBRARIAN — 713 people, 98.5% correct", [
      "**How it is decided.** Eleven literal patterns, not the machine: a title either "
      "contains a library word or it does not. The employer carries no weight at all. "
      "Current posts only.",
      "**It is the one audience whose error rate we actually know**, because every "
      "assignment is exact and all 700 people were read rather than a sample. The errors "
      "are the word used for something else: *DNA-encoded library technology*, *crypto "
      "library developer*, *game librarian*.",
      "**Two exclusions by choice.** Archivists, because the word also collected "
      "archaeologists and glaciologists, and *information specialist*, because it "
      "collected every IT job in the data."])

    return d
