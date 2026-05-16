# Data Dictionary

This file will be completed during data exploration.

## Core Fields To Investigate

| Field | Plain-English Meaning | Why It Matters |
|---|---|---|
| `Rndrng_NPI` | Rendering provider National Provider Identifier | Used to group services and payments by provider |
| `Rndrng_Prvdr_Type` | Provider specialty/type | Enables peer comparison by specialty |
| `Rndrng_Prvdr_State_Abrvtn` | Provider state | Enables geographic analysis |
| `HCPCS_Cd` | Procedure or service code | Connects coding patterns to utilization and payment |
| `HCPCS_Desc` | Procedure or service description | Makes dashboards understandable |
| `Place_Of_Srvc` | Facility or non-facility setting | Important for reimbursement context |
| `Tot_Srvcs` | Total services billed | Core utilization metric |
| `Tot_Benes` | Total Medicare beneficiaries | Helps compare service volume to patient count |
| `Avg_Sbmtd_Chrg` | Average submitted charge | Used to compare provider charge patterns |
| `Avg_Mdcr_Alowd_Amt` | Average Medicare allowed amount | Represents allowed reimbursement basis |
| `Avg_Mdcr_Pymt_Amt` | Average Medicare payment amount | Core payment metric |
| `Avg_Mdcr_Stdzd_Amt` | Standardized payment amount | Helps compare payment after geographic adjustment |

## Derived Fields Planned

| Field | Formula Idea | Portfolio Use |
|---|---|---|
| `charge_to_payment_ratio` | submitted charge / Medicare payment | Payment variance indicator |
| `allowed_to_payment_gap` | allowed amount - payment amount | Patient/other responsibility proxy |
| `payment_per_service` | total estimated payment / total services | Reimbursement KPI |
| `service_volume_rank` | provider rank within specialty | Outlier detection |
| `specialty_payment_share` | specialty payment / total payment | Executive dashboard KPI |

