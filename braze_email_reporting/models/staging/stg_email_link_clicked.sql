Select canvas_name,
canvas_step_name,
canvas_variation_name,
SAFE_CAST(SUBSTR(date, 1, 10) AS DATE) AS date,
count(id) as email_click
from {{ ref('raw_email_link_clicked') }}
group by 1,2,3,4

