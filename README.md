# AnVILLLMs
examine LLM usage in NHGRI AnVIL

### NHGRI AnVIL – A Cloud‑Based Genomics “Lab‑Space”

| What | Why |
|------|-----|
| **Abbreviation** | **AnVIL** = *Analysis, Visualization, and Informatics Lab‑space* |
| **Sponsor** | National Human Genome Research Institute (NHGRI), part of the U.S. National 
Institutes of Health (NIH) |
| **Purpose** | To provide a secure, scalable, and interoperable cloud environment where 
researchers can **discover, access, analyze, and share** large‑scale genomic data – and to 
promote reproducible, FAIR‑compliant science. |

---

## 1.  Core Mission

1. **Centralize data** – Host all NIH‑funded genomic data (e.g., dbGaP, GDC, NIH Genomics 
Data Commons) in a single, harmonized portal.  
2. **Facilitate analysis** – Offer a suite of cloud‑native analytic tools (Jupyter, RStudio, 
Galaxy, etc.) that run on the same infrastructure that stores the data.  
3. **Enable reproducibility** – Every analysis is reproducible by packaging code, data, and 
environment in Docker/Kubernetes containers.  
4. **Streamline data access** – Simplify the often‑cumbersome dbGaP/IRB authorization process 
through a unified consent & data‑use framework.  
5. **Support FAIR principles** – Ensure data are Findable, Accessible, Interoperable, and 
Reusable.

---

## 2.  Architecture & Technology Stack

| Layer | Technology | Why It Matters |
|-------|------------|----------------|
| **Data Layer** | Google Cloud Storage, BigQuery, Cloud Spanner | Massive, highly available  storage and fast analytics on petabyte‑scale datasets. |
| **Compute Layer** | Kubernetes (Anthos), Cloud VMs, Docker | Flexible, scalable compute  that can run notebooks, pipelines, or high‑throughput jobs. |
| **Security & Governance** | IAM, Google Cloud KMS, dbGaP‑controlled access, AnVIL Consent &  Data‑Use Management (CDUM) | Ensures that sensitive PHI/PII remains protected and that only  authorized users can read/write data. |
| **Data Discovery & Integration** | AnVIL Data Catalog, Data Commons API, dbGaP metadata, GDC API | One-click search across all NIH datasets. |
| **Analysis & Visualization** | JupyterLab, RStudio, Galaxy, Nextflow, Snakemake, Dockstore, R/Bioconductor packages | “One‑stop shop” for downstream bioinformatics. |
| **Collaboration & Sharing** | Git, GitHub, Docker Hub, Notebooks, R Markdown, Shiny,  Interactive Dashboards | Enables sharing of code, reproducible workflows, and results. |
| **Cost Management** | Cloud Billing, Budgets, Usage Reports | Keeps research budgets  transparent and predictable. |

---

## 3.  Data Resources in AnVIL

| Resource | What It Contains | Typical Users |
|----------|------------------|---------------|
| **dbGaP** | Human genomic & phenotypic data with controlled access | Clinical researchers,  epidemiologists |
| **Genomic Data Commons (GDC)** | TCGA, TARGET, and other cancer genomics | Oncologists,  cancer genomics teams |
| **NIH Genomics Data Commons (GDC‑style)** | Broad array of phenotypic & omics datasets |  Multi‑omics investigators |
| **Other consortia (e.g., 1000 Genomes, TOPMed)** | Reference panels, population genetics |  Population genetics, ancestry research |
| **AnVIL Data Catalog** | Aggregated metadata, dataset descriptions | Data discovery across  all resources |

> **Note**: Many of these datasets are “controlled access”; you must obtain dbGaP credentials or submit an application. AnVIL simplifies this by providing a single portal for all 
consents.

---

## 4.  Analysis & Workflow Tools

| Tool | Key Features | Example Use Cases |
|------|--------------|-------------------|
| **JupyterLab** | Python/R notebooks, interactive visualizations | Exploratory data  analysis, machine learning prototypes |
| **RStudio Cloud** | R + Bioconductor, Shiny apps | Statistical genomics, pipeline debugging  |
| **Galaxy** | GUI for bioinformatics pipelines (e.g., variant calling, RNA‑seq) | Standard  workflows without scripting |
| **Nextflow / Snakemake** | Workflow execution on Kubernetes, reproducible pipelines |  Large‑scale, multi‑step pipelines |
| **Dockstore** | Containerized workflows, CWL/Snakemake/Nextflow specs | Sharing and versioning of analytic methods |
| **Google BigQuery** | SQL‑style queries on genomic tables | Population‑level association  studies |
| **Shiny / Dashboards** | Interactive reporting | Data portal dashboards, patient outcome  visualizations |

All of these run in the **same cloud environment** as the data, eliminating data transfer 
bottlenecks and reducing I/O costs.

---

## 5.  Security & Data Access Workflow

1. **Authentication** – Sign in with Google Cloud / NIH credentials.  
2. **Consent & Authorization** – Through the **AnVIL Consent & Data‑Use Management (CDUM)** 
interface, users can request access to controlled datasets.  
3. **Data Use Agreement** – Upon approval, a unique project ID is generated.  
4. **Access** – Users can read/write within the authorized project; all activity is logged.  
5. **Auditing** – Cloud Logging + NIH data‑use audits ensure compliance.

---

## 6.  How to Get Started

| Step | Action | Where |
|------|--------|-------|
| 1. **Create an AnVIL account** | Fill out the sign‑up form; link to an existing NIH or  Google Cloud account | https://anvil.terra.bio/ |
| 2. **Explore datasets** | Use the Data Catalog; filter by study, phenotype, data type |  AnVIL portal |
| 3. **Set up a workspace** | Create a new project; attach storage buckets; configure IAM |  Workspace UI |
| 4. **Launch an analysis tool** | Start a Jupyter, RStudio, or Galaxy session | Workspace >  “New” > “Analysis” |
| 5. **Run or upload a workflow** | Drag and drop from Dockstore, or write your own Nextflow  pipeline | Workspace > “Add Data / Workflows” |
| 6. **Publish results** | Share notebooks, Docker images, or Shiny apps; export to GitHub |  Workspace > “Share” |

---

## 7.  Use‑Case Highlights

| Project | Dataset | Tool Used | Outcome |
|---------|---------|-----------|---------|
| **Genome‑Wide Association Study of Type 2 Diabetes** | dbGaP (UKBB, DIAGRAM) | Jupyter +  BigQuery | Identified novel loci; published preprint in *Nature Genetics* |
| **Cancer Immune Microenvironment Analysis** | GDC TCGA | Galaxy + RStudio | Created an  interactive Shiny dashboard for clinicians |
| **Multi‑omics Drug Response Prediction** | TOPMed + GEO | Nextflow + Snakemake | Engineered  an ML model that predicts drug response; code deposited in Dockstore |
| **Open‑Source Variant Caller Benchmark** | 1000 Genomes | Docker + Galaxy | Published  standardized benchmarking pipeline on Docker Hub |

---

## 8.  The Big Picture: Why AnVIL Matters

| Issue | AnVIL Solution |
|-------|----------------|
| **Data silos** | Centralized catalog of all NIH genomic data |
| **Reproducibility gap** | Containerized workflows and standardized environments |
| **Cost of compute** | Cloud scaling eliminates local server maintenance |
| **Security concerns** | Robust IAM + dbGaP‑level access control |
| **Collaboration barriers** | Shared notebooks, Docker images, and Git integration |
| **Interoperability** | FAIR metadata standards, Data Commons APIs |

---

## 9.  Quick Reference

| URL | What It Is |
|-----|------------|
| https://anvil.terra.bio/ | AnVIL portal & workspace interface |
| https://datarepo.anvil.terra.bio/ | Data catalog & discovery |
| https://anvil.terra.bio/apidocs | REST APIs for programmatic access |
| https://dockstore.org/ | Containerized workflows (CWL, Nextflow) |
| https://github.com/nih-anvil | AnVIL community GitHub organization |

---

### Bottom Line

**NHGRI AnVIL is the NIH’s flagship cloud platform that turns raw genomic data into a 
“lab‑space” where researchers can *discover, analyze, and share* – all while staying 
compliant with privacy regulations and adhering to the FAIR principles.** It’s a one‑stop 
shop that brings together data, compute, tools, and collaboration under a single, secure 
umbrella, dramatically accelerating genomic research and discovery.
