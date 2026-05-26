# Project 7 — Python Automation Pipeline

**Language:** Python  
**Dataset:** [Retail Sales Dataset](https://www.kaggle.com/datasets/mohammadtalib786/retail-sales-dataset) — 1,000 rows  
**GitHub:** [project7_python_automation](https://github.com/Zolow-kuni/data-portfolio-2/tree/main/project7_python_automation)

---

## What it does

A fully automated end-to-end data pipeline that ingests a retail sales CSV,
cleans and validates it, runs 6 analyses, and produces a formatted multi-sheet
Excel report — all with a single command.

---

## How to run

```bash
cd project7_python_automation
python automation_pipeline.py
```

---

## Dataset source

Kaggle — Retail Sales Dataset  
Columns: Transaction ID, Date, Customer ID, Gender, Age, Product Category,
Quantity, Price per Unit, Total Amount

---

## Cleaning steps applied

| Step | Action |
|------|--------|
| Date | Converted from string to datetime using `pd.to_datetime()` |
| Duplicates | Removed duplicate Transaction IDs |
| Calculation check | Flagged rows where Total Amount != Quantity × Price per Unit |
| Age outliers | Flagged rows where Age is outside 18–100 |
| Quantity errors | Flagged rows where Quantity <= 0 |
| Derived columns | Added month, year, day_of_week, age_group |

---

## Outputs

All outputs land in `outputs/`:

| File | Description |
|------|-------------|
| `Retail_Sales_Report_YYYY-MM-DD.xlsx` | 5-sheet Excel report |
| `pipeline_log.txt` | Timestamped log of every pipeline step |

### Excel sheets

| Sheet | Contents |
|-------|----------|
| Cleaned Data | Full cleaned dataset with formatting |
| Validation Report | Row counts, drop reasons, data quality score |
| Revenue by Category | Electronics / Clothing / Beauty breakdown |
| Monthly Trend | Revenue per month with MoM growth % |
| Customer Summary | Top 10 customers, age group patterns, gender split |

---

## Libraries

```
pandas
openpyxl
```
