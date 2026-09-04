# ADR 0002: Mart Design, Risk Scorecard

**Status:** Accepted, with one open item

## Context

The mart needs to answer the risk early warning question from ADR 0001 at a grain a stakeholder can actually read: one row per institution, not a raw time series.

## Decision

### Grain

mart_institution_risk_scorecard is one row per currently active CERT. It is a scorecard, not a time series.

### Model layers

**Staging:** stg_institutions, stg_financials, stg_failures. Drops the auto returned id field, handles ASSET and REPDTE nulls.

**int_institution_quarterly_signals:** one row per CERT per REPDTE, computing four raw signals as a time series before any thresholding. Fields: CERT, REPDTE, RBCRWAJ, rbcrwaj_trend_8q, NETINC, netinc_trend_8q, ASSET, asset_growth_8q, LNLSNET, DEP, loan_to_deposit_ratio, loan_concentration_trend_8q, quarters_of_history_available.

**int_failed_cohort_prefailure_signals:** an analysis step, not a permanent production model. Joins failures to financials, restricts to the trailing window before FAILDATE per institution, derives thresholds, and validates against a survivor sample. Feeds the seeds file below, not recalculated every run.

**mart_institution_risk_scorecard:** final grain. Fields: CERT, NAME, STALP, ASSET (most recent), REPDTE (most recent), capital_ratio_flag, earnings_flag, asset_growth_flag, loan_concentration_flag, flag_count (0 to 4), risk_tier (open, see below), data_confidence (Full or Limited, based on quarters_of_history_available).

### Trend window

8 trailing quarters (2 years) for trend calculations. Fallback minimum of 4 quarters for institutions without full history, flagged as Limited confidence rather than excluded.

### Threshold derivation

Percentile based, derived from the failed cohort's actual pre failure distribution (8 quarters before FAILDATE), not fixed numbers chosen by inspection. Validated against a survivor sample from the same historical windows to confirm the thresholds actually separate failed from healthy populations.

### Aggregation method

Flag count, not a weighted composite score. Four boolean signals summed to a 0 to 4 count, chosen for transparency and to echo the BCBS 239 framing, aggregating known discrete risk signals into something reviewable rather than a single opaque score.

### Seeds

Derived thresholds live in a dbt seed (thresholds.csv), not hardcoded into a model or recalculated on every run. Thresholds should be a documented, defensible number derived once, not something that silently drifts between runs.

### Snapshots

dbt snapshot applies to institutions only (snap_institutions), not financials or failures, since those are already historized time series in the source (REPDTE and FAILDATE respectively). Institutions is the correct use case because the API only returns current state, with no native history of when ACTIVE or STALP changed.

**Strategy:** check, not timestamp. The FDIC API provides no genuine audit timestamp to key off (REPDTE is a reporting date, not a last modified field), so a check strategy comparing ACTIVE and STALP between runs is the correct call.

**Columns tracked:** ACTIVE and STALP. ACTIVE lets an intermediate model classify currently inactive CERTs as failed (present in the failures table) versus merged or acquired (inactive, absent from failures), correcting the survivor cohort in threshold validation. Without this, a merged away institution could sit in the healthy survivor population and pollute the derived thresholds.

Snapshotting institutions correctly depends on RAW.institutions being loaded truncate and replace (current state only), not appended. Financials and failures remain append, since they are genuine incremental time series.

### Schema shape

Given the actual data volume (thousands of institutions, quarterly since 2004), a full star schema with separate fact and dimension tables is not justified. One wide mart table for the scorecard, with the intermediate signal calculation model underneath it, is the appropriate amount of structure.

## Open item: risk tier mapping

Two schemes under consideration, deferred until cohort validation produces real separation data between failed and survivor populations at each flag count.

- **Scheme A, straight 1 to 1:** 0 Low, 1 Watch, 2 Elevated, 3 and 4 both High, collapsed since four boolean signals do not support five distinct tiers cleanly
- **Scheme B, graduated:** 0 and 1 both Low, 2 Watch, 3 Elevated, 4 High, delays the jump to higher tiers by one flag relative to Scheme A

Decision rule: once survivor cohort validation runs, check whether institutions with 2 flags in the failed group's pre failure window look meaningfully different from 2 flag survivors. If they do, Scheme A is justified. If 2 flags shows up about as often in survivors as in eventual failures, Scheme B is the more honest choice.

The mart exposes flag_count as a raw column regardless of which scheme is chosen later, so risk_tier can be added without a mart rebuild once validation data exists.

## Consequences

- The mart depends on the Snowflake loader using truncate and replace for institutions, append for financials and failures, this constraint has to be built into the loader rather than decided after the fact
- risk_tier is not yet populated in the mart, flag_count stands in until the scheme decision is made
