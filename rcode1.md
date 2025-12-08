>>> Produce some R code that illustrates the use of random forests in a biology application.
Thinking...
We need to produce R code that illustrates use of random forests in a biology application. 
Should include typical bioinformatics data, maybe gene expression dataset, classification of 
disease states, or prediction of phenotype from genomic features. Show data loading, 
preprocessing, model training with randomForest or ranger, cross-validation, feature 
importance, plotting, etc.

Also we might need to import libraries, maybe use caret or tidymodels.

We can give a step-by-step example: using publicly available dataset, e.g., the "Pima Indians 
Diabetes" dataset? But that's not biology; better use "breast cancer Wisconsin dataset" or 
"TCGA" expression data.

Could also use a toy dataset like "iris" but that's not biology.

Better to use gene expression data: load from GEO using GEOquery; or use simulated data.

The user just asked for code, not explanation, but we can add comments to illustrate. The 
code should illustrate random forest in a biology application. Let's produce a reproducible 
example: load the "GSE18469" dataset from GEO, classify samples as healthy vs diseased based 
on expression of genes. Use randomForest.

Alternatively, we could use "TCGA" dataset from TCGAbiolinks to classify tumor subtypes. But 
to keep it simple, use "PANC1" vs "HPDE" cell lines dataset maybe.

We can use "TCGAbiolinks" to download gene expression data for a cancer type, e.g., breast 
cancer, with subtypes (e.g., luminal A vs basal). Then use randomForest to predict subtype.

We need to ensure code is clear and self-contained.

Alternatively, use the "GSE39582" dataset for colon cancer and predict recurrence.

Let's choose a simpler dataset: the "GSE2109" dataset for colorectal cancer gene expression. 
Use GEOquery to load the dataset. Then process it: filter, log transform, create a matrix of 
expression, label samples.

Alternatively, use the "TCGA" dataset from TCGAbiolinks: get RNA-seq counts for breast 
cancer, use PAM50 subtype labels.

We'll include code for:

- Load packages: TCGAbiolinks, SummarizedExperiment, dplyr, tidyr, randomForest, caret, 
ggplot2, pROC.

- Data retrieval: get expression and clinical data.

- Prepare matrix: log2(counts+1).

- Create binary outcome: e.g., luminal A vs others.

- Train random forest: 1000 trees, using cross-validation (caret train function).

- Evaluate performance: ROC curve, confusion matrix.

- Feature importance: top genes.

- Plotting.

Ok. Provide code with comments. Ensure we include library installation if necessary. Also 
mention that user should have internet connection to download data.

Let's produce final answer.
...done thinking.

Below is a **stand‑alone R script** that demonstrates how to use a Random‑Forest model to 
classify breast‑cancer subtypes from TCGA RNA‑seq data.  
The code

1. Downloads and preprocesses the data  
2. Builds a Random‑Forest classifier (using **`caret`** + **`randomForest`**)  
3. Evaluates the model (accuracy, ROC, confusion matrix)  
4. Shows variable importance (top genes)

```r
# ------------------------------------------------------------
#  Random Forest for Biology – Breast‑Cancer Subtype Prediction
# ------------------------------------------------------------
#  Author:  (Your Name / R Project)
#  Date:    2025‑12‑08
# ------------------------------------------------------------

## 1.  Load / install required packages ------------------------------------
packages <- c("TCGAbiolinks",   # TCGA data retrieval
              "SummarizedExperiment",
              "dplyr", "tidyr",
              "caret", "randomForest",   # ML
              "ggplot2", "pROC",          # Visualization
              "magrittr")                 # %>% pipe

new_pkgs <- packages[!(packages %in% installed.packages()[, "Package"])]
if (length(new_pkgs)) install.packages(new_pkgs)

lapply(packages, library, character.only = TRUE)

## 2.  Download TCGA‑BRCA RNA‑seq (HTSeq – Counts) ------------------------
# ----------------------------------------------------------
#  a) Query for expression data
# ----------------------------------------------------------
query_exp <- GDCquery(project = "TCGA-BRCA",
                      data.category = "Gene Expression Quantification",
                      data.type = "Gene Expression Quantification",
                      workflow.type = "HTSeq - Counts")

GDCdownload(query_exp, method = "api")          # Downloads ~10‑30 MB
exp_data  <- GDCprepare(query_exp)              # SummarizedExperiment

# ----------------------------------------------------------
#  b) Query for clinical data (subtype info)
# ----------------------------------------------------------
query_clin <- GDCquery(project = "TCGA-BRCA",
                       data.category = "Clinical",
                       file.type = "xml")

GDCdownload(query_clin)
clin_data <- GDCprepare_clinic(query_clin, clinical.info = "patient")

## 3.  Prepare the data ----------------------------------------------------
# ----------------------------------------------------------
#  a) Keep only samples that have PAM50 subtype (binary: LumA vs Others)
# ----------------------------------------------------------
#  PAM50 subtype is stored in "project.project_metadata$subtype"
#  (in XML clinical files) – we’ll merge on sample barcodes.
# ----------------------------------------------------------
#  Convert SummarizedExperiment to a data.frame
exp_df <- assay(exp_data)          # Genes × Samples
exp_df <- as.data.frame(exp_df)
exp_df$Gene <- rownames(exp_df)
exp_df <- exp_df %>% tidyr::pivot_longer(
  cols = -Gene,
  names_to = "Sample",
  values_to = "Counts"
)

#  Merge with clinical data
#  Clinical data may have patient barcodes; we need sample barcodes.
#  Sample barcodes: TCGA-xx-xxxx-xxA-xxA-xx-xxA
#  Patient barcodes: TCGA-xx-xxxx
sample2patient <- sub("(\\w{2}-\\w{4}-\\w{4}-\\w)(.*)", "\\1", exp_df$Sample)
exp_df$Patient <- sample2patient
exp_df <- left_join(exp_df, clin_data, by = c("Patient" = "bcr_patient_barcode"))

#  Keep only PAM50 subtypes that are non‑missing
pam50 <- exp_df %>%
  filter(!is.na(pam50)) %>%
  distinct(Sample, pam50)

#  Binary outcome: 1 = LumA (Luminal A), 0 = All other subtypes
pam50$SubtypeBin <- ifelse(pam50$pam50 == "LumA", 1, 0)

#  Merge back to expression
exp_long <- left_join(exp_df, pam50, by = "Sample")

# ----------------------------------------------------------
#  b) Build a gene‑by‑sample matrix (log2(count+1))
# ----------------------------------------------------------
exp_matrix <- exp_long %>%
  mutate(LogCounts = log2(Counts + 1)) %>%
  select(Sample, Gene, LogCounts) %>%
  pivot_wider(names_from = Gene, values_from = LogCounts)

#  Convert to matrix
sample_ids <- exp_matrix$Sample
expr_mat   <- as.matrix(exp_matrix[,-1])   # all genes

#  Remove genes with too many missing values
expr_mat[is.na(expr_mat)] <- 0   # simple imputation

# ----------------------------------------------------------
#  c) Create final data frame for modeling
# ----------------------------------------------------------
#  Response vector
y <- pam50 %>% filter(Sample %in% sample_ids) %>%
  arrange(match(Sample, sample_ids)) %>%
  pull(SubtypeBin)

#  Feature matrix
X <- expr_mat[match(sample_ids, rownames(expr_mat)), ]

## 4.  Train / Validate Random Forest ---------------------------------------
set.seed(123)

#  Create a training‑test split (80/20)
train_index <- createDataPartition(y, p = .8, list = FALSE)
X_train  <- X[train_index, ]
y_train  <- as.factor(y[train_index])
X_test   <- X[-train_index, ]
y_test   <- as.factor(y[-train_index])

#  Train Random Forest via caret
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

#  Predict on test set
pred_prob <- predict(rf_fit, X_test, type = "prob")[, "1"]
pred_class <- predict(rf_fit, X_test)

#  Evaluation ------------------------------------------------------------
conf_mat <- confusionMatrix(pred_class, y_test, positive = "1")
print(conf_mat)

#  ROC curve -------------------------------------------------------------
roc_obj <- roc(y_test, pred_prob, levels = rev(levels(y_test)))
auc_val  <- auc(roc_obj)
print(paste0("Test AUC = ", round(auc_val, 3)))

plot(roc_obj, main = paste0("ROC Curve – AUC = ", round(auc_val, 3)))

#  Feature Importance -----------------------------------------------------
rf_importance <- varImp(rf_fit, scale = FALSE)
top_genes <- rf_importance$importance %>%
  tibble(Gene = rownames(.), Importance = Overall) %>%
  arrange(desc(Importance)) %>%
  slice_head(n = 20)

ggplot(top_genes, aes(x = reorder(Gene, Importance), y = Importance)) +
  geom_col(fill = "steelblue") +
  coord_flip() +
  labs(title = "Top 20 Genes by Random Forest Importance",
       x = "Gene",
       y = "Importance (OOB)") +
  theme_minimal()

## 5.  (Optional) Save results ---------------------------------------------
saveRDS(rf_fit, file = "rf_brca_subtype_classifier.rds")
write_csv(top_genes, "top_20_genes.csv")
```

### What the script does

| Step | Purpose | Key functions |
|------|---------|---------------|
| **1** | Install & load libraries | `install.packages()`, `library()` |
| **2** | Pull TCGA‑BRCA HTSeq‑count data + XML clinical files | `GDCquery()`, 
`GDCdownload()`, `GDCprepare()` |
| **3** | Merge counts → sample → patient → PAM50 subtype | `dplyr`, `tidyr`, `left_join()` |
| **4** | Build a **log‑transformed, gene‑by‑sample matrix** | `pivot_wider()`, `log2()` |
| **5** | Binary outcome: Luminal‑A vs. Other | `ifelse()` |
| **6** | Train a Random‑Forest with 5‑fold CV | `caret::train()` |
| **7** | Test‑set predictions, accuracy & ROC | `confusionMatrix()`, `pROC::roc()` |
| **8** | Plot top 20 predictive genes | `varImp()` + `ggplot2` |

---

#### Why this is “biology‑friendly”

- **Data source** – TCGA is a gold‑standard cancer genomics repository.  
- **Feature set** – thousands of genes (high‑dimensional omics).  
- **Outcome** – clinically meaningful breast‑cancer subtypes (PAM50).  
- **Interpretation** – gene importance can be mapped back to biology (e.g., known drivers).  

Feel free to adapt the script:

- Change `pam50` to a multiclass PAM50 model (`method = "multinom"` in `caret`)  
- Replace TCGA‑BRCA with another TCGA project (`project = "TCGA-OVCA"`, etc.)  
- Use `ranger` for faster trees if you have > 10 k samples.  

Happy modeling!
