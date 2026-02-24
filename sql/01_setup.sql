-- =============================================================
-- FILE: 01_setup.sql
-- PURPOSE: Create database, schema, warehouse, and roles
-- RUN AS: ACCOUNTADMIN or SYSADMIN
-- =============================================================

USE ROLE SYSADMIN;

-- ── Database & Schema ────────────────────────────────────────
CREATE DATABASE IF NOT EXISTS CORTEX_DEMO
    COMMENT = 'Snowflake Cortex AI Healthcare Claims Demo';

CREATE SCHEMA IF NOT EXISTS CORTEX_DEMO.HEALTHCARE
    COMMENT = 'Healthcare claims data for Cortex demo';

-- ── Warehouse ────────────────────────────────────────────────
-- XSmall with auto-suspend to keep costs minimal
CREATE WAREHOUSE IF NOT EXISTS CORTEX_WH
    WITH WAREHOUSE_SIZE      = 'XSMALL'
         AUTO_SUSPEND        = 60        -- suspend after 60 seconds idle
         AUTO_RESUME         = TRUE
         INITIALLY_SUSPENDED = TRUE
         COMMENT             = 'Warehouse for Cortex demo project';

-- ── Role setup ───────────────────────────────────────────────
USE ROLE ACCOUNTADMIN;

-- Create a dedicated role for this project
CREATE ROLE IF NOT EXISTS CORTEX_DEMO_ROLE
    COMMENT = 'Role for Cortex demo project access';

-- Grant warehouse usage
GRANT USAGE ON WAREHOUSE CORTEX_WH TO ROLE CORTEX_DEMO_ROLE;

-- Grant database and schema privileges
GRANT USAGE  ON DATABASE CORTEX_DEMO              TO ROLE CORTEX_DEMO_ROLE;
GRANT USAGE  ON SCHEMA   CORTEX_DEMO.HEALTHCARE   TO ROLE CORTEX_DEMO_ROLE;
GRANT ALL    ON SCHEMA   CORTEX_DEMO.HEALTHCARE   TO ROLE CORTEX_DEMO_ROLE;

-- Grant Cortex function usage
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE CORTEX_DEMO_ROLE;

-- Assign role to your user (replace YOUR_USERNAME)
-- GRANT ROLE CORTEX_DEMO_ROLE TO USER YOUR_USERNAME;

-- Switch to working context
USE ROLE      SYSADMIN;
USE DATABASE  CORTEX_DEMO;
USE SCHEMA    HEALTHCARE;
USE WAREHOUSE CORTEX_WH;

-- Confirm setup
SELECT CURRENT_DATABASE(), CURRENT_SCHEMA(), CURRENT_WAREHOUSE(), CURRENT_ROLE();
