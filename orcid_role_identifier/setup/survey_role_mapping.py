# -*- coding: utf-8 -*-
"""Map the observed survey answers onto our ten title groups."""
MAP = {
 # ---- student -----------------------------------------------------------
 "ph.d. / master's student":"student", "phd/masters student":"student",
 "student":"student", "phd student":"student", "undergraduate student":"student",
 "medical student":"student", "ph.d. candidate / doctoral student":"student",
 "undergraduate / master student":"student", "phd or masters student":"student",
 "graduate student":"student", "master's student":"student",
 # ---- researcher_early --------------------------------------------------
 "postdoc":"researcher_early", "post-doctoral fellow":"researcher_early",
 "postdoctoral researcher":"researcher_early", "research associate":"researcher_early",
 "researcher":"researcher_early",
 # ---- researcher_established -------------------------------------------
 "research scientist":"researcher_established",
 "principal investigator":"researcher_established",
 "senior scientist":"researcher_established",
 "senior researcher":"researcher_established",
 "mid-career researcher":"researcher_established",
 "research scientist or other researcher":"researcher_established",
 "research professor":"researcher_established",
 # our `head of laboratory` anchor sits in researcher_established, not leadership
 "laboratory director / head":"researcher_established",
 "laboratory director/head":"researcher_established",
 "head of lab":"researcher_established",
 # ---- teaching_academic -------------------------------------------------
 "professor":"teaching_academic", "assistant professor":"teaching_academic",
 "associate professor":"teaching_academic", "lecturer":"teaching_academic",
 "senior lecturer / reader":"teaching_academic", "senior lecturer":"teaching_academic",
 "associate professor / reader":"teaching_academic",
 "associate / assistant professor":"teaching_academic",
 "professor / associate professor":"teaching_academic",
 "adjunct professor":"teaching_academic", "teacher":"teaching_academic",
 # ---- leadership --------------------------------------------------------
 "head of academic dept / faculty":"leadership",
 "head of academic dept/faculty":"leadership",
 "head of department":"leadership", "head of department / faculty":"leadership",
 "head of school / institute director":"leadership", "dean of faculty":"leadership",
 "institute director":"leadership", "vice-chancellor / vice president":"leadership",
 "associate/deputy vice-chancellor / vice president":"leadership",
 "associate vice-chancellor / vice president":"leadership",
 "associate director":"leadership",
 # ---- practitioner ------------------------------------------------------
 "healthcare professional":"practitioner", "physician/clinician":"practitioner",
 "physician / clinician":"practitioner", "consultant":"practitioner",
 "care professional":"practitioner",
 # ---- support_technical -------------------------------------------------
 "editor":"support_technical", "editorial board member":"support_technical",
 "associate editor":"support_technical", "editor-in-chief":"support_technical",
 "section editor":"support_technical", "managing editor":"support_technical",
 "editorial advisor":"support_technical", "research manager":"support_technical",
 "project manager":"support_technical", "engineer":"support_technical",
 "senior program specialist":"support_technical",
 "research funding manager":"support_technical",
 "associate director, grants and scientific communications":"support_technical",
 # ---- librarian ---------------------------------------------------------
 "librarian / information scientist":"librarian", "librarian":"librarian",
 # ---- should be UNASSIGNED in our dictionary ----------------------------
 "retired/not currently working":"__NONE__",
}
# deliberately not mapped - genuinely two different jobs in one option,
# or no occupational content at all
EXCLUDE = {
 "technician / research assistant","technician/research assistant",
 "technician or research assistant",
 "research director / vp of research","research director/vp of research",
 "research director or vp of research","research director",
 "assistant professor / postdoctoral researcher",
 "other","other (please specify)","other (please specify):",
 "other editorial position (please specify):",
 "i no longer have an editorial role at this journal",
 "sonstige (bitte eintragen)",
}
def lookup(raw):
    k = " ".join(str(raw).strip().lower().split())
    if k in EXCLUDE: return None, "excluded"
    g = MAP.get(k)
    if g == "__NONE__": return None, "should_be_unassigned"
    if g: return g, "mapped"
    return None, "unmapped"
