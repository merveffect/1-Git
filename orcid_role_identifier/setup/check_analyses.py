# -*- coding: utf-8 -*-
"""Parse every statement in analyses/, and warn about semicolons in comments.

TWO SEPARATE THINGS, because conflating them is how the first version of this
script reported 113 failures that were all one bug.

1. PARSING. Comments are stripped FIRST and only then is the file split on the
   semicolon. That is the correct order: a semicolon inside a comment is not a
   statement separator to BigQuery, and a checker that splits before stripping
   reports the comment text as broken SQL.

2. A SEMICOLON INSIDE A COMMENT is still worth a warning, because these files
   are used by pasting one statement at a time and anything that splits on the
   semicolon - an editor, a script, a person dragging a selection - will cut a
   statement in half. It is a warning, not a failure.
"""
import glob, io, os, re, sys
import sqlglot


def strip_comments(sql):
    sql = re.sub(r'/\*.*?\*/', '', sql, flags=re.S)
    return '\n'.join(l for l in sql.split('\n') if not l.strip().startswith('--'))


# Known and not new. Checked 2026-11-10 and left alone deliberately.
#   08  sqlglot will not parse this project's regexp_replace arity. The SQL
#       runs in BigQuery; the parser is what is wrong here, not the file.
#   17  two statements carry a semicolon inside a STRING literal, which the
#       splitter cannot see past. Same cause as the comment warning below.
#   20  contains Jinja. It cannot be pasted into BigQuery without compiling
#       first, which is a real problem with that file and is recorded as one.
KNOWN = {'08_assignment_audit.sql', '17_diagnostics.sql',
         '20_external_role_library.sql'}

fails = warns = 0
for path in sorted(glob.glob(os.path.join(os.path.dirname(__file__), '..', 'analyses', '*.sql'))):
    name = os.path.basename(path)
    sql = open(path, encoding='utf-8').read()

    local_warn = []
    for i, line in enumerate(sql.split('\n'), 1):
        if line.strip().startswith('--') and ';' in line:
            local_warn.append(f'{name}:{i}')
    for block in re.findall(r'/\*.*?\*/', sql, re.S):
        if ';' in block:
            local_warn.append(f'{name}:~{sql[:sql.index(block)].count(chr(10)) + 1} (block)')

    n = bad = 0
    for st in strip_comments(sql).split(';'):
        body = st.strip()
        if not body:
            continue
        n += 1
        if body.lower().startswith('declare'):
            continue
        try:
            sqlglot.parse_one(body, read='bigquery')
        except Exception as e:
            print(f'  PARSE FAIL  {name} statement {n}: {str(e)[:90]}')
            bad += 1

    if bad and name not in KNOWN:
        fails += bad
    warns += len(local_warn)
    flag = 'FAIL ' if bad else 'ok   '
    print(f'{flag}  {name:52} {n:2} statements'
          + (f'   [{len(local_warn)} semicolon-in-comment]' if local_warn else ''))


# ---------------------------------------------------------------------------
# 3. EVERY FULLY-QUALIFIED TABLE REFERENCE MUST NAME A RELATION THAT EXISTS,
#    IN THE DATASET IT ACTUALLY LIVES IN.
#
#    Added 2026-11-12, after a query failed on
#    `..._presentation.fct_researcher_roles`. The table is real and the column
#    list was right; it is in the SCORING dataset. fct_researcher_roles sits in
#    models/scoring/ even though its own header says the whole presentation
#    layer is built from it, and that sentence is what made the wrong dataset
#    feel right while writing eight references to it across three files.
#
#    These files are run by pasting a statement into the BigQuery console, so a
#    wrong dataset is not caught by anything until a person is sitting there
#    waiting for a result. sqlglot parses it happily - it is a valid identifier.
#
#    The mapping is exact and needs no table: dbt_project.yml gives every model
#    directory a +schema equal to its own name, and seeds get 'seeds'. So the
#    dataset in a reference must equal the directory the .sql file is in.
#
#    INFORMATION_SCHEMA references are skipped - they are a BigQuery facility,
#    not a relation of ours - and so is the review dataset, which is populated
#    by hand rather than by dbt.
PROJECT = 'dat-analytics-eng-ec869189'
PREFIX = 'dev_orcid_role_identifier_'
SKIP_DATASETS = {'review'}

# Relations dbt does not own. survey_self_declared_roles was uploaded by hand
# on 2026-10-30 from a CSV and is documented in analyses/29 - it holds the
# self-declared roles the audiences were validated against. The CSV is NOT in
# this repository and must not be: it is keyed on email, and a per-person row
# does not get committed. So the table is real, it is not a model, and the
# check has to know it rather than fail on it.
HAND_LOADED = {'survey_self_declared_roles': {'raw'}}

where = dict((k, set(v)) for k, v in HAND_LOADED.items())
for f in glob.glob('models/*/*.sql'):
    where.setdefault(os.path.basename(f)[:-4], set()).add(
        os.path.basename(os.path.dirname(f)))
for f in glob.glob('seeds/*.csv'):
    where.setdefault(os.path.basename(f)[:-4], set()).add('seeds')

ref_re = re.compile(r'`' + re.escape(PROJECT) + r'\.' + re.escape(PREFIX)
                    + r'([a-z_]+)\.([A-Za-z_][A-Za-z_0-9]*)')
ref_bad = 0
for path in sorted(glob.glob('analyses/*.sql')):
    body = strip_comments(io.open(path, encoding='utf-8').read())
    for dataset, relation in set(ref_re.findall(body)):
        if dataset in SKIP_DATASETS or relation == 'INFORMATION_SCHEMA':
            continue
        homes = where.get(relation)
        if homes is None:
            print(f'  NO SUCH RELATION  {os.path.basename(path)}: '
                  f'{PREFIX}{dataset}.{relation} - no model or seed by that name')
            ref_bad += 1
        elif dataset not in homes:
            print(f'  WRONG DATASET     {os.path.basename(path)}: '
                  f'{relation} is in {"/".join(sorted(homes))}, not {dataset}')
            ref_bad += 1

print(f'\nreference check: {"OK" if not ref_bad else str(ref_bad) + " WRONG"}'
      f'   ({len(where)} relations known)')

print()
print(f'parse failures: {fails} (excluding {len(KNOWN)} known legacy files)'
      f'     semicolon-in-comment warnings: {warns}')
sys.exit(1 if fails or ref_bad else 0)
