"""
    SYNTAX CHECK — renders every model's Jinja and parses the result with a
    real SQL parser, so a broken CTE chain or a swallowed alias is caught
    here instead of three minutes into a dbt run.

    Written after a missing comma before a new CTE cost a full build. The
    same class of error has cost three others: a `--` comment swallowing a
    column alias when whitespace-stripping tags joined two lines, fourteen
    REGEXP_REPLACE calls nested into thirteen open parens, and an operator
    spliced into a WHERE clause with a replace() chain.

    The macros here are stubs. They do not reproduce dbt's output exactly -
    they only have to produce the right SQL SHAPE, because the question is
    whether the statement parses, not what it returns. Keep them in step
    with macros/ when a macro's shape changes.

        python3 setup/check_sql.py        # from the project root
        echo $?                           # 0 = every model parses

    Needs pyyaml, jinja2 and sqlglot.
"""
import sys, re, yaml, jinja2, sqlglot, pathlib

proj = yaml.safe_load(open('dbt_project.yml'))
roles = proj['vars']['roles']
V = proj['vars']

def role_keys(): return sorted(k for k, v in roles.items() if v.get('enabled', True))
def all_role_keys(): return sorted(roles)
def role(k): return roles[k]
def sql_in_list(items): return ', '.join("'%s'" % i for i in items) or "''"
def var(n, d=None): return V.get(n, d)

def composite_score_expr():
    out = ['CASE role_key']
    for k in role_keys():
        w = roles[k]['weights']
        t = f"LEAST(1.0, COALESCE(role_score,0.0)*{w['role']} + COALESCE(org_score,0.0)*{w['org']}"
        if w['dept'] > 0: t += f" + COALESCE(dept_score,0.0)*{w['dept']}"
        out.append(f"WHEN '{k}' THEN {t})")
    return '\n'.join(out) + '\nELSE NULL END'

def role_label_expr(col='role_final_score'):
    out = ['CASE']
    for k in role_keys():
        t = roles[k]['thresholds']
        out.append(f"WHEN role_key = '{k}' AND {col} >= {t['confirmed']} THEN 'CONFIRMED'")
        out.append(f"WHEN role_key = '{k}' AND {col} >= {t['probable']} THEN 'PROBABLE'")
    return '\n'.join(out) + "\nELSE 'NOT_QUALIFIED' END"

def current_only_predicate(col='is_current'):
    ks = [k for k in role_keys() if roles[k].get('current_only')]
    if not ks: return 'TRUE'
    return f"(role_key NOT IN ({sql_in_list(ks)}) OR {col})"

def role_flag_columns(qualified_labels=('CONFIRMED', 'PROBABLE')):
    out = []
    for k in role_keys():
        out.append(
            f"MAX(IF(role_key = '{k}' AND role_label IN ({sql_in_list(qualified_labels)}), TRUE, FALSE)) AS is_{k},\n"
            f"MAX(IF(role_key = '{k}', role_final_score, NULL)) AS {k}_score,\n"
            f"MAX(IF(role_key = '{k}', role_label, NULL)) AS {k}_label")
    return ',\n'.join(out)

def consent_predicate():
    basis = V['contract']['consent_basis']
    return 'is_marketable' if basis == 'marketing_opt_in' else 'in_cdp'

def contract_array_order():
    return 'role_inferred'

def role_display_name_expr(col='role_key'):
    return 'CASE ' + ' '.join(
        f"WHEN {col} = '{k}' THEN '{roles[k].get('display_name', k)}'" for k in role_keys()) + ' END'

def role_detail_dimension_expr(col='role_key'):
    return 'CASE ' + ' '.join(
        f"WHEN {col} = '{k}' THEN '{roles[k].get('detail_dimension', 'none')}'" for k in role_keys()) + ' END'

def roles_with_parent():
    return [{'child': k, 'parent': v['parent'],
             'bucket': v.get('parent_bucket', 'X'),
             'bucket_label': v.get('parent_bucket', 'X').lower().title()}
            for k, v in roles.items()
            if v.get('enabled', True) and v.get('parent') in role_keys()]

env = jinja2.Environment()
macro_src = ''
for f in pathlib.Path('macros').glob('*.sql'):
    macro_src += f.read_text() + '\n'
# pull parent_rollup_union out of the real macro file so it is not stubbed
pr = macro_src.split('{% macro parent_rollup_union(cte_name) %}')[1].split('{% endmacro %}')[0]
def parent_rollup_union(cte):
    return env.from_string(pr).render(roles_with_parent=roles_with_parent,
                                      cte_name=cte, sql_in_list=sql_in_list)

ctx = dict(config=lambda **k: '', ref=lambda n: f'`p.d.{n}`', source=lambda a, b: f'`p.{a}.{b}`',
           var=var, role_keys=role_keys, all_role_keys=all_role_keys, role=role,
           sql_in_list=sql_in_list, role_title_groups=lambda k: roles[k].get('title_groups', []),
           role_disciplines=lambda k: roles[k].get('disciplines', []),
           role_match_mode=lambda k: roles[k].get('match', 'title_required'),
           composite_score_expr=composite_score_expr, role_label_expr=role_label_expr,
           current_only_predicate=current_only_predicate,
           parent_rollup_union=parent_rollup_union, roles_with_parent=roles_with_parent,
           role_flag_columns=role_flag_columns, consent_predicate=consent_predicate,
           contract_array_order=contract_array_order,
           role_display_name_expr=role_display_name_expr,
           role_detail_dimension_expr=role_detail_dimension_expr,
           normalize_title=lambda c: f'LOWER({c})', clean_text=lambda c: f'LOWER({c})',
           this='`p.d.this`', is_incremental=lambda: False)

bad = 0
for f in sorted(pathlib.Path('models').rglob('*.sql')):
    try:
        sql = env.from_string(f.read_text()).render(**ctx)
    except Exception as e:
        print(f'JINJA  {f}: {e}'); bad += 1; continue
    try:
        sqlglot.parse_one(sql, dialect='bigquery')
        print(f'ok     {f.name}')
    except Exception as e:
        print(f'SYNTAX {f}: {str(e)[:160]}'); bad += 1
sys.exit(1 if bad else 0)
