# KPI Definitions

## Step 7 Goal

Define the revenue integrity KPIs and risk indicators used in the project.

This step makes the project easier to explain to recruiters because it connects SQL fields to healthcare business meaning.

## Executive KPIs

| KPI | Definition | Why It Matters |
|---|---|---|
| Total Services | Sum of Medicare services in the dataset | Measures utilization volume |
| Estimated Submitted Charges | `total services * average submitted charge` | Shows billed charge exposure |
| Estimated Medicare Allowed | `total services * average Medicare allowed amount` | Shows Medicare allowed reimbursement basis |
| Estimated Medicare Payment | `total services * average Medicare payment amount` | Shows estimated Medicare payment exposure |
| Average Payment Per Service | `estimated Medicare payment / total services` | Normalizes payment across services |
| Charge-To-Payment Ratio | `estimated submitted charges / estimated Medicare payment` | Highlights charge/payment variance |
| Allowed-To-Payment Ratio | `estimated Medicare allowed / estimated Medicare payment` | Helps compare allowed and paid amounts |

## Risk Indicators

| Indicator | Logic | Interpretation |
|---|---|---|
| Payment Exposure Score | Higher score for providers with larger estimated Medicare payments | Helps prioritize high-dollar review areas |
| Charge Variance Score | Higher score for larger charge-to-payment ratios | Flags unusual submitted charge/payment variance |
| Utilization Score | Higher score for providers with larger service volume | Identifies high-volume billing patterns |
| Specialty Payment Outlier Flag | Provider is at or above the 95th percentile within specialty by payment | Supports peer-based provider comparison |
| Specialty Charge Variance Outlier Flag | Provider is at or above the 95th percentile within specialty by charge variance | Supports peer-based variance review |
| Total Risk Indicator Score | Sum of all risk indicator points | Creates an audit prioritization metric |
| Review Priority Tier | High, moderate, or baseline based on total risk score | Makes results easier for executives to interpret |

## Important Healthcare Framing

These KPIs do not prove fraud, abuse, incorrect coding, or overpayment.

They are designed to identify:

- reimbursement variation
- coding utilization patterns
- provider outlier candidates
- charge/payment variance
- areas for possible audit prioritization

## Portfolio Language

Suggested wording:

> Created revenue integrity KPIs and provider risk indicators using PostgreSQL, including charge-to-payment variance, estimated Medicare payment exposure, utilization intensity, specialty peer outlier flags, and review priority tiers.

## SQL Views Created

The SQL script below creates reusable views for analysis and Tableau:

```text
sql/04_kpi_and_risk_views.sql
```

Views:

| View | Purpose |
|---|---|
| `revenue_integrity.vw_executive_kpis` | Dashboard headline KPIs |
| `revenue_integrity.vw_specialty_kpis` | Specialty comparison |
| `revenue_integrity.vw_hcpcs_kpis` | HCPCS/service-level analysis |
| `revenue_integrity.vw_provider_risk_indicators` | Provider-level risk scoring |
| `revenue_integrity.vw_provider_risk_tiers` | Provider review priority tiers |
| `revenue_integrity.vw_state_kpis` | State-level comparison |

## Common Beginner Mistakes To Avoid

Do not compare raw payment totals without considering specialty context. Peer comparison is more defensible.

Do not treat high payment as inherently bad. High payment may reflect legitimate volume, specialty mix, or service complexity.

Do not describe the score as a fraud score. Use "risk indicator score" or "review priority score."

