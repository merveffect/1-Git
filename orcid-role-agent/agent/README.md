# Agent layer (phase 2 - not real yet)

`demo_agent.py` is a learning artefact. It uses fake data and never
touches BigQuery. It exists to show one thing: **an agent is not a
product, it is a loop.**

## Access: the agent is NOT blocked by the missing BigQuery connection

These are two different paths to the same API:

```
BigQuery  --[CLOUD_RESOURCE connection]-->  Vertex AI     <- missing in this project
Python    --[application-default creds]-->  Vertex AI     <- what the agent uses
```

The in-SQL LLM judge needs the first one, which this project does not
have (see `dbt/setup/03_test_access.sql`). The agent needs only the
second: `roles/aiplatform.user` on whoever runs the process. So the
agent may work today even while the SQL judge does not.

Verify with `dbt/setup/03_test_access.sql` TEST 4.

## Run

```bash
pip install -r requirements.txt
gcloud auth application-default login
export GCP_PROJECT=researcher-360-prod-e7fd74be
export GCP_LOCATION=europe-west1

python demo_agent.py "which roles exist?"
python demo_agent.py "how many HCPs in Germany, and how many can we reach?"
python demo_agent.py "which role has the largest audience?"
```

On the second and third question, look at **[the model's own decisions]**
at the end of the output. That shows which tools the model called and in
what order - and we never wrote that order. That is the agent part.

> Not tested here: this sandbox has no GCP credentials. Python syntax is
> verified. A small fix may be needed on first run for SDK version drift.

## What the real agent will have

| tool | what it does |
|---|---|
| `list_roles()` | roles from the registry |
| `search_titles(query)` | VECTOR_SEARCH over the title dictionary |
| `preview_role(role_key)` | which titles a role currently covers |
| `count_audience(role, filters)` | identified / in_cdp / marketable |
| `export_audience(role, filters)` | the SNID list |
| `propose_new_role(description)` | gather anchors, draft the YAML block |
| `explain_person(snid)` | why this person carries this role |

All of them **read** the mart tables. The agent never touches the
200k+ source rows and has no write access.

## Where it runs

| stage | where | why |
|---|---|---|
| development | your laptop | fastest loop, no deploy |
| internal use | Cloud Run + Streamlit | one container, IAM-gated |
| managed | Vertex AI Agent Engine | if you want Google to host it |

Start on the laptop. Do not deploy anything until the dbt pipeline
reproduces the existing HCP labels.
