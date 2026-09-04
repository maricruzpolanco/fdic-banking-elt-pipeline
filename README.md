# FDIC Bank Financial Data Pipeline

An end to end data pipeline that ingests public FDIC bank financial data, transforms it with dbt, and orchestrates the full flow with Airflow, anchored around a bank risk early warning use case: which currently active institutions show financial trajectories similar to those that preceded past failures.

See `docs/architecture.md` for the full stack and design reasoning, and `docs/adr/` for the key decisions behind the business framing and data model.

## Status

Active development.

- Ingestion (FDIC API to S3): complete, being migrated into the current project structure
- Data warehouse setup (Snowflake production, DuckDB local dev): in progress
- dbt transformation layer: not started
- Orchestration (Airflow): not started
- Dashboard (Streamlit): not started

## Architecture

See `docs/architecture.md`, `docs/adr/0001-business-case.md`, and `docs/adr/0002-mart-design.md`.

## API reference

See `docs/api-reference.md` for the FDIC BankFind Suite API details this pipeline depends on.

## Setup

TODO, add once the dev container and tooling scaffolding are finalized.

## License

TODO
