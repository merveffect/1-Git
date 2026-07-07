# MDT dbt unit test style

Use this style for all unit tests across the MDT repo.

- **REQUIRED**: Each unit test must include a `model` property specifying the model being tested:
  ```yaml
  - name: test_name
    model: model_name
    description: "..."
  ```
- Keep logic separated: one unit test per logic branch or rule.
- Include positive and negative cases for each logic branch.
- Use YAML unit_tests format with given and expect sections.
- Use inline Dict row style for normal row values, for example: { col_a: 'x', col_b: true }.
- Do not use SQL fixture files or fixture blocks; keep tests inline in YAML.
- For ARRAY<STRUCT> fields, do not use nested Dict objects. Use string struct literals in arrays, for example:
  - struct_array_field: ['struct(st_geogpoint(75, 45) as my_point)', 'struct(st_geogpoint(75, 35) as my_point)']
- In expect.rows, keep the same set and order of fields across all rows within a test to avoid UNION ALL column-count mismatches.
- expected part should contain only the key fields to join the data and the tested field

## File Organization
- Store unit tests in a separate `unit_tests.yml` file in the same directory as the model.
- Keep `schema.yml` focused on model/column definitions and generic tests (unique, not_null, etc.).
- dbt automatically discovers and runs unit_tests from `unit_tests.yml` files.
- Name file pattern: `unit_tests.yml` (lowercase, plural) for consistency.

## Common Issues & Fixes
- **"Not able to get columns for unit test"** error: This occurs when dbt tries to introspect input models that don't exist in the database. Ensure all input models referenced with `ref()` in the `given` section are materialized in your target database before running unit tests. You cannot use explicit `schema` blocks in inputs as this violates the inline Dict style guideline.
- If introspection still fails for mocked inputs, use inline SQL fixtures inside YAML for that specific input:
  - `format: sql`
  - `rows: |` with `select ... union all ...`
  - Keep the fixture inline in `unit_tests.yml` (do not create separate SQL fixture files unless explicitly requested).
- Avoid non-deterministic test data when the model joins on partial keys (for example, joining only by email): do not provide multiple rows for the same join key unless the model logic explicitly handles it deterministically.
- {{ this }} tables must be represented in unit tests as input: this.

