    select
        id,
        names,
        domains,
        locations
    from {{ source('prod_institution_disambiguation_raw', 'raw_ror_data') }}
