

  create or replace view `snproject-cbb9ca25`.`dbt_analytics_engineering`.`ga4_data`
  OPTIONS()
  as select event_date, country from `snproject-cbb9ca25`.`b2b_e2e_report`.`b2b_ga4_final_view`;

