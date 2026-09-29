{#-
    DATASET NAMING
    --------------
    dbt's default already produces <profile_dataset>_<custom_schema>,
    but stating the behaviour explicitly avoids surprises if the
    profile changes.

    profiles.yml -> dataset: orcid_role_agent
        models/raw/*          -> orcid_role_agent_raw
        models/staging/*      -> orcid_role_agent_staging
        models/dictionary/*   -> orcid_role_agent_dictionary
        models/scoring/*      -> orcid_role_agent_scoring
        models/presentation/* -> orcid_role_agent_presentation
        seeds/*               -> orcid_role_agent_seeds
-#}

{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- set default_schema = target.schema -%}
    {%- if custom_schema_name is none -%}
        {{ default_schema }}
    {%- else -%}
        {{ default_schema }}_{{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
