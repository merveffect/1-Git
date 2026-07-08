with source as (

    select * from {{ source('joint_submissions_core', 'submissions') }}

),

renamed as (

    select
        submission_id,
        internal_submission_id,
        source_system,
        journal_id,
        cast(submission_date as date) as submission_date,
        submission_date as submission_ts,
        final_decision,
        corresponding_author_email,
        collection_id,
        -- collection flag as used by the Colab (mis_1_authors: is_in_collection)
        case when collection_id is null then 0 else 1 end as is_in_collection
    from source

)

select * from renamed
