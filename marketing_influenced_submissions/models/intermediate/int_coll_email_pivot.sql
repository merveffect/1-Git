-- Phase 6 collections: pivot collection-email flags to one column per email type
-- (Colab mis_2_coll_email_2 + mis_2_coll_email_3 total). The Colab builds the pivot
-- dynamically with EXECUTE IMMEDIATE; here the column set is the fixed
-- collection_email_types var (dashboard hardcodes these 5).
--
-- SN-REVIEW (D3): confirm the fixed email-type list. total_collection_email is the
-- count of matched email types per submission (Colab mis_2_coll_email_1a).

{{ config(materialized='table', tags=['ga']) }}

select
    internal_submission_id,
    {% for t in var('collection_email_types') %}
    max(if(collection_email_type = '{{ t }}', flag_collection_email, null)) as {{ t }},
    {% endfor %}
    sum(flag_collection_email) as total_collection_email
from {{ ref('int_coll_email_1') }}
group by 1
