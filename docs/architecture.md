# FDIC Bank Financial Data Pipeline: Architecture

## Overview

An end to end data pipeline that ingests public FDIC bank financial data, lands it in S3, loads it into a cloud data warehouse, transforms it into analysis ready models with dbt, and orchestrates the full flow with Airflow. The pipeline is built around a bank risk early warning use case: which currently active institutions show financial trajectories similar to those that preceded past failures. See docs/adr/0001-business-case.md for the reasoning behind that framing.

## Stack

| Layer | Tool |
|---|---|
| Language | Python 3.12 |
| AWS SDK | boto3 |
| Cloud storage | AWS S3 |
| Local dev and test warehouse | DuckDB |
| Production warehouse | Snowflake |
| Transformation | dbt Core |
| Orchestration | Apache Airflow, self hosted, Docker Compose, LocalExecutor |
| Containerization | Docker / Docker Compose |
| Linting and formatting | Ruff |
| Type checking | mypy, strict mode |
| Commit hooks | pre-commit |
| Task runner | Makefile |
| Visualization | Streamlit |
| Dependency management | uv |

## Dev and production split

Snowflake bills for active compute time, not just storage, so iterating directly against it during model development would cost money on every run. All dbt model development and testing happens locally against DuckDB, reading directly from the S3 raw layer, which keeps development cost at zero regardless of how many times models are rebuilt.

Snowflake is reserved for production runs only, validated and dev tested models only, sized X-Small with a short auto suspend window to minimize billed compute time.

## Transformation: dbt Core only

dbt Core handles both local development against DuckDB and the production run against Snowflake. dbt Cloud was evaluated and dropped: its free Developer tier supports only one project per account, and this project shares a portfolio with other projects that also need scheduling. Paying for the Starter tier to unlock a second project was not justified at this scale.

## Orchestration: Apache Airflow

All three pipeline stages, ingestion (FDIC API to S3), dbt transform (against Snowflake), and export (Snowflake mart to Parquet in S3), run as a single Airflow DAG with explicit task dependencies and retry logic. This replaced an earlier setup of three independently scheduled jobs (two on GitHub Actions, one on dbt Cloud) with staggered timing and no real dependency enforcement between them, an approach that worked only because the timing buffer happened to be long enough, not because it verified the prior job had actually finished.

**Executor:** LocalExecutor. This is a single sequential DAG with three tasks and no distributed worker requirement, so CeleryExecutor and its Redis dependency would add overhead with no benefit.

**Hosting:** local Docker Compose, run on demand rather than a continuously running deployment. A managed option like AWS MWAA runs roughly $350 a month at the smallest environment size, local Docker Compose avoids that recurring cost entirely. Because of this, the pipeline is not an unattended production schedule, it runs when the Docker Compose stack is started.

**Task execution:** BashOperator. Each DAG task invokes its underlying script or CLI directly (run_ingestion.py, the dbt Core CLI, the export script), no code changes required. PythonOperator was rejected since dbt is a CLI tool first, and importing the project's package directly into Airflow's worker process would force the project's dependency versions to coexist with Airflow's own. DockerOperator was rejected on scope: it offers stronger isolation but is disproportionate setup for a three task sequential DAG.

## Visualization: Streamlit

Streamlit reads from a periodically refreshed Parquet export in S3, not a live Snowflake query. A public facing app querying Snowflake per page view would trigger warehouse compute on every visitor, an unpredictable cost. The static export keeps visitor traffic free of any warehouse cost beyond Streamlit Community Cloud hosting.

## Repo structure

```
fdic-banking-elt-pipeline/
├── src/fdic_pipeline/
│   ├── config.py
│   ├── ingestion/
│   ├── export/
│   └── utils/
│       └── logging.py
├── tests/
├── dbt_project/
├── snowflake/
├── airflow/
│   └── dags/
├── docker-compose.yaml
├── streamlit_app/
├── docs/
│   ├── architecture.md
│   ├── api-reference.md
│   ├── pipeline.md
│   └── adr/
├── TROUBLESHOOTING.md
├── .devcontainer/
├── pyproject.toml
├── uv.lock
├── Makefile
├── .pre-commit-config.yaml
├── CLAUDE.md
└── README.md
```

## Known limitations

No hands on experience with a managed Airflow deployment such as MWAA, Cloud Composer, or Astronomer. Accepted tradeoff given the cost priority on this project.
