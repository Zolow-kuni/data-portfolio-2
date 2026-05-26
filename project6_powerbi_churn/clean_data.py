"""
clean_data.py — Clean Bank Customer Churn dataset for Power BI
Run: python clean_data.py
"""

import os
import pandas as pd

DATA_PATH   = r"C:\Users\lalit\Downloads\bank_customer_churn\Bank Customer Churn Prediction.csv"
OUTPUT_DIR  = os.path.join(os.path.dirname(__file__), "outputs")
OUTPUT_PATH = os.path.join(os.path.dirname(__file__), "bank_churn_cleaned.csv")
os.makedirs(OUTPUT_DIR, exist_ok=True)


def clean():
    print("Reading dataset ...")
    df = pd.read_csv(DATA_PATH)
    print(f"  Loaded {len(df):,} rows x {len(df.columns)} columns")

    # ── Validation ──────────────────────────────────────────────────────────────
    null_counts = df.isnull().sum()
    print(f"\nNull check:\n{null_counts[null_counts > 0].to_string() if null_counts.any() else '  Zero nulls found — dataset is clean'}")

    # Check and remove duplicate customer_id rows
    dupes = df.duplicated(subset=["customer_id"]).sum()
    if dupes:
        df = df.drop_duplicates(subset=["customer_id"])
        print(f"  Removed {dupes} duplicate customer_id rows")
    else:
        print(f"\nDuplicate check: No duplicate customer_id rows found")

    # ── Transformations ─────────────────────────────────────────────────────────

    # 1. credit_card: 0/1 → "No"/"Yes"
    df["credit_card"] = df["credit_card"].map({0: "No", 1: "Yes"})
    print("\nTransformations:")
    print("  credit_card     : 0/1 -> No/Yes")

    # 2. active_member: 0/1 → "Inactive"/"Active"
    df["active_member"] = df["active_member"].map({0: "Inactive", 1: "Active"})
    print("  active_member   : 0/1 -> Inactive/Active")

    # 3. churn: 0/1 → "Retained"/"Churned"
    df["churn"] = df["churn"].map({0: "Retained", 1: "Churned"})
    print("  churn           : 0/1 -> Retained/Churned")

    # 4. age_group
    def age_group(age):
        if age <= 30:   return "18-30"
        elif age <= 45: return "31-45"
        elif age <= 60: return "46-60"
        else:           return "60+"

    df["age_group"] = df["age"].apply(age_group)
    print("  age_group       : bucketed into 18-30 / 31-45 / 46-60 / 60+")

    # 5. credit_score_band
    def credit_band(score):
        if score < 580:   return "Poor (300-579)"
        elif score < 670: return "Fair (580-669)"
        elif score < 740: return "Good (670-739)"
        elif score < 800: return "Very Good (740-799)"
        else:             return "Exceptional (800+)"

    df["credit_score_band"] = df["credit_score"].apply(credit_band)
    print("  credit_score_band: Poor / Fair / Good / Very Good / Exceptional")

    # 6. balance_segment
    def balance_seg(bal):
        if bal == 0:          return "Zero Balance"
        elif bal < 50_000:    return "Low (<50K)"
        elif bal <= 100_000:  return "Medium (50K-100K)"
        else:                 return "High (>100K)"

    df["balance_segment"] = df["balance"].apply(balance_seg)
    print("  balance_segment : Zero Balance / Low / Medium / High")

    # ── Summary ─────────────────────────────────────────────────────────────────
    churn_rate = (df["churn"] == "Churned").mean() * 100
    print(f"\nSummary:")
    print(f"  Total customers  : {len(df):,}")
    print(f"  Churned          : {(df['churn'] == 'Churned').sum():,} ({churn_rate:.1f}%)")
    print(f"  Retained         : {(df['churn'] == 'Retained').sum():,} ({100-churn_rate:.1f}%)")
    print(f"  Active members   : {(df['active_member'] == 'Active').sum():,}")
    print(f"  Avg credit score : {df['credit_score'].mean():.1f}")

    # ── Export ──────────────────────────────────────────────────────────────────
    df.to_csv(OUTPUT_PATH, index=False)
    print(f"\nExported: {OUTPUT_PATH}")

    # Also save a copy to outputs/
    df.to_csv(os.path.join(OUTPUT_DIR, "bank_churn_cleaned.csv"), index=False)
    print(f"Copy in : {os.path.join(OUTPUT_DIR, 'bank_churn_cleaned.csv')}")

    return df


if __name__ == "__main__":
    clean()
