# -*- coding: utf-8 -*-
"""Build docs/Role-Pipeline-Walkthrough.pptx from the October source deck.

Run:  python setup/update_deck.py   then   python setup/deck_fit.py
The second one measures every text frame against its box and prints what
overflows; it is the only check this deck has and it has earned its keep twice.

Editing the existing file rather than regenerating it: deck_lib.py, which built
it, was a scratch file and is gone. Every shape's formatting is preserved; only
the text changes, plus one slide move.

Still 15 slides. Slide 7 ("There is no false-positive rate") is now wrong at the
headline - there IS an outside reference - so it becomes the validation slide.
The two researcher slides merge, which Merve has asked for twice on the grounds
that the audiences do not distinguish early from established. The slide that
frees up moves to the end as Limitations.
"""
import copy, os, sys
from pptx import Presentation

HERE = os.path.dirname(os.path.abspath(__file__))

PR = Presentation(os.path.join(HERE, "deck_october_source.pptx"))
S = list(PR.slides)
MISSES = []

def find(slide, prefix, n=1):
    hits = [sh for sh in slide.shapes
            if sh.has_text_frame and sh.text_frame.text.strip().startswith(prefix)]
    if len(hits) != n:
        MISSES.append((prefix[:60], len(hits)))
        return None
    return hits[0] if n == 1 else hits

def put(sh, text):
    """Replace a shape's text, keeping each paragraph's first run's formatting."""
    if sh is None: return
    tf = sh.text_frame
    lines = text.split("\n")
    while len(tf.paragraphs) < len(lines):
        tf._txBody.append(copy.deepcopy(tf.paragraphs[-1]._p))
    while len(tf.paragraphs) > len(lines):
        p = tf.paragraphs[-1]._p; p.getparent().remove(p)
    for para, line in zip(tf.paragraphs, lines):
        runs = para.runs
        if not runs:
            para.add_run().text = line
        else:
            runs[0].text = line
            for r in runs[1:]:
                r._r.getparent().remove(r._r)

def edit(slide, prefix, text):
    put(find(slide, prefix), text)

# ===================================================================== 1 TITLE
edit(S[0], "analytics engineering",
     "analytics engineering  /  ORCID role enrichment  /  November 2026")

# ============================================================== 2 FOUR WORDS
edit(S[1], "310,299 distinct", "317,302 distinct")
edit(S[1], "450K distinct",    "459K distinct")

# ================================================================ 3 ONE TITLE
edit(S[2], "Almost every one of the 310,299",
     "Almost every one of the 317,302 titles takes this path. It runs ONCE, not once per person.")

# ========================================================= 5 THE TWO PATHS
edit(S[4], "348 decisions", "533 decisions")
edit(S[4], "11 patterns, Librarian only", "21 patterns, two groups")
edit(S[4], "Anchors failed here twice",
     "Anchors failed here twice, at 69% and 73% wrong. Librarian has ZERO anchors, so the vector "
     "search can never return it and it cannot take a title from another group. In November a "
     "second kind arrived: ten patterns SCOPED to one group, so head of department only fires on "
     "a title the model already read as teaching. Unscoped, it would have moved 14,500 records "
     "out of eight groups that have nothing to do with the question.")
edit(S[4], "The lesson worth keeping:",
     "The lesson worth keeping:\n"
     "a correct dictionary and a correct audience are two different things. 42,949 records moved "
     "for junior researcher and no audience changed. Measured five times since - most recently "
     "when 106 corrections over 7,126 records left the Head of faculty error rate exactly where "
     "it was, 101 people wrong before and 102 after.")

# ===================================================================== 6 MAP
for old, new in [("12,024,436", "11,946,079"), ("8,343,585", "8,408,047"),
                 ("1,968,320", "1,970,615"),   ("1,917,931", "1,945,519"),
                 ("1,656,354", "1,650,456"),   ("1,458,782", "1,453,643"),
                 ("953,819", "1,010,332"),     ("801,282", "751,548"),
                 ("74,941", "74,951"),         ("21,832", "21,855"),
                 ("399,884", "404,367"),       ("20,347", "33,242"),
                 ("15,796", "32,003")]:
    edit(S[5], old, new)
edit(S[5], "Do not add the column",
     "Do not add the column - people hold several roles, so the same person appears on more than "
     "one line. Group records and the Lecturer and Head of faculty figures are from the 2 November "
     "build; the other audiences were last counted in October.")

# ================================================================ 7 VALIDATION
v = S[6]
edit(v, "honesty", "validation")
edit(v, "There is no false-positive rate", "The first outside check, and it passed")
edit(v, "A false-positive rate needs",
     "For most of this project there was nothing to compare against - ORCID has no profession "
     "field. There is now: 28,866 people who answered two separate surveys the same way.")
edit(v, "share below 0.75", "did we find them")
edit(v, "How much of a group the model was UNSURE",
     "Of the people who say they are X, how many we put in X.")
edit(v, "NOT:  An error rate.",
     "NOT:  an error rate. A low score means we are MISSING people.")
edit(v, "records corrected", "do they agree")
edit(v, "Titles a person read and judged wrong",
     "Of the people we put in X, how many say so themselves.")
edit(v, "NOT:  All the errors",
     "NOT:  our error rate. A survey takes ONE answer per person.")
edit(v, "coverage", "did we read the title right")
edit(v, "The share of a group's records",
     "Of those who disagree, how many hold no title of that kind at all.")
edit(v, "NOT:  Confidence.",
     "THIS one is our error rate. The other two are not.")
edit(v, "Proof one", "Lecturer")
edit(v, "We removed 70,977 wrong records",
     "78.2% agree - and 99.2% of the titles are read right")
edit(v, "Moving junior researcher out",
     "Of 1,354 people who call themselves something else, only 50 hold a title that is not a "
     "teaching title. The rest wrote Professor in ORCID and ticked PhD student on a form. Both "
     "are true at once, and only the 50 are ours to fix.")
edit(v, "Proof two", "The ceiling")
edit(v, "The number is partly a measure of title LENGTH",
     "88.9%, not 100% - and a figure near it is not suspicious")
edit(v, "head of national reference laboratory",
     "88.9% is how often the same person gives the same answer twice, across the two surveys. "
     "Nothing measured against a human answer can beat it. Head of faculty reads 79.2% certainly "
     "right, 15.0% uncertain and 5.7% wrong by the third question above.")
edit(v, "What we have instead:",
     "What it did NOT settle:\n"
     "coverage. 290,045 people in the survey, 238,440 matched to the CDP, and only 46,656 we know "
     "anything at all about. Accuracy is not what limits this project - reach is.")

print("MISSES:", MISSES if MISSES else "none")

def finde(slide, exact):
    hits = [sh for sh in slide.shapes
            if sh.has_text_frame and sh.text_frame.text.strip() == exact]
    if len(hits) != 1:
        MISSES.append(("EXACT " + exact[:50], len(hits))); return None
    return hits[0]

def edite(slide, exact, text):
    put(finde(slide, exact), text)

EMU = 914400
def _at(slide, left_in, top_in, tol=0.06):
    hits = [sh for sh in slide.shapes if sh.has_text_frame
            and abs(sh.left - left_in*EMU) < tol*EMU
            and abs(sh.top  - top_in*EMU)  < tol*EMU]
    if len(hits) != 1:
        MISSES.append((f"AT {left_in},{top_in}", len(hits))); return None
    return hits[0]

def tiles(slide, pairs, lefts=(0.76, 3.81, 6.86, 9.91), v_top=6.57, c_top=6.93):
    """The four stat tiles along the bottom of a profession slide."""
    for i, (value, caption) in enumerate(pairs):
        if value   is not None: put(_at(slide, lefts[i], v_top), value)
        if caption is not None: put(_at(slide, lefts[i], c_top), caption)

# ============================================================= 8 PRACTITIONER
# Tile 1 carried "share below 0.75", which slide 7 now disowns as a metric.
# The external figure is both more current and more honest.
edite(S[7], "41% → 34%", "35.8%")
edite(S[7], "unsure, over October", "agree - no recall figure exists")

# ======================================================== 10 TEACHING ACADEMIC
edite(S[9], "399,884", "404,367")
edite(S[9], "810,767", "99.2%")
edite(S[9], "low-confidence records - the MOST", "of Lecturer titles read right")
edit(S[9], "lecturer has a department weight of ZERO",
     "lecturer has a department weight of ZERO. The weakest acceptable title (0.75 x 0.70 = 0.525) "
     "plus a resolved organisation (0.25) gives 0.775 - confirmed. There is no second axis to "
     "catch anything, which is why this group is read by hand more often than its 6.7% figure "
     "suggests it needs: nothing else is checking. Fourteen corrections landed in October over "
     "16,507 records, and the audience moved by one person.")

# ===================================================== 11 RESEARCHER, MERGED
r = S[10]
edit(r,  "profession  /  researcher_early",
     "profession  /  researcher_early  +  researcher_established")
edite(r, "Researcher, early career", "Researcher, both halves")
edit(r,  "The cleanest group in the project",
     "Two title groups feeding the same two audiences - the seniority split is computed and then "
     "never used. The cleanest group in the project sits next to the home of its largest error.")
edit(r,  "researcher  (title required, 0.75/0.25/0.00)",
     "researcher  (title required, 0.75/0.25/0.00)      hcp_researcher  (title and field, "
     "0.40/0.20/0.40)      -  BOTH groups feed BOTH")
edit(r,  "postdoctoral researcher · postdoc",
     "EARLY  postdoctoral researcher · postdoc · postdoctoral fellow · post doctor · research "
     "fellow · research assistant · research associate · researcher · wissenschaftlicher "
     "mitarbeiter · assegnisti · borsisti · collaboratori      ESTABLISHED  senior researcher · "
     "senior scientist · research scientist · principal investigator · group leader · staff "
     "scientist · scientist · head of laboratory · scientific director")
edit(r,  "PREDICTED DIRTY: collaboratori",
     "EARLY CAREER NEEDED NO FIXES AT ALL - the only group where that happened. Every prediction "
     "we made beforehand was wrong: collaboratori looked worst at 54.6% unsure, and 83% of it was "
     "one correct title, dottorandi. Being generic did not make researcher dirty.")
edite(r, "47,810", "0")
edit(r,  "-> 83% was ONE correct title", "-> corrections needed on the first read")
edit(r,  "PREDICTED DIRTY: research fellow",
     "ESTABLISHED HELD THE LARGEST SINGLE ERROR IN THE PROJECT. junior researcher sat in the "
     "SENIOR group for the project's entire life. It scored 0.870, and every review query filtered "
     "below 0.75 - so the method was blind to it.")
edite(r, "~21,000", "52,279")
edit(r,  "-> Named fellowships and misspellings", "-> Moved to researcher_early")
edit(r,  "PREDICTED DIRTY: researcher, the most generic",
     "senior scientist attracted every senior X - senior manager 2,772, senior software developer "
     "810 - and writing and software roles arrived too: scientific editor 544, scientific "
     "programmer 735, head of innovation 253.")
edite(r, "—", "18,106")
edit(r,  "-> Measured 8.1% below 0.75. Clean", "-> Moved one title at a time")
edit(r,  "A group that needed no fixes at all", "And then we made the model's mistake in reverse")
edit(r,  "It came back at 6.9% unsure",
     "We moved junior group leader (5,943 records) out of the established group, then withdrew "
     "the override. A German Nachwuchsgruppenleiter runs their own group on their own funding and "
     "IS an independent researcher. We read the word junior and did exactly what we had just "
     "corrected the model for doing.\n"
     "It cost nothing, because both halves feed the same two audiences - which is also why the "
     "seniority split has never been worth defending.")
# Tiles are addressed by POSITION, not by text. Addressing them by text breaks
# as soon as one edit makes a value collide with another tile's value - setting
# a tile to "0" while another tile already reads "0" is exactly what happened.
tiles(r, [("74.3%", "say so and we found them"),
          ("43.9%", "agree - one answer per person"),
          ("~70%",  "of records read"),
          ("321,824", "Researcher audience")])

# ================================================================ 13 LEADERSHIP
L = S[12]
edit(L,  "The only group where the title alone",
     "The only group where the title alone is deliberately not enough - that is the design, not a "
     "weakness. And in November it nearly doubled.")
edit(L,  "chancellor s fellow is an early-career fellowship",
     "NOVEMBER: ten patterns scoped to this group brought in the professor-and-dean compounds - "
     "professor and head of department, and every separator spelling of it at once, which "
     "1,700 individual overrides could never have done consistently.")
edite(L, "1,363", "48,518")
edit(L,  "-> Moved to research and support", "-> Moved from teaching, by pattern")
edit(L,  "A leadership title says nothing about",
     "A leadership title says nothing about whether the person is academic - the organisation "
     "decides. faculty_head scores a Company at 0.00 and an unresolved organisation at 0.00, so a "
     "corporate title cannot confirm there at all.\n"
     "That is also what had been starving it: ~14,600 records carried a strong leadership title "
     "and an employer that never resolved. Most of the growth from 17,528 to 33,242 is those "
     "people arriving, not our compound work, which brought 1,715 of it - within 4% of forecast. "
     "Two findings in one build, and they have to be reported as two.")
tiles(L, [("33,242", "Head of faculty, from 17,528"),
          ("79.2%",  "certainly right, 5.7% wrong"),
          ("201",    "people the roster review removed"),
          ("~62%",   "of records read")])

# ================================================================ 14 PHARMACIST
edit(S[13], "Weights 0.55 / 0.15 / 0.30 against a 0.60 threshold",
     "Weights 0.55 / 0.15 / 0.30 against a 0.60 threshold mean the weakest assignment plus a FULLY "
     "resolved organisation reaches only 0.535. A pharmacy department is required, so a chemist "
     "without one was never confirmed in the first place.\n"
     "And this group cannot be checked from outside at all: the survey has no pharmacist option. "
     "Everything known about it comes from reading it.")

# ================================================================= 15 LIBRARIAN
edit(S[14], "I was still tuning anchor wording",
     "I was still tuning anchor wording when the second attempt came back WORSE. "
     "int_anchor_embeddings was INCREMENTAL, so a deleted anchor kept its vector and stayed a live "
     "search target for ever - removing one did nothing, silently.\n"
     "In November the pattern mechanism gained its second user, ten rules scoped to leadership, "
     "and a build failed the same day: associate dean for library operations is claimed by librar "
     "and by dean at once. One record, and the guard caught it before anything shipped.")

# ============================================= 12 -> END, REWRITTEN AS LIMITS
lim = S[11]
sld = PR.slides._sldIdLst
nodes = list(sld)
sld.remove(nodes[11]); sld.append(nodes[11])

edit(lim,  "profession  /  researcher_established", "limitations")
edite(lim, "Researcher, established", "What this cannot do")
edit(lim,  "48 human decisions",
     "Five properties of the method rather than defects waiting to be fixed. Worth knowing before "
     "anyone leans on a number from it.")
edit(lim,  "FEEDS", "IN SHORT")
edit(lim,  "researcher      hcp_researcher",
     "Coverage limits us far more than accuracy does  ·  one title can only name one profession  "
     "·  a clean dictionary is not a clean audience")
edit(lim,  "ANCHORS", "THE NUMBER THAT MATTERS MOST")
edit(lim,  "senior researcher · senior scientist",
     "290,045 people in the survey   ->   238,440 matched to the CDP   ->   46,656 we know "
     "anything at all about")
edit(lim,  "WHAT WENT WRONG", "THE FIVE")
edit(lim,  "junior researcher sat in the SENIOR group",
     "COVERAGE, NOT ACCURACY, IS THE LIMIT. We can only classify someone who typed something we "
     "can read. Of 290,045 people in the survey we could say anything at all about 46,656, and no "
     "amount of dictionary work changes that ratio.")
edite(lim, "52,279", "16%")
edit(lim,  "-> Moved to researcher_early", "-> of survey people we can speak to")
edit(lim,  "senior scientist and senior researcher attracted",
     "ONE TITLE NAMES ONE PROFESSION. A professor who heads a department must be filed as one or "
     "the other. Marketing decided on 30 October that they stay put; the consequence is that an "
     "audience can never be a complete list of the people doing that job.")
edite(lim, "10,073", "78,000")
edit(lim,  "-> Moved one title at a time", "-> records this one decision governs")
edit(lim,  "Writing, software and directing roles",
     "A CORRECT DICTIONARY IS NOT A CORRECT AUDIENCE. 106 corrections over 7,126 records moved the "
     "Head of faculty error from 101 people wrong to 102, because the people wrongly in an "
     "audience are not there through the titles you happened to review.")
edite(lim, "8,033", "5x")
edit(lim,  "-> Moved to support and leadership", "-> measured, and never once otherwise")
edit(lim,  "And then we made the model's mistake in reverse",
     "And two the numbers cannot reach")
edit(lim,  "We moved junior group leader",
     "PHARMACIST AND LIBRARIAN HAVE NO EXTERNAL CHECK. The survey offers no option for either, and "
     "the Librarian ground truth is four people. What we know about them comes from reading them, "
     "which for Librarian is a complete reading - 89 wrong records of 21,855 - and for Pharmacist "
     "is half the group.\n"
     "AND chair, director and head ARE MODIFIERS, NOT PROFESSIONS. 15.0% of Head of faculty rests "
     "on nothing but one of those three words. That is a question for marketing, not a bug - and "
     "it now has a price attached to it for the first time.")
tiles(lim, [("5.7%",   "known wrong in Head of faculty"),
            ("88.9%",  "ceiling - people against themselves"),
            ("2 of 9", "audiences cannot be checked at all"),
            ("15.0%",  "resting on chair / director / head")])

# ===================================================================== TRIM PASS
# fit.py measures every frame against its box. The original deck carried two
# frames that already overflowed; these edits added ten more, all of them prose
# written without the box in mind. Each one below is cut to what its frame
# actually holds - a "what went wrong" row body is two lines of about 100
# characters, and no amount of good wording survives a third.
_at(S[4], 6.98, 4.82) and put(_at(S[4], 6.98, 4.82),
    "Anchors failed here twice, at 69% and 73% wrong. Librarian has ZERO anchors, so the vector "
    "search can never return it. In November a second kind arrived: ten patterns SCOPED to one "
    "group, so head of department only fires on a title already read as teaching. Unscoped it "
    "would have moved 14,500 records out of eight unrelated groups.")
put(_at(S[4], 0.90, 6.31),
    "The lesson worth keeping:\n"
    "a correct dictionary and a correct audience are two different things. Measured five times - "
    "last when 106 corrections over 7,126 records left the Head of faculty error where it was.")
put(_at(S[5], 8.50, 5.93),
    "Do not add the column. People hold several roles, so the same person appears on several lines.")
put(_at(S[5], 0.62, 1.34),
    "Neither direction is one-to-one: a group can feed two audiences, and an audience can draw on "
    "two groups. Records and the Lecturer and Head of faculty counts are from the 2 November "
    "build; the rest were counted in October.")
put(_at(S[6], 0.62, 1.34),
    "Until now there was nothing to compare against. There is now: 28,866 people who answered two "
    "surveys the same way.")

ROWS = (3.99, 4.86, 5.73)
for slide, texts in (
  (S[10], ["EARLY CAREER NEEDED NO FIXES AT ALL - the only group where that happened. Every "
           "prediction was wrong: collaboratori looked worst at 54.6% unsure, and 83% of it was "
           "one correct title.",
           "ESTABLISHED HELD THE PROJECT'S LARGEST ERROR. junior researcher sat in the SENIOR group "
           "for its whole life at 0.870, and every review query filtered below 0.75 - so the "
           "method was blind.",
           "senior scientist attracted every senior X - senior manager 2,772, senior software "
           "developer 810 - and writing roles too: scientific editor 544, scientific programmer "
           "735."]),
  (S[12], [None, None,
           "NOVEMBER: ten patterns scoped to this group brought in the professor-and-dean "
           "compounds - every separator spelling at once, which 1,700 single overrides could "
           "never do consistently."]),
  (S[11], ["COVERAGE, NOT ACCURACY, IS THE LIMIT. We can only classify someone who typed something "
           "we can read. Of 290,045 survey people we could say anything about 46,656.",
           "ONE TITLE NAMES ONE PROFESSION. A professor who heads a department is filed as one or "
           "the other, so an audience can never be a complete list of the people doing that job.",
           "A CORRECT DICTIONARY IS NOT A CORRECT AUDIENCE. 106 corrections over 7,126 records "
           "moved the Head of faculty error from 101 people wrong to 102. Five times measured."]),
):
    for top, txt in zip(ROWS, texts):
        if txt: put(_at(slide, 0.76, top), txt)

NOTES = {
1: """Hi everyone. Before anything else - if you have been wondering what I actually do on role
enrichment, here it is in one sentence.

We are trying to work out what job a researcher does, from what they typed about themselves in
ORCID. Nine roles: Lecturer, Researcher, Healthcare professional, Practitioner, Clinical
researcher, Clinical administrator, Head of faculty, Pharmacist and Librarian. We look at the
roles they list - past and present - plus their organisation and their department, and we put a
label on it. That is the whole project. Everything after this slide is detail.""",

2: """I want to get four words straight first, because almost every confusion I have had on this
project came from mixing two of them up.

A TITLE is what the person typed. We do not choose these - there are 317,302 different ones and
some of them are a mess.

An ANCHOR is an example word I wrote by hand to define a job. There are 151, and I put the list
together with AI's help.

A TITLE GROUP is one of ten buckets. One group owns many anchors.

A DISCIPLINE is the subject - and that comes from the DEPARTMENT, not from the title. That one
matters: we measured it, and trying to get the subject out of job titles leaves three quarters of
them unusable.

So the chain is: the title is matched to its nearest anchor, the anchor belongs to a group, and
the group feeds the audiences. Read that once and the rest of the deck follows.""",

3: """Let me follow one title all the way through. Say somebody typed "Consultant Paediatrician".

First we normalise it - lowercase, strip the punctuation, keep the accents. Then that text goes to
a Vertex AI model, which turns it into 768 numbers standing for its meaning. Then we compare those
numbers against all 151 anchors at once and the nearest one wins. Here it is `consultant`, at a
similarity of 0.699. And `consultant` only belongs to one group, practitioner - so that is the
group this title gets.

The important bit: this runs ONCE PER DISTINCT TITLE, not once per person. 317,302 titles, one
pass. Everybody who typed the same string gets the same answer, and labelling a person afterwards
is just a join.

Now, group_score - this is the line at the bottom and it confused me for a while, so let me say it
plainly.

The raw similarity numbers live in a narrow band. Anything below 0.65 we throw away; that is the
floor. And in practice nothing ever comes back above about 0.95. So a raw 0.699 LOOKS like a weak
score when it is actually a perfectly good match that just sits near the bottom of the range.

group_score re-spreads that surviving band so the number means what it looks like: the weakest
match we would accept becomes 0.70, a perfect match stays 1.00, and everything in between is
stretched evenly across the gap. 0.699 comes out at 0.742.

That is all the formula does. It adds no information - it just puts the score on a scale the rest
of the pipeline can use.""",

4: """Now the same title, but for an actual person. Three signals.

The TITLE gives us practitioner, carrying that 0.742.

The ORGANISATION we look up by its ROR id. Great Ormond Street Hospital, ROR type Healthcare -
full marks, 1.00.

The DEPARTMENT is Paediatrics, which maps to health_clinical - full marks again.

Then each audience weights those three differently, because they do not matter equally. For
Practitioner it is 0.45 title, 0.15 organisation, 0.40 department. The organisation is worth least
because a hospital only weakly tells you somebody is clinical - plenty of non-clinical people work
in hospitals. The department is worth a lot, because that is where the specific words live.

Multiply and add: 0.334 plus 0.150 plus 0.400 is 0.884. That is above the confirm line, so this
person is CONFIRMED and gets delivered. If it had landed between 0.50 and the line, they would be
PROBABLE instead.

And here is the part I like. Change one field and the answer changes. Same title, but the
department says Mechanical Engineering - this audience needs both axes and now it only has one, so
no row is produced at all. The person is not scored low; they are simply not in the list. That is
the second axis doing its job.""",

5: """The model is not always right, so there are two ways to overrule it.

The first is a HUMAN DECISION. 533 of them now. My favourite example is `chemist`. In British
English a chemist is a pharmacy, so the model confidently filed it under Pharmacist. But in ORCID,
as a job title, a chemist is almost always a chemistry researcher. The model was not wrong about
the word - it was wrong about the world. 6,923 records, moved by hand. There is a French one too:
`pharmacien` and `praticien` are three letters apart, and the model put a pile of French hospital
doctors in with the pharmacists.

The second is a PATTERN - a literal text match, no similarity computed at all. We did that for
Librarian because anchors failed there twice, at 69% and 73% wrong. Librarian now has ZERO anchors
and eleven patterns: if the title contains "librar", it IS a librarian. Exact, every time. And
because it has no anchors, the model can never return it, so it cannot steal a title from another
group. Fixed by construction rather than by tuning.

The lesson I would keep from all of this: a correct dictionary and a correct audience are two
different things. I have measured that five times now. Most recently, 106 corrections covering
7,126 records moved the Head of faculty error rate from 101 people wrong to 102. The dictionary
got better and the audience did not move - because the people who are wrongly in an audience are
not there through the titles you just fixed.""",

6: """This is the whole thing on one page. Ten title groups on the left with their record counts and
what each one feeds; nine audiences on the right with how many people are in them and how many we
can actually reach.

Neither direction is one-to-one - a group can feed two audiences, and an audience can draw on two
groups.

Two things to flag. Do not add the audience column up: people hold more than one role, so the same
person appears on several lines. And two groups feed nothing at all - student and support/technical.
That is deliberate. They are where titles that belong nowhere get parked, so their quality numbers
do not matter today.""",

7: """For most of this project there was nothing to check ourselves against. ORCID has no profession
field. There is now: 28,866 people who answered two separate surveys the same way.

There are three different questions you can ask, and I want to keep them apart, because two of
them get quoted as error rates and neither one is.

DID WE FIND THEM - of the people who say they are X, how many did we put in X. A low score means
we are MISSING people.

DO THEY AGREE - of the people we put in X, how many say so themselves. A low score here is not our
error rate either, because a survey takes one answer per person and a career has several.

DID WE READ THE TITLE RIGHT - of the people who disagree, how many hold no title of that kind at
all. That one IS our error rate.

Lecturer is the clearest case. 78.2% agree, which sounds mediocre. But ask the third question: of
1,354 people who called themselves something else, only 50 hold a title that is not a teaching
title. The rest wrote Professor in ORCID and ticked PhD student on a form. Both are true. So the
real figure is 99.2%.

One more thing - the ceiling is 88.9%, not 100%. That is how often the same person gives the same
answer twice. Nothing measured against a human answer can beat it, and a number near it is not
suspicious.

And what validation did NOT settle: coverage. 290,045 people in the survey, 238,440 we could match
to the CDP, and only 46,656 we know anything at all about. Accuracy is not what limits this
project. Reach is.""",

8: """Practitioners. 58 anchors, the most of any group, and still the hardest one.

Clinical vocabulary is the most scattered in the data. Academic titles are nearly the same
everywhere - Professor, Associate Professor, Lecturer. Clinical ones are not: Resident, Registrar,
Facharzt and Interno all mean a doctor in training and share no common word.

What went wrong is mostly that whole professions had no anchor, so the model used the nearest thing
it had. 2,684 veterinarians matched dentist. 2,765 anaesthetists matched neurosurgeon. We added 25
specialty anchors and that largely fixed it.

The one we chose NOT to fix is `consultant`: 253,841 records. In Britain it is a hospital
specialist; everywhere else it is a business adviser - and the wrong ones score HIGHER than the
right ones, so no threshold separates them. That is an honest open problem, not a bug.""",

9: """Clinical trainee. Eight anchors, the fewest anywhere, and two of them are ordinary English
words.

The problem here was training positions with no clinical content at all. `internship` on its own is
19,557 records and names no profession. And seven fully qualified clinicians were sitting in the
TRAINEE group, because `internist` reaches `intern` on its first six letters.

What I took from this group: it is not how ambiguous a word LOOKS that decides whether an anchor
leaks. `resident` is just as ordinary an English word as `intern`, and it is almost perfectly
clean. It depends on what else lives near it in the model's space, and you cannot tell that by
reading the word.""",

10: """Teaching academic. Twelve million records, the biggest group, and the one with the least
protection against a wrong title.

Lecturer has a department weight of ZERO. So there is no second axis here - anything that lands in
this group reaches the audience as soon as the organisation resolves. That is why we read it by
hand more often than its numbers suggest it needs: nothing else is checking.

Fourteen corrections landed in October over 16,507 records - and the audience moved by one person.
Same lesson again.""",

11: """Researcher - and I have merged the two slides this used to be, because the two groups feed
exactly the same two audiences. We compute a seniority split and then never use it.

The early-career half needed ZERO corrections on its first read. The only group where that
happened. Being generic did not make `researcher` dirty, because the space around it is densely
packed with real research vocabulary.

The established half held the biggest single error in the project, which the slide covers.

And then we made the model's mistake in reverse, which I want to own. We moved `junior group
leader` out of the group, then put it back - because a German Nachwuchsgruppenleiter runs their own
group on their own funding and IS an independent researcher. We read the word "junior" and did
exactly what we had just corrected the model for doing.""",

12: """Leadership. The only group where the title alone is deliberately not enough - and that is the
design, not a weakness. A leadership title tells you nothing about whether the person is academic,
so the organisation decides: Head of faculty scores a company at zero, and an unresolved
organisation at zero.

In November this audience nearly doubled, 17,528 to 33,242. I want to be careful about that number,
because only 1,715 of it is our work - the professor-and-dean compound titles finally reaching the
audience, which is within 4% of what we forecast. The rest is employers finally resolving to
academic organisations, which is the thing that had been starving it all along.

Two findings in one build, and they have to be reported as two, or our work takes credit for the
ROR data.""",

13: """Pharmacist. Proportionally the dirtiest group in the project - 21% of its records were wrong -
and foreign-language anchors caused nearly all of it.

But the interesting part is what fixing it cost. The audience moved by 91 people. The weights
effectively require a pharmacy department, so a chemist without one was never confirmed in the
first place.

It is also the group we cannot check from outside at all: the survey has no pharmacist option.
Everything we know about it comes from reading it.""",

14: """Librarian. The one group decided by the word rather than by the model. Zero anchors, eleven
patterns, every score exactly 1.000.

This is the only group whose error rate we know exactly, because we read ALL of it rather than a
sample: 89 wrong records out of 21,855, and both are genetic and chemical libraries rather than
library staff.

The real lesson from this one was somewhere else though. I was tuning anchor wording for weeks and
the second attempt came back WORSE - because the embedding table was incremental, so a deleted
anchor kept its vector and stayed a live search target for ever. Removing an anchor did nothing,
silently.""",

15: """And finally, what this cannot do. These are properties of the method, not defects waiting to be
fixed.

COVERAGE IS THE REAL LIMIT, not accuracy. Of 290,045 people in the survey we could say anything at
all about 46,656. No amount of dictionary work changes that ratio.

ONE TITLE NAMES ONE PROFESSION. A professor who heads a department has to be filed as one or the
other - marketing decided they stay where they are. The consequence is that an audience can never
be a complete list of the people doing that job.

A CLEAN DICTIONARY IS NOT A CLEAN AUDIENCE. Five times measured, never once otherwise.

TWO OF THE NINE AUDIENCES CANNOT BE CHECKED AT ALL - no survey option for Pharmacist, and four
people in the ground truth for Librarian.

And 15% of Head of faculty rests on nothing but the words chair, director or head - which are
modifiers, not professions. That one is a question for marketing rather than a bug, and it now has
a price attached to it for the first time.

That is everything. Happy to go back to any slide.""",
}

# Written into the notes pane so the script travels with the deck and appears in
# presenter view, rather than living in a separate file that gets lost - which
# is exactly what happened to the script that built this deck in October.
for n, text in NOTES.items():
    tf = S[n - 1].notes_slide.notes_text_frame
    tf.text = " ".join(text.split("\n\n")[0].split())
    for para in text.split("\n\n")[1:]:
        tf.add_paragraph().text = " ".join(para.split())

PR.save(os.path.join(HERE, "..", "docs", "Role-Pipeline-Walkthrough.pptx"))
print("MISSES:", MISSES if MISSES else "none")
print("saved docs/Role-Pipeline-Walkthrough.pptx")
