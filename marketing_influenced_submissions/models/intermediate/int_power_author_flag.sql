-- Phase 1B identity: power-author flag per email (Colab power_author_flag). Joins the
-- researcher email lookup to researcher profiles; flag = 1 if any profile for the
-- email is in the power-author group. SN-REVIEW (A9): label set is the power_author_labels var.

{% set labels = var('power_author_labels') %}

select
    lkp.email,
    max(
        case
            when loy.total_amt_5yr_author_group in (
                {%- for l in labels -%}
                '{{ l }}'{% if not loop.last %}, {% endif %}
                {%- endfor -%}
            ) then 1 else 0
        end
    ) as flag_power_author
from {{ ref('stg_researcher_email_lookup') }} lkp
join {{ ref('stg_researcher_profiles') }} loy
    on lkp.researcher_id = loy.researcher_id
group by 1
