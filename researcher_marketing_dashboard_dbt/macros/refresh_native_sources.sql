{% macro refresh_native_sources() %}

{% set native_tables = [
    {
      "source": "snproject-cbb9ca25.ga4_ria_researcher_report.countries",
      "target": "snproject-cbb9ca25.ga4_ria_researcher_report.countries_native"
    },
    {
      "source": "snproject-cbb9ca25.ga4_ria_researcher_report.optins_sheet",
      "target": "snproject-cbb9ca25.ga4_ria_researcher_report.optins_sheet_native"
    },
    {
      "source": "snproject-cbb9ca25.ria_researcher_report.journalids",
      "target": "snproject-cbb9ca25.ria_researcher_report.journalids_native"
    },
    {
      "source": "snproject-cbb9ca25.ria_researcher_report.team_codes",
      "target": "snproject-cbb9ca25.ria_researcher_report.team_codes_native"
    },
    {
      "source": "snproject-cbb9ca25.ga4_ria_researcher_report.regions",
      "target": "snproject-cbb9ca25.ga4_ria_researcher_report.regions_native"
    },
    {
      "source": "snproject-cbb9ca25.ga4_ria_researcher_report.transformative_agreements_sheet",
      "target": "snproject-cbb9ca25.ga4_ria_researcher_report.transformative_agreements_sheet_native"
    },
    {
      "source": "dat-analytics-eng-ec869189.ae_metadata.channel_groupings",
      "target": "dat-analytics-eng-ec869189.ae_metadata.channel_groupings_native"
    },
    {
      "source": "snproject-cbb9ca25.e2e_b2c_researcher_dev.journal_table",
      "target": "snproject-cbb9ca25.e2e_b2c_researcher_dev.journal_table_native"
    }
] %}


{% for table in native_tables %}

{% set sql %}
CREATE OR REPLACE TABLE `{{ table.target }}` AS
SELECT *
FROM `{{ table.source }}`
{% endset %}


{{ log("Refreshing " ~ table.target, info=True) }}

{% do run_query(sql) %}

{% endfor %}

{% endmacro %}