-- Phase 5 enrichment: corresponding-author country per submission (Colab mis_1_country).
-- Joins the corresponding author on each submission to SDM author profiles for country.
--
-- SN-REVIEW: the exact Colab mis_1_country SQL was not available; this uses the
-- corresponding-author email -> sdm_author_profiles.author_country and takes one
-- country per submission. Confirm the intended author role and tie-break.

select
    a.internal_submission_id,
    any_value(p.author_country) as author_country
from {{ ref('int_authors') }} a
join {{ ref('stg_author_profiles') }} p
    on a.author_email = p.author_email
where a.is_corresponding_author
group by 1
