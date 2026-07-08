with source as (

    select * from {{ source('joint_submissions_core', 'journals') }}

),

renamed as (

    select
        journal_id,
        journal_abbreviation,
        journal_title,
        journal_status,
        publishing_model,
        imprint_code,
        imprint_term,
        commercial_group
    from source

)

select * from renamed
