-- Phase 1B identity: authors + client_id + power-author flag (Colab mis_2_authors_2).
-- Adds flag_power_author (default 0 when the author has no researcher profile).

select
    sub.*,
    case when pa.flag_power_author is null then 0 else pa.flag_power_author end as flag_power_author
from {{ ref('int_authors_clientid') }} sub
left join {{ ref('int_power_author_flag') }} pa
    on sub.author_email = pa.email
