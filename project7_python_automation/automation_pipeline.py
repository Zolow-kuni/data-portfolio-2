"""
Project 7 — Python Automation Pipeline
Dataset: Retail Sales Dataset (1,000 rows)
Run: python automation_pipeline.py
"""

import os
import logging
import datetime
import pandas as pd
from report_generator import generate_excel_report

# ── Paths ──────────────────────────────────────────────────────────────────────
DATA_PATH = r"C:\Users\lalit\Downloads\retail_sales_dataset\retail_sales_dataset.csv"
OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "outputs")
os.makedirs(OUTPUT_DIR, exist_ok=True)

LOG_PATH = os.path.join(OUTPUT_DIR, "pipeline_log.txt")

# ── Logging setup ──────────────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s  %(levelname)-8s  %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
    handlers=[
        logging.FileHandler(LOG_PATH, mode="w"),
        logging.StreamHandler(),
    ],
)
log = logging.getLogger(__name__)


# ── Step 1: Ingest ─────────────────────────────────────────────────────────────
def ingest() -> pd.DataFrame:
    log.info("STEP 1 — INGEST")
    df = pd.read_csv(DATA_PATH)
    log.info(f"  Loaded {len(df):,} rows × {len(df.columns)} columns from {DATA_PATH}")
    return df


# ── Step 2: Clean ──────────────────────────────────────────────────────────────
def clean(df: pd.DataFrame) -> tuple[pd.DataFrame, dict]:
    log.info("STEP 2 — CLEAN")
    report = {
        "total_ingested": len(df),
        "dropped": [],
        "flagged": [],
    }

    # 2a. Convert Date to datetime
    before = df["Date"].dtype
    df["Date"] = pd.to_datetime(df["Date"], errors="coerce")
    nat_count = df["Date"].isna().sum()
    if nat_count:
        df = df.dropna(subset=["Date"])
        report["dropped"].append({"reason": "unparseable Date", "count": nat_count})
        log.info(f"  Dropped {nat_count} rows with unparseable Date")
    log.info(f"  Date converted: {before} -> datetime64")

    # 2b. Remove duplicate Transaction IDs
    dupes = df.duplicated(subset=["Transaction ID"]).sum()
    if dupes:
        df = df.drop_duplicates(subset=["Transaction ID"])
        report["dropped"].append({"reason": "duplicate Transaction ID", "count": dupes})
        log.info(f"  Dropped {dupes} duplicate Transaction ID rows")
    else:
        log.info("  No duplicate Transaction IDs found")

    # 2c. Validate Total Amount = Quantity × Price per Unit
    df["_expected_total"] = df["Quantity"] * df["Price per Unit"]
    df["calculation_error"] = ~df["Total Amount"].round(2).eq(df["_expected_total"].round(2))
    calc_errors = df["calculation_error"].sum()
    report["flagged"].append({"reason": "Total Amount != Quantity × Price per Unit", "count": int(calc_errors)})
    log.info(f"  Flagged {calc_errors} rows with calculation mismatch (Total Amount != Qty × Price)")
    df = df.drop(columns=["_expected_total"])

    # 2d. Age validation (18–100)
    df["age_outlier"] = ~df["Age"].between(18, 100)
    age_flags = df["age_outlier"].sum()
    report["flagged"].append({"reason": "Age outside 18–100", "count": int(age_flags)})
    log.info(f"  Flagged {age_flags} rows with Age outside 18–100")

    # 2e. Quantity must be > 0
    df["quantity_error"] = df["Quantity"] <= 0
    qty_flags = df["quantity_error"].sum()
    report["flagged"].append({"reason": "Quantity <= 0", "count": int(qty_flags)})
    log.info(f"  Flagged {qty_flags} rows with Quantity <= 0")

    # 2f. Derived columns
    df["month"]       = df["Date"].dt.month
    df["year"]        = df["Date"].dt.year
    df["day_of_week"] = df["Date"].dt.day_name()

    def age_group(age):
        if age <= 30:   return "18-30"
        elif age <= 45: return "31-45"
        elif age <= 60: return "46-60"
        else:           return "60+"

    df["age_group"] = df["Age"].apply(age_group)
    log.info("  Added derived columns: month, year, day_of_week, age_group")

    report["final_clean_count"] = len(df)
    total_dropped = sum(d["count"] for d in report["dropped"])
    report["data_quality_score"] = round((report["final_clean_count"] / report["total_ingested"]) * 100, 2)

    log.info(f"  Clean complete — {len(df):,} rows remaining (quality score: {report['data_quality_score']}%)")
    return df, report


# ── Step 3: Validate report ────────────────────────────────────────────────────
def print_validation_summary(report: dict):
    log.info("STEP 3 — VALIDATION REPORT")
    log.info(f"  Total rows ingested  : {report['total_ingested']:,}")
    for d in report["dropped"]:
        log.info(f"  Rows dropped [{d['reason']}]: {d['count']:,}")
    for f in report["flagged"]:
        log.info(f"  Rows flagged [{f['reason']}]: {f['count']:,}")
    log.info(f"  Final clean rows     : {report['final_clean_count']:,}")
    log.info(f"  Data quality score   : {report['data_quality_score']}%")


# ── Step 4: Analyse ────────────────────────────────────────────────────────────
def analyse(df: pd.DataFrame) -> dict:
    log.info("STEP 4 — ANALYSIS")

    results = {}

    # Revenue by Product Category
    rev_cat = (
        df.groupby("Product Category")["Total Amount"]
        .sum()
        .reset_index()
        .rename(columns={"Total Amount": "Revenue"})
        .sort_values("Revenue", ascending=False)
    )
    results["revenue_by_category"] = rev_cat
    log.info(f"  Revenue by category:\n{rev_cat.to_string(index=False)}")

    # Monthly revenue with MoM growth %
    monthly = (
        df.groupby(["year", "month"])["Total Amount"]
        .sum()
        .reset_index()
        .rename(columns={"Total Amount": "Revenue"})
        .sort_values(["year", "month"])
    )
    monthly["MoM_Growth_%"] = monthly["Revenue"].pct_change().mul(100).round(2)
    results["monthly_revenue"] = monthly
    log.info(f"  Monthly revenue computed for {len(monthly)} months")

    # Top 10 customers by total spend
    top_customers = (
        df.groupby("Customer ID")["Total Amount"]
        .sum()
        .reset_index()
        .rename(columns={"Total Amount": "Total Spend"})
        .sort_values("Total Spend", ascending=False)
        .head(10)
    )
    results["top_customers"] = top_customers
    log.info(f"  Top customer: {top_customers.iloc[0]['Customer ID']} -- {top_customers.iloc[0]['Total Spend']:,.2f}")

    # Gender split per category
    gender_cat = (
        df.groupby(["Product Category", "Gender"])["Total Amount"]
        .sum()
        .reset_index()
        .rename(columns={"Total Amount": "Revenue"})
        .sort_values(["Product Category", "Revenue"], ascending=[True, False])
    )
    results["gender_by_category"] = gender_cat
    log.info(f"  Gender × category split computed")

    # Best day of week by revenue
    dow_rev = (
        df.groupby("day_of_week")["Total Amount"]
        .sum()
        .reset_index()
        .rename(columns={"Total Amount": "Revenue"})
        .sort_values("Revenue", ascending=False)
    )
    results["revenue_by_dow"] = dow_rev
    log.info(f"  Best day: {dow_rev.iloc[0]['day_of_week']} -- {dow_rev.iloc[0]['Revenue']:,.2f}")

    # Age group spending patterns
    age_spend = (
        df.groupby("age_group").agg(
            Transactions=("Transaction ID", "count"),
            Revenue=("Total Amount", "sum"),
            Avg_Order=("Total Amount", "mean"),
        )
        .reset_index()
        .sort_values("Revenue", ascending=False)
    )
    age_spend["Avg_Order"] = age_spend["Avg_Order"].round(2)
    results["age_group_spending"] = age_spend
    log.info(f"  Age group spending computed")

    return results


# ── Main ───────────────────────────────────────────────────────────────────────
def main():
    log.info("=" * 60)
    log.info("RETAIL SALES AUTOMATION PIPELINE")
    log.info(f"Started: {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    log.info("=" * 60)

    df = ingest()
    df, validation_report = clean(df)
    print_validation_summary(validation_report)
    analysis = analyse(df)

    log.info("STEP 5 — GENERATE EXCEL REPORT")
    report_path = generate_excel_report(df, validation_report, analysis, OUTPUT_DIR)
    log.info(f"  Report saved: {report_path}")

    log.info("=" * 60)
    log.info("PIPELINE COMPLETE")
    log.info(f"  Output folder : {OUTPUT_DIR}")
    log.info(f"  Log file      : {LOG_PATH}")
    log.info("=" * 60)


if __name__ == "__main__":
    main()
