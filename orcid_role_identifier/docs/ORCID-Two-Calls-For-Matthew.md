# Two definition calls on the healthcare audiences

Draft of the note to Matthew, 20 November 2026. Written to be pasted into email
or Teams by Merve. Nothing in it identifies a person: counts and reasons only.

Why it is a file: the two items are the last thing open from the 19 November
reading of the status document, and the shape of the question is the part worth
keeping. `analyses/55` query 7 sizes them and explains why the two are in the
audience for different reasons.

---

**Subject:** Two small definition calls on the healthcare audiences — in or out?

Hi Matthew,

We sort the job titles researchers type into their own ORCID records into ten
audiences. Two groups are sitting inside the healthcare audiences today without
anyone having decided they belong there, and you are the person who can settle
it. Both are small, and either answer is one line of configuration.

**1. Are veterinarians healthcare professionals? — about 90 people**

We added *veterinarian* as a recognised clinical job title in October, and that
was deliberate: before we did, 2,684 real vets were being read as **dentists**,
because dentist was the closest word the system had been given.

Their subject area is treated separately, and there we already draw a line — a
veterinary medicine department counts as a biomedical field rather than a
human-health one, so vets are **not** in *Healthcare Practitioner*. But about 90
of them are in *Healthcare Professional (broad)*, because that audience accepts a
clinical job title on its own without checking the subject.

So the question is narrow: **is a clinician who treats animals in an audience
called Healthcare Professional?**

**2. Is sport and exercise science a human-health field? — about 80 people**

Departments like *Faculty of Sport Sciences* and *Sport and Health Sciences* are
matched to whichever human-health subject they most resemble. Sport science has
never been written down as either in or out, so these 80 are in by resemblance
rather than by decision — which is the difference between this one and the vets.

**What your answer changes.** *In* means we write the decision down and nothing
moves — but it stops being an accident. *Out* means both groups leave the
healthcare audiences. Either way it also affects how we quote accuracy: the
people reading samples by hand are currently told to mark both cases **not
sure**, and not-sure rows are left out of the published 90.6% figure for
*Healthcare Professional (broad)*. So today that figure counts them as neither
right nor wrong. Your answer turns them into one or the other.

**In or out is enough — two words each.** If we do not hear back they stay in,
which is today's behaviour, but it stays an accident rather than a decision.

Thanks,
Merve

---

## Notes for Merve, not for Matthew

- **The two sizes are 12 November counts** and nobody has re-measured them, which
  is why the note says *about 90* and *about 80*. `analyses/55` query 7 gets the
  current figures; swap them in if you would rather send exact numbers.
- **Do not promise the accuracy figure will move in a particular direction.** We
  do not know how many of the hand-read not-sure rows were these two cases, only
  that the reviewer instructions put them there.
- **The 2,684 figure is safe to quote** — it is in
  `seeds/title_group_anchors.csv` against the `veterinarian` anchor, measured
  2026-10-20.
- If he asks what we recommend: we do not have one, and that is the honest
  answer. Neither group can be settled by measuring anything in our data.
