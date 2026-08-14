    select
        id,
        names,
        domains,
        locations
    from {{ source('ror', 'ror_data_refresh') }}
