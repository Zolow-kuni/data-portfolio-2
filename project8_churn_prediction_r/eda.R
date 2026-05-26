# eda.R — Exploratory Data Analysis for Telco Churn
# Project 8: R Churn Prediction
# Run: Rscript eda.R

# ── Setup ──────────────────────────────────────────────────────────────────────
user_lib <- file.path(Sys.getenv("LOCALAPPDATA"), "R", "win-library",
                      paste0(R.version$major, ".", substr(R.version$minor, 1, 1)))
if (!dir.exists(user_lib)) dir.create(user_lib, recursive = TRUE)
.libPaths(c(user_lib, .libPaths()))

required_packages <- c("tidyverse","ggplot2","randomForest",
                       "rpart","caret","pROC","corrplot","dplyr")
new_packages <- required_packages[!(required_packages %in%
                installed.packages()[,"Package"])]
if (length(new_packages)) {
  tryCatch(
    install.packages(new_packages, lib = user_lib, repos = "https://cran.r-project.org"),
    error = function(e) {
      message("First install attempt failed, retrying: ", conditionMessage(e))
      install.packages(new_packages, lib = user_lib, repos = "https://cran.r-project.org")
    }
  )
}

library(ggplot2)
library(dplyr)
library(tidyr)
library(corrplot)

BASE_DIR   <- r"(C:\Users\lalit\data-portfolio-2\project8_churn_prediction_r)"
OUTPUT_DIR <- file.path(BASE_DIR, "outputs")
if (!dir.exists(OUTPUT_DIR)) dir.create(OUTPUT_DIR, recursive = TRUE)

# Load cleaned data
source(file.path(BASE_DIR, "clean_data.R"))
df <- telco_clean

save_plot <- function(filename, width = 8, height = 5) {
  ggsave(file.path(OUTPUT_DIR, filename), width = width, height = height, dpi = 150)
  cat(sprintf("  Saved: %s\n", filename))
}

COLORS <- c("No" = "#27AE60", "Yes" = "#E74C3C")

cat("\n=== EDA Plots ===\n")

# ── Plot 1: Overall churn rate bar chart ───────────────────────────────────────
cat("Plot 1: Overall churn rate\n")
churn_summary <- df %>%
  count(Churn) %>%
  mutate(pct = round(n / sum(n) * 100, 1),
         label = paste0(n, "\n(", pct, "%)"))

p1 <- ggplot(churn_summary, aes(x = Churn, y = n, fill = Churn)) +
  geom_col(width = 0.5, show.legend = FALSE) +
  geom_text(aes(label = label), vjust = -0.3, size = 4, fontface = "bold") +
  scale_fill_manual(values = COLORS) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(title = "Overall Churn Rate", x = "Churn", y = "Number of Customers") +
  theme_minimal(base_size = 12)
print(p1)
save_plot("01_overall_churn_rate.png")

# ── Plot 2: Churn rate by Contract type ───────────────────────────────────────
cat("Plot 2: Churn by Contract type\n")
contract_churn <- df %>%
  group_by(Contract, Churn) %>%
  summarise(n = n(), .groups = "drop") %>%
  group_by(Contract) %>%
  mutate(pct = round(n / sum(n) * 100, 1))

p2 <- ggplot(contract_churn, aes(x = Contract, y = pct, fill = Churn)) +
  geom_col(position = "dodge", width = 0.6) +
  geom_text(aes(label = paste0(pct, "%")), position = position_dodge(0.6),
            vjust = -0.4, size = 3.5) +
  scale_fill_manual(values = COLORS) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(title = "Churn Rate by Contract Type", x = "Contract", y = "Percentage (%)") +
  theme_minimal(base_size = 12)
print(p2)
save_plot("02_churn_by_contract.png")

# ── Plot 3: Churn rate by Internet Service ────────────────────────────────────
cat("Plot 3: Churn by Internet Service\n")
internet_churn <- df %>%
  group_by(InternetService, Churn) %>%
  summarise(n = n(), .groups = "drop") %>%
  group_by(InternetService) %>%
  mutate(pct = round(n / sum(n) * 100, 1))

p3 <- ggplot(internet_churn, aes(x = InternetService, y = pct, fill = Churn)) +
  geom_col(position = "dodge", width = 0.6) +
  geom_text(aes(label = paste0(pct, "%")), position = position_dodge(0.6),
            vjust = -0.4, size = 3.5) +
  scale_fill_manual(values = COLORS) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(title = "Churn Rate by Internet Service Type",
       x = "Internet Service", y = "Percentage (%)") +
  theme_minimal(base_size = 12)
print(p3)
save_plot("03_churn_by_internet_service.png")

# ── Plot 4: Tenure distribution — churned vs retained ─────────────────────────
cat("Plot 4: Tenure distribution\n")
p4 <- ggplot(df, aes(x = tenure, fill = Churn, color = Churn)) +
  geom_histogram(aes(y = after_stat(density)), alpha = 0.5, bins = 30,
                 position = "identity") +
  scale_fill_manual(values = COLORS) +
  scale_color_manual(values = COLORS) +
  labs(title = "Tenure Distribution: Churned vs Retained",
       x = "Tenure (months)", y = "Density") +
  theme_minimal(base_size = 12)
print(p4)
save_plot("04_tenure_distribution.png")

# ── Plot 5: Monthly Charges vs Churn — box plot ───────────────────────────────
cat("Plot 5: Monthly Charges box plot\n")
p5 <- ggplot(df, aes(x = Churn, y = MonthlyCharges, fill = Churn)) +
  geom_boxplot(alpha = 0.7, outlier.shape = 21, outlier.size = 1.5) +
  scale_fill_manual(values = COLORS) +
  labs(title = "Monthly Charges by Churn Status",
       x = "Churn", y = "Monthly Charges ($)") +
  theme_minimal(base_size = 12) +
  theme(legend.position = "none")
print(p5)
save_plot("05_monthly_charges_boxplot.png")

# ── Plot 6: Correlation heatmap of numeric variables ──────────────────────────
cat("Plot 6: Correlation heatmap\n")
num_vars <- df %>% select(tenure, MonthlyCharges, TotalCharges, ChurnBinary)
cor_matrix <- cor(num_vars, use = "complete.obs")

png(file.path(OUTPUT_DIR, "06_correlation_heatmap.png"), width = 700, height = 600, res = 120)
corrplot(cor_matrix, method = "color", type = "upper", tl.col = "black",
         tl.srt = 45, addCoef.col = "black", number.cex = 0.9,
         title = "Correlation Heatmap — Numeric Variables", mar = c(0,0,2,0))
dev.off()
cat("  Saved: 06_correlation_heatmap.png\n")

# ── Plot 7: Churn rate by Payment Method ──────────────────────────────────────
cat("Plot 7: Churn by Payment Method\n")
payment_churn <- df %>%
  group_by(PaymentMethod, Churn) %>%
  summarise(n = n(), .groups = "drop") %>%
  group_by(PaymentMethod) %>%
  mutate(pct = round(n / sum(n) * 100, 1))

p7 <- ggplot(payment_churn, aes(x = reorder(PaymentMethod, -pct), y = pct, fill = Churn)) +
  geom_col(position = "dodge", width = 0.6) +
  scale_fill_manual(values = COLORS) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +
  labs(title = "Churn Rate by Payment Method",
       x = "Payment Method", y = "Percentage (%)") +
  theme_minimal(base_size = 11) +
  theme(axis.text.x = element_text(angle = 20, hjust = 1))
print(p7)
save_plot("07_churn_by_payment_method.png", width = 9)

# ── Plot 8: Churn by gender and senior citizen status ─────────────────────────
cat("Plot 8: Churn by gender + senior citizen\n")
demo_churn <- df %>%
  group_by(gender, SeniorCitizen, Churn) %>%
  summarise(n = n(), .groups = "drop") %>%
  group_by(gender, SeniorCitizen) %>%
  mutate(pct = round(n / sum(n) * 100, 1)) %>%
  unite("Group", gender, SeniorCitizen, sep = " / Senior=")

p8 <- ggplot(demo_churn, aes(x = Group, y = pct, fill = Churn)) +
  geom_col(position = "stack", width = 0.6) +
  scale_fill_manual(values = COLORS) +
  labs(title = "Churn by Gender and Senior Citizen Status",
       x = "Group (Gender / Senior Citizen)", y = "Percentage (%)") +
  theme_minimal(base_size = 11) +
  theme(axis.text.x = element_text(angle = 20, hjust = 1))
print(p8)
save_plot("08_churn_by_gender_senior.png", width = 9)

cat("\nEDA complete. All 8 plots saved to outputs/\n")
