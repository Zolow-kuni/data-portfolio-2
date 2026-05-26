# Project 5 — SQL Retail Analysis

**Language:** SQL (SQLite via Python)  
**Dataset:** [Online Retail II](https://www.kaggle.com/datasets/lakshmi25npathi/online-retail-dataset) — 525,461 rows  
**GitHub:** [project5_sql_retail_analysis](https://github.com/Zolow-kuni/data-portfolio-2/tree/main/project5_sql_retail_analysis)

---

## What it does

Loads a real UK e-commerce dataset into SQLite, applies rigorous data cleaning,
then runs 15 SQL queries ranging from basic aggregations to advanced window
functions, CTEs, RFM segmentation, and cohort analysis.

---

## How to run

```bash
cd project5_sql_retail_analysis

# Step 1 — clean and load into SQLite (~30s for large file)
python load_to_sqlite.py

# Step 2 — run all 15 queries and export CSVs
python run_analysis.py
```

---

## Dataset source

Kaggle — Online Retail II Dataset  
UK-based online retailer, transactions from 2009–2011.  
Columns: Invoice, StockCode, Description, Quantity, InvoiceDate, Price, Customer ID, Country

---

## Cleaning steps applied

| Step | Action | Rows affected |
|------|--------|---------------|
| Null Customer ID | Dropped | ~107,927 |
| Null Description | Dropped | ~2,928 |
| Cancelled invoices (Invoice starts with C) | Dropped | varies |
| Quantity <= 0 | Dropped | varies |
| Price <= 0 | Dropped | varies |
| Column rename | "Customer ID" → "CustomerID" | — |
| Derived column | TotalValue = Quantity × Price | — |

---

## SQL Queries (15 total)

| # | Query | Technique |
|---|-------|-----------|
| 1 | Total revenue by country | GROUP BY, ORDER BY |
| 2 | Top 20 products by quantity | GROUP BY, LIMIT |
| 3 | Monthly revenue trend | SUBSTR date, GROUP BY |
| 4 | Unique customers per country | COUNT DISTINCT, window % |
| 5 | Avg order value per customer | JOIN, GROUP BY |
| 6 | Top 10 customers by spend | JOIN, ORDER BY |
| 7 | Revenue contribution % by country | SUM OVER window |
| 8 | Single-purchase products | HAVING = 1 |
| 9 | MoM revenue growth | CTE + LAG() |
| 10 | Customer ranking by spend | RANK() / NTILE() OVER |
| 11 | Rolling 3-month revenue average | AVG OVER ROWS frame |
| 12 | Cohort retention analysis | Multi-CTE, first purchase |
| 13 | RFM segmentation | NTILE, CASE, multi-CTE |
| 14 | Top 3 products per country | RANK() OVER PARTITION BY |
| 15 | Customers with 3+ months consecutive growth | Streak detection CTE |

---

## Outputs

All outputs in `outputs/`:

| File | Description |
|------|-------------|
| `retail.db` | SQLite database (transactions + customers tables) |
| `q01_revenue_by_country.csv` | Query 1 result |
| `q02_top20_products_by_quantity.csv` | Query 2 result |
| ... | one CSV per query |
| `q15_customers_3plus_consecutive_growth.csv` | Query 15 result |

---

## Libraries

```
pandas
openpyxl
sqlite3 (stdlib)
```
