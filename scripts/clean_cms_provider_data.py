from pathlib import Path

import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
RAW_FILE = PROJECT_ROOT / "data" / "raw" / "MUP_PHY_R25_P05_V20_D23_Prov_Svc.csv"
PROCESSED_DIR = PROJECT_ROOT / "data" / "processed"

CHUNK_SIZE = 250_000
SAMPLE_ROWS = 250_000

USE_COLUMNS = [
    "Rndrng_NPI",
    "Rndrng_Prvdr_Last_Org_Name",
    "Rndrng_Prvdr_First_Name",
    "Rndrng_Prvdr_Ent_Cd",
    "Rndrng_Prvdr_City",
    "Rndrng_Prvdr_State_Abrvtn",
    "Rndrng_Prvdr_Cntry",
    "Rndrng_Prvdr_Type",
    "Rndrng_Prvdr_Mdcr_Prtcptg_Ind",
    "HCPCS_Cd",
    "HCPCS_Desc",
    "HCPCS_Drug_Ind",
    "Place_Of_Srvc",
    "Tot_Benes",
    "Tot_Srvcs",
    "Tot_Bene_Day_Srvcs",
    "Avg_Sbmtd_Chrg",
    "Avg_Mdcr_Alowd_Amt",
    "Avg_Mdcr_Pymt_Amt",
    "Avg_Mdcr_Stdzd_Amt",
]

TEXT_COLUMNS = [
    "Rndrng_Prvdr_Last_Org_Name",
    "Rndrng_Prvdr_First_Name",
    "Rndrng_Prvdr_Ent_Cd",
    "Rndrng_Prvdr_City",
    "Rndrng_Prvdr_State_Abrvtn",
    "Rndrng_Prvdr_Cntry",
    "Rndrng_Prvdr_Type",
    "Rndrng_Prvdr_Mdcr_Prtcptg_Ind",
    "HCPCS_Cd",
    "HCPCS_Desc",
    "HCPCS_Drug_Ind",
    "Place_Of_Srvc",
]

NUMERIC_COLUMNS = [
    "Tot_Benes",
    "Tot_Srvcs",
    "Tot_Bene_Day_Srvcs",
    "Avg_Sbmtd_Chrg",
    "Avg_Mdcr_Alowd_Amt",
    "Avg_Mdcr_Pymt_Amt",
    "Avg_Mdcr_Stdzd_Amt",
]


def clean_chunk(chunk: pd.DataFrame) -> pd.DataFrame:
    """Clean one chunk of raw CMS rows and add revenue integrity metrics."""
    cleaned = chunk.copy()

    cleaned.columns = [col.lower() for col in cleaned.columns]

    for col in [c.lower() for c in TEXT_COLUMNS]:
        cleaned[col] = cleaned[col].fillna("Unknown").astype(str).str.strip()

    for col in [c.lower() for c in NUMERIC_COLUMNS]:
        cleaned[col] = pd.to_numeric(cleaned[col], errors="coerce").fillna(0)

    cleaned["place_of_service_label"] = cleaned["place_of_srvc"].map(
        {"F": "Facility", "O": "Office"}
    ).fillna("Other/Unknown")

    cleaned["provider_entity_label"] = cleaned["rndrng_prvdr_ent_cd"].map(
        {"I": "Individual", "O": "Organization"}
    ).fillna("Unknown")

    cleaned["estimated_submitted_charges"] = (
        cleaned["tot_srvcs"] * cleaned["avg_sbmtd_chrg"]
    )
    cleaned["estimated_medicare_allowed"] = (
        cleaned["tot_srvcs"] * cleaned["avg_mdcr_alowd_amt"]
    )
    cleaned["estimated_medicare_payment"] = (
        cleaned["tot_srvcs"] * cleaned["avg_mdcr_pymt_amt"]
    )
    cleaned["estimated_standardized_payment"] = (
        cleaned["tot_srvcs"] * cleaned["avg_mdcr_stdzd_amt"]
    )

    cleaned["charge_to_payment_ratio"] = (
        cleaned["avg_sbmtd_chrg"] / cleaned["avg_mdcr_pymt_amt"]
    ).replace([float("inf"), -float("inf")], 0).fillna(0)

    cleaned["allowed_to_payment_gap"] = (
        cleaned["avg_mdcr_alowd_amt"] - cleaned["avg_mdcr_pymt_amt"]
    )

    cleaned["services_per_beneficiary"] = (
        cleaned["tot_srvcs"] / cleaned["tot_benes"]
    ).replace([float("inf"), -float("inf")], 0).fillna(0)

    cleaned["high_charge_variance_flag"] = cleaned["charge_to_payment_ratio"] >= 5
    cleaned["high_service_intensity_flag"] = cleaned["services_per_beneficiary"] >= 10

    return cleaned


def summarize_group(cleaned: pd.DataFrame, group_cols: list[str]) -> pd.DataFrame:
    summary = (
        cleaned.groupby(group_cols, dropna=False)
        .agg(
            row_count=("rndrng_npi", "size"),
            total_beneficiaries=("tot_benes", "sum"),
            total_services=("tot_srvcs", "sum"),
            estimated_submitted_charges=("estimated_submitted_charges", "sum"),
            estimated_medicare_allowed=("estimated_medicare_allowed", "sum"),
            estimated_medicare_payment=("estimated_medicare_payment", "sum"),
            estimated_standardized_payment=("estimated_standardized_payment", "sum"),
        )
        .reset_index()
    )
    return summary


def finalize_summary(summary: pd.DataFrame) -> pd.DataFrame:
    summary["avg_payment_per_service"] = (
        summary["estimated_medicare_payment"] / summary["total_services"]
    ).fillna(0)
    summary["charge_to_payment_ratio"] = (
        summary["estimated_submitted_charges"] / summary["estimated_medicare_payment"]
    ).replace([float("inf"), -float("inf")], 0).fillna(0)
    summary["allowed_to_payment_ratio"] = (
        summary["estimated_medicare_allowed"] / summary["estimated_medicare_payment"]
    ).replace([float("inf"), -float("inf")], 0).fillna(0)
    return summary.sort_values("estimated_medicare_payment", ascending=False)


def combine_summaries(summaries: list[pd.DataFrame], group_cols: list[str]) -> pd.DataFrame:
    combined = pd.concat(summaries, ignore_index=True)
    rolled_up = (
        combined.groupby(group_cols, dropna=False)
        .agg(
            row_count=("row_count", "sum"),
            total_beneficiaries=("total_beneficiaries", "sum"),
            total_services=("total_services", "sum"),
            estimated_submitted_charges=("estimated_submitted_charges", "sum"),
            estimated_medicare_allowed=("estimated_medicare_allowed", "sum"),
            estimated_medicare_payment=("estimated_medicare_payment", "sum"),
            estimated_standardized_payment=("estimated_standardized_payment", "sum"),
        )
        .reset_index()
    )
    return finalize_summary(rolled_up)


def main() -> None:
    if not RAW_FILE.exists():
        raise FileNotFoundError(f"Raw file not found: {RAW_FILE}")

    PROCESSED_DIR.mkdir(parents=True, exist_ok=True)

    specialty_summaries = []
    hcpcs_summaries = []
    state_summaries = []
    provider_summaries = []
    sample_written = 0
    total_rows = 0

    reader = pd.read_csv(
        RAW_FILE,
        usecols=USE_COLUMNS,
        chunksize=CHUNK_SIZE,
        low_memory=False,
    )

    for chunk_number, chunk in enumerate(reader, start=1):
        cleaned = clean_chunk(chunk)
        total_rows += len(cleaned)

        specialty_summaries.append(summarize_group(cleaned, ["rndrng_prvdr_type"]))
        hcpcs_summaries.append(summarize_group(cleaned, ["hcpcs_cd", "hcpcs_desc"]))
        state_summaries.append(summarize_group(cleaned, ["rndrng_prvdr_state_abrvtn"]))
        provider_summaries.append(
            summarize_group(
                cleaned,
                ["rndrng_npi", "rndrng_prvdr_type", "rndrng_prvdr_state_abrvtn"],
            )
        )

        if sample_written < SAMPLE_ROWS:
            remaining = SAMPLE_ROWS - sample_written
            sample = cleaned.head(remaining)
            sample.to_csv(
                PROCESSED_DIR / "cms_provider_service_clean_sample.csv",
                mode="w" if sample_written == 0 else "a",
                header=sample_written == 0,
                index=False,
            )
            sample_written += len(sample)

        print(f"Processed chunk {chunk_number}: {total_rows:,} rows")

    specialty_summary = combine_summaries(specialty_summaries, ["rndrng_prvdr_type"])
    hcpcs_summary = combine_summaries(hcpcs_summaries, ["hcpcs_cd", "hcpcs_desc"])
    state_summary = combine_summaries(state_summaries, ["rndrng_prvdr_state_abrvtn"])
    provider_summary = combine_summaries(
        provider_summaries,
        ["rndrng_npi", "rndrng_prvdr_type", "rndrng_prvdr_state_abrvtn"],
    )

    specialty_summary.to_csv(PROCESSED_DIR / "specialty_summary.csv", index=False)
    hcpcs_summary.head(5000).to_csv(PROCESSED_DIR / "top_hcpcs_summary.csv", index=False)
    state_summary.to_csv(PROCESSED_DIR / "state_summary.csv", index=False)
    provider_summary.head(10000).to_csv(
        PROCESSED_DIR / "top_provider_summary.csv", index=False
    )

    print("Cleaning complete.")
    print(f"Total rows processed: {total_rows:,}")
    print(f"Clean sample rows exported: {sample_written:,}")


if __name__ == "__main__":
    main()
