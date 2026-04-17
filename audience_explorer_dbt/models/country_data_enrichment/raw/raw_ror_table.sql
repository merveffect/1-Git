Select * from {{ source('ror_mapping_raw_tables', 'ror_raw_final') }}
