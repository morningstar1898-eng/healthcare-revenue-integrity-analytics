-- Healthcare Revenue Integrity Analytics Platform
-- Step 7: KPI and risk indicator views
--
-- Run this script in pgAdmin after loading the processed CSV files.
-- These views are designed for Tableau and portfolio storytelling.

-- ============================================================
-- 1. Executive KPI View
-- ============================================================

CREATE OR REPLACE VIEW revenue_integrity.vw_executive_kpis AS
SELECT
    COUNT(*) AS specialty_count,
    SUM(row_count) AS provider_service_rows,
    ROUND(SUM(total_beneficiaries), 0) AS total_beneficiaries,
    ROUND(SUM(total_services), 0) AS total_services,
    ROUND(SUM(estimated_submitted_charges), 2) AS estimated_submitted_charges,
    ROUND(SUM(estimated_medicare_allowed), 2) AS estimated_medicare_allowed,
    ROUND(SUM(estimated_medicare_payment), 2) AS estimated_medicare_payment,
    ROUND(SUM(estimated_standardized_payment), 2) AS estimated_standardized_payment,
    ROUND(
        SUM(estimated_submitted_charges) / NULLIF(SUM(estimated_medicare_payment), 0),
        2
    ) AS charge_to_payment_ratio,
    ROUND(
        SUM(estimated_medicare_allowed) / NULLIF(SUM(estimated_medicare_payment), 0),
        2
    ) AS allowed_to_payment_ratio,
    ROUND(
        SUM(estimated_medicare_payment) / NULLIF(SUM(total_services), 0),
        2
    ) AS avg_payment_per_service
FROM revenue_integrity.specialty_summary;

-- ============================================================
-- 2. Specialty KPI View
-- ============================================================

CREATE OR REPLACE VIEW revenue_integrity.vw_specialty_kpis AS
SELECT
    rndrng_prvdr_type AS specialty,
    row_count,
    ROUND(total_beneficiaries, 0) AS total_beneficiaries,
    ROUND(total_services, 0) AS total_services,
    ROUND(estimated_submitted_charges, 2) AS estimated_submitted_charges,
    ROUND(estimated_medicare_allowed, 2) AS estimated_medicare_allowed,
    ROUND(estimated_medicare_payment, 2) AS estimated_medicare_payment,
    ROUND(estimated_standardized_payment, 2) AS estimated_standardized_payment,
    ROUND(avg_payment_per_service, 2) AS avg_payment_per_service,
    ROUND(charge_to_payment_ratio, 2) AS charge_to_payment_ratio,
    ROUND(allowed_to_payment_ratio, 2) AS allowed_to_payment_ratio,
    ROUND(
        estimated_medicare_payment
        / NULLIF(SUM(estimated_medicare_payment) OVER (), 0),
        4
    ) AS payment_share,
    CASE
        WHEN charge_to_payment_ratio >= 6 THEN 'High charge variance'
        WHEN charge_to_payment_ratio >= 4 THEN 'Moderate charge variance'
        ELSE 'Baseline variance'
    END AS charge_variance_band
FROM revenue_integrity.specialty_summary;

-- ============================================================
-- 3. HCPCS KPI View
-- ============================================================

CREATE OR REPLACE VIEW revenue_integrity.vw_hcpcs_kpis AS
SELECT
    hcpcs_cd,
    hcpcs_desc,
    row_count,
    ROUND(total_beneficiaries, 0) AS total_beneficiaries,
    ROUND(total_services, 0) AS total_services,
    ROUND(estimated_submitted_charges, 2) AS estimated_submitted_charges,
    ROUND(estimated_medicare_allowed, 2) AS estimated_medicare_allowed,
    ROUND(estimated_medicare_payment, 2) AS estimated_medicare_payment,
    ROUND(avg_payment_per_service, 2) AS avg_payment_per_service,
    ROUND(charge_to_payment_ratio, 2) AS charge_to_payment_ratio,
    CASE
        WHEN total_services >= 100000 AND charge_to_payment_ratio >= 5
            THEN 'High-volume/high-variance'
        WHEN total_services >= 100000
            THEN 'High-volume'
        WHEN charge_to_payment_ratio >= 5
            THEN 'High-variance'
        ELSE 'Baseline'
    END AS hcpcs_review_category
FROM revenue_integrity.top_hcpcs_summary;

-- ============================================================
-- 4. Provider Risk Indicator View
-- ============================================================

CREATE OR REPLACE VIEW revenue_integrity.vw_provider_risk_indicators AS
WITH provider_scoring AS (
    SELECT
        rndrng_npi,
        rndrng_prvdr_type AS specialty,
        rndrng_prvdr_state_abrvtn AS state,
        row_count,
        total_services,
        estimated_submitted_charges,
        estimated_medicare_allowed,
        estimated_medicare_payment,
        avg_payment_per_service,
        charge_to_payment_ratio,
        PERCENT_RANK() OVER (
            PARTITION BY rndrng_prvdr_type
            ORDER BY estimated_medicare_payment
        ) AS specialty_payment_percentile,
        PERCENT_RANK() OVER (
            PARTITION BY rndrng_prvdr_type
            ORDER BY charge_to_payment_ratio
        ) AS specialty_charge_variance_percentile
    FROM revenue_integrity.top_provider_summary
)
SELECT
    rndrng_npi,
    specialty,
    state,
    row_count,
    ROUND(total_services, 0) AS total_services,
    ROUND(estimated_submitted_charges, 2) AS estimated_submitted_charges,
    ROUND(estimated_medicare_allowed, 2) AS estimated_medicare_allowed,
    ROUND(estimated_medicare_payment, 2) AS estimated_medicare_payment,
    ROUND(avg_payment_per_service, 2) AS avg_payment_per_service,
    ROUND(charge_to_payment_ratio, 2) AS charge_to_payment_ratio,
    ROUND(specialty_payment_percentile::numeric, 4) AS specialty_payment_percentile,
    ROUND(specialty_charge_variance_percentile::numeric, 4) AS specialty_charge_variance_percentile,
    CASE
        WHEN estimated_medicare_payment >= 1000000 THEN 3
        WHEN estimated_medicare_payment >= 500000 THEN 2
        WHEN estimated_medicare_payment >= 250000 THEN 1
        ELSE 0
    END AS payment_exposure_score,
    CASE
        WHEN charge_to_payment_ratio >= 8 THEN 3
        WHEN charge_to_payment_ratio >= 5 THEN 2
        WHEN charge_to_payment_ratio >= 3 THEN 1
        ELSE 0
    END AS charge_variance_score,
    CASE
        WHEN total_services >= 100000 THEN 3
        WHEN total_services >= 50000 THEN 2
        WHEN total_services >= 10000 THEN 1
        ELSE 0
    END AS utilization_score,
    CASE
        WHEN specialty_payment_percentile >= 0.95 THEN 1
        ELSE 0
    END AS specialty_payment_outlier_flag,
    CASE
        WHEN specialty_charge_variance_percentile >= 0.95 THEN 1
        ELSE 0
    END AS specialty_charge_variance_outlier_flag
FROM provider_scoring;

-- ============================================================
-- 5. Provider Risk Tier View
-- ============================================================

CREATE OR REPLACE VIEW revenue_integrity.vw_provider_risk_tiers AS
SELECT
    *,
    payment_exposure_score
        + charge_variance_score
        + utilization_score
        + specialty_payment_outlier_flag
        + specialty_charge_variance_outlier_flag AS total_risk_indicator_score,
    CASE
        WHEN payment_exposure_score
            + charge_variance_score
            + utilization_score
            + specialty_payment_outlier_flag
            + specialty_charge_variance_outlier_flag >= 7
            THEN 'High review priority'
        WHEN payment_exposure_score
            + charge_variance_score
            + utilization_score
            + specialty_payment_outlier_flag
            + specialty_charge_variance_outlier_flag >= 4
            THEN 'Moderate review priority'
        ELSE 'Baseline monitoring'
    END AS review_priority_tier
FROM revenue_integrity.vw_provider_risk_indicators;

-- ============================================================
-- 6. State KPI View
-- ============================================================

CREATE OR REPLACE VIEW revenue_integrity.vw_state_kpis AS
SELECT
    rndrng_prvdr_state_abrvtn AS state,
    row_count,
    ROUND(total_beneficiaries, 0) AS total_beneficiaries,
    ROUND(total_services, 0) AS total_services,
    ROUND(estimated_submitted_charges, 2) AS estimated_submitted_charges,
    ROUND(estimated_medicare_payment, 2) AS estimated_medicare_payment,
    ROUND(avg_payment_per_service, 2) AS avg_payment_per_service,
    ROUND(charge_to_payment_ratio, 2) AS charge_to_payment_ratio,
    ROUND(
        estimated_medicare_payment
        / NULLIF(SUM(estimated_medicare_payment) OVER (), 0),
        4
    ) AS payment_share
FROM revenue_integrity.state_summary;

