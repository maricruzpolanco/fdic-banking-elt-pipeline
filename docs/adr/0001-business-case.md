# ADR 0001: Business Framing, Risk Early Warning

**Status:** Accepted

## Context

This project originally targeted Data Engineering roles, where the priority was demonstrating pipeline build ability alone. Positioning shifted toward Analytics Engineering roles, which expect a clear business impact angle, answering "so what, how does this help the business" from a stakeholder's point of view rather than infrastructure alone.

## Decision

Frame the pipeline around a risk early warning use case for bank risk and credit risk teams and examiners.

Core question: which currently active institutions show financial trajectories similar to those that preceded past bank failures.

Mechanism: track known risk signals per institution over time, capital ratio trend (RBCRWAJ), earnings trend (NETINC), asset growth or stagnation, and loan concentration relative to deposits, compare those trajectories against institutions that actually failed, and flag active institutions whose indicators cross defined thresholds.

### Capital ratio signal: RBCRWAJ and Prompt Corrective Action

RBCRWAJ is titled TOTAL RBC RATIO-PCA in FDIC's own Financial APIs field definitions, calculated as risk based capital (RBC) divided by total risk weighted assets (RWAJT), expressed as a percentage. PCA refers to Prompt Corrective Action, the FDICIA framework regulators use to sort banks into capital categories: well capitalized, adequately capitalized, undercapitalized, and further down from there. This is the actual ratio regulators use to determine a bank's PCA capital category, not an analyst proxy for capital adequacy.

### Alternatives considered

Three other angles were evaluated: capital adequacy and regulatory compliance tracking, peer benchmarking, and M&A or investment screening.

Risk early warning was chosen as the strongest personal fit, grounded in a background in regulatory reporting, data quality, and governance in banking rather than a generically chosen use case. Capital adequacy tracking is folded in as a supporting indicator inside the same mart rather than treated as a separate story, keeping the pitch to one sharp question rather than several shallow ones. Peer benchmarking and M&A screening were rejected as weaker personal fits, framings any candidate could pick regardless of background.

## BCBS 239 framing

BCBS 239, formally "Principles for Effective Risk Data Aggregation and Risk Reporting," was issued by the Basel Committee in January 2013 because banks could not aggregate risk data quickly or completely enough to see their own exposures building up before the 2007-2008 financial crisis. This project is a small scale demonstration of that same underlying capability, aggregating financial data over time and across institutions to surface deteriorating risk before failure rather than after.

**Caveat:** BCBS 239 formally applies only to Global and Domestic Systemically Important Banks (G-SIBs and D-SIBs). Most FDIC failures in this dataset, including the bulk of the 2008-2012 wave, are small or mid size community and regional banks, not institutions BCBS 239 technically governs. The accurate framing is that this project applies the same risk data aggregation principle BCBS 239 was built around to a broader population of FDIC insured institutions using public data. It does not claim these specific banks were BCBS 239 obligated entities.

## Date range: financials expanded to 2004 through present

Previously filtered to 2020-2024. Expanded to capture:

- Pre crisis buildup years (2004-2007), needed to see deteriorating trends before institutions failed, not just at the point of failure
- The 2008-2012 failure wave, 465 banks closed in this period, a real sample size to derive indicator thresholds from
- The recovery and stability period afterward, serving as a contrast group of institutions that survived with similar characteristics
- The current window, which is what the model is actually applied against to flag active institutions today

The 2023 failures, including Silicon Valley Bank and Signature Bank, add a recent, name recognizable supplementary case study, but too small a sample on their own to derive indicator thresholds from.

## Consequences

- The financials pull is substantially larger than the original 2020-2024 window, which is the direct driver behind the dev and production cost split, see docs/architecture.md
- Threshold derivation for the mart depends on this wider historical window, see docs/adr/0002-mart-design.md
