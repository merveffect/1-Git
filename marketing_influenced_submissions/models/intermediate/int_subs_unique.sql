-- Phase 2 submissions: submission-level spine (Colab mis_1_subs_unique). Collapses
-- the author-level backbone to one row per internal_submission_id; flag_power_author
-- = 1 if any author on the submission is a power author.

select
    internal_submission_id,
    submission_date,
    source_system,
    is_in_collection,
    journal_id,
    imprint_code,
    business_model,
    main_group,
    portfolio,
    max(flag_power_author) as flag_power_author
from {{ ref('int_authors_enriched') }}
group by 1, 2, 3, 4, 5, 6, 7, 8, 9
