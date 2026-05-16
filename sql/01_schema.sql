-- Healthcare Revenue Integrity Analytics Platform
-- Step 5: PostgreSQL schema for cleaned CMS processed files
--
-- Recommended database name:
-- healthcare_revenue_integrity
--
-- Run this script in pgAdmin after creating the database.

CREATE SCHEMA IF NOT EXISTS revenue_integrity;

DROP TABLE IF EXISTS revenue_integrity.cms_provider_service_clean_sample;
DROP TABLE IF EXISTS revenue_integrity.specialty_summary;
DROP TABLE IF EXISTS revenue_integrity.state_summary;
DROP TABLE IF EXISTS revenue_integrity.top_hcpcs_summary;
DROP TABLE IF EXISTS revenue_integrity.top_provider_summary;

CREATE TABLE revenue_integrity.cms_provider_service_clean_sample (
    rndrng_npi BIGINT,
    rndrng_prvdr_last_org_name TEXT,
    rndrng_prvdr_first_name TEXT,
    rndrng_prvdr_ent_cd TEXT,
    rndrng_prvdr_city TEXT,
    rndrng_prvdr_state_abrvtn TEXT,
    rndrng_prvdr_cntry TEXT,
    rndrng_prvdr_type TEXT,
    rndrng_prvdr_mdcr_prtcptg_ind TEXT,
    hcpcs_cd TEXT,
    hcpcs_desc TEXT,
    hcpcs_drug_ind TEXT,
    place_of_srvc TEXT,
    tot_benes NUMERIC,
    tot_srvcs NUMERIC,
    tot_bene_day_srvcs NUMERIC,
    avg_sbmtd_chrg NUMERIC,
    avg_mdcr_alowd_amt NUMERIC,
    avg_mdcr_pymt_amt NUMERIC,
    avg_mdcr_stdzd_amt NUMERIC,
    place_of_service_label TEXT,
    provider_entity_label TEXT,
    estimated_submitted_charges NUMERIC,
    estimated_medicare_allowed NUMERIC,
    estimated_medicare_payment NUMERIC,
    estimated_standardized_payment NUMERIC,
    charge_to_payment_ratio NUMERIC,
    allowed_to_payment_gap NUMERIC,
    services_per_beneficiary NUMERIC,
    high_charge_variance_flag BOOLEAN,
    high_service_intensity_flag BOOLEAN
);

CREATE TABLE revenue_integrity.specialty_summary (
    rndrng_prvdr_type TEXT,
    row_count BIGINT,
    total_beneficiaries NUMERIC,
    total_services NUMERIC,
    estimated_submitted_charges NUMERIC,
    estimated_medicare_allowed NUMERIC,
    estimated_medicare_payment NUMERIC,
    estimated_standardized_payment NUMERIC,
    avg_payment_per_service NUMERIC,
    charge_to_payment_ratio NUMERIC,
    allowed_to_payment_ratio NUMERIC
);

CREATE TABLE revenue_integrity.state_summary (
    rndrng_prvdr_state_abrvtn TEXT,
    row_count BIGINT,
    total_beneficiaries NUMERIC,
    total_services NUMERIC,
    estimated_submitted_charges NUMERIC,
    estimated_medicare_allowed NUMERIC,
    estimated_medicare_payment NUMERIC,
    estimated_standardized_payment NUMERIC,
    avg_payment_per_service NUMERIC,
    charge_to_payment_ratio NUMERIC,
    allowed_to_payment_ratio NUMERIC
);

CREATE TABLE revenue_integrity.top_hcpcs_summary (
    hcpcs_cd TEXT,
    hcpcs_desc TEXT,
    row_count BIGINT,
    total_beneficiaries NUMERIC,
    total_services NUMERIC,
    estimated_submitted_charges NUMERIC,
    estimated_medicare_allowed NUMERIC,
    estimated_medicare_payment NUMERIC,
    estimated_standardized_payment NUMERIC,
    avg_payment_per_service NUMERIC,
    charge_to_payment_ratio NUMERIC,
    allowed_to_payment_ratio NUMERIC
);

CREATE TABLE revenue_integrity.top_provider_summary (
    rndrng_npi BIGINT,
    rndrng_prvdr_type TEXT,
    rndrng_prvdr_state_abrvtn TEXT,
    row_count BIGINT,
    total_beneficiaries NUMERIC,
    total_services NUMERIC,
    estimated_submitted_charges NUMERIC,
    estimated_medicare_allowed NUMERIC,
    estimated_medicare_payment NUMERIC,
    estimated_standardized_payment NUMERIC,
    avg_payment_per_service NUMERIC,
    charge_to_payment_ratio NUMERIC,
    allowed_to_payment_ratio NUMERIC
);

CREATE INDEX idx_sample_specialty
    ON revenue_integrity.cms_provider_service_clean_sample (rndrng_prvdr_type);

CREATE INDEX idx_sample_hcpcs
    ON revenue_integrity.cms_provider_service_clean_sample (hcpcs_cd);

CREATE INDEX idx_sample_state
    ON revenue_integrity.cms_provider_service_clean_sample (rndrng_prvdr_state_abrvtn);

CREATE INDEX idx_provider_summary_specialty
    ON revenue_integrity.top_provider_summary (rndrng_prvdr_type);
