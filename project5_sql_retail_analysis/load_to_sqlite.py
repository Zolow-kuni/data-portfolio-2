"""
load_to_sqlite.py — Clean online_retail_II.xlsx and load into retail.db
Run: python load_to_sqlite.py
"""

import os
import sqlite3
import pandas as pd

DATA_PATH = r"C:\Users\lalit\Downloads\Online Retail\online_retail_II.xlsx"
DB_PATH   = os.path.join(os.path.dirname(__file__), "outputs", "retail.db")
os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)


def load_and_clean() -> pd.DataFrame:
    print("Reading Excel file (both sheets) — this may take ~30s ...")
    sheets = pd.read_excel(DATA_PATH, sheet_name=None, dtype={"Invoice": str, "Customer ID": str})
    df = pd.concat(sheets.values(), ignore_index=True)
    print(f"  Raw rows: {len(df):,}")

    # ── Cleaning steps ──────────────────────────────────────────────────────────

    # 1. Drop rows where Customer ID is null
    before = len(df)
    df = df.dropna(subset=["Customer ID"])
    print(f"  Dropped {before - len(df):,} rows with null Customer ID")

    # 2. Drop rows where Description is null
    before = len(df)
    df = df.dropna(subset=["Description"])
    print(f"  Dropped {before - len(df):,} rows with null Description")

    # 3. Remove cancelled invoices (start with 'C')
    before = len(df)
    df = df[~df["Invoice"].astype(str).str.startswith("C")]
    print(f"  Dropped {before - len(df):,} cancelled invoices (Invoice starts with C)")

    # 4. Remove rows where Quantity <= 0
    before = len(df)
    df["Quantity"] = pd.to_numeric(df["Quantity"], errors="coerce")
    df = df[df["Quantity"] > 0]
    print(f"  Dropped {before - len(df):,} rows with Quantity <= 0")

    # 5. Remove rows where Price <= 0
    before = len(df)
    df["Price"] = pd.to_numeric(df["Price"], errors="coerce")
    df = df[df["Price"] > 0]
    print(f"  Dropped {before - len(df):,} rows with Price <= 0")

    # 6. Rename "Customer ID" → "CustomerID"
    df = df.rename(columns={"Customer ID": "CustomerID"})

    # 7. Parse InvoiceDate as datetime, store as ISO string for SQLite
    df["InvoiceDate"] = pd.to_datetime(df["InvoiceDate"], errors="coerce")
    df["InvoiceDate"] = df["InvoiceDate"].dt.strftime("%Y-%m-%d %H:%M:%S")

    # 8. Add TotalValue = Quantity × Price
    df["TotalValue"] = (df["Quantity"] * df["Price"]).round(2)

    # 9. Ensure CustomerID is integer string (strip .0 from "12345.0")
    df["CustomerID"] = df["CustomerID"].apply(
        lambda x: str(int(float(x))) if x == x else None
    )

    # 10. Strip whitespace from string columns
    for col in ["StockCode", "Description", "Country"]:
        df[col] = df[col].astype(str).str.strip()

    print(f"  Clean rows: {len(df):,}")
    return df


def load_to_sqlite(df: pd.DataFrame):
    conn = sqlite3.connect(DB_PATH)
    cur  = conn.cursor()

    # Drop + recreate tables
    cur.executescript("""
        DROP TABLE IF EXISTS transactions;
        DROP TABLE IF EXISTS customers;

        CREATE TABLE transactions (
            Invoice     TEXT,
            StockCode   TEXT,
            Description TEXT,
            Quantity    INTEGER,
            InvoiceDate TEXT,
            Price       REAL,
            CustomerID  TEXT,
            Country     TEXT,
            TotalValue  REAL
        );

        CREATE TABLE customers (
            CustomerID  TEXT PRIMARY KEY,
            Country     TEXT
        );
    """)

    # Load transactions
    print("Loading transactions table ...")
    cols = ["Invoice","StockCode","Description","Quantity","InvoiceDate","Price","CustomerID","Country","TotalValue"]
    df[cols].to_sql("transactions", conn, if_exists="append", index=False, chunksize=5000)
    print(f"  Inserted {len(df):,} rows into transactions")

    # Load customers (distinct CustomerID + most common Country)
    print("Loading customers table ...")
    customers = (
        df.groupby("CustomerID")["Country"]
        .agg(lambda x: x.value_counts().index[0])
        .reset_index()
    )
    customers.to_sql("customers", conn, if_exists="append", index=False, chunksize=5000)
    print(f"  Inserted {len(customers):,} distinct customers")

    # Create indexes for query speed
    cur.executescript("""
        CREATE INDEX IF NOT EXISTS idx_tx_customer  ON transactions(CustomerID);
        CREATE INDEX IF NOT EXISTS idx_tx_invoice   ON transactions(Invoice);
        CREATE INDEX IF NOT EXISTS idx_tx_stockcode ON transactions(StockCode);
        CREATE INDEX IF NOT EXISTS idx_tx_country   ON transactions(Country);
        CREATE INDEX IF NOT EXISTS idx_tx_date      ON transactions(InvoiceDate);
    """)

    conn.commit()
    conn.close()
    print(f"  Database saved: {DB_PATH}")


if __name__ == "__main__":
    df = load_and_clean()
    load_to_sqlite(df)
    print("Done.")
