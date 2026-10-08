#!/usr/bin/env python3
"""
Role registry consistency check. Run before dbt:

    python3 setup/validate_registry.py

Checks:
  - dbt_project.yml and the model yml files are valid YAML
  - every .sql file is valid Jinja
  - each enabled role's weights sum to 1.0
  - every enabled role names at least one title group or discipline
  - every group it names exists in the seed files
  - every group has enough anchors
  - parent references point at roles that exist
  - no model uses an undefined var() without a default
"""
import csv
import glob
import re
import sys

import yaml
from jinja2 import Environment

ok = True

for f in ['dbt_project.yml'] + glob.glob('models/**/*.yml', recursive=True) + glob.glob('seeds/*.yml'):
    try:
        yaml.safe_load(open(f))
    except Exception as e:
        ok = False
        print(f"YAML FAIL {f}: {e}")

env = Environment(extensions=['jinja2.ext.do'])
for f in glob.glob('macros/*.sql') + glob.glob('models/**/*.sql', recursive=True) + glob.glob('tests/*.sql'):
    try:
        env.parse(open(f).read())
    except Exception as e:
        ok = False
        print(f"JINJA FAIL {f}: {e}")

roles = yaml.safe_load(open('dbt_project.yml'))['vars']['roles']

title_groups, disciplines = {}, {}
for r in csv.DictReader(open('seeds/title_group_anchors.csv')):
    title_groups.setdefault(r['title_group'], 0)
    title_groups[r['title_group']] += 1
for r in csv.DictReader(open('seeds/discipline_anchors.csv')):
    disciplines.setdefault(r['discipline'], 0)
    disciplines[r['discipline']] += 1

print(f"\n{'role':<18}{'on':<5}{'match':<7}{'weights r/o/d':<20}"
      f"{'title groups':<44}{'disciplines'}")
print("-" * 124)
for k, v in roles.items():
    if not v.get('enabled', True):
        print(f"{k:<18}{'no':<5}{'-':<7}{'-':<20}{'-':<44}-")
        continue
    w = v['weights']
    wtxt = f"{w['role']} / {w['org']} / {w['dept']}"
    tg = v.get('title_groups', [])
    dg = v.get('disciplines', [])
    warn = ''
    if abs(sum(w.values()) - 1.0) > 1e-9:
        warn += f" !!weights sum to {sum(w.values())}"; ok = False
    if not tg and not dg:
        warn += " !!role has neither a title group nor a discipline"; ok = False
    for g in tg:
        if g not in title_groups:
            warn += f" !!unknown title group: {g}"; ok = False
    for g in dg:
        if g not in disciplines:
            warn += f" !!unknown discipline: {g}"; ok = False
    if v.get('parent') and v['parent'] not in roles:
        warn += f" !!unknown parent: {v['parent']}"; ok = False

    # 'all' means both axes are required, so a missing list makes the role
    # match nothing at all - a silent empty audience rather than an error.
    mode = v.get('match', 'any')
    if mode not in ('any', 'all', 'title'):
        warn += f" !!match must be 'any', 'all' or 'title', got {mode!r}"; ok = False
    if mode == 'title' and not tg:
        warn += " !!match:title needs a title group"; ok = False
    if mode == 'all' and (not tg or not dg):
        warn += " !!match:all needs BOTH a title group and a discipline"; ok = False
    if mode == 'all' and w['dept'] == 0:
        warn += " !!match:all with dept weight 0 - the required axis scores nothing"
        ok = False

    print(f"{k:<18}{'yes':<5}{mode:<7}{wtxt:<20}{str(tg):<44}{dg or 'any'}{warn}")

print(f"\n{'title group':<26}{'anchors':<10}{'discipline':<26}anchors")
print("-" * 76)
tg_items = sorted(title_groups.items()); dg_items = sorted(disciplines.items())
for i in range(max(len(tg_items), len(dg_items))):
    a = f"{tg_items[i][0]:<26}{tg_items[i][1]:<10}" if i < len(tg_items) else " " * 36
    b = f"{dg_items[i][0]:<26}{dg_items[i][1]}" if i < len(dg_items) else ""
    print(a + b)

for g, n in list(title_groups.items()) + list(disciplines.items()):
    if n < 5:
        ok = False
        print(f"  !! {g} has only {n} anchors; at least 5 are needed")

for k, v in roles.items():
    if v.get('enabled', True) and v.get('parent'):
        print(f"\nroll-up: {k} -> {v['parent']} / {v.get('parent_bucket')}")

# ── undefined var() check ────────────────────────────────────────────────
# Edits to dbt_project.yml have silently failed before, leaving models
# referencing vars that were never defined; dbt run then fails at compile
# time. This catches it beforehand.
cfg_text = open('dbt_project.yml').read()
defined = set(re.findall(r"^\s{2}([a-z_]+):", cfg_text, re.M))
used = {}
for f in glob.glob('models/**/*.sql', recursive=True) + glob.glob('macros/*.sql') + glob.glob('tests/*.sql'):
    for name, comma in re.findall(r"var\(\s*['\"]([a-z_]+)['\"]\s*(,)?", open(f).read()):
        used.setdefault(name, False)
        if comma:
            used[name] = True
missing = sorted(n for n, has_default in used.items() if n not in defined and not has_default)
if missing:
    ok = False
    print("\nUNDEFINED var() (and no default):")
    for n in missing:
        print(f"  - {n}")
else:
    print(f"\nvar check: {len(used)} vars used, all defined")

print("\nOK" if ok else "\nFAILED")
sys.exit(0 if ok else 1)
