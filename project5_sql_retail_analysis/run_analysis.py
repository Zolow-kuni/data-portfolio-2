"""
run_analysis.py — Execute all 15 SQL queries and export results to CSV
Run: python run_analysis.py
"""

import os
import re
import sqlite3
import pandas as pd

DB_PATH     = os.path.join(os.path.dirname(__file__), "outputs", "retail.db")
SQL_PATH    = os.path.join(os.path.dirname(__file__), "retail_analysis.sql")
OUTPUT_DIR  = os.path.join(os.path.dirname(__file__), "outputs")
os.makedirs(OUTPUT_DIR, exist_ok=True)


QUERY_NAMES = {
    1:  "revenue_by_country",
    2:  "top20_products_by_quantity",
    3:  "monthly_revenue_trend",
    4:  "unique_customers_by_country",
    5:  "avg_order_value_per_customer",
    6:  "top10_customers_by_spend",
    7:  "revenue_contribution_by_country",
    8:  "single_purchase_products",
    9:  "mom_revenue_growth",
    10: "customer_ranking_by_spend",
    11: "rolling_3month_avg",
    12: "cohort_retention",
    13: "rfm_segmentation",
    14: "top3_products_per_country",
    15: "customers_3plus_consecutive_growth",
}


def parse_queries(sql_path: str) -> list[tuple[int, str, str]]:
    """Parse SQL file into list of (query_num, label, sql) tuples."""
    with open(sql_path, "r", encoding="utf-8") as f:
        content = f.read()

    # Split on "-- Query N:" comments
    pattern = r"--\s*Query\s*(\d+):"
    parts = re.split(pattern, content)

    queries = []
    for i in range(1, len(parts), 2):
        num = int(parts[i])
        body = parts[i + 1]
        # Find first SELECT or WITH at start of a non-comment line
        sql_match = re.search(r"^(?!--)\s*(SELECT|WITH)\b", body, re.IGNORECASE | re.MULTILINE)
        if sql_match:
            sql_text = body[sql_match.start():]
            # Take up to first semicolon
            stmt = sql_text.split(";")[0].strip() + ";"
            queries.append((num, QUERY_NAMES.get(num, f"query_{num:02d}"), stmt))
    return queries


def run_queries():
    if not os.path.exists(DB_PATH):
        print(f"ERROR: Database not found at {DB_PATH}")
        print("Run load_to_sqlite.py first.")
        return

    conn = sqlite3.connect(DB_PATH)
    print(f"Connected to {DB_PATH}\n")

    queries = parse_queries(SQL_PATH)
    print(f"Found {len(queries)} queries to run.\n")

    for num, name, sql in queries:
        try:
            df = pd.read_sql_query(sql, conn)
            out_path = os.path.join(OUTPUT_DIR, f"q{num:02d}_{name}.csv")
            df.to_csv(out_path, index=False)
            print(f"  Q{num:02d} {name:<40} {len(df):>6,} rows  ->  {os.path.basename(out_path)}")
        except Exception as e:
            print(f"  Q{num:02d} {name:<40} ERROR: {e}")

    conn.close()
    print(f"\nAll CSVs saved to: {OUTPUT_DIR}")


if __name__ == "__main__":
    run_queries()
