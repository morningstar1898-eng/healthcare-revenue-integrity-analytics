# Healthcare Revenue Integrity Analytics Platform

## Project Objective

This beginner-friendly portfolio project analyzes Medicare provider utilization and payment data to identify reimbursement variation, coding utilization patterns, and provider-level outlier risk.

The project is designed to demonstrate a complete healthcare analytics workflow:

- Select and document a credible public healthcare dataset
- Explore and clean data with Python and pandas
- Load cleaned data into SQL
- Write SQL queries for revenue integrity insights
- Create Tableau-ready extracts and dashboard KPIs
- Communicate findings in a recruiter-friendly case study

## Dataset

Primary dataset:

**CMS Medicare Physician & Other Practitioners - by Provider and Service**

This dataset includes Medicare provider and service-level utilization, submitted charges, allowed amounts, payment amounts, HCPCS codes, provider specialty, geography, and place of service.

Dataset landing page:
https://catalog.data.gov/dataset/medicare-physician-other-practitioners-by-provider-and-service

Recommended file for this project:

`MUP_PHY_R25_P05_V20_D23_Prov_Svc.csv`

## Business Questions

1. Which specialties generate the highest Medicare service volume and payment amounts?
2. Which HCPCS services show the largest submitted-charge-to-payment variance?
3. Which providers appear as outliers compared with peers in the same specialty?
4. Which specialties or services show high concentration of utilization?
5. Which revenue integrity risk indicators should be monitored by leadership?

## Project Structure

```text
healthcare-revenue-integrity-analytics-platform/
  data/
    raw/          # Original CMS files downloaded from source
    interim/      # Temporary working files created during cleaning
    processed/    # Cleaned CSV files and Tableau extracts
  docs/
    data_dictionary.md
    data_sources.md
    portfolio_positioning.md
  notebooks/
    01_data_exploration_and_cleaning.ipynb
  scripts/
  sql/
    01_schema.sql
    03_analysis_queries.sql
    04_kpi_and_risk_views.sql
  tableau/
    dashboard_plan.md
  outputs/
  README.md
  environment.yml
```

## Portfolio Positioning

This project connects medical coding audit experience with analytics by using coding, reimbursement, and compliance logic to create measurable risk indicators. The goal is not to prove fraud or improper billing, but to identify patterns that may deserve audit review, documentation review, or revenue cycle monitoring.
