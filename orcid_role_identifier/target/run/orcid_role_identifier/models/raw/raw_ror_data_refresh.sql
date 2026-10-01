

  create or replace view `dat-analytics-eng-ec869189`.`dev_orcid_role_identifier_raw`.`raw_ror_data_refresh`
  OPTIONS(
      description="""ror_data_refresh as-is (separate project)."""
    )
  as 

/*
    RAW LAYER - ror_data_refresh  (SEPARATE PROJECT)
    The ROR organisation registry, not a local matching output.
*/

select * from `ri-data-engineering-dd4c0eca`.`ror`.`ror_data_refresh`;

