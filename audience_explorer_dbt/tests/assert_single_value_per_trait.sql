-- This test checks trait consistency at user level.
-- For each (`canonical_segment_id`, `name`) pair, it verifies there is only one distinct non-empty `value`.
--
-- Any returned row is a failure and indicates conflicting values for the same trait name on the same user.
--
-- Failures are visible in dbt test output/logs. If you want persisted failure rows in BigQuery,
-- enable `store_failures = true` via a test-level config.

select canonical_segment_id, name
from {{ ref('raw_user_traits') }}
where value is not null and value != ''
group by 1,2
having count(distinct value) > 1