# AIFRE - Adversarial Identity & Fraud Risk Engine

> A Snowflake & dbt-powered Medallion Architecture for Synthetic Fraud Detection and Behavioural Forensic Auditing in Ontario's Insurance Ecosystem.

---

## Project Motivation

Ontario's Statutory Accident Benefits Schedule (SABS) is one of the most fraud-vulnerable insurance frameworks in Canada. Informed by front-line exposure to claims and accident benefits processing, this project was built to answer a specific question: **can a modern analytics engineering stack detect coordinated fraud patterns that manual adjudication consistently misses?**

AIFRE simulates the data environment of a mid-sized Ontario insurer (raw, adversarial, and deliberately difficult) and constructs a forensic pipeline capable of surfacing $69.3M in isolated exposure-at-risk across six distinct fraud typologies.

---

## Project Stats at a Glance

| Metric | Value |
|---|---|
| Data Volume | 300,000+ Records across 3 source domains (CSV/JSON) |
| Core Stack | Snowflake, dbt-core, Python, Tableau |
| Fraud Typologies Encoded | 6 (see [DATA_GENERATION.md](./DATA_GENERATION.md)) |
| Financial Exposure Isolated | $69.3M |
| Regulatory Scope | FSRA, SABS, IBC Fraud Bureau Standards |

---

## Architecture: Forensic Medallion Framework

The engine uses a three-tier Medallion Architecture within Snowflake. Each layer has a distinct forensic purpose: data is never overwritten at source, and every transformation is auditable.

```
RAW SOURCES (CSV / JSON)
        │
        ▼
┌───────────────────┐
│  🥉 BRONZE        │  Immutable Evidence Locker
│  Raw Ingestion    │  Exact source fidelity, no cleansing
└────────┬──────────┘
         │
         ▼
┌───────────────────┐
│  🥈 SILVER        │  Investigation & Fusion Layer
│  Transformation   │  SCD Type 2 · REGEX Cleansing · Domain Joins
└────────┬──────────┘
         │
         ▼
┌───────────────────┐
│  🥇 GOLD          │  Decision Support Layer
│  Analytical Marts │  Risk Scoring · SIU Flags · Executive KPIs
└───────────────────┘
```

### Bronze - The Evidence Locker

Raw identity records, financial claims, network logs, and device telemetry are ingested with zero transformation. The deliberate preservation of dirty data (address variants, nulls, malformed JSON) is intentional: forensic re-processing requires original evidence. Materialized as **tables** for immutability.

### Silver - Investigation & Fusion

This is where the analytical work happens across three sub-layers:

**1. Historical Engine (SCD Type 2)**
Identity records for claimants, clinics, and providers are tracked using dbt snapshots with `valid_from` / `valid_to` timestamps. This is a deliberate architectural choice over SCD Type 1: overwriting identity records would destroy the forensic signal of "nurtured" accounts (entities that cycle through addresses, phone numbers, or associated providers over time to evade detection). SCD Type 2 preserves the full evolution chain.

Reference/lookup data (postal code mappings, sector code descriptions) uses **SCD Type 1**, as these are corrections with no forensic value in their history.

**2. Address Munging Resolution**
Custom REGEX logic collapses identity fragmentation clusters in the GTA corridor. A single fraudulent claimant may appear as "123 Main St", "123 Main Street", "123 mane st Apt 2B", and "123 MAIN STREET UNIT 2" across different claim submissions. Silver standardizes these into canonical identity clusters before joins.

**3. Domain Fusion**
Fragmented digital fingerprints (IP logs, device IDs) are joined to financial claim records to close the "Visibility Gap" (the space between what a claimant submits and what their network behaviour reveals). The three source domains were generated with deliberate cross-dataset linkages, with fraud signals embedded in identity, ledger, and network logs simultaneously, meaning domain fusion is the only path to a confirmed fraud signal. No single source is sufficient in isolation.

Materialized as **views** to remain flexible as upstream data evolves.

### Gold - Decision Support

High-velocity analytical marts optimized for BI consumption and regulatory reporting. Key models:

- `fct_claimant_risk`: Entity-level composite risk scoring across all fraud typologies
- `fct_daily_velocity`: Submission velocity analysis for automated and bot-driven claim detection
- `fct_fraud_exposure`: Claimant exposure concentration and whale pattern analysis
- `dim_provider_status`: Provider and clinic risk profiling by sector
- `mart_siu_referral_flags`: SIU referral actions and investigator-facing reason strings, consuming pre-computed risk scores from int_user_risk_scoring

Materialized as **tables** for query performance against Tableau.

---

## Schema Design: STAR Schema

After forensic cleansing in Silver, Gold marts are structured as a STAR schema, with a central fact table surrounded by dimension tables. This was chosen over 3NF for two reasons: (1) fraud detection is a read-heavy, aggregation-heavy workload that benefits from denormalized joins, and (2) it maps cleanly to the BI layer without requiring analysts to understand complex relational joins.

```
                    dim_claimant (SCD2)
                          │
dim_clinic ───── fct_claims ───── dim_device
                          │
                    dim_date
                          │
                    dim_location
```

---

## Key Design Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Identity tracking | SCD Type 2 | Preserves address/entity evolution for nurtured account detection |
| Reference data | SCD Type 1 | No forensic value in historical correction |
| Schema design | STAR | Optimized for aggregation; readable by BI consumers |
| Gold materialization | Tables | Stable, performant targets for Tableau and regulatory exports |
| Silver materialization | Views | Flexible; upstream schema changes propagate without rebuilds |
| Data generation | Python (adversarial) | Privacy constraints under PIPEDA/PHIPA require synthetic data; generated with deliberate quality defects to simulate real-world ingestion |

---

## Fraud Typologies Detected

| Typology | Description | Detection Method |
|---|---|---|
| **Synthetic Identity** | Fabricated claimants assembled from real identity fragments, linked via SIN pattern across source domains | SCD Type 2 evolution tracking; cross-domain SIN pool join |
| **Bot / Automated Submission** | Automated claim submissions via proxy IP pool, non-human browser agents, and near-zero dwell time | IP velocity analysis; browser fingerprint scoring; dwell time thresholds |
| **Geographic Collision Rings** | Multiple unrelated identities sharing a single GTA building address to evade exact-match deduplication | REGEX canonicalization; postal code cluster analysis |
| **Whale Concentration** | Disproportionate exposure concentrated in a small claimant population via power law funnelling | Concentration ratio analysis; exposure percentile ranking |
| **Clinic / Provider Collusion** | Hotspot claimants funnelled toward a fixed pool of suspicious merchants at elevated billing amounts | Dominant clinic ratio; co-occurrence frequency analysis |
| **Structuring-like Patterns** | Claims clustered below adjudication thresholds, high-frequency small submissions, and round-number billing concentrations | Threshold proximity scoring; round-number frequency distributions |

> For full typology encoding methodology, prevalence rates, and generation code, see [DATA_GENERATION.md](./DATA_GENERATION.md).

---

## Key Forensic Findings

### The Bot Attack
A single IP address (`45.33.22.11`) was responsible for **2,270 fraudulent claims** totalling **$3.68M** in exposure. Silver-layer device fusion exposed the pattern; Bronze preservation confirmed the IP appeared across 14 distinct synthetic claimant identities.

### The Whale Outlier
The top 10 claimants by exposure represent **$1.1M** in concentrated risk, a Whale Concentration ratio that would trigger enhanced review under IBC fraud detection guidelines.

### Sector Risk: Medical Clinics
Medical clinics emerged as the highest-severity provider sector with an average claim value of **$57.3k**, consistent with known SABS abuse patterns in Ontario's accident benefits ecosystem, where treatment plan inflation is a documented fraud vector.

### Total Exposure Isolated
**$69.3M** in Exposure-at-Risk surfaced across all six typologies after Gold-layer risk scoring and SIU referral flagging.

---

## Regulatory Context

This project is scoped to Ontario's insurance regulatory environment:

- **FSRA (Financial Services Regulatory Authority of Ontario): Governs auto and health insurance conduct in Ontario. mart_siu_referral_flags produces referral actions and reason strings aligned with FSRA's expectation that insurers maintain systematic fraud detection and escalation processes under the Insurance Act (Ontario).
- **SABS (Statutory Accident Benefits Schedule):** Ontario Regulation 34/10. The claim structures, treatment billing patterns, and provider relationships in this dataset reflect SABS-specific fraud vectors.
- **IBC Fraud Bureau:** Industry-standard fraud referral and reporting framework referenced for whale concentration and bot detection thresholds.
- **PIPEDA / PHIPA:** Federal and provincial privacy constraints that make real insurance claims data inaccessible for portfolio use, and the direct motivation for adversarial synthetic data generation.

---

## Engineering Workflow & AI Disclosure

The project architecture, data model design, fraud detection logic, STAR schema, SCD strategy, and dbt transformation authorship were designed and implemented by the developer, drawing on domain knowledge from front-line claims and accident benefits work.

LLM assistance was used in two specific, bounded ways:

1. **Documentation scaffolding:** Accelerating `schema.yml` field-level documentation across 300k+ records, a mechanical task disproportionate to its analytical value.
2. **Syntax debugging:** Used as a pair-programming tool for complex Snowflake JSON flattening syntax and REGEX pattern refinement.

All AI-generated output was reviewed, functionally tested, and validated against the project's forensic logic before commit. The analytical decisions, typology definitions, and risk scoring thresholds are original.

---

## Tech Stack

| Layer | Tool | Purpose |
|---|---|---|
| Cloud Warehouse | Snowflake | Storage, compute, and JSON semi-structured handling |
| Transformation | dbt-core | Medallion layer modelling, SCD snapshots, testing |
| Data Generation | Python | Adversarial synthetic data with deliberate quality defects |
| Orchestration | dbt CLI | Model execution and lineage |
| BI / Reporting | Tableau | Executive dashboards and SIU referral views |

---

## Repository Structure

```
AIFRE/
├── snowflake_setup/        # Warehouse, database, and role configuration
├── dbt_project/
│   ├── models/
│   │   ├── bronze/         # Raw ingestion models
│   │   ├── silver/         # Cleansing, SCD snapshots, domain fusion
│   │   └── gold/           # Analytical marts and risk scoring
│   ├── snapshots/          # SCD Type 2 identity tracking
│   ├── seeds/              # Watchlist reference data (flagged IPs, blacklisted clinics)
│   └── tests/              # dbt schema tests (not null, unique, referential integrity)
├── Visuals/                # Architecture diagrams and dashboard screenshots
├── DATA_GENERATION.md      # Synthetic data design, typology encoding, and privacy compliance
└── README.md
```

---

## Roadmap

- [x] Bronze ingestion layer
- [x] Silver cleansing and SCD Type 2 identity tracking
- [x] Gold analytical marts (`fct_claimant_risk`, `fct_daily_velocity`, `fct_fraud_exposure`, `dim_provider_status`)
- [x] Bot detection and whale concentration analysis
- [x] `mart_siu_referral_flags`: SIU escalation logic with FSRA-aligned risk tiering
- [x] dbt test suite expansion (referential integrity, accepted value ranges)
- [x] Structuring pattern mart with threshold proximity scoring
- [ ] Tableau executive dashboard
- [ ] Executive Slide Deck

---

*Built to reflect the operational reality of Ontario's insurance fraud environment. All data is synthetic and generated to model real-world adversarial characteristics under PIPEDA/PHIPA privacy constraints.*

