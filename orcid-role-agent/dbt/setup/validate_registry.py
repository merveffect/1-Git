#!/usr/bin/env python3
"""
Rol kayit defteri tutarlilik kontrolu. dbt calistirmadan once calistir:
    python3 setup/validate_registry.py

Kontroller:
  - dbt_project.yml ve yml dosyalari gecerli YAML mi
  - butun .sql dosyalari gecerli Jinja mi
  - her aktif rolun agirlik toplami 1.0 mi
  - her aktif rolun yeterli anchor'i var mi
  - parent referanslari mevcut role mi isaret ediyor
"""
import csv, glob, sys, yaml
from jinja2 import Environment

ok = True

for f in ['dbt_project.yml'] + glob.glob('models/**/*.yml', recursive=True) + glob.glob('seeds/*.yml'):
    try:
        yaml.safe_load(open(f))
    except Exception as e:
        ok = False
        print(f"YAML FAIL {f}: {e}")

env = Environment(extensions=['jinja2.ext.do'])
for f in glob.glob('macros/*.sql') + glob.glob('models/**/*.sql', recursive=True):
    try:
        env.parse(open(f).read())
    except Exception as e:
        ok = False
        print(f"JINJA FAIL {f}: {e}")

roles = yaml.safe_load(open('dbt_project.yml'))['vars']['roles']

anchors = {}
for r in csv.DictReader(open('seeds/role_anchors.csv')):
    anchors.setdefault(r['role_key'], {'include': 0, 'exclude': 0})[r['polarity']] += 1

print(f"\n{'rol':<14}{'aktif':<7}{'agirlik':<9}{'esik':<14}{'current':<9}anchor (inc/exc)")
for k, v in roles.items():
    if not v.get('enabled', True):
        print(f"{k:<14}{'hayir':<7}{'-':<9}{'-':<14}{'-':<9}-")
        continue
    w = round(sum(v['weights'].values()), 4)
    t = v['thresholds']
    a = anchors.get(k, {'include': 0, 'exclude': 0})
    warn = ''
    if abs(w - 1.0) > 1e-9:
        warn += ' !!agirlik toplami 1.0 degil'; ok = False
    if a['include'] < 5:
        warn += ' !!en az 5 include anchor gerekli'; ok = False
    if v.get('parent') and v['parent'] not in roles:
        warn += f" !!bilinmeyen parent: {v['parent']}"; ok = False
    print(f"{k:<14}{'evet':<7}{w:<9}{str(t['confirmed']) + '/' + str(t['probable']):<14}"
          f"{str(v['current_only']):<9}{a['include']}/{a['exclude']}{warn}")

for k, v in roles.items():
    if v.get('enabled', True) and v.get('parent'):
        print(f"\nroll-up: {k} -> {v['parent']} / {v.get('parent_bucket')}")


# ── tanimsiz var denetimi ────────────────────────────────────────────────
# Gecmiste sessizce basarisiz olan duzenlemeler yuzunden modellerde
# tanimsiz var() kalmisti; dbt run derleme hatasi veriyordu. Bu kontrol
# onu build'den ONCE yakaliyor.
import re
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
    print("\nTANIMSIZ var() (varsayilani da yok):")
    for n in missing:
        print(f"  - {n}")
else:
    print(f"\nvar denetimi: {len(used)} var kullaniliyor, hepsi tanimli")

print("\nOK" if ok else "\nHATA VAR")
sys.exit(0 if ok else 1)
