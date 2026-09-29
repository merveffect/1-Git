# ORCID Role Agent

Turns ORCID employment and education data into **role-based audiences**.
A generalisation of the existing HCP Phase-1/Phase-2 pipeline: instead of
hand-written regex for one role, a single pipeline that works for any role.

Output: **multi-label** role assignments per `snid`, with scores,
evidence and consent flags.

---

## The core idea

We do not classify 24.8 million people. We classify **distinct job
titles** — there are far fewer of them, and they repeat constantly.

```
millions of employment records
  ~hundreds of thousands of distinct title strings
    AI runs ONCE per distinct title, and the answer is cached
      labelling people is then a plain SQL join
```

AI only runs while the **dictionary** is being built. Once it exists,
labelling people is deterministic, instant and free.

---

## What the data actually looks like

Measured, not assumed (`analyses/00_source_profile.sql`, `01_field_coverage.sql`):

| | |
|---|---|
| ORCID profiles | 24,864,410 |
| **Carrying an SNID** (our working population) | **1,755,447** |
| Present in CDP | 1,684,121 (96%) |
| Marketing consent | 423,904 (24%) |
| Advertising consent | 328,406 (19%) |
| Employment records | 38,656,511 |
| `role` populated | 82% |
| `organisation` populated | 100% |
| `department` populated | 79% |
| Visibility PUBLIC | 96% |

Two things follow. Without an SNID a person is unreachable, so the raw
layer filters them out. And **consent, not identification, is the
binding constraint** — every audience output reports reachable counts,
not just matched counts.

---

## Roles

The registry lives in `dbt/dbt_project.yml` -> `vars.roles`

| role_key | axis | current_only | note |
|---|---|---|---|
| `hcp` | profession | no | detail: Practitioner / Researcher / Administrator |
| `pharmacist` | profession | no | **also** rolls up into `hcp` / PRACTITIONER |
| `librarian` | profession | **yes** | institutional sales audience; a current post is required |
| `researcher` | position | no | **all fields**, not restricted to health |
| `faculty_head` | position | **yes** | a temporary post; current records only |
| `lecturer` | position | — | `enabled: false`, deferred |

A person can hold several roles. `Professor of Cardiology, Head of
Department` produces `hcp` + `researcher` + `faculty_head`.

To add a role: [docs/ADDING_A_ROLE.md](docs/ADDING_A_ROLE.md)

---

## Pipeline

```
raw/          sources + visibility filter + SNID filter
   |
staging/      flatten, normalise, resolve organisations
   |
dictionary/   ⭐ THE DICTIONARY  (AI runs here, and only here)
   |  int_title_distinct      distinct titles + frequency
   |  int_anchor_terms        anchors per role + '__distractor'
   |  int_*_embeddings        ML.GENERATE_EMBEDDING, once per title
   |  int_title_role_match    VECTOR_SEARCH -> distractor margin -> decision
   |  int_title_role_judged   optional LLM judge (currently disabled)
   |  int_org_resolved        organisation -> ROR id -> organisation type
   |  dim_title_role          ⭐ title x role dictionary
   |
scoring/      int_employment_scored -> fct_researcher_roles
   |             (snid x role_key x source_key, scored and labelled)
   |
presentation/ dim_researcher_role_flags   wide per-person view
              fct_role_audience           audience + consent
              fct_role_audience_summary   identified vs reachable
              rpt_title_review_queue      human review queue
              fct_braze_contact_roles     ⭐ Braze data contract
```

### The decision rule

Calibration (`analyses/02_similarity_calibration.sql`) showed that
absolute similarity **does not** separate true from false matches:

```
true matches   0.682 - 1.000
false matches  0.519 - 0.953      heavy overlap
```

`pharmacologist` scores 0.953 against pharmacist anchors but is not a
pharmacist. What separates the classes is the **distractor margin** —
how much closer a title is to a target role than to common non-target
occupations:

```
true matches   minimum  +0.13
false matches  mostly NEGATIVE, highest +0.12
```

So the rule is:

| Check | Effect |
|---|---|
| Role-specific `exclude` anchor is closer | reject (caught 9 of 15 false matches) |
| Similarity below `sim_floor` (0.65) | reject |
| Distractor margin below 0.13 | reject |
| Outside the tie band of the best role | reject |
| Otherwise | accept |

The **tie band** is what preserves multi-label: every role within 0.12
of the best role is accepted, because a title genuinely can belong to
two roles at once.

Human decisions in `seeds/role_title_overrides.csv` override everything.

---

## Sources

Today there is one source: ORCID.

`stg_role_records` is where role records enter the pipeline, and
everything downstream reads it rather than `stg_orcid__employment`. When
web scraping arrives (expected shape: `snid` + `role_title`, little
else) it becomes a UNION ALL there, plus one branch in
`fct_braze_contact_roles` for the display name.

Columns a future source cannot supply are simply NULL. The scoring layer
already treats a NULL organisation or department as "no evidence", so
nothing special is needed for that.

Nothing is abstracted ahead of the second source arriving - its real
shape will decide what, if anything, needs generalising.

---

## Setup

```bash
cp dbt/profiles.yml.example ~/.dbt/profiles.yml   # then edit
cd dbt
python3 setup/validate_registry.py
dbt deps && dbt seed && dbt run && dbt test
```

Projects:

```
READ   researcher-360-prod-e7fd74be   ORCID + CDP
       ri-data-engineering-dd4c0eca   ROR registry
       datasn-rm-live                 embedding model
WRITE  dat-analytics-eng-ec869189 . orcid_role_agent
```

### Still open

- [ ] Verify column names: `bq show --schema ri-data-engineering-dd4c0eca:ror.ror_data_refresh`
- [ ] Confirm the display names match the MPC `role` field spellings exactly
- [ ] Vertex AI connection (optional — enables the LLM judge)
- [ ] Load ESCO and set `use_esco: true` (optional, widens multilingual anchors)
- [ ] DPO decision on `consent_basis`

---

## Using it

```sql
-- Clinical academics in Germany who can be marketed to
SELECT a.snid, a.evidence_title, a.evidence_org
FROM orcid_role_agent_presentation.fct_role_audience a
JOIN orcid_role_agent_presentation.dim_researcher_role_flags f USING (snid)
WHERE f.is_hcp AND f.is_researcher
  AND a.country_code = 'DE'
  AND a.is_marketable;

-- Reachability summary per role
SELECT * FROM orcid_role_agent_presentation.fct_role_audience_summary
ORDER BY marketable DESC;
```

---

## Braze data contract

`fct_braze_contact_roles` — one row per contact.

| field | example |
|---|---|
| `contact_email` | xx@xcv.com  (from `audience_builder_big.email`) |
| `snid` | 1233 |
| `role_inferred` | `['Head of Faculty', 'Healthcare Professional']` |
| `role_detailed_inferred` | `['Head of Faculty - University', 'Healthcare Professional - Practitioner']` |
| `role_inferred_data_source` | `['Orcid', 'Orcid + Web scraping']` |
| `role_inferred_data_source_last_updated` | `[ts, ts]` |

### Array alignment

The four arrays are **positionally** aligned: `role_inferred[i]` and
`role_inferred_data_source[i]` describe the same role. Braze cannot
validate that. If it drifts, the wrong person lands in the wrong segment
and nobody notices.

So all four are derived from **one ordered source** using the same
`ORDER BY`, and two tests run on every build:

- `assert_contract_arrays_aligned` — array lengths match
- `assert_detailed_prefix_matches_role` — `detailed[i]` really starts with `role_inferred[i]`

The canonical form is also kept in `roles_struct` (an array of structs
rather than parallel arrays) for debugging.

### Settings — `dbt_project.yml` -> `vars.contract`

| setting | options | note |
|---|---|---|
| `consent_basis` | `marketing_opt_in` / `legitimate_interest` / `both` | DPO decision; safe default first |
| `include_labels` | `['CONFIRMED']` / `+ 'PROBABLE'` | adding PROBABLE roughly doubles volume |
| `array_order` | `alphabetical` / `score` | the contract says alphabetical; `score` is more useful |
| `detail_separator` | `' - '` | |

---

## Validation

The existing `hcp_identified_phase1` output is this pipeline's
**regression test**. If it reproduces the same labels on the same
population, the system is validated. Divergences must be inspected
individually — the new pipeline is expected to *find* non-English titles
Phase-1 missed, which shows up as a recall difference rather than an
error.

---

## The AI agent (not built yet)

The dbt pipeline **works on its own**; the agent is not required. It
adds two things:

1. **Querying** — a plain-English request becomes the right role filter
   and SQL, with the result explained.
2. **Role onboarding** — "add lecturer" makes the agent gather anchors,
   show what matches in the real data, write the config block and seed
   rows, and **ask for approval**. It never runs anything by itself.

The agent reads the dictionary and the marts. It never touches the
person-level tables.
