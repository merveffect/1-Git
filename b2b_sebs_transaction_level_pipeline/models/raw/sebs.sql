 select
    date as transaction_date,
    transaction_id,
    item_id,
    month,
    month_number,
    year,
    bpid,
    organization_name
from {{ source('b2b_e2e_report', 'b2b_sebs_final_static') }}