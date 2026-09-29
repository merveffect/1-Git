# Adding a Role

The design goal: **adding a role should touch two files.**
No model, macro or SQL file is edited.

---

## 1. Add a block under `vars.roles` in `dbt/dbt_project.yml`

```yaml
    veterinarian:
      display_name: 'Veterinarian'      # exact spelling used in the Braze contract
      detail_dimension: setting         # bucket | setting | org_type | none
      enabled: true
      label: 'Veterinarian'
      axis: profession                  # profession | position
      description: >
        Veterinary surgeons in clinical practice and animal health
        research. This text is passed verbatim to the LLM judge, so keep
        it precise and state the boundaries.
      isco_groups: ['2250']
      weights:         {role: 0.60, org: 0.25, dept: 0.15}
      education_bonus: 0.20
      thresholds:      {confirmed: 0.60, probable: 0.30}
      current_only:    false
      # parent: hcp                     # also rolls up into a parent role
      # parent_bucket: PRACTITIONER
```

Weights must sum to 1.0 — `setup/validate_registry.py` checks this.

## 2. Add anchor rows to `dbt/seeds/role_anchors.csv`

At least 10–15 `include` terms and a few `exclude` terms. Write them in
several languages: the embedding model is multilingual (verified), so a
German or Turkish anchor genuinely widens coverage.

```csv
veterinarian,veterinarian,include,en,
veterinarian,veterinary surgeon,include,en,
veterinarian,tierarzt,include,de,
veterinarian,veteriner hekim,include,tr,
veterinarian,veterinary nurse,exclude,en,separate occupation
```

Exclude anchors matter more than they look. In calibration they caught
9 of 15 false matches on their own.

Optional: add rows to `org_type_scores.csv`, `dept_signals.csv`,
`education_signals.csv` and `role_detail_map.csv`. Anything you skip
simply scores 0 for that component.

## 3. Run

```bash
python3 setup/validate_registry.py     # catches weight and anchor mistakes
dbt seed
dbt run --select int_anchor_terms+
```

Only the new anchors are embedded — the existing title embeddings are
incremental and are not recomputed.

## 4. Check the result

```sql
SELECT * FROM orcid_role_agent_presentation.rpt_title_review_queue
WHERE role_key = 'veterinarian' ORDER BY frequency DESC LIMIT 100;
```

Work down the list, then record your decisions in
`seeds/role_title_overrides.csv` and re-run:

```bash
dbt seed && dbt run -s dim_title_role+
```

---

## Retiring a role

Set `enabled: false`. **Never delete it** — historical scores and
roll-ups would lose their meaning. A disabled role drops out of every
loop automatically.

## Tuning

| Symptom | Fix |
|---|---|
| Too many false positives | Add `exclude` anchors, or add the offending occupation to `__distractor` |
| Too few people matched | Add more `include` anchors — different languages, abbreviations, spellings |
| Wrong organisation weighting | Edit `org_type_scores.csv` |
| Title is right but the score is low | Raise `weights.role` for that role |
| A whole class of unrelated jobs sneaks in | Add them to the `__distractor` rows in `role_anchors.csv` |

## About `__distractor`

`__distractor` is a pseudo-role holding common occupations that are none
of our targets (software engineer, hr manager, lawyer, ...). It is the
reference point the decision rule measures against.

Calibration showed absolute similarity cannot separate true from false
matches — the classes overlap heavily (true 0.682–1.000, false
0.519–0.953). What does separate them is how much closer a title sits to
a target role than to these distractors: true matches score at least
+0.13, false matches are mostly negative.

So when a new role starts pulling in unrelated jobs, the fix is usually
to strengthen `__distractor`, not to raise the threshold.
