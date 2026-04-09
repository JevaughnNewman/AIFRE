# AIFRE: Adversarial Identity & Fraud Risk Engine
### *Closing the "Visibility Gap" in Ontario’s Insurance Ecosystem*



**AIFRE** is a production-grade forensic pipeline designed to bridge the "Visibility Gap" in claims data. By simulating an adversarial insurance environment, this project identifies **$69.3M in hidden exposure** across six distinct fraud typologies.

① **Interactive Dashboard** → [View Tableau Dashboard](#)  
② **Executive Strategy Deck** → [View Presentation](#)  
③ **Technical Architecture** → [View Snowflake & dbt logic](https://github.com/JevaughnNewman/AIFRE/tree/main/dbt_project)

---

### 🚀 The Business Case: Reducing Financial Leakage

In the Ontario Statuory Accident Benefits Schedule (SABS) framework, manual adjudication often fails to detect coordinated fraud. AIFRE shifts the paradigm from **reactive auditing** to **proactive risk mitigation** by surfacing patterns that appear as isolated, "clean" claims to the human eye.

* **Financial Exposure Isolated:** $69.3M in high-risk claims.
* **Target ROI:** Significant reduction in loss ratios by automating the identification of bot-driven and professional fraud rings before payment.
* **Regulatory Alignment:** Aligned with FSRA expectations for systematic fraud detection and SIU escalation.

---

### 🔍 Key Forensic Insights
*Decision-ready intelligence surfaced through forensic modelling:*

* **The Bot Breach ($3.68M Exposure):** By fusing device telemetry with financial records in the Silver layer, we exposed a single IP address linked to **2,270 claims**. 
* **Medical Clinic Collusion:** Clinics emerged as the highest-severity vector with an average claim value of **$57.3k**. This confirms that "Treatment Plan Inflation" is a primary driver of rising loss ratios.
* **The "Whale" Concentration:** 1% of claimants represent **$1.1M in concentrated risk**. Shifting SIU resources to these outliers yields a significantly higher recovery-per-hour than random auditing.

---

### 🧠 My Approach: Risk-First Engineering
I approached this project not just as a developer, but as a risk professional with years of front-line experience in Ontario Accident Benefits.

* **SCD Type 2 Identity Tracking:** I chose to track the evolution of identities rather than overwriting them. This is the only way to catch "Nurtured Accounts"—entities that cycle through addresses over time to evade detection.
* **The "Evidence Locker" (Bronze):** Preserved raw, "dirty" data to ensure every transformation is legally auditable and meets FSRA/SABS forensic standards.
* **Adversarial Synthetic Data:** Since privacy constraints (PIPEDA/PHIPA) prevent the use of real claims data, I built a custom Python generator to create a realistic, "dirty" dataset that tests the pipeline's limits.

---

### 🛠 Project Stats at a Glance

| Metric | Value |
| :--- | :--- |
| **Data Volume** | 300,000+ Records across 3 source domains |
| **Core Stack** | Snowflake, dbt-core, Python, Tableau |
| **Regulatory Scope** | FSRA, SABS, IBC Fraud Bureau Standards |
| **Fraud Typologies** | 6 (Synthetic, Bot, Collision Rings, Whale, Collusion, Structuring) |

---

### 🏗 Technical Architecture: Forensic Medallion Framework

The engine uses a three-tier Medallion Architecture within Snowflake. Every transformation is auditable, ensuring data is never overwritten at the source.

```text
       RAW SOURCES (CSV / JSON)
               │
               ▼
┌─────────────────────────────┐
│       🥉 BRONZE             │  Immutable Evidence Locker
│       Raw Ingestion         │  Exact source fidelity, no cleansing
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│       🥈 SILVER             │  Investigation & Fusion Layer
│       Transformation        │  SCD Type 2 · REGEX · Domain Fusion
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│       🥇 GOLD               │  Decision Support Layer
│       Analytical Marts      │  Risk Scoring · SIU Flags · KPIs
└─────────────────────────────┘

```

#### **Bronze (The Evidence Locker)**
* Raw ingestion of identity records, financial claims, and network logs. We preserve address variants and malformed JSON because forensic re-processing requires original evidence.

#### **Silver (Investigation & Fusion)**
* **Address Munging Resolution:** Custom REGEX logic collapses identity fragmentation clusters (e.g., standardizing "123 Main St" vs "123 Main Street").
* **Domain Fusion:** Joins fragmented digital fingerprints (IPs, Device IDs) to financial records to close the visibility gap.

#### **Gold (Decision Support)**
High-velocity analytical marts optimized for BI and SIU consumption:
* `fct_claimant_risk`: Entity-level composite risk scoring.
* `fct_daily_velocity`: Automated and bot-driven claim detection.
* `mart_siu_referral_flags`: Investigator-facing reason strings and referral actions.

---

### 📐 Schema Design: STAR Schema

After forensic cleansing, Gold marts are structured as a STAR schema. This was chosen to optimize for aggregation-heavy fraud workloads and ease of use in the BI layer without requiring complex relational joins.

```
                    dim_claimant (SCD2)
                          │
dim_clinic ───── fct_claims ───── dim_device
                          │
                    dim_date
                          │
                    dim_location

---


*Built to reflect the operational reality of Ontario's insurance fraud environment. All data is synthetic and generated to model real-world adversarial characteristics under PIPEDA/PHIPA privacy constraints.*

