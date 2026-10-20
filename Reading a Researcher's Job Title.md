Researcher 360 · Build of 20 October 2026

# Reading a researcher's job title, in any language

ORCID holds 1.8 million researcher profiles. Each one says where the person works and what their job is called — but only as free text they typed themselves. This project reads that text and decides what profession each person has, so marketing can build an audience from it.

**673,553**people now have a profession we can name

**501,522**of them reachable — in the CDP and opted in

**9**audiences, where there was one

**1.6**professions per person on average

Where we started

## One audience, English only

Before this project there was a single audience: healthcare professional. Someone had written a list of English words — physician, nurse, surgeon — and if a job title contained one of them, the person counted. That is a reasonable way to start, and it has two hard limits. It covers one profession, and it only works in English.

### Before

- 1 audience
- English job titles only
- Adding an audience meant a new project
- Rules hand-written for one profession

### Now

- 9 audiences
- Any language the model understands
- Adding an audience is a settings change
- One method, shared by all of them

We checked the old rules against ours on healthcare. Of the people the old system called healthcare professionals and we do not, about **53,000 work in engineering, earth science, mathematics or humanities departments**. They were picked up for *where* they worked — a medical school, a hospital — not for what they did.

The method

## How one person gets a profession

The important idea is that we never classify people. We classify the **vocabulary** — the 310,299 different job titles and 450,307 different department names that appear anywhere in ORCID — and we do that once. After that, giving 1.8 million people their profession is an ordinary database join.

That is why the AI cost does not grow. The thinking happens once over the words; the daily refresh is free.

1. **Turn every job title into numbers.** An AI model reads each title and turns it into a list of 768 numbers that stand for its meaning. Two titles that mean the same thing end up close together, even in different languages.
2. **Compare it to our example words.** We hand-wrote 143 example job titles and 162 example research fields. Each real title is matched to whichever example it is closest to in meaning.
3. **Score the evidence.** The job title, the organisation and the department each contribute. Each audience weighs them differently.
4. **Label it.** Above the audience's threshold the person is *confirmed*. Below it but still close, *probable*. Only confirmed people are delivered today.

Two questions, kept apart

## What they do, and what field they work in

A job title tells you the *kind* of work. A department tells you the *subject*. They are not the same question, so we answer them separately and combine the answers afterwards.

We measured this rather than assumed it. If you try to read the research field out of the job title, 73.5% of records tell you nothing — "professor" has no field. Read it from the department instead and only 1.6% are unusable.

### Axis 1 — the title

What kind of work is this? Sorted into 10 groups: practitioner, clinical trainee, teaching, early-career research, established research, leadership, student, support, pharmacist, librarian.

"consultant cardiologist"

combined

### Axis 2 — the field

What subject is this? Sorted into 12 fields: clinical health, life and biomedical, pharmacy, engineering, computing, earth and agriculture, and so on.

"Department of Cardiology"

Why example words

## We write the examples. The model does the generalising.

We cannot write a rule for 310,299 job titles, and nobody can list every way the world says "nurse". So we do the opposite: we write a small number of clear examples and let the model find everything that *means the same thing*.

This is the part that makes language stop mattering. We never translated anything. Every example below is an English word, and the titles reaching it were typed in Portuguese, Turkish, German, Spanish and Russian. The number on the right is how close the meaning is, from 0 to 1.

enfermeiro*Portuguese*→nurse0.73

hemşire*Turkish*→nurse0.69

ärzte*German*→physician0.75

facharzt*German*→medical doctor0.73

médico de familia*Spanish*→medical doctor0.74

bibliotecário*Portuguese*→librarian0.79

директор библиотеки*Russian*→library director0.83

The old keyword rules could not see a single one of these.

Why a score and not a yes or no

## The same word can be two different jobs

This is the clearest reason the system scores evidence instead of simply matching words. In Britain, a hospital specialist is called a consultant. Almost everywhere else, a consultant is a business adviser. The job title is identical. Only the department tells them apart.

### Consultant, in a cardiology department

job title × 0.350.35

organisation × 0.250.25

department × 0.400.40

total1.00

**confirmed** far above the 0.60 line.

### Consultant, in a business school

job title × 0.350.35

organisation × 0.250.25

department × 0.400.00

total0.60

**exactly on the line** and only because the title is a perfect match.

The arithmetic is doing real work here. To be confirmed on a job title with no department agreeing, the title has to match an example word *exactly* and the organisation has to be fully identified. Anything less cannot reach 0.60. That is why **business consultant**, which the model scores at 0.84, can never get into the healthcare audience — and why only **1,008 people** out of 126,270 are there on a title alone.

We checked this by country. Where "consultant" means a hospital doctor, 68–88% of them also name a clinical department. In the United States it is 20%, in Brazil 8%. The department axis was already separating them.

The nine audiences

## What marketing can pull today

Each audience has its own rule about what evidence it needs, and its own threshold. These were not guessed — each one was set after measuring what it let in and what it kept out.

| Audience | What it needs | Identified | Reachable |
| --- | --- | --- | --- |
| Lecturer | title | 400,445 | 309,206 |
| Researcher | title | 322,266 | 227,913 |
| Healthcare professional | title *or* field | 126,270 | 94,250 |
| Practitioner | title *and* field | 60,083 | 44,910 |
| Clinical researcher | title *and* field | 50,590 | 37,198 |
| Clinical administrator | title *and* field | 6,855 | 5,357 |
| Pharmacist | title | 2,335 | 1,752 |
| Head of faculty | title, current post only | 20,222 | 15,708 |
| Librarian | the word in the title | 666 | 360 |

The four indented rows sit *inside* healthcare professional, not next to it. And the numbers cannot be added: people hold 1.6 professions on average, so a professor who publishes research appears as both a Lecturer and a Researcher. For one total, use 501,522 people.

### Reachable people, by audience

Lecturer309,206

Researcher227,913

Healthcare94,250

Practitioner44,910

Clinical researcher37,198

Clinical admin5,357

Pharmacist1,752

Head of faculty15,708

Librarian360

Where the people go

## Coverage is the ceiling now, not permission

ORCID profiles1,812,702

Has a usable job record849,370

We can name a profession673,553

Also in the CDP646,233

And opted in501,522

Read the third row. **1,139,149 people get no audience at all**, and most of that is a choice rather than a failure: there is no audience yet for students (1.9M job records) or for technical and support staff (1.4M). Losing people to CDP membership and opt-in together costs 172,000 by comparison. The place to grow is a new audience, not more permission.

What went wrong

## Four problems, and how they showed up

None of these failed loudly. Each one looked fine and produced wrong numbers, and each was found by measuring something rather than by noticing it.

### Veterinarians were being called dentists

There was no example word for "veterinarian", so the model picked the closest one it had. Same for anaesthetists, optometrists and midwives. The answers were wrong because the vocabulary we gave it was incomplete, not because the method was. We added 31 missing professions.

2,684*records*

### Example words in 11 languages made things worse

For the librarian audience we wrote the word in Spanish, Portuguese, Turkish, Russian and Japanese, expecting better coverage. It attracted anything that merely *looked* similar: biólogo, catedrática, nutricionista. Nearly seven records in ten were wrong, so we deleted all of them — and the real foreign librarians stayed, because they were reaching the English word on their own.

69%*wrong*

### Deleting an example word did nothing at all

The table holding the examples only ever added rows, so anything we removed stayed live. It had already been misdiagnosed once: corporate job titles kept arriving in the leadership group after we removed "chief executive officer" and "founder", and we concluded the model simply generalised to them. It had not. The deletion had never happened.

silent*for weeks*

### Epidemiologists became clinicians

Adding "pathologist" as an example pulled in every science ending in the same way — epidemiologist, toxicologist, entomologist, hydrologist. We moved them back by hand and kept the example word, because real pathologists need it. The lesson: what makes an example word dangerous is not how it is spelled but how crowded its neighbourhood is.

7,779*records*

### How the clinical audience improved in one day

Before40.6%

After34.3%

Share of clinical job titles the model was unsure about. Clinical titles are the hardest vocabulary in the data — Resident, Registrar, Facharzt, Interno and Senior House Officer all overlap in meaning and share no common word — so this is the group we will keep working on.

Being straight about it

## What we cannot claim

**There is no accuracy percentage, and there never will be one.** ORCID has no "profession" field. The job title is free text the researcher typed, so there is no correct answer anywhere to compare ours against. The old system is not a reference either — we can show 53,000 people it got wrong. If we quoted "94% accurate" we would be inventing it.

What we do instead is make every decision inspectable. For any person, we can say which words they typed, which example word it matched, how close the match was, and whether a human or the model decided. **96 decisions are currently pinned by hand** and always beat the model. Ten automated tests guard the specific ways this system has failed before.

Two other honest limits. **Reachable means opted in, not deliverable** — the CDP holds no bounce or suppression data, so we cannot promise an address works. And **seven of the nine audiences count past jobs**: someone who was a researcher in 2010 and works in a bank today is still in the Researcher audience, on the reasoning that researcher is a profession you have rather than a post you hold. Head of faculty and Librarian are the exceptions.

Next

## Three decisions, and the biggest unused signal

Three questions are waiting on marketing, because each is a definition rather than a technical problem. Should the second confidence tier be switched on — it nearly doubles the healthcare audience and adds almost nothing to the others. Are biomedical researchers healthcare professionals, which turns on 15,588 people. Is a "Director" at a university a head of faculty, which is about 2,900.

The largest technical opportunity is something we hold and have never touched. ORCID also records each person's **education** — their degrees. A degree is far more standard than a job title: MD, MBBS, BDS and PharmD mean one thing worldwide. That is exactly what would settle the 146,865 records where the job title is only dr or md and tells us nothing at all.

And the biggest audience opportunity is the student group: 1.9 million job records already classified and feeding nothing. For a publisher, that is probably the most valuable group we are currently ignoring.

Springer Nature · Researcher 360 · analytics engineering. All figures measured on the build of 20 October 2026. A detailed technical reference and a full register of open questions are kept alongside the code.