# ❄️ Snowflake Cortex AI — Healthcare Claims Assistant

> **A hands-on demonstration of Snowflake Cortex LLM functions applied to synthetic healthcare claims data, with a fully interactive Streamlit in Snowflake UI.**

Built by **Sonal Mishra** — Data Engineer | Snowflake Squad Member | SnowPro Associate Certified | Snowflake Austin User Group Leader

📎 [LinkedIn](https://www.linkedin.com/in/mishrasonal)

---

## 📌 What This Project Does

This project simulates a real-world healthcare analytics use case where AI enriches claims data automatically — reducing manual review time and surfacing actionable insights for care coordinators.

| Cortex Function | What It Does in This Project |
|---|---|
| `SENTIMENT()` | Scores patient feedback as positive, neutral, or negative |
| `SUMMARIZE()` | Condenses long provider notes into 1–2 sentence digests |
| `COMPLETE()` | Generates AI care recommendations per claim using mistral-large |
| `TRANSLATE()` | Translates patient feedback into Spanish and French |

The Streamlit app lets users filter claims, view AI-enriched results, and ask free-text questions about the data — answered live by Cortex.

---

## 🏗️ Architecture

```
Synthetic Claims Data (CSV)
        │
        ▼
Snowflake Table: patient_claims
        │
        ▼
Cortex LLM Functions (SENTIMENT, SUMMARIZE, COMPLETE, TRANSLATE)
        │
        ▼
Snowflake View: ai_enriched_claims
        │
        ▼
Streamlit in Snowflake — Interactive Dashboard
```

---

## ❄️ Snowflake Features Used

- **Snowflake Cortex** — SENTIMENT, SUMMARIZE, COMPLETE, TRANSLATE
- **Streamlit in Snowflake** — embedded UI, no external hosting needed
- **Snowpark Python** — session management inside Streamlit
- **Virtual Warehouses** — XSmall, auto-suspend for cost control
- **Views** — reusable AI-enriched claims layer
- **RBAC** — role-based access setup included

---

## 📁 Repo Structure

```
snowflake-cortex-healthcare-assistant/
│
├── README.md
├── data/
│   └── sample_claims.csv          # Synthetic claims data (10 rows)
├── sql/
│   ├── 01_setup.sql               # Database, schema, warehouse, roles
│   ├── 02_create_tables.sql       # Table definitions
│   ├── 03_load_data.sql           # Data insert statements
│   └── 04_cortex_queries.sql      # All Cortex LLM queries + enriched view
├── streamlit/
│   └── app.py                     # Streamlit in Snowflake application
└── docs/
    └── screenshots/               # Add your screenshots here
```

---

## 🚀 How to Run It

### Prerequisites
- A Snowflake account (trial or lab account works)
- ACCOUNTADMIN or SYSADMIN role access
- Cortex enabled on your account (available in most AWS/Azure regions)

### Step 1 — Run SQL scripts in order
Open a Snowflake worksheet and run each file in the `sql/` folder in order:

```
sql/01_setup.sql          ← creates database, schema, warehouse, roles
sql/02_create_tables.sql  ← creates patient_claims table
sql/03_load_data.sql      ← loads 10 synthetic claims records
sql/04_cortex_queries.sql ← runs Cortex functions, creates enriched view
```

### Step 2 — Create the Streamlit App
1. In Snowflake UI → left nav → **Streamlit**
2. Click **+ Streamlit App**
3. Name it: `cortex_claims_assistant`
4. Set database: `CORTEX_DEMO`, schema: `HEALTHCARE`
5. Paste the full contents of `streamlit/app.py`
6. Click **Run**

### Step 3 — Explore
- Filter claims by status
- Read AI-generated summaries and recommendations
- Type a free-text question and get a Cortex-powered answer

---

## 📊 Sample Output

| Claim | Diagnosis | Status | Sentiment | AI Summary |
|---|---|---|---|---|
| CLM001 | Type 2 Diabetes | APPROVED | 0.2 (Neutral) | Patient managing blood sugar with some fatigue... |
| CLM003 | Low Back Pain | DENIED | -0.8 (Negative) | Claim denied due to missing prior auth... |
| CLM005 | Depression | PENDING | -0.6 (Negative) | Moderate symptoms, therapy referral sent... |

---

## 🧠 Skills Demonstrated

`Snowflake Cortex` `LLM Prompting` `Streamlit in Snowflake` `Snowpark Python`
`SQL` `Healthcare Data` `Data Engineering` `BI & Analytics` `RBAC` `Cost Optimization`

---

## 📝 Notes

- All data in this project is **fully synthetic** — no real patient information is used
- Cortex availability depends on your Snowflake region — check [Snowflake docs](https://docs.snowflake.com/en/user-guide/snowflake-cortex/llm-functions) for supported regions
- XSmall warehouse with auto-suspend keeps costs minimal for a demo project

---

## 📬 Contact

**Sonal Mishra** — sonalmishrapachori@gmail.com | [LinkedIn](https://www.linkedin.com/in/mishrasonal)
