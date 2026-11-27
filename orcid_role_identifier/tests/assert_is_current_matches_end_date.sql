/*
    is_current MUST MEAN "THIS POST HAS NOT ENDED".

    Added 2026-11-27, with the correction it guards. The column read
    `end_date is null` alone, which treated an EXPECTED end date as a
    departure and dropped 4,646 students, 679 faculty heads and 4
    librarians out of the three current_only audiences. Nothing failed,
    because nothing was checking what is_current meant.

    This locks the definition in both directions, so neither half can
    drift back on its own:

      - a post with no end date, or one dated today or later, IS current
      - a post that ended before today is NOT current

    The test FAILS if any row is returned.
*/

select
    snid,
    role_title,
    end_date,
    is_current,
    case
        when end_date is null       then 'undated, so current - is_current said otherwise'
        when end_date >= current_date() then 'ends today or later, so current - is_current said otherwise'
        else 'ended before today, so not current - is_current said otherwise'
    end     as what_is_wrong
from {{ ref('stg_role_records') }}
where is_current != (end_date is null or end_date >= current_date())
