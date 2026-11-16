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
     [["**Researcher**", "96.8%", "1.0%", "2.3%", "**99.0% ± 1.0**", "~3,300"],
      ["**Lecturer**", "98.2%", "1.2%", "0.5%", "**98.7% ± 1.1**", "~5,100"],
      ["**Students**", "91.8%", "1.2%", "7.0%", "**98.7% ± 1.3**", "~1,300"],
      ["**Librarian** (all 700)", "97.1%", "1.4%", "1.4%", "**98.5%**", "10"],
      ["**Pharmacist**", "82.5%", "3.8%", "13.8%", "**95.7% ± 1.9**", "~80"],
      ["**HCP administrator**", "88.0%", "4.8%", "7.2%", "**94.9% ± 2.2**", "~360"],
      ["HCP practitioner", "82.0%", "5.8%", "12.2%", "93.4% ± 2.6", "~3,500"],
      ["HCP broad", "81.5%", "8.5%", "10.0%", "90.6% ± 3.0", "~10,600"],
      ["HCP researcher", "81.2%", "9.0%", "9.8%", "90.0% ± 3.1", "~4,800"],
      ["**Head of Faculty**", "56.2%", "11.2%", "32.5%", "**83.3% ± 4.4**", "~1,700"]],
     widths=[1.75, 0.7, 0.65, 0.75, 1.35, 1.2], size=8.5)
    para(d, "**How to read it.** *Correct, of the decided* leaves the not-sure rows out, "
            "so it is the error rate where an answer exists; the not-sure column says how "
            "much is waiting for a definition. The ± is a 95% interval. *Wrong people* "
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

    aud("LECTURER — 423,668 people, 98.7% correct", [
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
      "**Open:** visiting scholars and fellows, and honorary professors — both with "
      "marketing, both one line to change."])

    aud("RESEARCHER — 340,705 people, 99.0% correct", [
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

    aud("STUDENTS — 105,658 people, 98.7% correct", [
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
      "**Open:** 6% of the sample wrote only a qualification as their whole job title — "
      "`PhD`, `Master`, `Bachelor` — and the record cannot say whether they are studying "
      "for it or have held it for twenty years. One wrote `Phd holder`."])

    aud("HEALTHCARE (BROAD) — 181,295 people, 90.6% correct", [
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

    aud("PRACTITIONER and CLINICAL RESEARCHER — 62,141 and 108,805 people, "
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
      "**Open:** veterinarians (91 people) and sport and exercise science (78), both in "
      "the healthcare audiences today by accident rather than decision."])

    aud("CLINICAL ADMINISTRATOR — 8,258 people, 94.9% correct", [
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
      "**Open:** industry medical directors still keep Healthcare (broad), whose "
      "threshold is lower. Left as it is until that audience is defined."])

    aud("HEAD OF FACULTY — 17,218 people, 83.3% correct — PARKED", [
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

    aud("PHARMACIST — 2,064 people, 95.7% correct", [
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

    aud("LIBRARIAN — 700 people, 98.5% correct", [
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
