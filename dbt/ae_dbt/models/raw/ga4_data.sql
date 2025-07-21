select event_date, country from {{source('b2b_e2e_report', 'b2b_ga4_final_view') }}

