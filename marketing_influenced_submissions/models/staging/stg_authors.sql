with source as (

    select * from {{ source('joint_submissions_core', 'authors') }}

),

renamed as (

    select
        submission_id,
        source_system,
        journal_id,
        author_email,
        snid,
        author_id,
        -- flatten author_roles struct into explicit boolean flags
        author_roles.submitter          as is_submitter,
        author_roles.coauthor           as is_coauthor,
        author_roles.correspondingauthor as is_corresponding_author
    from source

)

select * from renamed
