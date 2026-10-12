-- A singular test fails if it returns any rows.
-- Every user must have exactly 10 predictions. This is checked here as well
-- as on inferred_snts because the rolling refresh introduced a new way to
-- break it: merge on (snid, inferred_snt_id) never deletes, so an SNT
-- dropping out of a refreshed user's top-10 leaves an orphan row unless the
-- model's post_hook clears it. If this test fails but inferred_snts passes,
-- suspect the hook.

SELECT snid, COUNT(*) AS snt_count
FROM {{ ref('favorite_snt_predictions') }}
GROUP BY snid
HAVING COUNT(*) != 10
