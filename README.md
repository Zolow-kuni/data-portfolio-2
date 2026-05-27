# Data Analytics Portfolio 2 — Subham Joshi

4 projects covering SQL, Python automation, Power BI, and R machine learning —
using real Kaggle datasets across retail, banking, and telecom domains.

**GitHub:** https://github.com/Zolow-kuni/data-portfolio-2

---

## Projects

| # | Project | Language | Dataset | Key Skills |
|---|---------|----------|---------|-----------|
| 5 | [SQL Retail Analysis](project5_sql_retail_analysis/) | SQL + Python | Online Retail II (525K rows) | CTEs, window functions, RFM, cohort analysis |
| 6 | [Power BI Churn Dashboard](project6_powerbi_churn/) | Python + Power BI | Bank Customer Churn (10K rows) | DAX, data cleaning, dashboard design |
| 7 | [Python Automation Pipeline](project7_python_automation/) | Python | Retail Sales (1K rows) | ETL, openpyxl, logging, Excel report |
| 8 | [R Churn Prediction](project8_churn_prediction_r/) | R | Telco Customer Churn (7K rows) | Logistic Regression, Random Forest, Decision Tree, ROC/AUC |

---

## Quick Start

```bash
# Install Python dependencies
pip install -r requirements.txt

# Project 7 — runs end-to-end with one command
cd project7_python_automation
python automation_pipeline.py

# Project 5 — load data then run queries
cd project5_sql_retail_analysis
python load_to_sqlite.py
python run_analysis.py

# Project 6 — generate cleaned CSV for Power BI
cd project6_powerbi_churn
python clean_data.py

# Project 8 — requires R installed (https://cran.r-project.org)
# Then from R console or terminal:
# Rscript project8_churn_prediction_r/eda.R
# Rscript project8_churn_prediction_r/churn_prediction.R
```

---

## Dataset Sources

| Dataset | Kaggle URL |
|---------|-----------|
| Online Retail II | kaggle.com/datasets/lakshmi25npathi/online-retail-dataset |
| Bank Customer Churn | kaggle.com/datasets/gauravtopre/bank-customer-churn-dataset |
| Retail Sales Dataset | kaggle.com/datasets/mohammadtalib786/retail-sales-dataset |
| Telco Customer Churn | kaggle.com/datasets/blastchar/telco-customer-churn |

---

## Certification Project

| # | Project | Tools | Dataset | Key Skills |
|---|---------|-------|---------|------------|
| G1 | [Automatidata × NYC TLC — Taxi Fare Prediction](https://github.com/Zolow-kuni/automatidata-nyc-tlc) | Python · Pandas · Matplotlib · Seaborn | NYC TLC Yellow Taxi 2017 (22,699 rows) | EDA, PACE workflow, regression prep, executive summary |

*Completed as part of the [Google Advanced Data Analytics Certificate](https://www.coursera.org/professional-certificates/google-advanced-data-analytics). Covers the full PACE workflow — data inspection, feature engineering, outlier analysis, correlation heatmaps, and stakeholder-ready reporting.*

---

## Part of a larger portfolio

Projects 1–4 are in [data-portfolio](https://github.com/Zolow-kuni/data-portfolio):
Fraud Detection, KPI Dashboard, Data Integrity Checker, Sales Trend Analyzer.
