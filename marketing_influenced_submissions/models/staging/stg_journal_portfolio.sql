-- Journal portfolio reference (native table refreshed from the Drive-backed sheet).
-- journal_id is INTEGER in the native table but STRING in joint_submissions_core;
-- cast to string here so downstream joins on journal_id are type-consistent.

with source as (

    select * from {{ source('e2e_b2c_researcher_dev', 'journal_table') }}

),

renamed as (

    select
        cast(journal_id as string) as journal_id,
        journal_title,
        business_model,
        main_group,
        portfolio,
        main_discipline
    from source

)

select * from renamed
