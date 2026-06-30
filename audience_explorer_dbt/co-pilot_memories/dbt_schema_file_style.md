# MDT dbt schema.yml style

Use this style for all schema.yml files across the MDT repo.

## File Structure
- Always start with `version: 2`.
- One `schema.yml` per model directory (colocated with the models it describes).
- Keep `schema.yml` focused on model/column definitions, contracts, and generic tests (unique, not_null, etc.).
- Store unit tests in a separate `unit_tests.yml` file — never in schema.yml, sometimes the file is also called `unit_test.yml` instead, they both are equally valid.

## Model Block
- Each model entry must include:
  - `name`: matching the SQL filename (without `.sql`).
  - `description`: short sentence or multi-line `>` block describing the model's purpose.
  - `config.contract.enforced: true` — enforced on all models.
  - `columns`: full list of all columns with at minimum `name` and `data_type`.

```yaml
version: 2

models:
  - name: my_model
    description: >
      Short description of what this model contains and its purpose.
    config:
      contract:
        enforced: true
    columns:
      - name: id
        data_type: string
        description: "{{ doc('my_doc_block') }}"
        tests:
          - unique
```

## Column Definitions
- Every column must have `name` and `data_type`.
- `data_type` uses BigQuery types: `string`, `int64`, `float64`, `bool`, `date`, `timestamp`, `struct`, `array`, `integer`, `json`.
- `description` should use `{{ doc('doc_block_name') }}` references where doc blocks exist. Otherwise use inline quoted strings.
- Both single quotes (`'{{ doc("x") }}'`) and double quotes (`"{{ doc('x') }}"`) are acceptable for descriptions — be consistent within a file.

## Tests
- Place column-level generic tests under the column's `tests:` key.
- Place model-level tests (e.g., `dbt_utils.unique_combination_of_columns`) under the model's `tests:` key.
- Use `constraints` for contract-enforced checks (not_null at the database level):
  ```yaml
  constraints:
    - type: not_null
  ```
- Use `tests` for dbt-executed validation:
  ```yaml
  tests:
    - unique
  ```
- Always prefer constraint: not_null over tests: not_null with the exception being if the model is materialized as a view. If any constraints are defined, also make sure that the model is contract-enforced.

## Struct Columns
- Declare the parent struct column with `data_type: struct`.
- Declare nested fields using dot notation: `parent.child_field`.
- Each nested field gets its own `name`, `data_type`, and optionally `description`/`constraints`.

```yaml
- name: main_account
  description: "{{ doc('field_main_account') }}"
  data_type: struct
- name: main_account.account_id
  description: "{{ doc('field_account_id') }}"
  data_type: string
  constraints:
    - type: not_null
```

## Indentation & Formatting
- 2-space indentation throughout.
- Blank line between model entries when multiple models are in one file.
- Column properties in order: `name`, `data_type`, `description`, `constraints`, `tests`.
- No trailing whitespace or extra blank lines at end of file.

## Naming Conventions
- Column names: `snake_case` (lowercase, underscores).
- Doc block references: prefix with a short namespace relevant to the domain (e.g., `gh_` for gaps_holdings, `field_` for CRMNext fields).
- Model names should match the SQL filename exactly.

## Macro

- Theres also the `generate_model_yaml_custom` macro that can be used to generate a skeleton schema.yml entry of a model
- Use this if you can't generate the whole entry by yourself
- Make sure to verify if the output matches this style guide if you used it
