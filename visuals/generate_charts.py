"""
Generate professional dark-theme charts for Healthcare Revenue Integrity Analytics Platform.
Uses processed CMS Medicare data to visualize revenue, risk, geographic, and HCPCS insights.
"""

import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker
import os

# Paths
BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA = os.path.join(BASE, "data", "processed")
OUT = os.path.dirname(os.path.abspath(__file__))

# Style
plt.style.use("dark_background")
COLORS = ["#00B4D8", "#0077B6", "#48CAE4", "#90E0EF", "#CAF0F8",
           "#FF6B6B", "#FFA07A", "#FFD93D", "#6BCB77", "#4D96FF"]
ACCENT = "#00B4D8"
WARN = "#FF6B6B"

def fmt_millions(x, _):
    return f"${x/1e6:,.0f}M"

def fmt_billions(x, _):
    return f"${x/1e9:,.1f}B"


# ── Chart 1: Top 15 Specialties by Medicare Payment ──────────────────────────
def chart_revenue_by_specialty():
    df = pd.read_csv(os.path.join(DATA, "specialty_summary.csv"))
    df = df.nlargest(15, "estimated_medicare_payment").sort_values("estimated_medicare_payment")

    fig, ax = plt.subplots(figsize=(12, 7))
    bars = ax.barh(df["rndrng_prvdr_type"], df["estimated_medicare_payment"],
                   color=COLORS[:15], edgecolor="none", height=0.7)

    ax.xaxis.set_major_formatter(mticker.FuncFormatter(fmt_billions))
    ax.set_xlabel("Total Medicare Payment", fontsize=11, color="#CAF0F8")
    ax.set_title("Top 15 Specialties by Medicare Payment", fontsize=15,
                 fontweight="bold", color="white", pad=15)
    ax.tick_params(colors="#CAF0F8", labelsize=9)
    ax.spines[["top", "right"]].set_visible(False)
    ax.spines[["bottom", "left"]].set_color("#444")

    # Annotate top 3
    for bar in bars[-3:]:
        w = bar.get_width()
        ax.text(w + 1e8, bar.get_y() + bar.get_height()/2,
                f"${w/1e9:.1f}B", va="center", fontsize=9, color="white")

    fig.tight_layout()
    fig.savefig(os.path.join(OUT, "revenue_by_specialty.png"), dpi=200,
                facecolor=fig.get_facecolor(), bbox_inches="tight")
    plt.close(fig)
    print("  -> revenue_by_specialty.png")


# ── Chart 2: Payment Variance — Charge-to-Payment Ratio by Specialty ────────
def chart_payment_variance():
    df = pd.read_csv(os.path.join(DATA, "specialty_summary.csv"))
    # Filter to specialties with meaningful volume and high variance
    df = df[df["total_services"] > 1e6]
    df = df.nlargest(20, "charge_to_payment_ratio").sort_values("charge_to_payment_ratio")

    fig, ax = plt.subplots(figsize=(12, 7))
    colors = [WARN if r > 5 else ACCENT for r in df["charge_to_payment_ratio"]]
    bars = ax.barh(df["rndrng_prvdr_type"], df["charge_to_payment_ratio"],
                   color=colors, edgecolor="none", height=0.7)

    ax.axvline(x=df["charge_to_payment_ratio"].median(), color="#FFD93D",
               linestyle="--", linewidth=1, alpha=0.7)
    ax.text(df["charge_to_payment_ratio"].median() + 0.1,
            len(df) - 0.5, "Median", color="#FFD93D", fontsize=9)

    ax.set_xlabel("Charge-to-Payment Ratio", fontsize=11, color="#CAF0F8")
    ax.set_title("Revenue Integrity Risk: Charge-to-Payment Ratio by Specialty",
                 fontsize=14, fontweight="bold", color="white", pad=15)
    ax.tick_params(colors="#CAF0F8", labelsize=9)
    ax.spines[["top", "right"]].set_visible(False)
    ax.spines[["bottom", "left"]].set_color("#444")

    # Annotate high-risk
    for bar in bars:
        w = bar.get_width()
        if w > 5:
            ax.text(w + 0.05, bar.get_y() + bar.get_height()/2,
                    f"{w:.1f}x  HIGH RISK", va="center", fontsize=8,
                    color=WARN, fontweight="bold")

    fig.tight_layout()
    fig.savefig(os.path.join(OUT, "payment_variance_risk.png"), dpi=200,
                facecolor=fig.get_facecolor(), bbox_inches="tight")
    plt.close(fig)
    print("  -> payment_variance_risk.png")


# ── Chart 3: Top 15 States by Medicare Payment ──────────────────────────────
def chart_geographic_distribution():
    df = pd.read_csv(os.path.join(DATA, "state_summary.csv"))
    df = df.nlargest(15, "estimated_medicare_payment").sort_values("estimated_medicare_payment", ascending=False)

    fig, ax = plt.subplots(figsize=(12, 6))
    bars = ax.bar(df["rndrng_prvdr_state_abrvtn"], df["estimated_medicare_payment"],
                  color=COLORS[:15], edgecolor="none", width=0.65)

    ax.yaxis.set_major_formatter(mticker.FuncFormatter(fmt_billions))
    ax.set_ylabel("Total Medicare Payment", fontsize=11, color="#CAF0F8")
    ax.set_xlabel("State", fontsize=11, color="#CAF0F8")
    ax.set_title("Top 15 States by Medicare Payment Volume",
                 fontsize=15, fontweight="bold", color="white", pad=15)
    ax.tick_params(colors="#CAF0F8", labelsize=10)
    ax.spines[["top", "right"]].set_visible(False)
    ax.spines[["bottom", "left"]].set_color("#444")

    for bar in bars[:3]:
        h = bar.get_height()
        ax.text(bar.get_x() + bar.get_width()/2, h + 1e8,
                f"${h/1e9:.1f}B", ha="center", fontsize=9, color="white")

    fig.tight_layout()
    fig.savefig(os.path.join(OUT, "geographic_payment_distribution.png"), dpi=200,
                facecolor=fig.get_facecolor(), bbox_inches="tight")
    plt.close(fig)
    print("  -> geographic_payment_distribution.png")


# ── Chart 4: Top 15 HCPCS Codes by Service Volume ───────────────────────────
def chart_top_hcpcs():
    df = pd.read_csv(os.path.join(DATA, "top_hcpcs_summary.csv"))
    df = df.nlargest(15, "total_services").sort_values("total_services")

    # Shorten descriptions
    df["label"] = df["hcpcs_cd"] + " — " + df["hcpcs_desc"].str[:45]

    fig, ax = plt.subplots(figsize=(12, 7))
    bars = ax.barh(df["label"], df["total_services"],
                   color=COLORS[:15], edgecolor="none", height=0.7)

    ax.xaxis.set_major_formatter(mticker.FuncFormatter(lambda x, _: f"{x/1e6:,.0f}M"))
    ax.set_xlabel("Total Services (Millions)", fontsize=11, color="#CAF0F8")
    ax.set_title("Top 15 HCPCS Codes by Service Volume",
                 fontsize=15, fontweight="bold", color="white", pad=15)
    ax.tick_params(colors="#CAF0F8", labelsize=8)
    ax.spines[["top", "right"]].set_visible(False)
    ax.spines[["bottom", "left"]].set_color("#444")

    for bar in bars[-3:]:
        w = bar.get_width()
        ax.text(w + 5e5, bar.get_y() + bar.get_height()/2,
                f"{w/1e6:,.1f}M", va="center", fontsize=8, color="white")

    fig.tight_layout()
    fig.savefig(os.path.join(OUT, "top_hcpcs_by_volume.png"), dpi=200,
                facecolor=fig.get_facecolor(), bbox_inches="tight")
    plt.close(fig)
    print("  -> top_hcpcs_by_volume.png")


if __name__ == "__main__":
    print("Generating charts...")
    chart_revenue_by_specialty()
    chart_payment_variance()
    chart_geographic_distribution()
    chart_top_hcpcs()
    print("Done. All charts saved to visuals/")
