# -*- coding: utf-8 -*-
# Builds docs/ORCID-Decision-Makers-Sizing.docx - the answer to marketing's
# request to open Head of Faculty beyond academia. The markdown twin is
# docs/ORCID-Decision-Makers-Sizing.md.
#
# WHY IT EXISTS. Marketing asked to widen Head of Faculty to reach opinion
# leaders, budget holders and purchase influencers, and sent a 55-class
# spreadsheet of the titles they wanted. Merve, 2026-11-16: "marketing e
# gidecek ozeti yaz."
#
# EVERY FIGURE IS A PEOPLE FIGURE FROM analyses/53, run on the live data on
# 2026-11-16. would_confirm_if_open is computed per person against the role
# threshold with the organisation gate removed - it is a count, not a model.
# The control total checks out: scores_today sums to 17,218, which is the
# Head of Faculty figure already on the one-pager.
#
# WRITTEN FOR THE PERSON WHO SENT THE LIST, not for us. No role_key, no
# org_type, no ROR, no thresholds. "We cannot identify the employer" rather
# than "org_type is UNKNOWN".
import sys, os
SP = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, SP)
from docx_lib import *
from docx.shared import Pt

d = doc_new()

p = d.add_paragraph(); p.paragraph_format.space_after = Pt(2)
r = p.add_run("ORCID ROLE ENRICHMENT"); r.bold = True; r.font.size = Pt(9.5)
r.font.color.rgb = PLUM; r.font.name = SANS
p = d.add_paragraph(); p.paragraph_format.space_after = Pt(4)
r = p.add_run("Opening Head of Faculty: what it would actually give you")
r.bold = True; r.font.size = Pt(19); r.font.color.rgb = INK; r.font.name = SANS
para(d, "16 November 2026  ·  Analytics Engineering  ·  measured, not forecast",
     size=9.5, color=MUT, space_after=10)

para(d, "You asked us to open Head of Faculty beyond academia so it reaches opinion "
        "leaders, budget holders and purchase influencers, and you sent a list of the "
        "job titles you have in mind. We have now run that against the live data. "
        "**Every number below is a count of real people, not an estimate.**",
     space_after=12)

box(d, "THE SHORT VERSION", [
 "**Opening the rule adds 18,160 people — and 408 of them work for a company.**",
 "",
 "The rule that keeps Head of Faculty inside academia is not what is holding back the "
 "people you want. Their job titles already pass. What stops us is that we often "
 "cannot tell who their employer is, and when we cannot, a chief executive and a dean "
 "look exactly the same to us.",
 "",
 "**So opening the rule lets both in, or neither.** It also makes the audience less "
 "precise, because the people it admits are twice as likely to have a job title that "
 "says only “Director” with no indication of what they direct.",
], fill="FBF6EE", accent=AMBER)

# ----------------------------------------------------------------- 1
h(d, "1.  What opening the rule gives you")
para(d, "Head of Faculty is 17,218 people today. Remove the academia-only rule and it "
        "becomes 35,378. Here is where those 18,160 extra people work.")
table(d, ["Their employer", "People", ""],
 [["**We could not identify it**", "**11,702**", "**64% of the gain**"],
  ["Hospital", "2,165", ""],
  ["Research funder (research councils and similar)", "1,459", ""],
  ["Research institute", "1,229", ""],
  ["Government body", "491", ""],
  ["Non-profit", "468", ""],
  ["**Company**", "**408**", "**2% of the gain**"],
  ["Other", "185", ""],
  ["Museum or archive", "53", ""]],
 widths=[3.3, 1.0, 1.9], size=9)
para(d, "Two thirds of the gain is people whose employer we could not identify at all. "
        "Of the third we can identify, almost none is industry — it is hospitals, "
        "research councils and institutes. **The rule is not what stands between you "
        "and a commercial audience.**", space_after=12)

# ----------------------------------------------------------------- 2
h(d, "2.  The people you want are in ORCID — we just cannot see where they work")
para(d, "This is the part worth your attention, because it is better news than it sounds.")
para(d, "The job titles are there and our system already recognises them. We found "
        "**7,723 records carrying commercial leadership language** — chief executive, "
        "founder, managing director, vice president, owner, board member — and they "
        "already reach the leadership category correctly. Around **1,900 of them sit in "
        "the group whose employer we could not identify**: 868 chief executives, 429 "
        "founders, 224 managing directors, 189 owners.")
para(d, "We identify employers by looking the organisation name up in a public register "
        "of research organisations. Universities, hospitals and institutes are in it. "
        "**Ordinary companies very often are not.** When the lookup fails we fall back "
        "to reading the organisation's name, which catches anything that says "
        "“university” or “college” — and that is exactly why the unidentified group "
        "is a mix of university deans and company chief executives we cannot separate.",
     space_after=12)

# ----------------------------------------------------------------- 3
h(d, "3.  Opening the rule also makes the audience less precise")
para(d, "A fifth of Head of Faculty today — 3,601 of 17,218 — has a job title that is a "
        "single bare word: *Director*, *Head*, *Chief*, with nothing saying what they "
        "lead. We cannot tell whether that is a dean, a head of IT or a department "
        "secretary's manager.")
table(d, ["Where they work", "Share whose title is a bare word"],
 [["Universities (the audience today)", "**19.9%**"],
  ["Hospitals", "44.7%"],
  ["Research funders", "44.7%"],
  ["Non-profits", "43.2%"],
  ["Research institutes", "42.4%"],
  ["Companies", "39.0%"]],
 widths=[3.9, 2.3], size=9)
para(d, "**The people the change would admit are more than twice as likely to have an "
        "uninformative title.** This matters because Head of Faculty is already our "
        "least accurate audience at 83.3%, and these bare titles are the single largest "
        "reason for it.", space_after=12)

# ----------------------------------------------------------------- 4
h(d, "4.  About the list you sent")
para(d, "We checked all 55 classes against what our system does today. Most line up. "
        "Four groups do not, and we would rather raise them than quietly apply them.")
bullet(d, "**Several of your titles are researchers to us, deliberately.** "
          "`principal investigator` (1,866), `group leader` (2,357), `principal "
          "scientist` (1,111), `research director` (883), `director of research` (400) "
          "and `scientific director` (382) all sit in our Researcher audience. They "
          "lead teams, but they lead research, not budgets.")
bullet(d, "**Several are academics to us.** `professor and head` (560), `professor and "
          "chair` (428), `chair professor` (200). A chair professorship is an honour, "
          "not a management post.")
bullet(d, "**Two were deliberately excluded on 5 November, with reasons on file.** "
          "`chief scientific officer` (268) and `co-founder` (276). If you want them "
          "back, that is a decision you can make — we just want it to be a decision.")
bullet(d, "**`editor` (233) sits with technical and editorial support.** You flagged "
          "editors yourself, and we agree they are not decision makers.")
para(d, "If we applied the list exactly as written, we would be reversing choices made "
        "in October and November that each have a measured reason behind them.",
     space_after=12)

# ----------------------------------------------------------------- 5
h(d, "5.  The exclusion list: journals and publishers are not an issue")
para(d, "You asked us to exclude certain publishers and journals as employers. We "
        "measured it: across the whole candidate pool there are **78 people** whose "
        "employer name contains a journal or publisher, and **5 of them are in the "
        "audience today.** There is nothing here worth writing a rule for, and a rule "
        "keyed on the employer would risk removing genuine academics at those "
        "organisations. We suggest dropping this one.", space_after=12)

# ----------------------------------------------------------------- 6
h(d, "6.  What we need from you")
table(d, ["", "The question", "Why it matters"],
 [["1", "**Is a bare `Director` or `Head`, with nothing saying what they lead, a "
        "decision maker to you?**",
   "9,804 people turn on this. It is the biggest single lever on both the size and "
   "the accuracy of this audience, in or out."],
  ["2", "**Is a hospital or research-institute director the audience you want, or "
        "only commercial roles?**",
   "The honest answer is that opening the rule gives you the first and barely any of "
   "the second."],
  ["3", "**What should this audience be called?**",
   "You said Head of Faculty is misleading, and we agree. The name should be settled "
   "before we change what goes in it."]],
 widths=[0.3, 2.9, 3.0], size=9)
para(d, "Our recommendation on timing: **settle question 1 before we open anything.** "
        "It changes both the size and the accuracy of this audience more than the "
        "academia rule does, and it applies whether or not the audience is widened.",
     space_after=12)

box(d, "WHERE THESE NUMBERS COME FROM", [
 "Every figure is counted on the live data on 16 November 2026. Nothing is sampled or "
 "projected. The “opened” figures are produced by scoring each person again with the "
 "academia rule removed and counting who then qualifies — so they are a count of a "
 "stated change, not a forecast of behaviour.",
 "",
 "One control: the audience as it stands today comes out of the same query at 17,218, "
 "which is the Head of Faculty figure already on the audiences one-pager.",
])

for out in (os.path.join(os.path.dirname(SP), "docs",
                         "ORCID-Decision-Makers-Sizing.docx"),
            os.path.join(os.path.expanduser("~"), "Downloads",
                         "ORCID-Decision-Makers-Sizing.docx")):
    d.save(out); print("saved:", out, os.path.getsize(out), "bytes")
