# -*- coding: utf-8 -*-
"""Section 6: one heading per target audience. Lecturer in full, the rest short."""
import os
from docx_lib import *
from docx.shared import Pt, Inches
F = None

def build(d, figdir):
    global F; F = figdir

    h(d, "6.  Every target audience, one by one")
    para(d, "Nine audiences. This section gives each one its own heading: how big it is, "
            "how it is labelled, how accurate it has been shown to be, what we fixed and "
            "what is still open. Lecturer is written out in full because it is the one we "
            "have measured most; the others are summarised and will be expanded in turn.")

    para(d, "**Two numbers appear throughout and they are not the same thing.** They fail "
            "in opposite directions and an audience can be good at one and poor at the "
            "other:", space_after=4)
    bullet(d, "**Did we find them?** Of the people who say they are this, how many did we "
              "put in the audience. A low score means we are missing people.")
    bullet(d, "**Do they agree?** Of the people we put in the audience, how many say they "
              "are this. A low score means we are letting the wrong people in.")
    para(d, "Both are measured against 28,866 people who answered two separate surveys the "
            "same way. Those people agree with themselves 88.9% of the time, so **88.9% is "
            "the ceiling** for either number.", space_after=10)

    table(d, ["Audience","People","Did we find them?","Do they agree?","State"],
     [["**Lecturer**","399,884","**91.1%**","**78.2%**","Best measured. Detailed below"],
      ["Researcher","321,824","74.3%","43.9%","Good. Precision depressed by multi-role people"],
      ["Healthcare (broad)","126,869","**90.9%**","22.7%","A wide net on purpose"],
      ["Practitioner","60,937","—","35.8%","Survey cannot split the healthcare sub-audiences"],
      ["Clinical researcher","50,600","—","48.2%","Same"],
      ["**Head of faculty**","17,528","**23.8%**","**26.3%**","**The weak one.** Known causes"],
      ["Clinical administrator","6,865","—","22.5%","71 people checked — too few"],
      ["Pharmacist","2,245","—","—","**Cannot be measured** — no survey option"],
      ["Librarian","668","—","—","**Cannot be measured** — 4 people"]],
     widths=[1.4,0.8,1.0,0.85,2.55], size=8.8)

    # ------------------------------------------------- 6.0 READ BY HAND, 5 NOV
    h(d, "6.0  A third number: every audience read by hand — 5 November", 2)
    para(d, "The survey numbers above cannot reach Pharmacist or Librarian at all, and for "
            "the healthcare sub-audiences they cannot separate one from another. So on "
            "5 November each audience was measured a third way: **400 CONFIRMED people "
            "drawn at random** (all 692 for Librarian), and every one read — job title, "
            "employer and department — and marked **correct**, **wrong** or **not sure**. "
            "*Not sure* is used for two things only: a definition marketing has not yet "
            "settled (psychologists, veterinarians, a bare `director`), and a record that "
            "does not carry enough to decide.", space_after=6)
    table(d, ["Audience", "Correct", "Wrong", "Not sure", "Correct, of the decided", "Wrong people, est."],
     [["**Researcher**", "96.8%", "1.0%", "2.3%", "**99.0% ± 1.0**", "~3,300"],
      ["**Lecturer**", "98.2%", "1.2%", "0.5%", "**98.7% ± 1.1**", "~5,100"],
      ["**Librarian** (all 692)", "97.1%", "1.4%", "1.4%", "**98.5%**", "10"],
      ["HCP practitioner", "82.0%", "5.8%", "12.2%", "93.4% ± 2.6", "~3,500"],
      ["HCP broad", "81.5%", "8.5%", "10.0%", "90.6% ± 3.0", "~10,600"],
      ["HCP researcher", "81.2%", "9.0%", "9.8%", "90.0% ± 3.1", "~4,800"],
      ["**HCP administrator** — after 5 Nov", "88.0%", "4.8%", "7.2%", "**94.9% ± 2.2**", "~360"],
      ["*HCP administrator — before*", "*80.2%*", "*10.0%*", "*9.8%*", "*88.9% ± 3.2*", "*~760*"],
      ["**Head of Faculty** — after 5 Nov", "56.2%", "11.2%", "32.5%", "**83.3% ± 4.4**", "~1,700"],
      ["*Head of Faculty — before*", "*39.2%*", "*18.8%*", "*42.0%*", "*67.7% ± 6.0*", "*~3,500*"],
      ["**Pharmacist** — after 5 Nov", "82.5%", "3.8%", "13.8%", "**95.7% ± 1.9**", "~80"],
      ["*Pharmacist — before*", "*72.0%*", "*16.0%*", "*12.0%*", "*81.8% ± 3.7*", "*~370*"]],
     widths=[1.75, 0.7, 0.65, 0.75, 1.35, 1.2], size=8.5)
    para(d, "**How to read it.** *Correct, of the decided* leaves the not-sure rows out, so it "
            "is the error rate on the cases where an answer exists; the not-sure column says "
            "how much is still waiting for a definition. The ± is a 95% interval. *Wrong "
            "people* scales the sample rate to the audience, so Lecturer's 1.2% is ~5,100 "
            "people and still a very clean audience.", space_after=4)
    para(d, "**What it found, audience by audience.**", space_after=2)
    bullet(d, "**Pharmacist** collected pharmacologists. 47 of its 64 errors were professors of "
              "pharmacology, pharmacognosy or pharmaceutics and clinical pharmacologists — "
              "the embedding cannot tell pharmacology from pharmacy, which this project "
              "first noticed in calibration (*pharmacologist* scored 0.953 against the "
              "pharmacist examples). **Fixed the same day**: 81.8% → 95.7% on a fresh "
              "sample. See the Pharmacist section.")
    bullet(d, "**HCP administrator** confirms industry medical directors (Pfizer, Novartis, "
              "GSK, UCB): the title and the clinical department clear the threshold even "
              "with the organisation scoring 0.2.")
    bullet(d, "**HCP researcher** loses 9% to fields that are not clinical — veterinary "
              "epidemiology, plant pathology, physics, and basic biomedical departments the "
              "1 November definition deliberately excludes.")
    bullet(d, "**Librarian's** ten errors are the literal pattern reading a library that is "
              "not a library: *DNA-encoded library technology*, *crypto library developer*, "
              "*game librarian*. One override each.")
    bullet(d, "**HCP broad** has no errors of its own — every one arrives through a "
              "sub-audience's roll-up, so it improves when they do.")
    para(d, "**What it is not.** One reader, not two: these are the analyst's judgements, "
            "made against the definitions in this document, and a second reader on a sample "
            "of them is the next step before any number here goes to marketing as a "
            "guarantee. The Head of Faculty and Pharmacist *after* figures were each "
            "measured on a **second, independent sample** drawn after the change, so they "
            "are not marked against the cases their rules were written from. The other audiences have one sample "
            "each, taken before any 5 November change.", space_after=10)

    # ---------------------------------------------------------------- LECTURER
    h(d, "6.1  LECTURER — teaching academics", 2)
    para(d, "The largest audience and the best understood. It is built from the "
            "`teaching_academic` title group and asks only one question of a person: does "
            "their job title name a teaching post.")

    h(d, "6.1.1  How big it is, and who decided", 3)
    table(d, ["", "Figure", "Against what"],
     [["Job titles in the group","**74,365**","out of 317,302 distinct titles in ORCID"],
      ["Employment records","**11,994,600**","the largest group by a wide margin"],
      ["People in the audience","**399,884**","308,671 of them reachable"],
      ["Example words behind it","**15**","professor, lecturer, docente, dozent, reader…"],
      ["Decided by the machine","**99.705%**","74,339 titles"],
      ["Decided by a person","**0.295%**","26 titles, 35,380 records"],
      ["Decided by a literal pattern","**none**","patterns exist only for Librarian"]],
     widths=[2.3,1.1,3.2], size=9)
    fig(d, f"{F}/human_share.png", 6.3,
        "Share of a group's records whose title a person decided by hand. Teaching "
        "academics have the least human attention of any assigned group, and the most "
        "records.")
    para(d, "**Fifteen hand-written words classify twelve million records.** That ratio is "
            "the whole design: we never classify people, only the vocabulary, and the "
            "vocabulary is small because job titles repeat.", space_after=10)

    para(d, "**Where the human decisions went**", bold=True, space_after=3)
    para(d, "26 titles, and they are the ones the machine could not have got right — "
            "mostly because it does not speak the language:")
    box(d, "THE FOUR LARGEST HUMAN CORRECTIONS IN THIS GROUP", [
     "`dr öğr üyesi        4,246   Turkish assistant professor, matched 'wissenschaftlicher mitarbeiter'`",
     "`doç dr              2,547   Turkish associate professor, matched 'medical doctor'`",
     "`ayudante doctor     1,861   a Spanish teaching post, matched 'medical doctor'`",
     "`אקדמי בכיר פרופסור     248   Hebrew for senior academic professor`",
     "",
     "The machine sent all four towards medicine, because the strings contain *dr* or "
     "*doctor*. A person who reads Turkish or Hebrew fixed them in one line each.",
    ])

    h(d, "6.1.2  How accurate is it", 3)
    fig(d, f"{F}/lecturer_three.png", 6.4,
        "Three different questions about the same audience, measured 30 October.")
    para(d, "**91.1% — did we find them?** Of the people who told a survey they are an "
            "academic and whom we classified at all, we put 91.1% in Lecturer. That is "
            "above the 88.9% ceiling, which does not mean we beat it: the ceiling compared "
            "one answer to one answer, while this asks whether Lecturer is among the roles "
            "we gave the person. The easier test.")
    para(d, "**78.2% — do they agree?** Of 6,205 people we put in Lecturer and can check, "
            "4,851 call themselves academics. The other 1,354 call themselves something "
            "else — mostly researchers, students or heads of department.")
    para(d, "**99.2% — did we read the title right?** This is the one that measures *us* "
            "rather than how people describe themselves. Of those 1,354, only **50** have "
            "an ORCID job title that is not a teaching title at all. The rest wrote "
            "*Lecturer* or *Professor* in their employment record and then picked a "
            "different option on a survey form.")
    box(d, "WHY 78.2% IS NOT AN ERROR RATE", [
     "`103 people  wrote 'lecturer' in ORCID,  said 'PhD student' on the survey`",
     "` 93 people  wrote 'professor',          said 'Laboratory Director'`",
     "` 54 people  wrote 'professor',          said 'Head of Department'`",
     "",
     "None of these is a mistake. They hold a lectureship AND they are a doctoral student, "
     "or a lab head, or a department head. The survey takes one answer; a career has "
     "several.",
     "",
     "And the first line is **marketing's own rule**: on 21 October the decision was that "
     "if somebody teaches they go in Lecturer, doctoral student or not.",
    ])

    h(d, "6.1.3  What we fixed, and what it taught us", 3)
    para(d, "Fourteen corrections on 30 October, covering **16,507 records**, found by "
            "reading the group four ways: by example word, by margin, by single-word "
            "titles, and by titles carrying another profession's vocabulary.")
    table(d, ["Title","Records","Was","Now"],
     [["`associate`","6,631","teaching","**rejected** — names no profession"],
      ["`visiting ph d student`","2,036","teaching","student"],
      ["`senior advisor`","1,754","teaching","**rejected**"],
      ["`facultativo especialista`","1,222","teaching","practitioner — Spanish hospital consultant"],
      ["`assistenzarzt`","1,133","teaching","clinical trainee — German junior doctor"],
      ["`assistant editor`","1,133","teaching","support"],
      ["`visiting`","585","teaching","**rejected** — no occupation attached"],
      ["`assistenzärztin`","487","teaching","clinical trainee"],
      ["`alumni`","433","teaching","**rejected** — being a graduate is not a job"],
      ["`科主任`","406","teaching","leadership — Chinese department head"],
      ["`co-editor`","312","teaching","support"],
      ["`universitätsassistent`","280","teaching","early researcher — Austrian doctoral post"],
      ["`recenseador`","95","teaching","**rejected** — Portuguese census enumerator"]],
     widths=[2.0,0.75,0.9,2.95], size=8.6)

    para(d, "**The pattern behind six of them has now cost us three times.**", space_after=4)
    fig(d, f"{F}/one_word.png", 6.2,
        "A title matching ONE word of a two-word example term.")
    para(d, "`member` reached `faculty member`. `fellow` reached `clinical fellow`. "
            "`associate` reached `associate professor`. In each case the single word "
            "carries no occupation at all — an associate is a grade at a law firm as "
            "readily as a university — and in each case it took a human reading the list "
            "to notice. **78,565 records**, and it will happen again. A check for it "
            "should run with every build.")

    box(d, "AND A CORRECTION DOES NOT TRAVEL TO OTHER LANGUAGES", [
     "Three of the fourteen were fixes we had **already made**, escaping in another "
     "language or inflection:",
     "",
     "`university assistant`  corrected in October, `universitätsassistent` was not",
     "`visiting scientist`    moved 21 October,    `visiting ph d student` was not",
     "`assistenzarzt`         fixed 30 October,    `assistenzärztin` needed its own row",
     "",
     "The dictionary keys on the exact string, so every correction should be followed by "
     "the question: what is this in the other languages we see?",
    ], fill="FDF8EF", accent=AMBER)

    box(d, "THE FIXES BARELY MOVED THE AUDIENCE, AND THAT IS THE LESSON", [
     "16,507 records left the teaching group. The Lecturer audience went from **6,206 to "
     "6,205** people in the checkable sample, and precision stayed at **78.2%**.",
     "",
     "Because somebody who wrote `associate` in one employment record almost always wrote "
     "`associate professor` in another. Removing the bad title does not remove the person "
     "— they are still a lecturer, through a better record.",
     "",
     "**A correct dictionary and a correct audience are different things.** This is the "
     "third time the project has measured that, and it is the single most useful thing to "
     "remember when judging whether a fix was worth making. It was — the dictionary is "
     "what the next audience will be built on.",
    ], fill="FAF2F5", accent=PLUM)

    h(d, "6.1.4  What is still open", 3)
    table(d, ["Question","Records","Where it stands"],
     [["Are visiting scholars and fellows teaching staff?","81,749",
       "**Open.** `visiting scholar` 60,561, `visiting fellow` 15,832. May teach, may only research"],
      ["Is an honorary professor active?","6,651",
       "**Open.** We rejected `emeritus professor` and `honorary researcher`; this one survived"],
      ["Compound titles split by word order","~68,000",
       "**Open.** `professor and director` is leadership, `professor & director` is teaching"],
      ["Does a title that names two jobs count as both?","78,000",
       "**Decided 30 Oct** — no, they stay in Lecturer. Awaiting marketing's confirmation"],
      ["Are teaching assistants lecturers?","178,205",
       "**Decided 21 Oct** — yes, if they teach"]],
     widths=[2.5,0.8,3.3], size=8.6)

    box(d, "THE STRUCTURAL RISK WORTH KNOWING", [
     "Lecturer asks only about the job title. Its **department weight is zero**, so there "
     "is no second signal to catch a wrong one.",
     "",
     "`weakest acceptable title 0.75 x 0.70 = 0.525,  resolved organisation 0.25  =  0.775`",
     "`the line is 0.60`",
     "",
     "Anything that lands in the teaching group reaches the audience as soon as the "
     "organisation resolves. Compare healthcare, where the department has to agree before "
     "anybody is confirmed.",
     "",
     "That is why the group is read by hand more often than its 6.7% uncertainty figure "
     "would suggest it needs — nothing else is checking.",
    ], fill="FBF1EF", accent=RED)

    # ---------------------------------------------------------------- OTHERS
    para(d, "**The other eight, in brief.** Each will get the same treatment as Lecturer "
            "in turn. For now, where they stand.", space_after=2)

    n = [1]
    def short(title, body):
        n[0] += 1
        h(d, f"6.{n[0]}  {title}", 2)
        for b in body: para(d, b, space_after=5)

    short("RESEARCHER — 321,824 people", [
      "**74.3% found, 43.9% agree.** Built from one title group, `researcher` "
      "(10.3M records). It was two, `researcher_early` and `researcher_established`, "
      "until 2026-11-10, when Merve removed the split: no audience ever read the two "
      "apart, and the project's largest single error - `junior researcher`, 42,949 "
      "records - was a title landing in the wrong one of two groups that meant the "
      "same thing. They feed this one "
      "audience — the seniority split is computed and then never used.",
      "**The low precision is largely an artefact.** A professor who runs a research group "
      "is in both Lecturer and Researcher; the survey records one answer, so one of the "
      "two memberships is counted wrong whatever we do.",
      "**Its cleanest half, when it still had halves.** What is now the early end of "
      "`researcher` needed **zero corrections** on its first "
      "read — the only group in the project that did. Being generic did not make "
      "`researcher` dirty, because the space around it is densely packed with real "
      "research vocabulary.",
      "**Same structural risk as Lecturer:** department weight zero, no second signal."])

    short("HEALTHCARE (BROAD) — 126,869 people", [
      "**90.9% found, 22.7% agree.** The widest net: it admits anybody whose job title is "
      "clinical **or** whose department is, so that nobody clinical is missed.",
      "**The 22.7% is mostly the design working.** 887 of the people in it describe "
      "themselves as professors or researchers rather than clinicians — they are there "
      "because of their department. A Professor of Cardiology belongs in it and will write "
      "*Professor* on a survey.",
      "**And that number prices an open question.** Whether those 887 belong is marketing "
      "question 2: is *healthcare professional* about the work or about the subject. The "
      "argument used to be abstract; it now has a figure attached."])

    short("HEAD OF FACULTY — 15,047 people after 5 November", [
      "**5 NOVEMBER: narrowed to education organisations, and measured twice.** A hand "
      "reading of 400 people (section 6.0) found 18.8% wrong, and the largest single cause "
      "was the organisation axis, not the title. Facility scored 0.60, Nonprofit 0.40 and "
      "Government 0.30, and with the title weighted 0.60 against a 0.65 threshold every "
      "one of them cleared it: a bare *Director* at Max Planck scored 0.84, at a nonprofit "
      "0.76, at WHO 0.72. And where ROR had no match, an organisation name containing "
      "*institut* or *academ* scored a full 1.00.",
      "**Two seed changes, no model change.** Only *Education* scores now, and the name "
      "fallback keeps *university*, *college*, *faculty* and *school of medicine* but "
      "drops *institute* and *academy*. Measured before deciding: of the 18,869, "
      "11,581 had an Education organisation in ROR, 3,734 had no ROR match but a "
      "university or college name, and 3,554 had neither. In the sample those 3,554 were "
      "2 correct in 58 at ROR-typed organisations. Cost knowingly accepted: a few deans "
      "at an *Institute of Technology* or *Pedagogical Institute* without a ROR match.",
      "**Then the titles.** Named chairs moved to Lecturer through a new pattern that can "
      "be vetoed (`unless_pattern`): `endowed chair`, `chair professor of x` and `canada "
      "research chair` move, but `vice chair for research`, `dean and chair professor` "
      "and `chair professor and head` stay. 223 people left this audience that way. 52 "
      "administrative titles were rejected — `director of it`, `director of international "
      "relations`, `director of assessment`, `chief technology officer` — including four "
      "that a 21 October decision had put in leadership on the reasoning that the "
      "organisation axis would keep companies out. It did not, at universities.",
      "`18,869  before        67.7% correct of decided, 18.8% wrong`",
      "`15,047  after         83.3% correct of decided, 11.2% wrong`",
      "`                      on a second, independent sample of 400`",
      "**What is left, and how big each part is.** 20% of the audience holds only "
      "`director`, `head` or `chair` — the marketing question in 10.6, and it is the "
      "biggest single number left. 7% are administrative Directors whose title is bare "
      "but whose *department* says what they do — *Centre for Internationalization*, "
      "*Innovation Office*, *Research and Sponsored Programs*; a department-word rule "
      "would reach them where no title rule can. 6% come in through a university-named "
      "hospital — *...University School of Medicine Affiliated Renji Hospital* — which "
      "the name fallback reads as a university.",
      "**Everything below this point is the history up to 3 November**, kept because the "
      "reasoning still holds. The audience sizes in it are those of the day.",
      "",
      "**33,241 people, up from 17,528 — and the audience is now measured properly.** "
      "Straight agreement reads 12.6% on 1,775 checkable people against 26.3% on 71 "
      "before, but that number answers the wrong question. Asked the way Lecturer was "
      "asked — does this person's title actually say they lead something:",
      "`223 people   said they are leadership themselves`",
      "`1,185        a title names a faculty-level post - head of department,`",
      "`             dean, rector, chancellor. They ticked one box on a form`",
      "`267          UNCERTAIN - their only leadership word is chair, director`",
      "`             or head, the three we have measured as unreliable`",
      "`102          no leadership word in ANY of their titles`",
      "",
      "**79.2% certainly right, 15.0% uncertain, 5.7% wrong.** So the audience is about "
      "94% defensible. The first version of this check gave ~14% wrong, because its word "
      "list counted `chair` as leadership and had no `chancellor` — wrong in both "
      "directions at once, which is worth remembering before quoting any figure that "
      "rests on a hand-written word list.",
      "",
      "**Re-measured on 3 November after 106 dictionary corrections, and it did not move.** "
      "The error was 101 people before them and 102 after. Section 6.4 below says why, and "
      "it is the most useful thing in this document.",
      "",
      "**And those 270 put a price on a question that has been open since October.** What "
      "to do with the `director` family had no cost attached to it. It now has one: 15.2% "
      "of this audience is there on nothing but `chair`, `director` or `head`. Whichever "
      "way marketing answers, that is the number that moves.",
      "",
      "**But most of the recall gap is not a defect.** Of people who say they head a "
      "department, around 62% wrote only `professor` in ORCID — nothing in their record "
      "says they lead anything. We cannot know, and the standing rule is not to guess.",
      "**Three known causes, two of them chosen deliberately.** One title belongs to one "
      "profession, so a dean who wrote *professor* is a lecturer to us. The audience counts "
      "current posts only. And it was narrowed to universities on 29 October at a measured "
      "cost of 2,819 people — a decision taken knowingly, preferring a small certain "
      "audience to a large arguable one.",
      "**It was starved by the organisation rather than the title, and that eased in the "
      "30 October build.** About 14,600 records carried a strong leadership title and an "
      "employer that did not resolve, so they scored zero and could never be confirmed. "
      "Most of the audience nearly doubling is those people arriving — not the compound "
      "work, which brought 1,715 of it.",
      "**And then the whole roster was read by hand, which is the clearest demonstration "
      "of the project's central lesson yet.** On 30 October Merve read all 33,000 matches "
      "and named two families that must not be in the audience — fellowships and assistant "
      "roles, and strings that are simply noise. 106 corrections went in, covering 7,126 "
      "records:",
      "",
      "`47 rejected          pro, de, committee, governance, a bare department name`",
      "`23 -> researcher      a fellowship NAMED AFTER an office is not that office:`",
      "`                      vice chancellor's fellow, dean's prize fellow`",
      "`21 -> support         assistants and secretaries - real jobs, not ones any`",
      "`                      audience is built for`",
      "`14 -> teaching        proessor, professot, profossor are MISSPELLINGS of a`",
      "`                      rank, not noise; and chief assistant is a Bulgarian`",
      "`                      academic grade`",
      "` 1 -> student         ph d stdent`",
      "",
      "**201 people left the audience, 277 stayed** — they hold a real leadership title as "
      "well as the one that was removed. **And the measured error rate did not move: 101 "
      "people before, 102 after.**",
      "",
      "Because the people who are wrongly in this audience are not there through the titles "
      "that were reviewed. They are there through some *other* title, and the reviewed ones "
      "were mostly held by people who also hold a genuine leadership post. **Cleaning the "
      "dictionary and cleaning an audience are different jobs** — measured now five times "
      "over, on `associate`, on Pharmacist, on the Lecturer corrections, on the compound "
      "patterns and here.",
      "",
      "**The review was still worth doing, for the dictionary rather than for this number.** "
      "7,126 records are read correctly that were not before, permanently, and every "
      "audience built from here inherits that. But to move the 5.7% we have to look at what "
      "those 102 people are in the audience *for* — their evidence record, not the titles we "
      "happened to review. That is the only question left that can change the figure."])

    box(d, "MEASURED 30 OCTOBER: THE COMPOUND TITLES, AND WHAT THEY WOULD BUY", [
     "This is the one route that could materially grow the audience from data we already "
     "hold: titles naming both posts — `professor and head of department`, `professor & "
     "dean`. They sit in teaching today, so none of them reaches Head of Faculty. Sized "
     "for the first time on 30 October:",
     "",
     "`head or dean, no chair word     1,982 titles    78,005 records`",
     "`chair word only                   968 titles    44,611 records`",
     "`both                                49 titles     1,421 records`",
     "",
     "**`chair` is ruled out. 335 chair titles over 8,889 records are endowed "
     "professorships**, not leadership posts — Canada Research Chairs, a `Dean's Chair`, "
     "a European Lehrstuhl. Reading the visible rows had put that at ~1,600 records; "
     "measured, it is five times larger. And the exclusion cannot "
     "be written as a pattern: the pattern layer is a plain text match, and BigQuery's "
     "regular expressions have no way to say \"not\", so \"contains professor and chair "
     "but not research chair\" is not expressible in one row.",
     "",
     "**The head and dean family: built, finished, and it did what was forecast.** 1,685 "
     "titles over 48,518 ORCID records, held by 2,333 people. After the build, **1,715 of "
     "them are in Head of Faculty** against a forecast of 1,778 — within 4%. The scoping "
     "then held across two builds: eight other title groups, zero records moved, twice.",
     "",
     "**And a warning about every record count in this document.** The build showed the "
     "pipeline holds 1,737,768 employment records in total, while the dictionary says "
     "teaching academics alone have 11,946,079. So a records figure is counted across all "
     "of ORCID, and a people figure comes from the records that matched a Springer Nature "
     "id — about 19 to 1. `48,518 ORCID records → 2,557 of ours → 2,333 people`. The two "
     "are not comparable and reading them as one scale is how the forecast for this change "
     "was nearly mis-stated.",
     "",
     "**The audience also nearly doubled in the same build, and that is NOT this work.** "
     "Head of Faculty went 17,528 → 33,241, and 31,526 of those people hold none of these "
     "titles. The record counts show the leadership group gained records from these "
     "patterns and from nothing else, so those people already had their titles — the only "
     "other thing this audience needs is an employer that resolves to an academic "
     "organisation, and about 14,600 strong leadership records were stranded on exactly "
     "that. Two findings in one build, and they have to be reported as two or this work "
     "takes credit for the organisation data.",
    ], fill="FDF8EF", accent=AMBER)

    box(d, "AND `head` ON ITS OWN CANNOT BE TRUSTED EITHER", [
     "Reading the list found that the word does not always mean a leadership post:",
     "",
     "`assistant professor director head and neck surgery        107   anatomy`",
     "`professor - senior consultant - head of thrombosis unit   128   clinical unit`",
     "`assistant professor head of spine center                  151   clinical centre`",
     "`associate professor - head of scientific committee        156   a committee`",
     "`dean of the sport sciences faculty 2010-2020 professor    126   ENDED in 2020`",
     "",
     "**head and neck surgery** settles it: a bare `head` match would read an anatomical "
     "term as a faculty post. So the rule has to name the level — `head of department`, "
     "`head of school`, `head of faculty`, `head of institute`, `head of division`, "
     "`dean`. Those are positive and specific, so they need no \"not\".",
    ], fill="FBF1EF", accent=RED)

    h(d, "The pattern layer was the obvious answer, and the measurement killed it", 3)
    para(d, "1,982 titles cannot be written out as individual overrides, so the plan was to "
            "extend the pattern layer beyond librarian for the first time — a pattern "
            "matches `professor and head of department` and `head of department professor` "
            "identically, which would have closed the word-order question too. Three "
            "queries were run first. The second one ended it.")
    box(d, "WHAT THE PATTERN WOULD HAVE TAKEN WITH IT — 14,500 RECORDS, EIGHT GROUPS", [
     "A pattern matches every title containing the phrase, not only professor compounds:",
     "",
     "`researcher, early        5,217 records   associate dean research`",
     "`researcher, established  3,389           principal researcher - head of department`",
     "`practitioner             2,353           head of department of cardiology`",
     "`pharmacist               1,990           cluster pharmacy manager & head of department`",
     "`support / technical      1,023`",
     "`student                    396           sub-dean graduate studies`",
     "`clinical trainee            91           dean s clinical research fellow`",
     "`librarian                   14           associate dean of library services`",
     "",
     "Against a gain of about 49,100 records out of teaching. And the reason is "
     "structural, not a regex that needs tightening:",
     "",
     "**`head of X` and `dean` are modifiers, not professions.** They attach to any job, "
     "so a pattern matching them overrides the profession word standing next to it in the "
     "same string. A head of a cardiology department stops being a clinician. A pharmacy "
     "manager stops being a pharmacist — and 1,990 records is **2.7% of the entire "
     "pharmacist group**, in the audience that has no external check at all.",
     "",
     "A pattern cannot reject and forces a score of 1.0, and it is undone one title at a "
     "time, so repairing that would take hundreds of exclusions — worse than the override "
     "list it was meant to replace.",
    ], fill="FBF1EF", accent=RED)

    para(d, "**This is the one-title-one-profession decision restated with numbers.** "
            "Marketing's rule that a title names one profession is exactly what makes the "
            "profession word the one that has to win. Being a head of department is an "
            "attribute of a job; it is not the job.")

    box(d, "WHAT SHIPPED — A PATTERN THAT APPLIES WITHIN ONE GROUP", [
     "A pattern row can now say **only when the model already put this title in "
     "teaching**. That removes the 14,500-record sweep by construction: practitioner, "
     "pharmacist and the researcher groups are never consulted. The three librarian "
     "collisions go the same way, the word-order split closes because a pattern matches "
     "every separator, and the profession word still wins.",
     "",
     "`10 patterns   head of department / school / faculty / institute / division,`",
     "`              head of the department, head of dept, dean, decano, dekan`",
     "`10 exclusions the possessives - dean s chair, college of science dean s`",
     "`              distinguished professor, dean s assistant full-time lecturer`",
     "` 1 correction ... vice dean/ acting dean/ dean s advisor IS a deanship.`",
     "`              The exclusion regex had flagged it on the possessive alone`",
     "` 3 decisions  the collision titles, all to librarian`",
     "",
     "**Why the trade is defensible, and it is not that Head of Faculty is small.** Under "
     "the one-title-one-profession rule something has to be dropped from `professor and "
     "head of department`, and the two readings are not equal: heading a department at a "
     "university entails being an academic there, while being a professor entails nothing "
     "about leading anything. The leadership reading keeps both facts; the teaching "
     "reading throws one away. That is an argument about what the title says.",
    ], fill="F2F6F5", accent=TEAL)

    box(d, "WHAT IS STILL NOT CERTAIN, AND IT IS SMALL", [
     "**One flaw was found while writing it and fixed before it shipped.** The scope has "
     "to mean the model *assigned* that group, not merely that teaching was its nearest "
     "guess. The nearest group is recorded even for a title the model rejected as too "
     "weak, so conditioning on it would have promoted those titles with a perfect score — "
     "rescuing precisely what the confidence floor exists to hold back.",
     "",
     "**Two things the build will settle.** A title that is teaching by human decision "
     "rather than by the model will not be claimed, which would show up as slightly fewer "
     "than 1,706 titles moving; there are 26 human decisions in that group and none of "
     "them is a head or dean compound, so this should be nil. And the four smallest "
     "patterns — `dekan` with 2 titles, `head of dept` and `decano` with 4, `head of "
     "faculty` with 6 — would fail the test that every pattern must match something, if "
     "even one of those few turns out to be a human decision. That failure is the guard "
     "working, and the fix is one word in a note.",
     "",
     "**And one known residual: 26 titles, 604 records, 1.2% of the scope.** They carry "
     "their own dates, and a date is not a rule — `dean 2010-2018` has ended, `dean 2014-` "
     "and `head of department 1997-pres` have not, and one title carries both ranges with "
     "the headship on the open side. Query L lists all 26 to be read rather than "
     "regexed.",
    ], fill="FDF8EF", accent=AMBER)

    box(d, "A FOURTH SIGHTING OF THE SAME FAILURE, IN THE POSSESSIVE", [
     "`dean s chair`, `dean s clinical prize`, `dean s clinical research fellow`, `dean s "
     "research assistant` — an award or a post **named after** the dean, which a `dean` "
     "match reads as a deanship.",
     "",
     "It is the shape that gave us `member` (23,157), `fellow` (48,777) and `associate` "
     "(6,631): a word that means something only in company. Found this time before it "
     "shipped rather than after, which is the first time that has happened.",
    ], fill="FDF8EF", accent=AMBER)

    short("PRACTITIONER and CLINICAL RESEARCHER — 60,937 and 50,600 people", [
      "**35.8% and 48.2% agree; neither has a recall figure**, because the survey offers "
      "only *Physician/Clinician* and *Healthcare professional* with no sub-breakdown.",
      "**Practitioner is the least-read group in the project** — titles covering 38% of its "
      "records, against 75% for early-career researchers. Clinical vocabulary is the most "
      "scattered in the data: 58 example words and still not enough, because *Resident*, "
      "*Registrar*, *Facharzt* and *Interno* share no common word.",
      "**It is also where the role library cannot help.** 52 of our 58 clinical example "
      "words are absent from it — it has Physician, Clinician and Surgeon but no specialty "
      "list at all. That gap is what the clinical expert conversation exists to fill."])

    short("CLINICAL ADMINISTRATOR — 7,528 people after 5 November", [
      "**Fixed and re-measured on 5 November: 88.9% → 94.9% correct of the decided**, the "
      "second figure on a fresh sample of 400. The organisation axis was confirming "
      "industry medical directors: title 1.00 × 0.35 plus a clinical department ~0.80 × 0.40 "
      "is 0.67, and a company scored 0.25 — or 0.15 as a *funder*, which Seagen, Amgen and "
      "Vertex also are in ROR — which lifted it over 0.70. Company and Funder now score "
      "0.00, and where ROR has no match an industry-word veto (*pharma, pharmaceuticals, "
      "therapeutics, biotech, biosciences*) does the same. Legal-form words were measured "
      "and rejected: a *ltd / inc / gmbh* veto also hit Klinikum Lippe GmbH and HMG Hospital "
      "Ltd. A code fix came with it: a veto used to fall back to the unknown-organisation "
      "score (0.20 here) instead of zero, so it had never worked for this audience.",
      "**One correction to the first reading, made in the open.** It marked public-health "
      "and epidemiology leaders as wrong or unsure; marketing's definition counts public "
      "health as clinical, so the *before* figure above is re-scored on that rule (88.0% as "
      "first reported). The fix, not the re-scoring, is the six points. What is left: "
      "non-clinical faculties read as clinical (*Faculty of Science*, *Sport Science* — ~1% "
      "of the audience, with no department override to fix them yet), research-centre "
      "directors, and the industry medical directors who still keep HCP broad, whose "
      "threshold is 0.60.",
      "**5 November: 88.0% correct of the decided, on 400 read by hand** — the survey's "
      "71 people were too few, this is not. Its errors are industry medical directors "
      "(Pfizer, Novartis, GSK, UCB, 11 of 41) and leaders of departments that are not "
      "clinical (epidemiology, musicology, basic sciences). The 5 November leadership "
      "corrections for Head of Faculty also removed ~45 people here, all of them "
      "administrative or named-chair titles.",
      "**22.5% agree, on 71 people checked — too few to conclude anything.**",
      "Worth one note from 29 October: `medical director` was moved into leadership so it "
      "would reach this audience, and 198 people arrived. The same move put 145 people "
      "into Head of Faculty, where they do not belong, and that was accepted rather than "
      "fixed because removing them would have cost 294 heads of department and 17 deans."])

    short("PHARMACIST — 2,051 people after 5 November", [
      "**Cannot be measured against the survey — but it has now been read, fixed and read "
      "again.** 400 by hand on 5 November: **81.8% correct of the decided, 16.0% wrong**, "
      "then the weakest audience in the project. Sized on the full audience before "
      "changing anything: 252 of 2,304 confirmed (11%) held a pharmacology or "
      "pharmaceutical-science title with no pharmacist word, ~25 were students and 13 "
      "technicians.",
      "**Four patterns, all scoped to the pharmacist group and all vetoed by a pharmacist "
      "word** (`pharmacist`, `clinical pharmacy`, `pharmacy practice`, `hospital "
      "pharmacy`, `farmac…`), so `hospital pharmacist / clinical pharmacologist` stays. "
      "Pharmacology professors and lecturers move to Lecturer; pharmacologists, "
      "pharmacometricians and pharmaceutical chemists to Researcher; pharmacy students to "
      "the student group; technicians out. *Pharmaceutical services, care and "
      "logistics* are deliberately not touched — that is hospital pharmacy management. "
      "Nor is a bare degree (`master of pharmacy`, `m pharm`): a graduate may be "
      "practising.",
      "`2,304  before   81.8% correct of decided, 16.0% wrong`",
      "`2,051  after    95.7% correct of decided,  3.8% wrong`",
      "`                on a second, independent sample of 400`",
      "**What is left is small and named.** A misspelling (`research pharmacolgist`), "
      "Portuguese pharmacology doctorates, clinical chemists, and Iberian technician "
      "titles (`TSDT Farmácia`, `auxiliar de servicios farmacéuticos`) — 15 people in "
      "400. Of the not-sure, 29 are professors of pharmacy practice: a definition for "
      "marketing, and either answer leaves the audience near 96%.",
      "**Cannot be measured.** The survey has no pharmacist option, so this audience has "
      "no external check at all and will not get one from this source.",
      "What we do know is internal. It was proportionally the dirtiest group in the "
      "project — 21% of its records were wrong, caused almost entirely by five foreign "
      "example words, with French `praticien` sitting three letters from `pharmacien`.",
      "**And fixing all of that moved the audience by 91 people.** The weights make a "
      "pharmacy department effectively mandatory, so a chemist without one was never "
      "confirmed in the first place. The clearest demonstration in the project that a "
      "dictionary and an audience are different things."])

    short("LIBRARIAN — 668 people", [
      "**Cannot be measured externally** — four people in the ground truth set.",
      "**But it is the one audience whose error rate we actually know**, because every "
      "assignment is exact. It is decided by eleven literal patterns rather than by the "
      "machine, so each of its 871 titles either contains the word or does not. We read "
      "the exceptions: **89 records of 21,855, or 0.4%**, both of them genetic and "
      "chemical *libraries* rather than library staff.",
      "That is a different kind of evidence from everything else here — not a sample, a "
      "complete reading. It is possible only because the group is small and the rule is "
      "literal."])
    return d
