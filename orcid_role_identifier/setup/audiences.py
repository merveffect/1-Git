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
      "**74.3% found, 43.9% agree.** Built from two title groups, `researcher_early` "
      "(8.4M records) and `researcher_established` (1.9M), which both feed this one "
      "audience — the seniority split is computed and then never used.",
      "**The low precision is largely an artefact.** A professor who runs a research group "
      "is in both Lecturer and Researcher; the survey records one answer, so one of the "
      "two memberships is counted wrong whatever we do.",
      "**Its cleanest half.** `researcher_early` needed **zero corrections** on its first "
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

    short("HEAD OF FACULTY — 17,528 people", [
      "**23.8% found, 26.3% agree. The weakest audience we have**, and poor in both "
      "directions.",
      "**But most of the recall gap is not a defect.** Of people who say they head a "
      "department, around 62% wrote only `professor` in ORCID — nothing in their record "
      "says they lead anything. We cannot know, and the standing rule is not to guess.",
      "**Three known causes, two of them chosen deliberately.** One title belongs to one "
      "profession, so a dean who wrote *professor* is a lecturer to us. The audience counts "
      "current posts only. And it was narrowed to universities on 29 October at a measured "
      "cost of 2,819 people — a decision taken knowingly, preferring a small certain "
      "audience to a large arguable one.",
      "**And it is starved by the organisation, not the title.** About 14,600 records carry "
      "a strong leadership title — average score 0.856 — and can never be confirmed because "
      "the organisation did not resolve and therefore scores zero."])

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
     "**The head and dean family, measured both ways.** 3,683 people hold one:",
     "",
     "`Lecturer loses      at most 1,739 of 399,884 people   0.43%`",
     "`                    the other 1,944 hold another teaching title and stay`",
     "`Head of Faculty gains  up to 3,376 of 17,528 people    +19%`",
     "`                    3,263 of them reachable; 307 are already in it`",
     "",
     "**That is the best trade this audience has been offered.** It is also an upper "
     "bound on the gain, because faculty_head still needs the organisation to resolve, "
     "and that is what already strands 14,600 strong leadership records. Query H in "
     "`analyses/30_leadership_compounds.sql` is what decides it.",
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

    box(d, "THE DESIGN THAT SURVIVES, AND WHAT IT STILL NEEDS", [
     "A pattern that applies **within one group**: a row that says \"only when the model "
     "already put this title in teaching\". Then —",
     "",
     "• the 14,500-record sweep disappears by construction, because practitioner, "
     "pharmacist and the researcher groups are never consulted;",
     "• so do the three librarian collisions the check turned up, for the same reason;",
     "• the word-order split still closes, because a pattern matches every separator;",
     "• and the profession word still wins, which is what was decided.",
     "",
     "It is one nullable column on the pattern seed and one condition in one join, plus "
     "making the model's own choice visible so the two existing pattern tests can still "
     "see what a conditional pattern acted on. Librarian rows leave the column empty and "
     "go on working unchanged.",
     "",
     "**Two things are measured before it is built, and one of them could still cancel "
     "it.** `analyses/30` query I lists the exclusions — `dean s chair`, `dean s clinical "
     "research fellow`, a post carrying its own end date. Query J asks whether these "
     "people's employers resolve to an academic organisation at all: faculty_head scores "
     "Healthcare, Company, Funder and UNKNOWN at zero, so if they sit there the +19% is "
     "fiction and nothing should be changed.",
    ], fill="F2F6F5", accent=TEAL)

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

    short("CLINICAL ADMINISTRATOR — 6,865 people", [
      "**22.5% agree, on 71 people checked — too few to conclude anything.**",
      "Worth one note from 29 October: `medical director` was moved into leadership so it "
      "would reach this audience, and 198 people arrived. The same move put 145 people "
      "into Head of Faculty, where they do not belong, and that was accepted rather than "
      "fixed because removing them would have cost 294 heads of department and 17 deans."])

    short("PHARMACIST — 2,245 people", [
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
