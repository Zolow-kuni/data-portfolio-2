# Project 6 — Power BI Customer Churn Dashboard

**Language:** Python (cleaning) + Power BI (dashboard)  
**Dataset:** [Bank Customer Churn](https://www.kaggle.com/datasets/gauravtopre/bank-customer-churn-dataset) — 10,000 rows  
**GitHub:** [project6_powerbi_churn](https://github.com/Zolow-kuni/data-portfolio-2/tree/main/project6_powerbi_churn)

---

## What it does

Cleans a bank customer churn dataset and prepares it for a 3-page
Power BI dashboard covering executive summary, customer demographics,
and financial analysis.

---

## How to run

```bash
# Step 1 — generate cleaned CSV
cd project6_powerbi_churn
python clean_data.py

# Step 2 — build the dashboard manually in Power BI Desktop
# See dashboard_notes.md for full step-by-step instructions
```

---

## Dataset source

Kaggle — Bank Customer Churn Prediction  
Columns: customer_id, credit_score, country, gender, age, tenure, balance,
products_number, credit_card, active_member, estimated_salary, churn

---

## Cleaning steps applied

| Step | Action |
|------|--------|
| Null check | Zero nulls — dataset is clean |
| Duplicates | Checked and removed if found |
| credit_card | 0/1 → "No" / "Yes" |
| active_member | 0/1 → "Inactive" / "Active" |
| churn | 0/1 → "Retained" / "Churned" |
| age_group | Bucketed: 18-30 / 31-45 / 46-60 / 60+ |
| credit_score_band | Poor / Fair / Good / Very Good / Exceptional |
| balance_segment | Zero Balance / Low (<50K) / Medium (50K-100K) / High (>100K) |

---

## Power BI Dashboard (3 pages)

| Page | Content |
|------|---------|
| Executive Summary | KPI cards, donut chart, churn by country + gender |
| Customer Demographics | Churn by age group, credit score, scatter, products |
| Financial Analysis | Churn by balance segment, tenure line, top 20 table |

DAX measures: Churn Rate, Active Rate, Avg Credit Score, Total Customers

Slicers: Country, Gender, Age Group, Credit Score Band (synced across pages)

---

## Outputs

| File | Description |
|------|-------------|
| `bank_churn_cleaned.csv` | Import this into Power BI |
| `dashboard_notes.md` | Full step-by-step build instructions + DAX |
| `outputs/bank_churn_cleaned.csv` | Same file, also saved to outputs/ |

---

## Libraries

```
pandas
```
