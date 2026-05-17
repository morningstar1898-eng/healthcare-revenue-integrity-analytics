-- Healthcare Revenue Integrity Analytics Platform
-- Step 6: PostgreSQL analysis queries
--
-- Run these queries in pgAdmin after loading the five processed CSV files.
-- These queries are written for portfolio storytelling: validation first,
-- then executive KPIs, specialty trends, HCPCS variance, provider outliers,
-- and geographic comparison.

-- ============================================================
-- 1. Load Validation
-- ============================================================

SELECT 'cms_provider_service_clean_sample' AS table_name, COUNT(*) AS row_count
FROM revenue_integrity.cms_provider_service_clean_sample
UNION ALL
SELECT 'specialty_summary', COUNT(*)
FROM revenue_integrity.specialty_summary
UNION ALL
SELECT 'state_summary', COUNT(*)
FROM revenue_integrity.state_summary
UNION ALL
SELECT 'top_hcpcs_summary', COUNT(*)
FROM revenue_integrity.top_hcpcs_summary
UNION ALL
SELECT 'top_provider_summary', COUNT(*)
FROM revenue_integrity.top_provider_summary
ORDER BY table_name;

-- Expected row counts:
-- cms_provider_service_clean_sample: 250000
-- specialty_summary: 104
-- state_summary: 62
-- top_hcpcs_summary: 5000
-- top_provider_summary: 10000

-- ============================================================
-- 2. Executive KPI Summary
-- ============================================================

SELECT
    COUNT(*) AS specialty_count,
    SUM(row_count) AS provider_service_rows,
    ROUND(SUM(total_beneficiaries), 0) AS total_beneficiaries,
    ROUND(SUM(total_services), 0) AS total_services,
    ROUND(SUM(estimated_submitted_charges), 2) AS estimated_submitted_charges,
    ROUND(SUM(estimated_medicare_allowed), 2) AS estimated_medicare_allowed,
    ROUND(SUM(estimated_medicare_payment), 2) AS estimated_medicare_payment,
    ROUND(
        SUM(estimated_submitted_charges) / NULLIF(SUM(estimated_medicare_payment), 0),
        2
    ) AS overall_charge_to_payment_ratio,
    ROUND(
        SUM(estimated_medicare_payment) / NULLIF(SUM(total_services), 0),
        2
    ) AS overall_payment_per_service
FROM revenue_integrity.specialty_summary;

-- Portfolio use:
-- This becomes the top KPI row for the Tableau executive dashboard.

-- ============================================================
-- 3. Top Specialties By Estimated Medicare Payment
-- ============================================================

SELECT
    rndrng_prvdr_type AS specialty,
    row_count,
    ROUND(total_services, 0) AS total_services,
    ROUND(estimated_medicare_payment, 2) AS estimated_medicare_payment,
    ROUND(avg_payment_per_service, 2) AS avg_payment_per_service,
    ROUND(charge_to_payment_ratio, 2) AS charge_to_payment_ratio
FROM revenue_integrity.specialty_summary
ORDER BY estimated_medicare_payment DESC
LIMIT 15;

-- Business question:
-- Which specialties represent the largest Medicare payment exposure?

-- ============================================================
-- 4. Specialties With Highest Charge-To-Payment Ratio
-- ============================================================

SELECT
    rndrng_prvdr_type AS specialty,
    row_count,
    ROUND(total_services, 0) AS total_services,
    ROUND(estimated_submitted_charges, 2) AS estimated_submitted_charges,
    ROUND(estimated_medicare_payment, 2) AS estimated_medicare_payment,
    ROUND(charge_to_payment_ratio, 2) AS charge_to_payment_ratio
FROM revenue_integrity.specialty_summary
WHERE total_services >= 10000
ORDER BY charge_to_payment_ratio DESC
LIMIT 15;

-- Business question:
-- Which specialties show the largest gap between submitted charges and Medicare payment?
-- This is a variance indicator, not proof of incorrect billing.

-- ============================================================
-- 5. Top HCPCS Codes By Estimated Medicare Payment
-- ============================================================

SELECT
    hcpcs_cd,
    hcpcs_desc,
    row_count,
    ROUND(total_services, 0) AS total_services,
    ROUND(estimated_medicare_payment, 2) AS estimated_medicare_payment,
    ROUND(avg_payment_per_service, 2) AS avg_payment_per_service,
    ROUND(charge_to_payment_ratio, 2) AS charge_to_payment_ratio
FROM revenue_integrity.top_hcpcs_summary
ORDER BY estimated_medicare_payment DESC
LIMIT 20;

-- Business question:
-- Which services drive the largest Medicare payment amounts?

-- ============================================================
-- 6. HCPCS Codes With High Charge-To-Payment Variance
-- ============================================================

SELECT
    hcpcs_cd,
    hcpcs_desc,
    row_count,
    ROUND(total_services, 0) AS total_services,
    ROUND(estimated_submitted_charges, 2) AS estimated_submitted_charges,
    ROUND(estimated_medicare_payment, 2) AS estimated_medicare_payment,
    ROUND(charge_to_payment_ratio, 2) AS charge_to_payment_ratio
FROM revenue_integrity.top_hcpcs_summary
WHERE total_services >= 10000
ORDER BY charge_to_payment_ratio DESC
LIMIT 20;

-- Business question:
-- Which high-volume services show unusually large charge/payment gaps?

-- ============================================================
-- 7. Provider Outlier Candidates By Payment Volume
-- ============================================================

SELECT
    rndrng_npi,
    rndrng_prvdr_type AS specialty,
    rndrng_prvdr_state_abrvtn AS state,
    row_count,
    ROUND(total_services, 0) AS total_services,
    ROUND(estimated_medicare_payment, 2) AS estimated_medicare_payment,
    ROUND(avg_payment_per_service, 2) AS avg_payment_per_service,
    ROUND(charge_to_payment_ratio, 2) AS charge_to_payment_ratio
FROM revenue_integrity.top_provider_summary
ORDER BY estimated_medicare_payment DESC
LIMIT 25;

-- Business question:
-- Which providers represent the largest payment exposure for review prioritization?

-- ============================================================
-- 8. Provider Outlier Candidates Within Specialty
-- ============================================================

WITH provider_rankings AS (
    SELECT
        rndrng_npi,
        rndrng_prvdr_type AS specialty,
        rndrng_prvdr_state_abrvtn AS state,
        total_services,
        estimated_medicare_payment,
        avg_payment_per_service,
        charge_to_payment_ratio,
        PERCENT_RANK() OVER (
            PARTITION BY rndrng_prvdr_type
            ORDER BY estimated_medicare_payment
        ) AS payment_percent_rank,
        PERCENT_RANK() OVER (
            PARTITION BY rndrng_prvdr_type
            ORDER BY charge_to_payment_ratio
        ) AS charge_variance_percent_rank
    FROM revenue_integrity.top_provider_summary
    WHERE total_services >= 100
)
SELECT
    rndrng_npi,
    specialty,
    state,
    ROUND(total_services, 0) AS total_services,
    ROUND(estimated_medicare_payment, 2) AS estimated_medicare_payment,
    ROUND(avg_payment_per_service, 2) AS avg_payment_per_service,
    ROUND(charge_to_payment_ratio, 2) AS charge_to_payment_ratio,
    ROUND(payment_percent_rank::numeric, 3) AS payment_percent_rank,
    ROUND(charge_variance_percent_rank::numeric, 3) AS charge_variance_percent_rank
FROM provider_rankings
WHERE payment_percent_rank >= 0.95
   OR charge_variance_percent_rank >= 0.95
ORDER BY payment_percent_rank DESC, charge_variance_percent_rank DESC
LIMIT 50;

-- Business question:
-- Which providers stand out compared with peers in the same specialty?

-- ============================================================
-- 9. State-Level Medicare Payment Comparison
-- ============================================================

SELECT
    rndrng_prvdr_state_abrvtn AS state,
    row_count,
    ROUND(total_services, 0) AS total_services,
    ROUND(estimated_medicare_payment, 2) AS estimated_medicare_payment,
    ROUND(avg_payment_per_service, 2) AS avg_payment_per_service,
    ROUND(charge_to_payment_ratio, 2) AS charge_to_payment_ratio
FROM revenue_integrity.state_summary
ORDER BY estimated_medicare_payment DESC
LIMIT 20;

-- Business question:
-- Which states represent the largest payment volume and charge/payment variance?

-- ============================================================
-- 10. Facility vs Office Comparison In Clean Sample
-- ============================================================

SELECT
    place_of_service_label,
    COUNT(*) AS provider_service_rows,
    ROUND(SUM(tot_srvcs), 0) AS total_services,
    ROUND(SUM(estimated_medicare_payment), 2) AS estimated_medicare_payment,
    ROUND(
        SUM(estimated_medicare_payment) / NULLIF(SUM(tot_srvcs), 0),
        2
    ) AS avg_payment_per_service,
    ROUND(
        SUM(estimated_submitted_charges) / NULLIF(SUM(estimated_medicare_payment), 0),
        2
    ) AS charge_to_payment_ratio
FROM revenue_integrity.cms_provider_service_clean_sample
GROUP BY place_of_service_label
ORDER BY estimated_medicare_payment DESC;

-- Business question:
-- How do payment and charge patterns differ by place of service?

-- ============================================================
-- 11. Audit Prioritization Matrix
-- ============================================================

WITH provider_risk AS (
    SELECT
        rndrng_npi,
        rndrng_prvdr_type AS specialty,
        rndrng_prvdr_state_abrvtn AS state,
        total_services,
        estimated_medicare_payment,
        charge_to_payment_ratio,
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
        END AS utilization_score
    FROM revenue_integrity.top_provider_summary
)
SELECT
    rndrng_npi,
    specialty,
    state,
    ROUND(total_services, 0) AS total_services,
    ROUND(estimated_medicare_payment, 2) AS estimated_medicare_payment,
    ROUND(charge_to_payment_ratio, 2) AS charge_to_payment_ratio,
    payment_exposure_score,
    charge_variance_score,
    utilization_score,
    payment_exposure_score + charge_variance_score + utilization_score AS total_risk_indicator_score
FROM provider_risk
ORDER BY total_risk_indicator_score DESC, estimated_medicare_payment DESC
LIMIT 50;

-- Business question:
-- Which providers should be prioritized for deeper review based on combined
-- payment exposure, charge variance, and utilization indicators?
