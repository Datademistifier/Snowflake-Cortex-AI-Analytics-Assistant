-- =============================================================
-- FILE: 02_create_tables.sql
-- PURPOSE: Create all tables for the Cortex demo project
-- RUN AFTER: 01_setup.sql
-- =============================================================

USE DATABASE  CORTEX_DEMO;
USE SCHEMA    HEALTHCARE;
USE WAREHOUSE CORTEX_WH;

-- ── Main claims table ────────────────────────────────────────
CREATE OR REPLACE TABLE PATIENT_CLAIMS (
    CLAIM_ID            VARCHAR(20)     NOT NULL    COMMENT 'Unique claim identifier',
    PATIENT_ID          VARCHAR(20)     NOT NULL    COMMENT 'Unique patient identifier',
    CLAIM_DATE          DATE            NOT NULL    COMMENT 'Date claim was submitted',
    DIAGNOSIS_CODE      VARCHAR(10)                 COMMENT 'ICD-10 diagnosis code',
    DIAGNOSIS_DESC      VARCHAR(200)                COMMENT 'Human-readable diagnosis description',
    MEDICATION_NAME     VARCHAR(100)                COMMENT 'Prescribed medication',
    CLAIM_AMOUNT        DECIMAL(10,2)               COMMENT 'Claim amount in USD',
    CLAIM_STATUS        VARCHAR(20)                 COMMENT 'APPROVED | DENIED | PENDING',
    PROVIDER_NOTES      VARCHAR(2000)               COMMENT 'Clinical notes from provider',
    PATIENT_FEEDBACK    VARCHAR(1000)               COMMENT 'Patient-reported experience',
    CREATED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP() COMMENT 'Record creation timestamp',

    CONSTRAINT PK_CLAIMS PRIMARY KEY (CLAIM_ID)
)
COMMENT = 'Synthetic healthcare claims data for Cortex AI demo';


-- ── Staging table (for CSV file load) ───────────────────────
CREATE OR REPLACE TABLE PATIENT_CLAIMS_STAGE (
    CLAIM_ID            VARCHAR(20),
    PATIENT_ID          VARCHAR(20),
    CLAIM_DATE          VARCHAR(20),    -- loaded as string, cast on insert
    DIAGNOSIS_CODE      VARCHAR(10),
    DIAGNOSIS_DESC      VARCHAR(200),
    MEDICATION_NAME     VARCHAR(100),
    CLAIM_AMOUNT        VARCHAR(20),    -- loaded as string, cast on insert
    CLAIM_STATUS        VARCHAR(20),
    PROVIDER_NOTES      VARCHAR(2000),
    PATIENT_FEEDBACK    VARCHAR(1000)
)
COMMENT = 'Staging table for CSV data load';


-- Confirm tables created
SHOW TABLES IN SCHEMA CORTEX_DEMO.HEALTHCARE;
