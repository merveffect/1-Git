-- ONE-TIME MIGRATION — run by hand in the BigQuery console, once per
-- environment, BEFORE the next `dbt run --select favorite_snt_predictions`.
--
-- Why this exists: favorite_snt_predictions renamed snt_id -> inferred_snt_id
-- and snt_name -> inferred_snt_name so the column names match the CDI-facing
-- inferred_snts contract end to end. The model is incremental with
-- on_schema_change='append_new_columns', which would ADD the two new columns
-- and leave the old ones in place — and since the merge key is now
-- (snid, inferred_snt_id), every existing row (NULL in that column) would
-- fail to match and get duplicated instead of updated.
--
-- Renaming in place avoids a --full-refresh, which would mean recomputing
-- VECTOR_SEARCH for all ~6.04M users and leaving inferred_snts incomplete
-- for the hours that takes. This is a metadata-only operation: free, instant,
-- and it keeps every existing prediction row.
--
-- Statement 3 backfills computed_at, which the rolling refresh added. NULL
-- would break the not_null test on that column, and NULL sorts first under
-- `nulls first`, so the epoch value gives the same effect (these users are
-- the stalest and get refreshed first) while staying a real timestamp.

-- 1. Rename the two columns.
ALTER TABLE `dat-analytics-eng-ec869189.prod_subject_based_segmentation.favorite_snt_predictions`
  RENAME COLUMN snt_id TO inferred_snt_id;

ALTER TABLE `dat-analytics-eng-ec869189.prod_subject_based_segmentation.favorite_snt_predictions`
  RENAME COLUMN snt_name TO inferred_snt_name;

-- 2. Add computed_at if the rolling-refresh version has not run yet.
--    Skip this if the column already exists (the statement will error).
ALTER TABLE `dat-analytics-eng-ec869189.prod_subject_based_segmentation.favorite_snt_predictions`
  ADD COLUMN IF NOT EXISTS computed_at TIMESTAMP;

-- 3. Backfill computed_at so the not_null test passes and these users sort
--    to the front of the refresh queue.
UPDATE `dat-analytics-eng-ec869189.prod_subject_based_segmentation.favorite_snt_predictions`
SET computed_at = TIMESTAMP('1970-01-01')
WHERE computed_at IS NULL;

-- 4. Verify: expect inferred_snt_id / inferred_snt_name / computed_at
--    present, snt_id / snt_name gone, and zero NULL computed_at.
SELECT column_name, data_type
FROM `dat-analytics-eng-ec869189.prod_subject_based_segmentation.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'favorite_snt_predictions'
ORDER BY ordinal_position;
