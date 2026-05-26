# clean_data.R — Telco Customer Churn data cleaning
# Project 8: R Churn Prediction
# Run: source("clean_data.R") or Rscript clean_data.R

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

library(dplyr)

DATA_PATH  <- r"(C:\Users\lalit\Downloads\WA_Fn-UseC_-Telco-Customer-Churn\WA_Fn-UseC_-Telco-Customer-Churn.csv)"
BASE_DIR   <- r"(C:\Users\lalit\data-portfolio-2\project8_churn_prediction_r)"
OUTPUT_DIR <- file.path(BASE_DIR, "outputs")
if (!dir.exists(OUTPUT_DIR)) dir.create(OUTPUT_DIR, recursive = TRUE)

cat("Reading Telco Churn dataset...\n")
df <- read.csv(DATA_PATH, stringsAsFactors = FALSE)
cat(sprintf("  Loaded %d rows x %d columns\n", nrow(df), ncol(df)))

# ── Cleaning steps ─────────────────────────────────────────────────────────────

# 1. TotalCharges: convert from character to numeric (blanks for tenure=0 become NA)
cat("\nCleaning TotalCharges...\n")
df$TotalCharges <- as.numeric(df$TotalCharges)
na_count <- sum(is.na(df$TotalCharges))
cat(sprintf("  NA values after conversion: %d (these are new customers with tenure=0)\n", na_count))
df$TotalCharges[is.na(df$TotalCharges)] <- 0
cat(sprintf("  Imputed %d NA values with 0\n", na_count))

# 2. SeniorCitizen: 0/1 integer → factor "No"/"Yes"
df$SeniorCitizen <- factor(ifelse(df$SeniorCitizen == 1, "Yes", "No"), levels = c("No", "Yes"))
cat("  SeniorCitizen: 0/1 -> factor No/Yes\n")

# 3. Churn: "Yes"/"No" → binary 1/0 for modelling
df$ChurnBinary <- ifelse(df$Churn == "Yes", 1L, 0L)
cat("  ChurnBinary added: Yes=1, No=0\n")

# 4. Convert all Yes/No columns to factors
yes_no_cols <- c("Partner", "Dependents", "PhoneService", "PaperlessBilling",
                 "MultipleLines", "OnlineSecurity", "OnlineBackup",
                 "DeviceProtection", "TechSupport", "StreamingTV", "StreamingMovies")
for (col in yes_no_cols) {
  if (col %in% names(df)) {
    df[[col]] <- factor(df[[col]])
  }
}
cat(sprintf("  Converted %d Yes/No columns to factors\n", length(yes_no_cols)))

# 5. Contract: ordered factor
df$Contract <- factor(df$Contract,
                      levels = c("Month-to-month", "One year", "Two year"),
                      ordered = TRUE)
cat("  Contract: ordered factor (Month-to-month < One year < Two year)\n")

# 6. Other categorical columns to factor
cat_cols <- c("gender", "InternetService", "PaymentMethod", "Churn")
for (col in cat_cols) {
  df[[col]] <- factor(df[[col]])
}

# 7. Remove customerID (not needed for modelling)
df <- df %>% select(-customerID)
cat("  Removed customerID column\n")

# 8. Check for duplicate rows
dupes <- sum(duplicated(df))
if (dupes > 0) {
  df <- df[!duplicated(df), ]
  cat(sprintf("  Removed %d duplicate rows\n", dupes))
} else {
  cat("  No duplicate rows found\n")
}

# 9. Final NA check
remaining_na <- sum(is.na(df))
if (remaining_na > 0) {
  df <- na.omit(df)
  cat(sprintf("  Removed %d rows with remaining NAs\n", remaining_na))
} else {
  cat("  No remaining NAs\n")
}

# ── Summary ─────────────────────────────────────────────────────────────────────
churn_rate <- mean(df$ChurnBinary) * 100
cat(sprintf("\nClean dataset summary:\n"))
cat(sprintf("  Rows         : %d\n", nrow(df)))
cat(sprintf("  Columns      : %d\n", ncol(df)))
cat(sprintf("  Churn rate   : %.1f%%\n", churn_rate))
cat(sprintf("  Avg tenure   : %.1f months\n", mean(df$tenure)))
cat(sprintf("  Avg monthly  : $%.2f\n", mean(df$MonthlyCharges)))

# ── Save cleaned data ──────────────────────────────────────────────────────────
out_path <- file.path(OUTPUT_DIR, "telco_churn_cleaned.csv")
write.csv(df, out_path, row.names = FALSE)
cat(sprintf("\nSaved: %s\n", out_path))

# Make available to sourcing scripts
telco_clean <- df
cat("  Object 'telco_clean' available in environment\n")
