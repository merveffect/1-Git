select
  iso_3166_country_name,
  official_state_name,
  alpha_2_code,
  springer_nature_data_standard_location_name,
  valid_to
  from {{ source('datasn_plattform', 'full_location_standard') }}
  where valid_to is null