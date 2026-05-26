# Project 8 — Customer Churn Prediction in R

**Language:** R  
**Dataset:** [Telco Customer Churn](https://www.kaggle.com/datasets/blastchar/telco-customer-churn) — 7,043 rows  
**GitHub:** [project8_churn_prediction_r](https://github.com/Zolow-kuni/data-portfolio-2/tree/main/project8_churn_prediction_r)

---

## What it does

Builds 3 machine learning models to predict customer churn —
Logistic Regression, Random Forest, and Decision Tree —
with full EDA, ROC curves, feature importance, and a final comparison table.

---

## Requirements

Install R from https://cran.r-project.org  
(Optionally install RStudio for a better experience)

Packages are auto-installed on first run:
```r
install.packages(c("dplyr","ggplot2","tidyr","corrplot",
                   "caret","randomForest","rpart","rpart.plot","pROC"))
```

---

## How to run

```r
# Option A — from RStudio or R console
source("eda.R")
source("churn_prediction.R")

# Option B — from terminal
Rscript eda.R
Rscript churn_prediction.R
```

Both scripts automatically call `clean_data.R` first.

---

## Dataset source

Kaggle — Telco Customer Churn (IBM Sample Data)  
Columns: customerID, gender, SeniorCitizen, Partner, Dependents, tenure,
PhoneService, MultipleLines, InternetService, OnlineSecurity, OnlineBackup,
DeviceProtection, TechSupport, StreamingTV, StreamingMovies, Contract,
PaperlessBilling, PaymentMethod, MonthlyCharges, TotalCharges, Churn

---

## Cleaning steps applied (clean_data.R)

| Step | Action |
|------|--------|
| TotalCharges | `as.numeric()` → NAs imputed with 0 (new customers, tenure=0) |
| SeniorCitizen | 0/1 integer → factor "No" / "Yes" |
| ChurnBinary | Added as 1/0 numeric for correlation analysis |
| Yes/No columns | Converted to factors (11 columns) |
| Contract | Ordered factor: Month-to-month < One year < Two year |
| customerID | Removed (not a predictor) |
| Duplicates | Checked and removed if found |
| Remaining NAs | Removed with `na.omit()` |

---

## EDA (eda.R) — 8 plots

| Plot | Description |
|------|-------------|
| 01 | Overall churn rate bar chart |
| 02 | Churn rate by Contract type |
| 03 | Churn rate by Internet Service |
| 04 | Tenure distribution — churned vs retained histogram |
| 05 | Monthly Charges box plot by churn |
| 06 | Correlation heatmap (numeric variables) |
| 07 | Churn by Payment Method |
| 08 | Churn by gender + senior citizen status |

---

## Models (churn_prediction.R)

| Model | Library |
|-------|---------|
| Logistic Regression | `glm()` (base R) |
| Random Forest | `randomForest` (ntree=100) |
| Decision Tree | `rpart` |

Train/test split: 70/30, `set.seed(42)`

Outputs per model: confusion matrix, accuracy, precision, recall, F1, AUC, ROC curve

---

## Outputs

All outputs in `outputs/`:

| File | Description |
|------|-------------|
| `telco_churn_cleaned.csv` | Cleaned dataset |
| `01_overall_churn_rate.png` – `08_churn_by_gender_senior.png` | EDA plots |
| `roc_logistic_regression.png` | LR ROC curve |
| `roc_random_forest.png` | RF ROC curve |
| `roc_decision_tree.png` | DT ROC curve |
| `roc_all_models.png` | Combined ROC comparison |
| `rf_feature_importance.png` | Top 15 features by Gini importance |
| `decision_tree_plot.png` | Visualised decision tree |
| `model_comparison.csv` | Accuracy / Precision / Recall / F1 / AUC table |
| `model_*.rds` | Saved model objects for reuse |
