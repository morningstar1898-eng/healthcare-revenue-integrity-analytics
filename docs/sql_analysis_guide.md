# SQL Analysis Guide

## Step 6 Goal

Use PostgreSQL to answer revenue integrity business questions from the cleaned CMS Medicare provider payment data.

The SQL queries are stored here:

```text
sql/03_analysis_queries.sql
```

## What This Step Accomplishes

This step turns cleaned data into business insight. Instead of only showing that the data can be cleaned, the project now shows that SQL can be used to identify:

- high-payment specialties
- high-volume HCPCS services
- charge-to-payment variance
- provider outlier candidates
- state-level reimbursement patterns
- audit prioritization indicators

## Why This Matters In Healthcare Analytics

Revenue integrity teams need to decide where limited review time should go. SQL helps summarize large healthcare datasets into targeted review lists and dashboard-ready KPIs.

The goal is not to prove incorrect billing. The goal is to identify patterns that may deserve review.

Use careful language:

- revenue integrity risk indicator
- reimbursement variation
- provider outlier candidate
- audit prioritization
- coding utilization pattern

Avoid saying:

- fraud
- abuse
- confirmed overpayment
- improper billing

## How To Run The Queries

1. Open pgAdmin.
2. Click the `healthcare_revenue_integrity` database.
3. Open **Query Tool**.
4. Open:

```text
C:\Users\morni\OneDrive\Documents\New project\healthcare-revenue-integrity-analytics-platform\sql\03_analysis_queries.sql
```

5. Highlight one query at a time.
6. Click **Execute**.
7. Review the output in the **Data Output** panel.

## Recommended Query Order

Run the queries in this order:

1. Load Validation
2. Executive KPI Summary
3. Top Specialties By Estimated Medicare Payment
4. Specialties With Highest Charge-To-Payment Ratio
5. Top HCPCS Codes By Estimated Medicare Payment
6. HCPCS Codes With High Charge-To-Payment Variance
7. Provider Outlier Candidates By Payment Volume
8. Provider Outlier Candidates Within Specialty
9. State-Level Medicare Payment Comparison
10. Facility vs Office Comparison
11. Audit Prioritization Matrix

## How This Appears In The Portfolio

Suggested portfolio wording:

> Used PostgreSQL to analyze cleaned CMS Medicare provider payment data, creating revenue integrity queries for specialty payment trends, HCPCS coding utilization, charge-to-payment variance, provider outlier detection, and audit prioritization.

## Next SQL File

After running the analysis queries, run:

```text
sql/04_kpi_and_risk_views.sql
```

This creates reusable KPI and risk indicator views for Tableau and portfolio reporting.

## Common Beginner Mistakes To Avoid

Do not run the entire SQL file at once while learning. Highlight and run one query at a time.

Do not interpret outliers as wrongdoing. An outlier is a review signal, not a conclusion.

Do not compare providers across all specialties without context. A cardiologist, pathologist, ambulance provider, and physical therapist have different payment and utilization patterns. Peer comparison by specialty is more defensible.

Do not forget to save useful query outputs. Results from these queries will later support the Tableau dashboard and GitHub case study.
