select distinct
  alpha_2_code as iso_code,
  springer_nature_data_standard_location_name as country_name
  
  from {{ ref('raw_location_standard') }}
  where valid_to is null
    and springer_nature_data_standard_location_name != 'Bonaire, Sint Eustatius and Saba'