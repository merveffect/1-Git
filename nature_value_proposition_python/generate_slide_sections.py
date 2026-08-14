from google.cloud import bigquery
import pandas as pd


PROJECT_ID = "snproject-cbb9ca25"

INPUT_TABLE = (
    "snproject-cbb9ca25.Nature_upsell_2.ai_value_prop_input"
)

OUTPUT_TABLE = (
    "snproject-cbb9ca25.dev_nvp_dbt_presentation.ai_slide_sections"
)


def read_data():
    """Read prepared input data from BigQuery."""

    client = bigquery.Client(project=PROJECT_ID)

    query = f"""
        SELECT *
        FROM `{INPUT_TABLE}`
    """

    df = client.query(query).to_dataframe()

    print(f"Read {len(df)} rows from {INPUT_TABLE}")

    return df


def Usage(r):
    bp_full_name = r.get("BP_Full_Name", "the institution")

    return (
        f"Consistently high and sustained usage of the Nature Journals "
        f"currently licensed by {bp_full_name} indicates that they are "
        f"actively supporting scientific research and remain important "
        f"resources for students and researchers at {bp_full_name}."
    )


def access_denials(r):
    bp_full_name = r.get("BP_Full_Name", "the institution")

    return (
        f"The chart highlights the Nature journals most frequently "
        f"requested but unavailable to researchers at {bp_full_name}, "
        f"indicating demand beyond the current subscription."
    )


def for2(r):
    bp_full_name = r.get("BP_Full_Name", "The institution")

    return (
        f"Over the past five years, researchers from {bp_full_name} "
        f"have published a total of {r.Total_pubs:,} articles "
        f"across multiple Fields of Research (FoR2). Fields of Research "
        f"Level 2 provide a more detailed view of research strengths "
        f"than broader subject classifications, making them a valuable "
        f"indicator of institutional expertise. The subject areas "
        f"covered by the recommended Nature journals closely align "
        f"with the institution's most active research fields, suggesting "
        f"that access to these journals would support both current and "
        f"future research activities."
    )


def SDG(r):
    bp_full_name = r.get("BP_Full_Name", "The institution")

    return (
        f"Over the past five years, researchers from {bp_full_name} "
        f"have published {r.total_sdg_publications:,} articles linked to Sustainable "
        f"Development Goal (SDG) areas. This section maps the recommended "
        f"Nature journals against the SDGs represented in the institution's "
        f"research publication output. The analysis highlights a strong "
        f"alignment between Nature journal content and the SDG areas most "
        f"frequently addressed by the institution's researchers."
    )


def citation(r):
    return (
        f"Researchers cited Nature Portfolio journals "
        f"{r.citation_count:,} times between 2022 and 2026, "
        f"demonstrating continued reliance on Nature content to support "
        f"their research. Significant citations to the recommended "
        f"journals further reinforce their relevance to the institution's "
        f"research community."
    )


def funding(r):
    return (
        "Active grant funding demonstrates strong institutional research "
        "activity across the key funded areas represented in the chart. "
        "The recommended Nature journals closely align with these research "
        "priorities, supporting ongoing research activity and future "
        "publishing needs across the institution."
    )


def create_sections(df):
    """Generate the text sections for each institution."""

    rows = []

    for _, r in df.iterrows():

        bp = r["bp_id"]
        name = r["BP_Full_Name"]

        # Handle missing values safely
        r["total_usage"] = (
            0 if pd.isna(r["total_usage"]) else r["total_usage"]
        )

        r["citation_count"] = (
            0 if pd.isna(r["citation_count"]) else r["citation_count"]
        )

        r["total_funding"] = (
            0 if pd.isna(r["total_funding"]) else r["total_funding"]
        )

        r["top_denied_journals"] = (
            "" if pd.isna(r["top_denied_journals"])
            else r["top_denied_journals"]
        )

        r["Total_pubs"] = (
            0 if pd.isna(r["Total_pubs"])
            else r["Total_pubs"]
        )

        r["total_sdg_publications"] = (
            0 if pd.isna(r["total_sdg_publications"])
            else r["total_sdg_publications"]
        )

        rows.append([
            bp,
            name,
            "Usage",
            Usage(r)
        ])

        rows.append([
            bp,
            name,
            "Access Denials",
            access_denials(r)
        ])

        rows.append([
            bp,
            name,
            "FOR2",
            for2(r)
        ])

        rows.append([
            bp,
            name,
            "SDG",
            SDG(r)
        ])

        rows.append([
            bp,
            name,
            "Citation Evidence",
            citation(r)
        ])

        rows.append([
            bp,
            name,
            "Funding Strength",
            funding(r)
        ])

    out_df = pd.DataFrame(
        rows,
        columns=[
            "bp_id",
            "BP_Full_Name",
            "section",
            "text"
        ]
    )

    print(f"Generated {len(out_df)} section rows")

    return out_df


def write_output(df):
    """Write generated sections to BigQuery."""

    client = bigquery.Client(project=PROJECT_ID)

    job_config = bigquery.LoadJobConfig(
        write_disposition="WRITE_TRUNCATE"
    )

    job = client.load_table_from_dataframe(
        df,
        OUTPUT_TABLE,
        job_config=job_config
    )

    job.result()

    print(
        f"Successfully wrote {len(df)} rows "
        f"to {OUTPUT_TABLE}"
    )


def main():
    """Main execution flow."""

    print("Starting Nature Value Proposition Python process...")

    df = read_data()

    output = create_sections(df)

    write_output(output)

    print("Nature Value Proposition process completed successfully.")


if __name__ == "__main__":
    main()