# FDIC Pipeline: Ingestion and Storage

## Ingestion scripts

Three scripts, located in src/fdic_pipeline/ingestion/.

### fdic_client.py

Fetches data from the three FDIC BankFind Suite API endpoints.

- Endpoint config stored as a dictionary, each endpoint has its own params dict. Adding a fourth endpoint is a new dict entry, no loop changes needed.
- Paginates using the total count from API metadata, not an empty records check
- Unwraps the nested {'data': {...}, 'score': 1} response structure per record
- Returns an all_data dict keyed by endpoint name: {"institutions": [...], "financials": [...], "failures": [...]}, a flat list of record dicts per endpoint. This structure passes cleanly between fdic_client.py and s3_uploader.py.

### s3_uploader.py

Accepts the all_data dict from fdic_client.py and uploads each endpoint's records to S3.

- Converts records to JSON, uploads via s3.put_object() (boto3)
- Date partitioned S3 key structure (Eastern time):
  - s3://fdic-bank-pipeline-raw/institutions/YYYY/MM/DD/institutions_raw.json
  - s3://fdic-bank-pipeline-raw/financials/YYYY/MM/DD/financials_raw.json
  - s3://fdic-bank-pipeline-raw/failures/YYYY/MM/DD/failures_raw.json
- This partitioning scheme is Athena and Glue friendly, each partition is a folder that can be scanned selectively
- Credentials loaded from .env via python-dotenv

### run_ingestion.py

Entry point. Calls fdic_client then s3_uploader in sequence, invoked as the first task in the Airflow DAG, see docs/architecture.md.

- Logging configured once here in main(), writes to both console and app.log
- try/except/re-raise at the top level ensures a non-zero exit code on failure

## S3

Bucket: fdic-bank-pipeline-raw, us-east-2. IAM user fdic-pipeline-user has a scoped inline policy (least privilege): ListBucket, GetObject, PutObject, DeleteObject on this bucket only.

## Snowflake

Account: Standard edition. Database: FDIC_PIPELINE. Schemas: RAW (landing zone) and TRANSFORMED (dbt output).
