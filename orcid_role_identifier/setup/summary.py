# -*- coding: utf-8 -*-
"""Section 10: the whole project in one read.

Written 2026-11-04 on Merve's instruction, after they said the project as a
whole had stopped being legible from the inside: "ben hala bu projede ne
yaptigimizi anlamiyorum". It is deliberately the LAST section rather than the
first - everything in it is stated in full earlier in the document, and this
is the version to hand someone who has five minutes.
"""
from docx_lib import *
from docx.shared import Pt


def build(d):
    h(d, "10.  Summary — the whole project in one read")
    para(d, "Everything below appears in full earlier in this document. This section "
            "exists so that the project can be explained in five minutes without "
            "reading the other nine.", space_after=10)

    # ------------------------------------------------------------ THE PROBLEM
    h(d, "10.1  The problem", 2)
    para(d, "ORCID is a public registry where researchers keep their own records. People "
            "type their job titles as **free text**. We hold **1,737,768 employment "
            "records** that carry a Springer Nature identifier, and inside them are "
            "**317,302 distinct job titles** — in every language, with every typo, from "
            "`professor` to `profossor` to `dean s chair associate professor`.")
    para(d, "What marketing needs is simple: *is this person a clinician, an academic, a "
            "librarian?* The project turns that free text into **nine audiences**.")

    # ------------------------------------------------------------ THE METHOD
    h(d, "10.2  How it works — three steps", 2)

    para(d, "**Step 1 — we label the dictionary, not the people.**", space_after=2)
    para(d, "This is the single most important decision in the design. We do not classify "
            "1.7 million people; we classify the **317,302 distinct job titles once**, "
            "into ten title groups, and the 459,123 distinct departments alongside them. "
            "After that, labelling a person is a join.")
    para(d, "What it buys: a correction is one row. When `junior researcher` was found in "
            "the senior research group, one override moved **42,949 records**.",
            space_after=8)

    para(d, "**Step 2 — three decision sources per title, in a fixed order of "
            "precedence.**", space_after=2)
    table(d, ["Source", "What it is", "Scale"],
     [["**HUMAN**", "A title decided by hand, because the model was wrong about the "
       "world rather than about the word", "533 titles"],
      ["**PATTERN**", "A rule for where the model is wrong *systematically*, so that one "
       "line fixes a family of titles", "21 patterns"],
      ["**VECTOR**", "The title compared **by meaning** to hand-written anchor titles. "
       "Above 0.65 similarity it joins that anchor's group. This does the great majority "
       "of the work, and it needs no language list: `Facharzt`, `médico` and `jefe de "
       "servicio` all land in the right place", "151 anchors"]],
     widths=[0.95, 4.75, 0.95], size=9)
    para(d, "A human decision beats a pattern, and a pattern beats the model. Nothing is "
            "ever overridden silently — every row records which of the three decided it.",
            space_after=8)

    para(d, "**Step 3 — a score per person, per audience, from three axes.**",
         space_after=2)
    para(d, "The **job title**, the employer's **organisation type** from ROR (university, "
            "hospital, company), and the department's **discipline**. Each audience weights "
            "the three differently and has its own threshold; above it the person is "
            "CONFIRMED, below it PROBABLE.")
    box(d, "THE PRINCIPLE BEHIND THE SCORE", [
     "**Certainty is two independent signals agreeing — not one signal scoring highly.**",
     "",
     "That is why the score has three axes rather than one, and it is also why raising a "
     "threshold is usually the wrong lever. Measured on 4 November: every single CONFIRMED "
     "person in the four healthcare audiences and in Head of Faculty is carried by two or "
     "more axes. Head of Faculty is structurally incapable of anything else — its title "
     "weight is 0.60 against a threshold of 0.65, so a job title alone can never confirm.",
    ])

    # ------------------------------------------------------------ THE TABLE
    h(d, "10.3  Where each audience stands", 2)
    para(d, "Counted after the build of 4 November, except the three rows marked "
            "*5 Nov*, which were re-counted after that day's rule changes.",
            space_after=4)
    table(d, ["Audience", "Confirmed", "Probable", "Marketing consent", "State"],
     [["**Lecturer**", "406,860", "308", "109,117", "Most worked, best validated"],
      ["**Researcher**", "332,026", "763", "64,981", "Solid; ships as ONE audience"],
      ["**HCP broad**", "124,223", "37,031", "26,790",
       "Wide, but the job title is now mandatory"],
      ["**HCP practitioner**", "61,421", "2,910", "13,887", "Long tail — least read"],
      ["**HCP researcher**", "53,621", "2,077", "9,750", "Follows Researcher"],
      ["**Head of Faculty**", "15,048", "—", "—",
       "**Narrowed 5 Nov; 83.3% read correct**"],
      ["**HCP administrator**", "7,528", "—", "—",
       "**Fixed 5 Nov: 89% → 94.9% read correct**"],
      ["**Pharmacist**", "2,051", "—", "—",
       "**Fixed 5 Nov: 82% → 95.7% read correct**"],
      ["**Librarian**", "692", "0", "177", "Small, entirely rule-driven"]],
     widths=[1.5, 0.95, 0.85, 1.25, 2.1], size=9)
    para(d, "**Measured accuracy for every audience, read by hand, is in section 6.0**: "
            "Researcher 99.0%, Lecturer 98.7%, Librarian 98.5%, Pharmacist 95.7%, HCP "
            "administrator 94.9%, the other healthcare audiences 90–93%, Head of Faculty "
            "83.3% — each the share correct of the cases that could be decided.",
            size=9, space_after=4)
    para(d, "**Three warnings about that table.** The rows **overlap** — one person can be "
            "both a Lecturer and an HCP researcher — so the columns must not be added up. "
            "\"Marketing consent\" here is `mkt_pref_opt_in` only; *legitimate "
            "interest* is a wider basis and is not counted in it. And the consent column "
            "was measured on 4 November **before** that day's build, so it trails the "
            "Confirmed column by roughly +0.7% everywhere except HCP broad, whose figure "
            "is post-build. The first five rows also predate the 5 November rule "
            "changes, which moved named chairs into Lecturer and pharmacologists out "
            "of Pharmacist, so they will move a little at the next full count.",
            space_after=8)

    # ------------------------------------------------------------ ONE BY ONE
    h(d, "10.4  One by one", 2)

    para(d, "**Lecturer** — the most mature part of the project. Against the survey we "
            "find **91.1%** of the people who call themselves academics. Of the people we "
            "put in Lecturer, 78.2% say so themselves — and that number looks worse than "
            "it is: of the 1,354 who said something else, only **50** held a title that "
            "was not a teaching title at all. So the rate at which we read the title "
            "correctly is **99.2%**. teaching_academic is the cleanest group in the "
            "dictionary.")

    para(d, "**Researcher** — the project's largest single error lived here and has been "
            "fixed: `junior researcher`, **42,949 records**, sat in the *established* "
            "research group at 0.870 similarity, because the model places 'junior' and "
            "'senior' close together as two ends of one axis. Merve closed the "
            "early/senior split question on 4 November: **Researcher ships as one "
            "audience and we are not asking.** The doctoral-student rule was settled the "
            "same day — see 10.6.")

    para(d, "**Head of Faculty — narrowed and re-measured on 5 November.** A hand reading "
            "of 400 people found 18.8% wrong, and the main cause was the organisation: "
            "research institutes, nonprofits and government bodies scored enough to "
            "confirm a bare *Director*. **Only education organisations count now** (ROR "
            "type *Education*, or a *university / college / faculty* name where ROR has no "
            "match), named chairs moved to Lecturer, and 52 administrative titles left. "
            "**18,869 → 15,047 people; 67.7% → 83.3% correct of the decided**, on a second, "
            "independent sample. What is left: 20% bare `director` / `head` / `chair` "
            "(marketing), 7% administrative Directors visible only in the department, "
            "6% university-named hospitals.")

    para(d, "**HCP broad** — deliberately the widest audience; its job is that nobody "
            "clinical is lost. On 4 November Merve closed its one soft edge: it used to "
            "admit a person on the **department alone**, and 6,115 CONFIRMED people had "
            "no clinical job title at all — an administrator in a cardiology department. "
            "**The job title is now mandatory.** The 1,624 people with a clinical title "
            "but no department stay, because the title is the evidence and 11.6% of "
            "records carry no department.")

    para(d, "**It built the same day and the forecast held.** CONFIRMED came in at "
            "124,223 against 123,258 predicted — 0.8% out, and the overshoot is the "
            "underlying data refreshing rather than the change, because every other "
            "audience grew in the same build. Nobody without a clinical title is left. "
            "But **PROBABLE fell from 107,896 to 37,031**, a drop of 70,865, which was "
            "not forecast and should have been: a clinical department alone scores "
            "0.40 against a probable threshold of 0.30, so everyone with a clinical "
            "department and no clinical title whatsoever had been sitting in that tier. "
            "It costs nothing commercially — only CONFIRMED ships — but anyone reading "
            "total audience size will see two thirds of that tier disappear.")

    para(d, "**And it exposed a different problem the department arm had been hiding.** "
            "The people who left are not administrators. Research and leadership titles "
            "in a clinical department keep their healthcare coverage through HCP "
            "researcher and HCP administrator; the cost falls almost entirely on "
            "`teaching_academic`, and inside it on a family that is unmistakably "
            "clinical — at least 2,516 people across `Clinical Assistant Professor`, "
            "`Professor of Medicine`, `Clinical Instructor` and their variants, plus "
            "1,979 medical students and 511 people whose entire title is `M.D.` These "
            "are floors read off a truncated list, not totals. This is **not** an "
            "argument to restore the department arm, which would readmit the 6,115. It "
            "is the strongest evidence yet on the one-title-one-profession question in "
            "1.10: a Clinical Assistant Professor really is both a lecturer and a "
            "clinician.")

    para(d, "**HCP practitioner** — one cleanup pass has landed: the share of records "
            "below 0.75 similarity went **40.64% to 33.80%**, through 31 specialty anchors "
            "and 40 human overrides, each one moving exactly the number of records "
            "predicted. But its **reading coverage is ~38%, the lowest of any group**, and "
            "the reason is structural: clinical job titles are the least standardised "
            "vocabulary in the data. Resident, Registrar, Facharzt, Interno and Senior "
            "House Officer describe overlapping things and share no common stem, so only a "
            "meaning-based match can connect them. More reading is the current task.")

    para(d, "**HCP researcher and HCP administrator** — neither has a dictionary group of "
            "its own; they intersect the research and leadership groups with a clinical "
            "discipline. hcp_administrator is the most threshold-sensitive role we have "
            "and has not been separately reviewed.")

    para(d, "**Pharmacist** — it **cannot be validated against the survey**, which offers "
            "no pharmacist option, so it was read by hand instead: 81.8% correct of the "
            "decided on 5 November, the weakest audience, because the embedding cannot "
            "tell pharmacology from pharmacy. Four patterns scoped to the pharmacist group "
            "moved pharmacologists to Lecturer or Researcher and students and technicians "
            "out, each vetoed by any pharmacist word. **2,304 → 2,051 people; 95.7% "
            "correct** on a fresh sample.")

    para(d, "**Librarian** — 692 people, and every single one scores exactly 1.000. The "
            "reason is worth knowing: the group is **99.9% decided by pattern** and the "
            "role is weighted 1.00 on the title and 0.00 on the organisation, so the "
            "threshold is inert at every value from 0.60 to 0.95. Librarian quality cannot "
            "be managed by a threshold — the only lever is the pattern list. Its "
            "reachable rate is also the lowest, 54% against 70–78% elsewhere, because "
            "library staff publish less and so ORCID knows fewer of them.")

    # ------------------------------------------------------------ THE LIMIT
    h(d, "10.5  The real limit is reach, not accuracy", 2)
    box(d, "WHERE THE PROJECT ACTUALLY NARROWS", [
     "`290,045   people answered the survey`",
     "`238,440   we could match to the CDP`",
     "` 46,656   we know anything at all about`",
     "",
     "The accuracy side is in good shape. **What narrows is how many people we know.** "
     "Any further effort spent on precision buys less than effort spent on coverage of "
     "identity — and that is a different project from this one.",
    ], fill="FDF8EF", accent=AMBER)

    # ------------------------------------------------------------ WHAT IS LEFT
    h(d, "10.6  What is genuinely left", 2)
    table(d, ["What", "Whose call", "Note"],
     [["`director` family, psychologists, and three smaller definition questions",
       "**Marketing**", "Re-priced 5 Nov on a fresh sample: bare `director` / `head` / "
       "`chair` is **20% of Head of Faculty, ~3,000 people** — now the largest thing "
       "between that audience and ~90%"],
      ["Pharmacist: the last 4%", "Ours",
       "DONE 5 Nov for pharmacology, students and technicians (81.8% → 95.7%). Left: "
       "Portuguese and Spanish forms the English stems miss, clinical chemists, one "
       "misspelling — overrides, not a new rule"],
      ["Department-word veto for Head of Faculty", "Ours",
       "7% of the audience: a bare *Director* whose department is an office "
       "(*internationalization, sponsored programs, enrollment, innovation office*). "
       "No title rule can see it"],
      ["Hospital veto in the organisation-name fallback", "Ours",
       "6% of Head of Faculty: *...University ... Affiliated Hospital* reads as a "
       "university. A 0.00 *hospital* pattern, the same mechanism as the company veto"],
      ["Department override (*Faculty of Science* read as clinical)", "Ours",
       "HCP administrator 89% → 95% was done 5 Nov through the organisation. What is left "
       "there is ~1%: general-science faculties the department dictionary reads as "
       "`health_clinical`. Titles have an override file; departments do not"],
      ["Is an industry medical director in HCP broad?", "**Marketing**",
       "They left HCP administrator (threshold 0.70) but keep HCP broad (0.60) through the "
       "roll-up. Left as it is until marketing says whether broad means the work or the field"],
      ["A second reader on the 5 Nov samples", "Merve",
       "The accuracy table in 6.0 is one reader's judgement; ~30 rows per audience "
       "read again turns it into a reportable figure"],
      ["Read more of practitioner", "Ours",
       "At ~38% coverage it is the least-read group. analyses/35 is the reading list, and "
       "it points at the band ABOVE 0.75 similarity that no review has ever examined"],
      ["The doctoral-student rule, as overrides", "Ours",
       "Decided 4 Nov: a doctoral student is in Researcher only if the **title** says "
       "research. `phd fellow`, 19,424 records, says neither. One question back to Merve "
       "first — whether `research assistant` counts as saying it"],
      ["The education signal", "Ours",
       "`educations` is pulled into the raw layer and consumed by nothing. A degree (MD, "
       "MBBS, PharmD, MLIS) is a far more standardised vocabulary than a job title, and "
       "it is the only signal that can speak to the 146,865 records whose title is just "
       "`dr` or `md`"],
      ["The clinical academics", "Ours + Marketing",
       "At least 2,516 people whose title says both `Clinical` and `Professor`, plus "
       "1,979 medical students, now reach no healthcare audience. Cannot be fixed "
       "without 1.10 — a title would have to sit in two groups"],
      ["The Students audience and its consent basis", "Both",
       "Agreed, not started"]],
     widths=[2.1, 0.95, 3.6], size=9)
    para(d, "**One thing that is NOT on that list.** Raising a confidence threshold was "
            "measured in full on 4 November and rejected: the people carried by a single "
            "axis are 372,841 Lecturers and 295,719 Researchers, not anyone in healthcare "
            "— and a threshold cannot reach them anyway, because 250,601 of those "
            "Lecturers score exactly 1.000 and no number below 1.00 removes them. If that "
            "population is ever to be tightened, the lever is a floor on the second axis, "
            "which is a rule rather than a number.")
