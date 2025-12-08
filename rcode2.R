packages <- c("phyloseq",     # Microbiome data handling
              "tidyverse",   # dplyr, tidyr, ggplot2
              "caret",       # ML + cross‑validation
              "randomForest",
              "pROC",        # ROC/AUC
              "doParallel")  # parallel backend for caret

new_pkgs <- packages[!(packages %in% installed.packages()[, "Package"])]
if (length(new_pkgs)) install.packages(new_pkgs)

lapply(packages, library, character.only = TRUE)

## 2. Read the built‑in dataset -------------------------------------------
data("GlobalPatterns")          # OTU table + sample metadata

# Inspect the data
print(head(otu_table(GlobalPatterns)))
print(sample_data(GlobalPatterns))

## 3. Pre‑process ---------------------------------------------------------
#  (a) Convert OTU counts → relative abundance
#  Note: OTU tables are usually raw counts; here they are already
#  log‑transformed in the GlobalPatterns data, but we’ll convert to
#  relative abundance anyway for clarity.
#  OTU table: OTUs × Samples
otu_mat <- as.matrix(otu_table(GlobalPatterns))
#  If values are counts (they are counts), convert to relative:
rel_abund <- sweep(otu_mat, 2, colSums(otu_mat), FUN = "/")

#  (b) Filter out very rare taxa (keep taxa with > 10 samples having > 0)
keep_taxa <- rowSums(rel_abund > 0) > 10
rel_abund_filtered <- rel_abund[keep_taxa, ]

#  (c) Create a tidy data.frame suitable for caret
library(tidyr)
library(dplyr)
df_long <- as.data.frame(t(rel_abund_filtered)) %>%   # Samples × Taxa
  mutate(Sample = rownames(.)) %>%
  pivot_longer(cols = -Sample,
               names_to = "Taxon",
               values_to = "Abundance")

#  Merge with sample metadata (metadata has column "SampleID" in GlobalPatterns)
metadata <- as(sample_data(GlobalPatterns), "data.frame") %>%
  tibble() %>%
  mutate(Sample = X.SampleID)   # why?

df_long <- left_join(df_long, metadata, by = "Sample")

#  For this demo we create a binary outcome:
#  “Host” column in GlobalPatterns indicates the host species
#  (e.g., human, rat, mouse, etc.).  We'll predict *Human* vs. *Non‑human*.
#df_long$HostBinary <- ifelse(df_long$Host == "Human", 1, 0)
#  regexpr("^[M|F].*", colnames(otu_table(GlobalPatterns))>0
df_long$HostBinary = factor(ifelse(regexpr("^[M|F].*", df_long$Sample)>0, "Human", "nothuman"))
df_long$Host = ifelse(regexpr("^[M|F].*", df_long$Sample)>0, "Human", "nothuman")

#  Keep only the samples that we used above
samples_used <- unique(df_long$Sample)
df_long <- df_long %>% filter(Sample %in% samples_used)

## 4. Build the feature matrix --------------------------------------------
#  Pivot back to wide format: Samples × Taxa
df_wide <- df_long %>%
  select(Sample, Taxon, Abundance, Host, HostBinary) %>%
  pivot_wider(names_from = Taxon,
              values_from = Abundance,
              values_fill = list(Abundance = 0))

#  Response vector
y <- df_wide %>% #mutate(HostBinary = ifelse(Host == "Human", 1, 0)) %>%
  arrange(match(Sample, samples_used)) %>%
  pull(HostBinary)

#  Feature matrix (remove Sample, Host, HostBinary columns)
X <- df_wide %>% select(-Sample, -Host, -HostBinary) %>%
  as.matrix()

## 5. Random Forest with caret -------------------------------------------
set.seed(2025)

#  Train/test split (70/30)
train_idx <- createDataPartition(y, p = .7, list = FALSE)
X_train <- X[train_idx, ]
y_train <- as.factor(y[train_idx])
X_test  <- X[-train_idx, ]
y_test  <- as.factor(y[-train_idx])

#  Cross‑validated Random Forest
rf_ctrl <- trainControl(method = "cv",
                        number = 5,
                        classProbs = TRUE,
                        summaryFunction = twoClassSummary,
                        verboseIter = FALSE)

rf_fit <- train(x = X_train,
                y = y_train,
                method = "rf",
                trControl = rf_ctrl,
                tuneLength = 5,
                metric = "ROC")

print(rf_fit)

## 6. Evaluation ----------------------------------------------------------
pred_prob  <- predict(rf_fit, X_test, type = "prob")[, "Human"]
pred_class <- predict(rf_fit, X_test)

conf_mat <- confusionMatrix(pred_class, y_test, positive = "Human")
print(conf_mat)

# ROC and AUC
roc_obj <- roc(y_test, pred_prob, levels = rev(levels(y_test)))
auc_val  <- auc(roc_obj)
print(paste0("Test AUC = ", round(auc_val, 3)))

plot(roc_obj, main = paste0("ROC – AUC = ", round(auc_val, 3)))

## 7. Variable importance ------------------------------------------------
imp <- varImp(rf_fit, scale = FALSE)
top_taxa <- imp$importance %>%
  tibble(Taxon = rownames(.), Importance = Overall) %>%
  arrange(desc(Importance)) %>%
  slice_head(n = 15)

ggplot(top_taxa, aes(x = reorder(Taxon, Importance), y = Importance)) +
  geom_col(fill = "darkorange") +
  coord_flip() +
  labs(title = "Top 15 Microbiome Features (Random Forest)",
       x = "Taxon",
       y = "Importance (OOB)") +
  theme_minimal()

