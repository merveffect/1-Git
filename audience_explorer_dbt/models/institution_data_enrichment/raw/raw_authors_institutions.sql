-- One clean row per author email: their most recent submitted institution 

with authors as (

    select
        author_email,
        submission_id,
        trim(institute) as raw_inst_name, 
        author_country as country_name, 
        author_country_iso_code as country_iso,
    from {{ source('prod_joint_submissions_core', 'authors') }} 
    where institute is not null and trim(institute) != '' 
    and author_email is not null and trim(author_email) != ''

),

submissions as (

    select
        submission_id,
        submission_date 
    from {{ source('prod_joint_submissions_core', 'submissions') }}
),

joined as (

    select 
        a.author_email,
        a.submission_id,
        a.raw_inst_name,
        a.country_name,
        a.country_iso,
        s.submission_date,
    from authors a
    join submissions s
    on a.submission_id = s.submission_id
),

ranked as (

    select 
        author_email,
        raw_inst_name,
        country_name,
        country_iso,
        submission_date,
        row_number() over (partition by author_email order by submission_date desc) as rn
    from joined

)

select
    author_email,
    raw_inst_name,
    country_name,
    country_iso
from ranked
where rn = 1
    and raw_inst_name is not null
    and raw_inst_name not like '%&#%'
    and raw_inst_name not like '%&amp;%'
    and raw_inst_name not like '%&lt;%'
    and raw_inst_name not like '%&gt;%'
