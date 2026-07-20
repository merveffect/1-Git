-- Phase 1B identity: authors joined to client_id (Colab mis_2_authors_clientid).
-- Left join the author backbone to the combined identity table on author_email; an
-- email that maps to several client_ids yields several rows, authors with no mapping
-- keep a null client_id.

select distinct
    a.*,
    t2.client_id
from {{ ref('int_authors') }} a
left join {{ ref('int_email_clientid') }} t2
    on a.author_email = t2.email
