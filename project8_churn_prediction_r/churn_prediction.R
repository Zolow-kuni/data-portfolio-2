# churn_prediction.R — Logistic Regression, Random Forest, Decision Tree
# Project 8: R Churn Prediction
# Run: Rscript churn_prediction.R

# ── Install packages if needed ─────────────────────────────────────────────────
required_packages <- c("tidyverse","ggplot2","randomForest",
                       "rpart","caret","pROC","corrplot","dplyr")
new_packages <- required_packages[!(required_packages %in%
                installed.packages()[,"Package"])]
if (length(new_packages)) {
  tryCatch(
    install.packages(new_packages, repos = "https://cran.r-project.org"),
    error = function(e) {
      message("First install attempt failed, retrying: ", conditionMessage(e))
      install.packages(new_packages, repos = "https://cran.r-project.org")
    }
  )
}
# Also ensure rpart.plot is installed (not in base list above)
if (!requireNamespace("rpart.plot", quietly = TRUE)) {
  tryCatch(
    install.packages("rpart.plot", repos = "https://cran.r-project.org"),
    error = function(e) {
      message("Retrying rpart.plot install: ", conditionMessage(e))
      install.packages("rpart.plot", repos = "https://cran.r-project.org")
    }
  )
}

library(dplyr)
library(caret)
library(randomForest)
library(rpart)
library(rpart.plot)
library(pROC)
library(ggplot2)

BASE_DIR   <- r"(C:\Users\lalit\data-portfolio-2\project8_churn_prediction_r)"
OUTPUT_DIR <- file.path(BASE_DIR, "outputs")
if (!dir.exists(OUTPUT_DIR)) dir.create(OUTPUT_DIR, recursive = TRUE)

# ── Load cleaned data ──────────────────────────────────────────────────────────
source(file.path(BASE_DIR, "clean_data.R"))
df <- telco_clean

# Use Churn (factor Yes/No) as outcome; drop ChurnBinary to avoid leakage
model_df <- df %>% select(-ChurnBinary)

cat("\n=== Modelling Setup ===\n")
cat(sprintf("Dataset: %d rows x %d columns\n", nrow(model_df), ncol(model_df)))

# ── Train / Test split (70/30, seed 42) ───────────────────────────────────────
set.seed(42)
train_idx  <- createDataPartition(model_df$Churn, p = 0.70, list = FALSE)
train_data <- model_df[train_idx, ]
test_data  <- model_df[-train_idx, ]
cat(sprintf("Train rows: %d | Test rows: %d\n", nrow(train_data), nrow(test_data)))

# ── Helper: compute metrics from caret confusionMatrix ────────────────────────
get_metrics <- function(cm, roc_obj) {
  tbl <- cm$byClass
  list(
    Accuracy  = round(cm$overall["Accuracy"] * 100, 1),
    Precision = round(tbl["Precision"] * 100, 1),
    Recall    = round(tbl["Recall"] * 100, 1),
    F1        = round(tbl["F1"] * 100, 1),
    AUC       = round(auc(roc_obj), 3)
  )
}

results <- list()

# ── Model 1: Logistic Regression ──────────────────────────────────────────────
cat("\n--- Model 1: Logistic Regression ---\n")
model_lr <- glm(Churn ~ ., data = train_data, family = binomial)

prob_lr  <- predict(model_lr, newdata = test_data, type = "response")
pred_lr  <- factor(ifelse(prob_lr > 0.5, "Yes", "No"), levels = c("No", "Yes"))
cm_lr    <- confusionMatrix(pred_lr, test_data$Churn, positive = "Yes")
roc_lr   <- roc(as.numeric(test_data$Churn == "Yes"), prob_lr, quiet = TRUE)

print(cm_lr$table)
results[["Logistic Regression"]] <- get_metrics(cm_lr, roc_lr)
cat(sprintf("  Accuracy: %.1f%% | AUC: %.3f\n",
            results[["Logistic Regression"]]$Accuracy,
            results[["Logistic Regression"]]$AUC))

# ROC curve — LR
png(file.path(OUTPUT_DIR, "roc_logistic_regression.png"), width = 600, height = 500, res = 120)
plot(roc_lr, col = "#2E86C1", lwd = 2,
     main = sprintf("ROC — Logistic Regression (AUC = %.3f)", auc(roc_lr)))
abline(a = 0, b = 1, lty = 2, col = "grey")
dev.off()
cat("  Saved: roc_logistic_regression.png\n")

# ── Model 2: Random Forest ────────────────────────────────────────────────────
cat("\n--- Model 2: Random Forest (ntree=100) ---\n")
set.seed(42)
model_rf <- randomForest(Churn ~ ., data = train_data, ntree = 100, importance = TRUE)

prob_rf  <- predict(model_rf, newdata = test_data, type = "prob")[, "Yes"]
pred_rf  <- predict(model_rf, newdata = test_data)
cm_rf    <- confusionMatrix(pred_rf, test_data$Churn, positive = "Yes")
roc_rf   <- roc(as.numeric(test_data$Churn == "Yes"), prob_rf, quiet = TRUE)

print(cm_rf$table)
results[["Random Forest"]] <- get_metrics(cm_rf, roc_rf)
cat(sprintf("  Accuracy: %.1f%% | AUC: %.3f\n",
            results[["Random Forest"]]$Accuracy,
            results[["Random Forest"]]$AUC))

# Feature importance plot
imp_df <- as.data.frame(importance(model_rf))
imp_df$Feature <- rownames(imp_df)
imp_df <- imp_df %>% arrange(desc(MeanDecreaseGini)) %>% head(15)

p_imp <- ggplot(imp_df, aes(x = reorder(Feature, MeanDecreaseGini), y = MeanDecreaseGini)) +
  geom_col(fill = "#2E86C1", alpha = 0.85) +
  coord_flip() +
  labs(title = "Random Forest — Top 15 Feature Importances",
       x = "Feature", y = "Mean Decrease Gini") +
  theme_minimal(base_size = 11)
ggsave(file.path(OUTPUT_DIR, "rf_feature_importance.png"), p_imp, width = 8, height = 5, dpi = 150)
cat("  Saved: rf_feature_importance.png\n")

# ROC curve — RF
png(file.path(OUTPUT_DIR, "roc_random_forest.png"), width = 600, height = 500, res = 120)
plot(roc_rf, col = "#27AE60", lwd = 2,
     main = sprintf("ROC — Random Forest (AUC = %.3f)", auc(roc_rf)))
abline(a = 0, b = 1, lty = 2, col = "grey")
dev.off()
cat("  Saved: roc_random_forest.png\n")

# ── Model 3: Decision Tree ────────────────────────────────────────────────────
cat("\n--- Model 3: Decision Tree ---\n")
set.seed(42)
model_dt <- rpart(Churn ~ ., data = train_data, method = "class",
                  control = rpart.control(cp = 0.01))

prob_dt  <- predict(model_dt, newdata = test_data, type = "prob")[, "Yes"]
pred_dt  <- predict(model_dt, newdata = test_data, type = "class")
cm_dt    <- confusionMatrix(pred_dt, test_data$Churn, positive = "Yes")
roc_dt   <- roc(as.numeric(test_data$Churn == "Yes"), prob_dt, quiet = TRUE)

print(cm_dt$table)
results[["Decision Tree"]] <- get_metrics(cm_dt, roc_dt)
cat(sprintf("  Accuracy: %.1f%% | AUC: %.3f\n",
            results[["Decision Tree"]]$Accuracy,
            results[["Decision Tree"]]$AUC))

# Decision tree plot
png(file.path(OUTPUT_DIR, "decision_tree_plot.png"), width = 1200, height = 700, res = 120)
rpart.plot(model_dt, type = 4, extra = 104, fallen.leaves = TRUE,
           main = "Decision Tree — Telco Churn Prediction")
dev.off()
cat("  Saved: decision_tree_plot.png\n")

# ROC curve — DT
png(file.path(OUTPUT_DIR, "roc_decision_tree.png"), width = 600, height = 500, res = 120)
plot(roc_dt, col = "#E74C3C", lwd = 2,
     main = sprintf("ROC — Decision Tree (AUC = %.3f)", auc(roc_dt)))
abline(a = 0, b = 1, lty = 2, col = "grey")
dev.off()
cat("  Saved: roc_decision_tree.png\n")

# ── Combined ROC curve ─────────────────────────────────────────────────────────
png(file.path(OUTPUT_DIR, "roc_all_models.png"), width = 700, height = 600, res = 120)
plot(roc_lr, col = "#2E86C1", lwd = 2, main = "ROC Curves — All Models")
lines(roc_rf, col = "#27AE60", lwd = 2)
lines(roc_dt, col = "#E74C3C", lwd = 2)
abline(a = 0, b = 1, lty = 2, col = "grey")
legend("bottomright", bty = "n",
       legend = c(
         sprintf("Logistic Regression (AUC=%.3f)", auc(roc_lr)),
         sprintf("Random Forest      (AUC=%.3f)", auc(roc_rf)),
         sprintf("Decision Tree      (AUC=%.3f)", auc(roc_dt))
       ),
       col = c("#2E86C1","#27AE60","#E74C3C"), lwd = 2)
dev.off()
cat("  Saved: roc_all_models.png\n")

# ── Comparison table ───────────────────────────────────────────────────────────
cat("\n=== MODEL COMPARISON TABLE ===\n")
comparison <- do.call(rbind, lapply(names(results), function(name) {
  r <- results[[name]]
  data.frame(
    Model     = name,
    Accuracy  = paste0(r$Accuracy, "%"),
    Precision = paste0(r$Precision, "%"),
    Recall    = paste0(r$Recall, "%"),
    F1        = paste0(r$F1, "%"),
    AUC       = r$AUC,
    stringsAsFactors = FALSE
  )
}))

print(comparison, row.names = FALSE)

write.csv(comparison, file.path(OUTPUT_DIR, "model_comparison.csv"), row.names = FALSE)
cat("\nSaved: model_comparison.csv\n")

# Save model objects
saveRDS(model_lr, file.path(OUTPUT_DIR, "model_logistic_regression.rds"))
saveRDS(model_rf, file.path(OUTPUT_DIR, "model_random_forest.rds"))
saveRDS(model_dt, file.path(OUTPUT_DIR, "model_decision_tree.rds"))
cat("Models saved as .rds files in outputs/\n")

cat("\n=== Churn Prediction complete ===\n")
