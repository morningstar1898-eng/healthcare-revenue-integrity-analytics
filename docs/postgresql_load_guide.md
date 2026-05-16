# PostgreSQL Load Guide

## Step 5 Goal

Load the cleaned CMS processed CSV files into PostgreSQL so SQL can be used for revenue integrity analysis.

## Recommended Tool

Use PostgreSQL with pgAdmin.

PostgreSQL is a strong choice for this portfolio because it is widely used in analytics teams and supports clear, professional SQL workflows.

## Create The Database

1. Open pgAdmin.
2. In the left sidebar, right-click **Databases**.
3. Click **Create**.
4. Click **Database...**.
5. Database name:

```text
healthcare_revenue_integrity
```

6. Click **Save**.

## Run The Schema Script

1. Click the new `healthcare_revenue_integrity` database.
2. Click **Query Tool**.
3. Open this file:

```text
sql/01_schema.sql
```

4. Copy the full SQL into pgAdmin.
5. Click the **Execute/Run** button.

This creates the `revenue_integrity` schema and five tables.

## Import The CSV Files

Import each file into its matching table.

### 1. Clean Provider-Service Sample

Table:

```text
revenue_integrity.cms_provider_service_clean_sample
```

CSV:

```text
data/processed/cms_provider_service_clean_sample.csv
```

### 2. Specialty Summary

Table:

```text
revenue_integrity.specialty_summary
```

CSV:

```text
data/processed/specialty_summary.csv
```

### 3. State Summary

Table:

```text
revenue_integrity.state_summary
```

CSV:

```text
data/processed/state_summary.csv
```

### 4. HCPCS Summary

Table:

```text
revenue_integrity.top_hcpcs_summary
```

CSV:

```text
data/processed/top_hcpcs_summary.csv
```

### 5. Provider Summary

Table:

```text
revenue_integrity.top_provider_summary
```

CSV:

```text
data/processed/top_provider_summary.csv
```

## pgAdmin Import Clicks

For each table:

1. In pgAdmin, expand:

```text
Databases > healthcare_revenue_integrity > Schemas > revenue_integrity > Tables
```

2. Right-click the table.
3. Click **Import/Export Data...**.
4. Choose **Import**.
5. Select the matching CSV file.
6. Set **Format** to `csv`.
7. Turn **Header** on.
8. Set **Delimiter** to comma.
9. Click **OK**.

## Quality Check Queries

After importing, run:

```sql
SELECT COUNT(*) FROM revenue_integrity.cms_provider_service_clean_sample;
SELECT COUNT(*) FROM revenue_integrity.specialty_summary;
SELECT COUNT(*) FROM revenue_integrity.state_summary;
SELECT COUNT(*) FROM revenue_integrity.top_hcpcs_summary;
SELECT COUNT(*) FROM revenue_integrity.top_provider_summary;
```

Expected row counts:

| Table | Expected Rows |
|---|---:|
| `cms_provider_service_clean_sample` | 250,000 |
| `specialty_summary` | 104 |
| `state_summary` | 62 |
| `top_hcpcs_summary` | 5,000 |
| `top_provider_summary` | 10,000 |

## Beginner Mistakes To Avoid

Do not import the 3 GB raw CMS file into PostgreSQL yet. This project starts with cleaned, focused files so you can learn the workflow without overwhelming your computer.

Make sure **Header** is turned on during import. If it is off, PostgreSQL may try to load column names as data.

Use the matching table for each CSV. The column order must match the table definition.

