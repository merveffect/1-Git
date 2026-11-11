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
            "CONFIRMED, below it PROBABLE. **Only CONFIRMED is ever delivered, and as of "
            "11 November that is settled rather than pending** — Merve closed the "
            "question of switching the second tier on: nobody we are not certain about "
            "enters an audience. It would have added 45,054 unique people and nearly "
            "doubled the broad healthcare audience.")
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
    para(d, "One measurement, taken from the second build of 10 November 2026, which "
            "landed the doctoral-student rule. Every figure in this table comes from "
            "that single count — earlier versions of it mixed three dates.",
            space_after=4)
    table(d, ["Audience", "Confirmed", "Reachable", "Of those", "State"],
     [["**Lecturer**", "410,499", "**319,291**", "77.8%", "Most worked, best validated"],
      ["**Researcher**", "333,280", "**237,391**", "71.2%",
       "ONE audience; students removed 10 Nov"],
      ["**HCP broad**", "124,982", "**93,377**", "74.7%",
       "Job title mandatory; departments fixed 10 Nov"],
      ["**HCP practitioner**", "61,945", "**46,450**", "75.0%", "Long tail — least read"],
      ["**HCP researcher**", "54,016", "**39,758**", "73.6%",
       "Read 3x; 94.3% after the department fix"],
      ["**Head of Faculty**", "15,159", "**11,962**", "78.9%",
       "Narrowed 5 Nov; 83.3% correct"],
      ["**HCP administrator**", "7,563", "**5,949**", "78.7%",
       "Org veto fixed 5 Nov; 94.9% correct"],
      ["**Pharmacist**", "2,060", "**1,531**", "74.3%",
       "Pharmacologists removed 5 Nov, −10.4%"],
      ["**Librarian**", "699", "**384**", "54.9%", "Small, entirely rule-driven"]],
     widths=[1.5, 0.95, 1.0, 0.7, 2.4], size=9)
    para(d, "**Measured accuracy for every audience, read by hand, is in section 6.0**: "
            "Researcher 99.0%, Lecturer 98.7%, Librarian 98.5%, Pharmacist 95.7%, HCP "
            "administrator 94.9%, HCP practitioner 93.4%, HCP broad 90.6%, Head of "
            "Faculty 83.3% — each the share correct of the cases that could be decided. "
            "**HCP researcher has been read three times**: 90.0%, then 89.0%, then "
            "**94.3%** after the department fix of 10 November. That last move is within "
            "sampling noise at n=100, and the error composition is the better evidence — "
            "field errors fell from 4 to 2 and both survivors are fields no anchor "
            "addressed.", size=9, space_after=4)
    para(d, "**Two warnings about that table.** The rows **overlap** — one person can be "
            "both a Lecturer and an HCP researcher — so the columns must not be added up.",
            space_after=4)
    box(d, "REACHABLE IS THREE TIMES WHAT THIS DOCUMENT USED TO SAY", [
     "**Reachable means any of four legal bases**: marketing opt-in, advertising opt-in, "
     "legitimate interest, and book-author consent. Set in `dbt_project.yml` as "
     "`consent_basis: 'any_basis'`, applied by `consent_predicate()`, counted as "
     "`reachable` in `fct_role_audience_summary`.",
     "",
     "Every reachable figure quoted from this document before 10 November was "
     "`mkt_pref_opt_in` ALONE, which is **one basis out of four**. Lecturer read 109,323 "
     "and is 319,291. Researcher read 64,618 and is 237,391. HCP researcher was out by "
     "4.1x. The pipeline has been right since 16 October and the reporting was taking a "
     "narrower column from the raw layer instead of reading the model built to answer "
     "this.",
     "",
     "Legitimate interest is the reason: it is far larger than either opt-in — 295,314 of "
     "Lecturer against 109,323 — and it was the column being left out.",
    ], fill="FDF8EF", accent=AMBER)
    box(d, "THE AUDIENCES GREW AND THE REACHABLE PART DID NOT", [
     "Against the 4 November build, the six audiences that no rule touched all grew by "
     "the same **+0.6% to +1.0%** — the underlying data refreshing, not anything we did. "
     "The three that moved further moved by exactly what was predicted of them: Head of "
     "Faculty −19.7%, Pharmacist −10.4%, HCP administrator −0.7% where it would otherwise "
     "have gained 0.8%.",
     "",
     "**Three quarters of every audience is reachable**, 71% to 79%, except Librarian at "
     "54.9%. An earlier version of this section said 18% to 30%, which was one legal "
     "basis out of four being mistaken for all of them.",
     "",
     "This is 10.5 restated with fresh numbers: effort spent on precision is no longer "
     "what limits this project.",
    ], fill="FDF8EF", accent=AMBER)

    # ------------------------------------------------------------ ONE BY ONE
    h(d, "10.4  One by one", 2)

    para(d, "**Lecturer** — the most mature part of the project. Against the survey we "
            "find **91.1%** of the people who call themselves academics. Of the people we "
            "put in Lecturer, 78.2% say so themselves — and that number looks worse than "
            "it is: of the 1,354 who said something else, only **50** held a title that "
            "was not a teaching title at all. So the rate at which we read the title "
            "correctly is **99.2%**. teaching_academic is the cleanest group in the "
            "dictionary.")

    para(d, "**Researcher — the doctoral-student rule landed on 10 November.** A "
            "doctoral student is in this audience only if the job title says research, "
            "in any language. `phd researcher` and `phd research fellow` stay; `phd "
            "fellow` — 19,424 records — leaves. **1,400 people of 333,289, 0.42%.** The "
            "two title groups behind it, early-career and senior, were also merged into "
            "one on the same day: no audience had ever read them apart, and the "
            "project's largest single error was a title landing in the wrong one of "
            "two groups that meant the same thing.")

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

    para(d, "**All four healthcare audiences — the department dictionary was corrected on "
            "10 November.** A department reaching a healthcare audience has to read as "
            "clinical, and 108,587 records of department names were reading as clinical "
            "when they are not: `School of Life Sciences`, `Faculty of Science`, `Plant "
            "Pathology`, `Physikalisches Institut`, `Faculty of Arts and Humanities`. The "
            "cause was two anchors, `faculty of medicine` and `school of medicine`, which "
            "are four words of which two carry no field at all, so anything named "
            "*Faculty of something* sat close to them. **85% of it is gone**, 108,587 "
            "records down to 16,536, and 4,620 records also left `pharmacy`.")

    para(d, "**It was fixed by ADDING anchors rather than removing those two, and the "
            "reason is worth keeping.** Removing them would have sent 270 departments to "
            "`pharmacy` — the one receiving discipline that feeds a live audience — so "
            "114,443 records of correct removal would have bought 12,525 records of new "
            "error. Adding puts a department where we chose; removing sends it wherever "
            "happens to be second.")

    para(d, "**HCP researcher and HCP administrator** — neither has a dictionary group of "
            "its own; they intersect the research and leadership groups with a clinical "
            "discipline. hcp_administrator is the most threshold-sensitive role we have "
            "and has not been separately reviewed.")

    para(d, "**Pharmacist** — it **cannot be validated against the survey**, which offers "
            "no pharmacist option, so it was read by hand instead: 81.8% correct of the "
            "decided on 5 November, the weakest audience, because the embedding cannot "
            "tell pharmacology from pharmacy. Four patterns scoped to the pharmacist group "
            "moved pharmacologists to Lecturer or Researcher and students and technicians "
            "out, each vetoed by any pharmacist word. **2,304 → 2,065 people; 95.7% "
            "correct** on a fresh sample.")

    para(d, "**Librarian** — 699 people, and every single one scores exactly 1.000. The "
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
      ["~~Department override (*Faculty of Science* read as clinical)~~", "**DONE 10 Nov**",
       "108,587 records of non-clinical departments were reading as clinical and **85% is "
       "gone**. Fixed by ADDING 16 anchors rather than removing the two that caused it — "
       "removal would have sent 270 departments into `pharmacy`, the one receiving "
       "discipline that feeds an audience. Departments still have no override file and "
       "did not need one"],
      ["Is an industry medical director in HCP broad?", "**Marketing**",
       "They left HCP administrator (threshold 0.70) but keep HCP broad (0.60) through the "
       "roll-up. Left as it is until marketing says whether broad means the work or the field"],
      ["A second reader on the 5 Nov samples", "Merve",
       "The accuracy table in 6.0 is one reader's judgement; ~30 rows per audience "
       "read again turns it into a reportable figure"],
      ["**Read practitioner — the agreed next task**", "Ours",
       "At ~38% coverage it is the least-read group, 36,266 titles. `analyses/35` query 3 "
       "is the reading list and points at the band **ABOVE** 0.75 similarity that no "
       "review has ever examined — every practitioner review ever written filtered "
       "*below* 0.75, and `junior researcher` sat at 0.870"],
      ["Two field errors no anchor reaches", "Ours",
       "Found in the third HCP researcher reading: `Institute of Vertebrate Paleontology "
       "and Paleoanthropology` and `Photometry and radiometry group`. Neither is "
       "agriculture, physics, humanities or life sciences, so the 16 new anchors do not "
       "see them. Small, and the method for fixing them is known"],
      ["A job title that is the single word `Fellow`", "**Marketing**",
       "Four of thirteen not-sure rows in the third reading, now the largest single "
       "uncertainty in HCP researcher. In an American teaching hospital it means a "
       "physician in subspecialty training; in a British university it means a "
       "researcher. The record carries nothing that separates them. Question 1.9"],
      ["~~The doctoral-student rule~~", "**DONE 10 Nov**",
       "Written as ONE pattern row with a veto, not 1,191 overrides. Merve chose the "
       "loose reading, so any research word in any language keeps them. 1,400 people left "
       "Researcher. Scoped to the early end on purpose: 24 of the 25 largest titles in "
       "the senior half carry `phd` as a CREDENTIAL, and the same rule there would demote "
       "senior researchers for holding a doctorate"],
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
