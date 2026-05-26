# Power BI Dashboard Build Notes
# Project 6 — Bank Customer Churn Analysis

---

## Setup

1. Run `python clean_data.py` to generate `bank_churn_cleaned.csv`
2. Open Power BI Desktop
3. **Get Data → Text/CSV** → select `bank_churn_cleaned.csv`
4. Load (do not transform — cleaning is already done)

---

## DAX Measures

Create these measures before building visuals. In the Fields pane,
right-click the table name → New Measure.

```dax
Churn Rate =
DIVIDE(
    COUNTROWS(FILTER(bank_churn_cleaned, bank_churn_cleaned[churn] = "Churned")),
    COUNTROWS(bank_churn_cleaned)
)

Avg Credit Score = AVERAGE(bank_churn_cleaned[credit_score])

Active Rate =
DIVIDE(
    COUNTROWS(FILTER(bank_churn_cleaned, bank_churn_cleaned[active_member] = "Active")),
    COUNTROWS(bank_churn_cleaned)
)

Total Customers = COUNTROWS(bank_churn_cleaned)

Churned Count =
COUNTROWS(FILTER(bank_churn_cleaned, bank_churn_cleaned[churn] = "Churned"))

Avg Balance = AVERAGE(bank_churn_cleaned[balance])
```

Format:
- Churn Rate → Percentage, 1 decimal
- Active Rate → Percentage, 1 decimal
- Avg Credit Score → Whole number
- Total Customers → Whole number

---

## Page 1 — Executive Summary

### Layout

```
┌─────────────────────────────────────────────────────────┐
│  Total Customers  │  Churn Rate %  │  Active Members %  │  Avg Credit Score │
├──────────────────────────┬──────────────────────────────┤
│   Donut: Churned vs      │   Bar: Churn Rate            │
│   Retained               │   by Country                 │
├──────────────────────────┴──────────────────────────────┤
│   Bar: Churn Rate by Gender                             │
└─────────────────────────────────────────────────────────┘
```

### Step-by-step

**KPI Cards (top row):**
1. Insert → Card → drag [Total Customers] into Fields
2. Insert → Card → drag [Churn Rate] | Format as % | Label: "Churn Rate"
3. Insert → Card → drag [Active Rate] | Format as % | Label: "Active Members"
4. Insert → Card → drag [Avg Credit Score] | Label: "Avg Credit Score"

**Donut Chart — Churned vs Retained:**
- Insert → Donut Chart
- Legend: `churn`
- Values: `Total Customers`
- Colors: Churned = #E74C3C, Retained = #2ECC71

**Bar Chart — Churn Rate by Country:**
- Insert → Clustered Bar Chart
- Y-axis: `country`
- X-axis: `Churn Rate` (measure)
- Sort: descending by Churn Rate
- Data labels: On

**Bar Chart — Churn Rate by Gender:**
- Insert → Clustered Bar Chart
- Y-axis: `gender`
- X-axis: `Churn Rate` (measure)

---

## Page 2 — Customer Demographics

### Step-by-step

**Bar Chart — Churn Rate by Age Group:**
- Insert → Clustered Bar Chart
- Y-axis: `age_group`
- X-axis: `Churn Rate`
- Sort order for age_group: create a sort column or use conditional column
  (18-30=1, 31-45=2, 46-60=3, 60+=4) if needed

**Bar Chart — Churn Rate by Credit Score Band:**
- Insert → Clustered Bar Chart
- Y-axis: `credit_score_band`
- X-axis: `Churn Rate`
- Recommended sort: Poor → Fair → Good → Very Good → Exceptional

**Scatter Plot — Age vs Balance coloured by Churn:**
- Insert → Scatter Chart
- X-axis: `age` (Average or Don't summarize)
- Y-axis: `balance` (Average)
- Legend: `churn`
- Size: `Total Customers`
- Colors: Churned = #E74C3C, Retained = #2ECC71

**Stacked Bar — Products Number vs Churn Rate:**
- Insert → Stacked Bar Chart
- Y-axis: `products_number`
- X-axis: `Total Customers`
- Legend: `churn`
- Turn on data labels

---

## Page 3 — Financial Analysis

### Step-by-step

**Bar Chart — Churn Rate by Balance Segment:**
- Insert → Clustered Bar Chart
- Y-axis: `balance_segment`
- X-axis: `Churn Rate`
- Sort: Zero Balance → Low → Medium → High

**Line Chart — Avg Balance of Churned vs Retained by Tenure:**
- Insert → Line Chart
- X-axis: `tenure`
- Y-axis: `Avg Balance` (measure)
- Legend: `churn`
- This shows if long-tenured churned customers have higher balances (at-risk)

**Bar Chart — Churn Rate by Number of Products Owned:**
- Insert → Clustered Bar Chart
- Y-axis: `products_number`
- X-axis: `Churn Rate`

**Table — Top 20 Highest Balance Churned Customers:**
- Insert → Table
- Columns: `customer_id`, `age`, `country`, `balance`, `credit_score`,
  `tenure`, `products_number`, `churn`
- Add visual filter: churn = "Churned"
- Sort by `balance` descending
- Top N filter: top 20 by balance

---

## Slicers (add to all pages)

1. Insert → Slicer → Field: `country` | Style: Dropdown
2. Insert → Slicer → Field: `gender` | Style: List
3. Insert → Slicer → Field: `age_group` | Style: List
4. Insert → Slicer → Field: `credit_score_band` | Style: Dropdown

Sync slicers across pages:
- View → Sync Slicers → enable sync for all 4 slicers across all 3 pages

---

## Formatting Tips

- Theme: Use a clean minimal theme (View → Themes → Executive)
- Page background: #F8F9FA (light grey)
- Header bar: Dark blue rectangle (#1F4E79) with white page title text
- Consistent colors: Churned = #E74C3C, Retained = #27AE60, Neutral = #2E86C1
- Card borders: Light shadow, rounded corners
- All charts: Turn off gridlines, minimal axis labels

---

## Key Insights to Highlight

Based on the cleaned dataset (10,000 customers):
- Overall churn rate is ~20.4%
- Older age groups (46-60, 60+) churn at higher rates
- Customers with only 1 product churn less; those with 3-4 products churn most
- Zero-balance customers and high-balance customers both show elevated churn
- Germany has a higher churn rate than France and Spain

Add text boxes on each page summarising the top insight for that page.
