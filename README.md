# AIFRE

**Adversarial Identity & Fraud Risk Engine** | A Snowflake & dbt-powered Medallion Architecture for Synthetic Fraud Detection and Behavioural Forensic Auditing.

---

### 📊 Project Stats at a Glance 
* **Data Volume:** 300,000+ Records (CSV/JSON)
* **Tech Stack:** Snowflake, dbt-core, Tableau, Python
* **Forensic Scope:** Synthetic Identity, Bot-Attacks, & "Whale" Concentration
* **Financial Impact:** Isolated **$69.3M** in Exposure-at-Risk

---

### 🏗️ The Architecture: Forensic Medallion Framework
The engine utilizes a three-tier Medallion Architecture within Snowflake to transform "toxic" raw data into auditable intelligence.

* **🥉 Bronze (The Evidence Locker):** * Immutable ingestion of raw identity, financial, and network logs.
    * Focus: Data preservation for forensic re-processing.
* **🥈 Silver (The Investigation & Fusion):**
    * **Historical Engine (SCD Type 2):** Uses dbt snapshots to track identity evolution and "Nurtured" account patterns.
    * **Standardization:** Custom REGEX logic to collapse "Address Munging" clusters in the GTA corridor.
    * **Domain Fusion:** Joins fragmented digital fingerprints with financial records to close the "Visibility Gap."
* **🥇 Gold (The Decision Support):** * High-velocity marts optimized for executive reporting.
    * Metrics: **Whale Concentration**, **Bot Penetration Rates**, and **Sector Risk Profiling**.

---

### 🤖 AI-Augmented Engineering
This project was developed using an **AI-Pilot workflow**, leveraging LLMs to accelerate architectural deployment:

* **Automation:** AI-assisted generation of dbt `schema.yml` and documentation for 300k+ fields.
* **Optimization:** Used AI to refine high-performance Snowflake SQL for complex JSON flattening.
* **Governance:** Human-in-the-loop auditing of all AI-generated transformation logic to ensure regulatory compliance (FSRA/SABS).

---

### 🕵️‍♂️ Key Forensic Insights
* **The Bot Attack:** Isolated a single IP (`45.33.22.11`) responsible for 2,270 fraudulent claims totalling **$3.68M**.
* **The Whale Outlier:** Identified that the Top 10 claimants represent **$1.1M** in risk.
* **Sector Risk:** Medical Clinics identified as the highest-severity sector (Avg. **$57.3k** per claim).
