# FDIC BankFind Suite API Reference

**Base URL:** https://api.fdic.gov/banks/

**Auth:** None required

**Docs:** https://banks.data.fdic.gov/docs/

## Endpoints

| Endpoint | Fields | Filter |
|---|---|---|
| /institutions | NAME, CERT, STALP, ASSET, REPDTE, ACTIVE | None |
| /financials | REPDTE, CERT, ASSET, DEP, LNLSNET, NETINC, RBCRWAJ | REPDTE:[2004-01-01 TO present] |
| /failures | NAME, CERT, FAILDATE, SAVR, RESTYPE, COST | None |

Neither the financials nor the failures endpoint is date limited by the API itself, both filters above are project decisions, not API constraints. The failures endpoint covers records from 1934 to the present regardless of any filter applied here.

## Response structure

The API returns a nested structure, each record wrapped in its own object:

```
{
  "data": [
    {"data": { ...record fields... }, "score": 1},
    {"data": { ...record fields... }, "score": 1}
  ],
  "meta": {
    "total": 27832
  }
}
```

Unwrap with: `[record['data'] for record in data.get('data', [])]`

## Pagination

- Uses limit and offset params
- Total record count comes from data["meta"]["total"]
- Pagination exits when len(all_records) >= total_record_count, not an empty records check, avoiding unnecessary extra API calls after the last page
- Offset resets to 0 at the start of each endpoint loop

## Field handling notes

- The API automatically returns an id field even when not explicitly requested. Left in the raw layer, dropped in dbt staging.
- Some institution records have genuine nulls for ASSET and REPDTE. These are missing in the source data, not a pipeline bug, left as is in raw and handled in dbt staging (coalesce, filter, or flag depending on model use).
- Endpoint fields are stored as comma separated strings (for example "NAME,CERT,STALP,ASSET,REPDTE,ACTIVE"), matching the API's expected query param format directly, not stored as lists.
