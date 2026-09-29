#!/usr/bin/env python3
"""
Role registry consistency check. Run before dbt:

    python3 setup/validate_registry.py

Checks:
  - dbt_project.yml and the model yml files are valid YAML
  - every .sql file is valid Jinja
  - each enabled role's weights sum to 1.0
  - each enabled role has enough anchors
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

anchors = {}
for r in csv.DictReader(open('seeds/role_anchors.csv')):
    anchors.setdefault(r['role_key'], {'include': 0, 'exclude': 0})[r['polarity']] += 1

print(f"\n{'role':<14}{'enabled':<9}{'weights':<9}{'thresholds':<14}{'current':<9}anchors (inc/exc)")
for k, v in roles.items():
    if not v.get('enabled', True):
        print(f"{k:<14}{'no':<9}{'-':<9}{'-':<14}{'-':<9}-")
        continue
    w = round(sum(v['weights'].values()), 4)
    t = v['thresholds']
    a = anchors.get(k, {'include': 0, 'exclude': 0})
    warn = ''
    if abs(w - 1.0) > 1e-9:
        warn += ' !!weights do not sum to 1.0'
        ok = False
    if a['include'] < 5:
        warn += ' !!needs at least 5 include anchors'
        ok = False
    if v.get('parent') and v['parent'] not in roles:
        warn += f" !!unknown parent: {v['parent']}"
        ok = False
    print(f"{k:<14}{'yes':<9}{w:<9}{str(t['confirmed']) + '/' + str(t['probable']):<14}"
          f"{str(v['current_only']):<9}{a['include']}/{a['exclude']}{warn}")

d = anchors.get('__distractor', {'include': 0})
print(f"{'__distractor':<14}{'-':<9}{'-':<9}{'-':<14}{'-':<9}{d['include']}/0")
if d['include'] < 20:
    ok = False
    print("  !! the distractor set is the primary decision reference - it needs at least 20 terms")

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
