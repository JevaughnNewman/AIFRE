> Part of the [AIFRE - Adversarial Identity & Fraud Risk Engine](./README.md) project.

# Data Generation: Adversarial Synthetic Dataset Design

## Why Synthetic Data

Real Ontario insurance claims data is protected under **PIPEDA** (Personal Information Protection and Electronic Documents Act) at the federal level and **PHIPA** (Personal Health Information Protection Act) at the provincial level. Accessing production claims data for portfolio or research purposes without explicit institutional authorization is legally prohibited.

Synthetic data generation was therefore not a shortcut — it was the only compliant path. The goal was to produce a dataset that is **statistically representative** of real-world insurance fraud patterns while containing zero real personal information.

---

## Design Philosophy: Adversarial by Default

Most synthetic datasets are generated to be *clean*. This dataset was generated to be *adversarial* — meaning it was deliberately constructed with the quality defects, fragmentation patterns, and obfuscation techniques that real fraud data exhibits in production ingestion pipelines.

A clean synthetic dataset would only demonstrate that the pipeline works under ideal conditions. An adversarial dataset demonstrates that the pipeline is forensically robust under the conditions it will actually encounter.

---

## Reproducibility

All three generation scripts use Python's `random` library combined with `numpy` for high-volume record generation. A fixed random seed was applied to ensure the dataset is fully reproducible — any re-run of the scripts produces identical output. This is consistent with standard data engineering practice for testable, auditable pipelines.

---

## Dataset Architecture: Three Source Domains

The synthetic data is split across three scripts, each producing a distinct source domain that mirrors how a real insurer's data would be fragmented across systems:

| Script | Output File | Format | Volume | Represents |
|---|---|---|---|---|
| `identity_gen.py` | `AIFRE_Identity_Registry_RAW.csv` | CSV | 50,000 rows | Claimant demographics, KYC status, address history |
| `ledger_gen.py` | `AIFRE_Ledger_Registry_RAW.csv` | CSV | 100,000+ rows | Financial transactions, merchant billing, claim amounts |
| `network_logs_gen.py` | `AIFRE_Logs_RAW.json` | JSON (newline-delimited) | 150,000 records | Session logs, IP addresses, device fingerprints, browser telemetry |

**Total: 300,000+ records across three source domains.**

The fragmentation is intentional. No single source file contains enough information to detect fraud in isolation. The forensic signal only becomes visible when the Silver layer joins all three domains — which is the exact problem the Medallion architecture is designed to solve.

---

## Cross-Dataset Forensic Anchor: APP-CRITICAL-999

A deliberate forensic breadcrumb was embedded across all three scripts. The entity `APP-CRITICAL-999` ("Michael Smith") appears with consistent high-risk attributes in every source domain:

- **Identity:** Assigned SIN `999-999-999` and hotspot postal code `M3N 1Y8` (North York)
- **Network logs:** Hardcoded to IP `192.168.1.50`, device `DEV-FRAUD-RING-001`, browser `PostmanRuntime` (a non-human client)
- **Ledger:** Pulled into the fraud SIN pool, triggering amounts between $5,000 and $9,500 via `MANUAL_KEY_IN` entry mode

This entity is undetectable as fraudulent from any single source file. It only surfaces as a high-confidence fraud signal when all three domains are joined in the Silver fusion layer — a deliberate design choice that validates the architecture's core premise.

---

## Fraud Typologies: Encoding Decisions

Each typology was deliberately seeded at a controlled prevalence rate chosen upfront. Rates were designed to ensure fraud signals are present but non-trivial — detectable only through the correct analytical approach, not through a simple filter.

### 1. Synthetic Identity Fraud

**Prevalence:** ~15% of claimant population via SIN `999` prefix pattern.

**Encoding (`identity_gen.py` + `ledger_gen.py`):**
The `APP-CRITICAL-999` anchor uses `SIN = "999-999-999"` as an explicit synthetic identity marker. `ledger_gen.py` reads back the identity file and isolates all claimants whose SIN contains `"999"` into a dedicated `fraud_sin_ids` pool, which then drives elevated transaction amounts and suspicious entry modes.

```python
# ledger_gen.py - Fraud SIN pool isolation
fraud_sin_ids = id_df[id_df['SIN'].str.contains('999', na=False)]['APP_ID'].tolist()

if app_id in fraud_sin_ids:
    amount = round(random.uniform(5000, 9500), 2)
    entry_mode = "MANUAL_KEY_IN"
```

**Why it matters:** Synthetic identity is the dominant fraud vector in Ontario auto insurance. The SIN pattern creates a detectable but non-obvious linkage that requires a cross-domain join to confirm.

---

### 2. Geographic Collision Rings (Address Munging)

**Prevalence:** 10% of the claimant population forced into four specific GTA hotspot addresses.

**Encoding (`identity_gen.py`):**
Four real high-risk postal codes in the GTA corridor were hardcoded as hotspot anchors. 10% of claimants are assigned to these locations with unit-level address variation to simulate multiple unrelated identities sharing a single building.

```python
# identity_gen.py - Hotspot injection
hotspots = [
    {"city": "Brampton",    "pc": "L6Y 2A1", "addr": "123 Sandalwood Pkwy"},
    {"city": "North York",  "pc": "M3N 1Y8", "addr": "4000 Jane St"},
    {"city": "Scarborough", "pc": "M1B 5P1", "addr": "250 Milner Ave"},
    {"city": "Etobicoke",   "pc": "M9V 3S9", "addr": "100 Humber College Blvd"}
]

if roll < 0.10:
    address = f"{random.randint(10, 50)} - {spot['addr']}"  # Multiple units, one building
```

The GTA corridor was chosen deliberately. Its dense M- and L-prefix postal code geography reflects the known geographic concentration of staged accident fraud rings in Ontario, a pattern documented by both FSRA and the IBC Fraud Bureau.

---

### 3. Clinic / Provider Collusion (Power Law Funneling)

**Prevalence:** 40% of hotspot claimants funneled toward six named suspicious merchants.

**Encoding (`ledger_gen.py`):**
A pool of six named clinics and legal hubs was defined alongside 1,000 standard vendor nodes. Hotspot claimants — identified by cross-referencing the identity file at generation time — face a 40% probability of being routed to a suspicious merchant at elevated billing amounts.

```python
# ledger_gen.py - Power law distribution
suspicious_merchants = [
    "GTA REHAB CENTER", "NORTH YORK LEGAL HUB", "BRAMPTON PHYSIO INC",
    "JANE ST ASSESSMENTS", "MILNER MEDICAL GROUP", "SCARBOROUGH CLINIC"
]

if app_id in hotspot_ids and random.random() < 0.40:
    merchant_name = random.choice(suspicious_merchants)
    amount = round(random.uniform(1900, 2450), 2)  # Staged billing range
```

The 1,000-vendor standard pool was deliberately sized to simulate a real city's commercial ecosystem, ensuring suspicious merchants are not statistically obvious without aggregation.

---

### 4. Bot / Automated Submission Patterns

**Prevalence:** All APP_IDs where `app_num % 12 == 0` routed through the fraud IP pool (~8.3% of sessions).

**Encoding (`network_logs_gen.py`):**
Bot behavior is encoded through four simultaneous signals: proxy IP reuse, a shared fraud device ID, a non-human browser agent (`Python-Requests`), and near-zero page dwell time (1-3 seconds vs. 30-300 for legitimate sessions).

```python
# network_logs_gen.py - Coordinated bot attack logic
proxy_ips = ["192.168.1.50", "45.33.22.11", "10.0.0.99"]
fraud_device = "DEV-FRAUD-RING-001"

if app_num % 12 == 0:
    ip_address = random.choice(proxy_ips)
    device_id = fraud_device
    browser = "Python-Requests"
    seconds_on_page = random.randint(1, 3)
    proxy_detected = True
```

The `% 12` modulus was chosen deliberately to create a non-contiguous, non-obvious bot population that requires velocity analysis to surface. A simple IP filter alone would not identify it.

---

### 5. Whale Concentration

**Encoding (`ledger_gen.py`):**
The power law distribution created by funneling hotspot claimants to high-value suspicious merchants ($1,900-$2,450 per transaction) concentrates disproportionate exposure in a small claimant population. No explicit whale flag was injected — the concentration emerges organically from the funneling logic, which is how whale patterns appear in real production data.

---

### 6. Structuring-like Patterns

**Prevalence:** Combination of three overlapping behaviors encoded across the fraud SIN pool.

**Encoding (`ledger_gen.py`):**

- **Threshold proximity:** Fraud SIN claimants receive amounts between $5,000 and $9,500, clustering just below a $10,000 adjudication review threshold
- **Round-number clustering:** The $1,900-$2,450 suspicious merchant billing range produces disproportionate round-number concentrations at scale
- **Systematic outlier injection:** Zero-value and extreme-value records injected at fixed intervals to simulate billing system errors

```python
# ledger_gen.py - Structuring signals
if app_id in fraud_sin_ids:
    amount = round(random.uniform(5000, 9500), 2)  # Below $10k threshold

if i % 3000 == 0: amount = 0.00        # Zero-value outlier
if i % 7000 == 0: amount = 99999.99    # Extreme-value outlier
```

---

## Deliberately Injected Data Quality Defects

| Defect | Implementation | Script |
|---|---|---|
| Mixed date formats | `get_dirty_date()` rotates across 4 format strings | `identity_gen.py` |
| ALL CAPS name variants | `full_name.upper()` at 5% probability | `identity_gen.py` |
| Leading/trailing whitespace | `f" {city} "` at 5% probability | `identity_gen.py` |
| Age outliers | `age = 300` at every 5,000th record | `identity_gen.py` |
| SIN format variation | Hyphens stripped at 15% probability | `identity_gen.py` |
| Null credit scores | `score = None` at 15% probability | `identity_gen.py` |
| Fuzzy name duplicates | `"Michael Smith"` seeded as `"m smith"` with different APP_ID | `identity_gen.py` |
| Double-billing duplicates | 300 ledger records sampled and re-appended | `ledger_gen.py` |
| Zero-value transactions | `amount = 0.00` at every 3,000th record | `ledger_gen.py` |
| Extreme outlier amounts | `amount = 99999.99` at every 7,000th record | `ledger_gen.py` |
| Unix vs. ISO timestamp | `event_time` format alternates at 10% probability | `network_logs_gen.py` |
| Lowercase session IDs | `session_id.lower()` at 5% probability | `network_logs_gen.py` |
| Negative dwell time | `seconds_on_page = -99` at 1% probability | `network_logs_gen.py` |

---

## Validation

After generation, the following checks confirmed the data behaved as designed:

- Row counts verified against target volumes for all three files
- `APP-CRITICAL-999` confirmed present across all three source domains with correct attributes
- Hotspot postal codes confirmed at approximately 10% prevalence in the identity file
- Suspicious merchant co-occurrence confirmed elevated for hotspot APP_IDs vs. the standard population
- Bot IP pool confirmed appearing across approximately 8.3% of log sessions (consistent with `% 12` modulus)
- Fraud SIN pool confirmed routing to the $5,000-$9,500 amount range in the ledger

---

## Privacy Compliance

No real personal information was used at any stage. All names, addresses, contact details, and identifiers are procedurally generated. GTA postal codes and street names are used for geographic realism but are not associated with any real individual. The four hotspot addresses reference real street names in Ontario because geographic specificity is required to simulate address munging detection — no real resident data was used or implied.

This dataset meets the de-identification standard under PHIPA Schedule 3 and the anonymization guidance under PIPEDA — though it is not derived from real data at all.
