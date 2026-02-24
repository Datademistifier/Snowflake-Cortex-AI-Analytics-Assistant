-- =============================================================
-- FILE: 04_cortex_queries.sql
-- PURPOSE: Snowflake Cortex LLM function queries + enriched view
-- RUN AFTER: 03_load_data.sql
-- CORTEX DOCS: https://docs.snowflake.com/en/user-guide/snowflake-cortex/llm-functions
-- =============================================================

USE DATABASE  CORTEX_DEMO;
USE SCHEMA    HEALTHCARE;
USE WAREHOUSE CORTEX_WH;


-- =============================================================
-- SECTION 1: SENTIMENT ANALYSIS
-- Scores patient feedback from -1.0 (negative) to 1.0 (positive)
-- =============================================================

SELECT
    CLAIM_ID,
    PATIENT_ID,
    CLAIM_STATUS,
    PATIENT_FEEDBACK,
    SNOWFLAKE.CORTEX.SENTIMENT(PATIENT_FEEDBACK)            AS SENTIMENT_SCORE,
    CASE
        WHEN SNOWFLAKE.CORTEX.SENTIMENT(PATIENT_FEEDBACK) >=  0.5 THEN 'Positive'
        WHEN SNOWFLAKE.CORTEX.SENTIMENT(PATIENT_FEEDBACK) <= -0.5 THEN 'Negative'
        ELSE 'Neutral'
    END                                                      AS SENTIMENT_LABEL
FROM PATIENT_CLAIMS
ORDER BY SENTIMENT_SCORE ASC;   -- most negative first


-- Aggregate: average sentiment by claim status
SELECT
    CLAIM_STATUS,
    COUNT(*)                                                        AS CLAIM_COUNT,
    ROUND(AVG(SNOWFLAKE.CORTEX.SENTIMENT(PATIENT_FEEDBACK)), 3)    AS AVG_SENTIMENT,
    SUM(CASE WHEN SNOWFLAKE.CORTEX.SENTIMENT(PATIENT_FEEDBACK) >= 0.5  THEN 1 ELSE 0 END) AS POSITIVE_COUNT,
    SUM(CASE WHEN SNOWFLAKE.CORTEX.SENTIMENT(PATIENT_FEEDBACK) <= -0.5 THEN 1 ELSE 0 END) AS NEGATIVE_COUNT
FROM PATIENT_CLAIMS
GROUP BY CLAIM_STATUS
ORDER BY AVG_SENTIMENT ASC;


-- =============================================================
-- SECTION 2: SUMMARIZE
-- Condenses long provider notes into a short digest
-- =============================================================

SELECT
    CLAIM_ID,
    DIAGNOSIS_DESC,
    LENGTH(PROVIDER_NOTES)                              AS ORIGINAL_LENGTH,
    PROVIDER_NOTES                                      AS FULL_NOTES,
    SNOWFLAKE.CORTEX.SUMMARIZE(PROVIDER_NOTES)          AS NOTES_SUMMARY,
    LENGTH(SNOWFLAKE.CORTEX.SUMMARIZE(PROVIDER_NOTES))  AS SUMMARY_LENGTH
FROM PATIENT_CLAIMS
ORDER BY ORIGINAL_LENGTH DESC;


-- =============================================================
-- SECTION 3: COMPLETE (LLM prompting with mistral-large)
-- Generates structured AI output from a custom prompt
-- =============================================================

-- 3a. Care coordinator recommendations per claim
SELECT
    CLAIM_ID,
    DIAGNOSIS_DESC,
    CLAIM_STATUS,
    SNOWFLAKE.CORTEX.COMPLETE(
        'mistral-large2',
        CONCAT(
            'You are a healthcare care coordinator assistant. ',
            'Based on the claim below, write a concise 2-sentence action recommendation for the care team.\n\n',
            'Claim ID: ',        CLAIM_ID,        '\n',
            'Diagnosis: ',       DIAGNOSIS_DESC,  '\n',
            'Claim Status: ',    CLAIM_STATUS,    '\n',
            'Provider Notes: ',  PROVIDER_NOTES,  '\n\n',
            'Recommendation:'
        )
    ) AS CARE_RECOMMENDATION
FROM PATIENT_CLAIMS;


-- 3b. Priority flags for denied and pending claims
SELECT
    CLAIM_ID,
    CLAIM_STATUS,
    DIAGNOSIS_DESC,
    SNOWFLAKE.CORTEX.COMPLETE(
        'mistral-large2',
        CONCAT(
            'You are a claims review specialist. ',
            'Rate the urgency of this claim as HIGH, MEDIUM, or LOW, ',
            'and give one sentence of justification.\n\n',
            'Status: ',   CLAIM_STATUS,   '\n',
            'Diagnosis: ',DIAGNOSIS_DESC, '\n',
            'Notes: ',    PROVIDER_NOTES, '\n\n',
            'Urgency Rating:'
        )
    ) AS URGENCY_RATING
FROM PATIENT_CLAIMS
WHERE CLAIM_STATUS IN ('DENIED', 'PENDING')
ORDER BY CLAIM_ID;


-- 3c. Patient-friendly explanation of denial reason
SELECT
    CLAIM_ID,
    CLAIM_STATUS,
    SNOWFLAKE.CORTEX.COMPLETE(
        'mistral-large2',
        CONCAT(
            'You are a patient advocate. ',
            'Write a kind, clear, and non-technical 2-sentence explanation ',
            'for why this claim was denied and what the patient can do next.\n\n',
            'Provider Notes: ', PROVIDER_NOTES, '\n\n',
            'Patient Explanation:'
        )
    ) AS PATIENT_FRIENDLY_EXPLANATION
FROM PATIENT_CLAIMS
WHERE CLAIM_STATUS = 'DENIED';


-- =============================================================
-- SECTION 4: TRANSLATE
-- Translates patient feedback for multilingual support
-- =============================================================

SELECT
    CLAIM_ID,
    PATIENT_FEEDBACK                                                    AS FEEDBACK_ENGLISH,
    SNOWFLAKE.CORTEX.TRANSLATE(PATIENT_FEEDBACK, 'en', 'es')           AS FEEDBACK_SPANISH,
    SNOWFLAKE.CORTEX.TRANSLATE(PATIENT_FEEDBACK, 'en', 'fr')           AS FEEDBACK_FRENCH,
    SNOWFLAKE.CORTEX.TRANSLATE(PATIENT_FEEDBACK, 'en', 'de')           AS FEEDBACK_GERMAN
FROM PATIENT_CLAIMS
LIMIT 3;


-- =============================================================
-- SECTION 5: AI-ENRICHED VIEW
-- Combines all Cortex functions into a single reusable view
-- This view powers the Streamlit dashboard
-- =============================================================

CREATE OR REPLACE VIEW AI_ENRICHED_CLAIMS AS
SELECT
    CLAIM_ID,
    PATIENT_ID,
    CLAIM_DATE,
    DIAGNOSIS_CODE,
    DIAGNOSIS_DESC,
    MEDICATION_NAME,
    CLAIM_AMOUNT,
    CLAIM_STATUS,

    -- Raw text fields
    PROVIDER_NOTES,
    PATIENT_FEEDBACK,

    -- Cortex: Sentiment
    ROUND(SNOWFLAKE.CORTEX.SENTIMENT(PATIENT_FEEDBACK), 3)     AS SENTIMENT_SCORE,
    CASE
        WHEN SNOWFLAKE.CORTEX.SENTIMENT(PATIENT_FEEDBACK) >=  0.5 THEN 'Positive'
        WHEN SNOWFLAKE.CORTEX.SENTIMENT(PATIENT_FEEDBACK) <= -0.5 THEN 'Negative'
        ELSE 'Neutral'
    END                                                         AS SENTIMENT_LABEL,

    -- Cortex: Summarize
    SNOWFLAKE.CORTEX.SUMMARIZE(PROVIDER_NOTES)                  AS NOTES_SUMMARY,

    -- Cortex: Complete — Care recommendation
    SNOWFLAKE.CORTEX.COMPLETE(
        'mistral-large2',
        CONCAT(
            'You are a healthcare care coordinator. ',
            'Write a concise 1-sentence action recommendation for: ',
            'Diagnosis: ', DIAGNOSIS_DESC, '. ',
            'Status: ',    CLAIM_STATUS,   '. ',
            'Notes: ',     LEFT(PROVIDER_NOTES, 300)
        )
    )                                                           AS CARE_RECOMMENDATION,

    -- Metadata
    CREATED_AT

FROM PATIENT_CLAIMS
COMMENT = 'AI-enriched claims view powered by Snowflake Cortex LLM functions';


-- Validate the view
SELECT * FROM AI_ENRICHED_CLAIMS;


-- =============================================================
-- SECTION 6: ANALYTICS QUERIES ON THE ENRICHED VIEW
-- =============================================================

-- Claims with negative sentiment that are still pending or denied
SELECT
    CLAIM_ID,
    DIAGNOSIS_DESC,
    CLAIM_STATUS,
    SENTIMENT_SCORE,
    SENTIMENT_LABEL,
    NOTES_SUMMARY,
    CARE_RECOMMENDATION
FROM AI_ENRICHED_CLAIMS
WHERE SENTIMENT_LABEL = 'Negative'
  AND CLAIM_STATUS IN ('DENIED', 'PENDING')
ORDER BY SENTIMENT_SCORE ASC;


-- Summary dashboard stats
SELECT
    CLAIM_STATUS,
    COUNT(*)                    AS TOTAL_CLAIMS,
    SUM(CLAIM_AMOUNT)           AS TOTAL_AMOUNT,
    AVG(CLAIM_AMOUNT)           AS AVG_AMOUNT,
    AVG(SENTIMENT_SCORE)        AS AVG_SENTIMENT,
    COUNT(CASE WHEN SENTIMENT_LABEL = 'Negative' THEN 1 END) AS NEGATIVE_FEEDBACK_COUNT
FROM AI_ENRICHED_CLAIMS
GROUP BY CLAIM_STATUS
ORDER BY CLAIM_STATUS;
