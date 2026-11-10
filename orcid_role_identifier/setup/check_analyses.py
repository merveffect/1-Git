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
import glob, os, re, sys
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

print()
print(f'parse failures: {fails} (excluding {len(KNOWN)} known legacy files)'
      f'     semicolon-in-comment warnings: {warns}')
sys.exit(1 if fails else 0)
