# Small Business Credit Risk – SBA 7(a) Loans

## 📌 Description
This project analyzed the performance and credit risk of loans guaranteed by the **U.S. Small Business Administration (SBA)**, specifically under the **7(a)** program.  
The goal was to build an **end-to-end** (E2E) pipeline covering everything from data preparation and import to the creation of aggregated views and a fact table ready for analysis and visualization.

---

## 📊 Data Source
- Source: [SBA Open Data Portal](https://data.sba.gov/en/dataset/7-a-504-foia)  
- Dataset: *FOIA – 7(a) Loans (FY2020 – Present)*  
- Official dictionary: available in the same source  
- Download date: 08/24/2025  

The public 7(a) & 504 FOIA database, published by the U.S. Small Business Administration (SBA), a federal agency of the United States, is a dataset that contains historical and current records of loans granted under the 7(a) and 504 programs. This data is published in compliance with the Freedom of Information Act (FOIA).

This study explores the most recent data from the 2020–2025 period. The dataset is provided in CSV tabular format, where each row corresponds to a loan approved under the SBA 7(a) program, which is the general program for Small and Medium-sized Enterprises. The columns contain information about the borrower, financial institution, approval amounts, interest terms, loan status, and key dates (approval, first disbursement, full repayment, charge-off). The dictionary is recommended for further details.

---

## 🎯 Project Objective
The objective of this project is to investigate credit risk in SBA 7(a) loans (U.S., 2020–2025) in order to improve origination decisions. The analysis identifies higher-risk segments by industry (NAICS), geography (State), loan size, and program type, and builds a simple, interpretable logistic model (PD) that ranks applicants by probability of default.

Based on the ranked loans by PD (deciles), an action threshold (cut-off) is defined to prioritize review/limit adjustments and estimate the expected impact on charge-off. The results are communicated through a dashboard with KPIs by cohorts/vintages, maps, segment tables, and an executive memo with actionable recommendations.

---

## 🛠️ Tools Used
- **Excel**: Dictionary, initial exploration (Power Query), and mapping.
- **PostgreSQL**: Import, cleaning, transformation/metric creation, aggregation queries, feature engineering, and exploratory data analysis.
- **Python**: Simple logistic model to estimate PD (Probability of Default).  
- **Power BI**: Interactive visualization of metrics and insights.

---

## 📂 Repository Structure
```
data/                # Raw CSV, cleaned, and modeling dataset
sql/                 # Scripts SQL: schema, cleaning, views, exploratory analysis
notebooks/           # Python notebooks with the simple logit model
dashboard/           # Dashboard Power BI (.pbix)
outputs/             # CSV: deciles, PD scores and aggregates
docs/                # Scope of Work, dashboard screenshots, dictionary, README.md (Spanish)
README.md            # Main project documentation
requirements.txt     # Python dependencies
LICENSE              # MIT license
```

---

## 🔄 Methodology (Case Study Roadmap)

### 1. Ask
The main goal was defined as analyzing **credit risk** in SBA 7(a) loans.

Key research questions: 
- Which factors have the strongest influence on the probability of default?
- Are there differences in default rates by state, industry, loan size, or program type?
- How do defaults evolve over time?
- How can we decrease credit risk without sacrificing to much volume?

---

### 2. Prepare
In the preparation phase, the data was downloaded from the official SBA portal and the reliability of the source was verified (meets ROCCC criteria). The data was then stored and loaded in to the RDBMS PostgreSQL. Inside, the **Small-Business Credit Risk** database was created together with the initial **sba_loans** table.

Import format used:
- Format: CSV
- Header: Yes (HEADER)
- Delimiter: comma (,)
- Text and escape quotes: double quotes (")

Validations and initial formatting issues were documented for date fields and missing values:
- Row count validation against the original CSV.
- Review of date formats (ApprovalDate, PaidInFullDate, FirstDisbursementDate).
- Detection of empty values ('') and duplicates.
- Conversion of variables to appropriate types: NUMERIC(10,2) for amounts, DATE for dates, SMALLINT for terms, etc.

Two paths are defined for continuing the study:

1. **Fast track**: Run *final schema* and *load clean data*

📂 /data/ → `fact_loans.csv`  
📂 /sql/ → `fact_loans_schema.sql`, `views.sql` (create views)

2. **Step by step**: Run *initial schema* and *load raw data* (data cleaning documented in **Process**)

📂 /data/ → `sba_loans_raw.csv` (not included due to size) available in SBA Open Data Portal  
📂 /sql/ → `sba_loans_schema.sql`, `cleaning_data.sql` (data cleaning), `views.sql` (create views)

---

### 3. Process
In the processing phase, the data was loaded and minor issues documented during the initial import were corrected.
- Empty or inconsistent date formats (""): Temporarily set affected columns to TEXT.
- Decimal values in columns conceptually meant to be integers: Temporarily set affected column to FLOAT.

resources:  
📂 /sql/ → `cleaning_data.sql`, `views.sql`

#### 3.1 Data Cleaning
Data cleaning and initial checks were performed:

- Converted variables to appropriate types (`INT`, `DATE`).  
- Removed duplicates.  
- Normalized empty values to `NULL`.  
- Performed some additional checks to ensure integrity.

#### 3.2 Feature Engineering
Created useful columns for the analysis:

- Created and set a unique identifier `loan_id`.  
- Created `approval_ym` and `approval_m` (year-month and month of approval).  
- Derived `naics_code_2` (2-digit industry code).  
- Created `size_bucket` (approved amount ranges).  
- Created `default_flag` (binary default indicator).  
- Created `processing_code` and `processing_bucket` (categorization of processing methods).  
- Removed unnecessary/irrelevant columns for the study.

#### 3.3 Fact Table
Created the `fact_loans` table with 16 main variables for analysis:

- Identifier (`loan_id`)  
- Dates (`approval_date`, `approval_ym`, `approval_m`)  
- Approved amount (`gross_approval`)  
- State (`project_state`, `borr_state`, `bank_state`)  
- Sector (`naics_code`, `naics_code_2`)  
- Term (`term_in_months`)  
- Buckets (`size_bucket`)  
- Risk (`default_flag`, `gross_charge_off_amount`)  
- Processing (`processing_code`, `processing_bucket`)  

#### 3.4 Aggregated Views
Defined SQL views for aggregated analysis:

- `agg_m`: metrics by month  
- `agg_m_state`: metrics by month and state  
- `agg_m_naics`: metrics by month and sector  
- `agg_m_size`: metrics by month and loan amount bucket  
- `agg_m_process`: metrics by month and processing method  
- `modeling_loans`: filtered data for predictive PD modeling  

Finally, all views were exported in CSV format.

---

### 4. Analyze
Once the ETL and data processing phases were completed, an exploratory analysis was conducted to identify patterns and extract actionable insights. A logistic model was then created to predict the probability of default (PD) for each loan.

resources:  
📂 /sql/ → `eda_modeling.sql`  
📂 /notebooks/ → `pd_modeling.ipynb`

#### 4.1 Exploratory Data Analysis
EDA was performed in both SQL and Python (histograms and final checklist), from which the following insights were extracted:

- Imbalanced dataset, with ~1.1% of loans in default.  
- Highest default rate in the Transportation and Warehousing sector.  
- Loan amount distribution heavily skewed toward lower values (few large/multi-million loans).  
- Negative correlation between loan amount and probability of default.  
- States with higher default rates: Nevada, Los Angeles, and Florida.  
- Negative correlation between loan term and default rate. However, this hypothesis was discarded due to the short window observed (2020–2025), since longer terms may not have matured.  
- High default rate in "COMMUNITY ADVANTAGE" programs (higher assumed risk).  

#### 4.2 Logistic Model (PD)
A model was built to predict the probability of default (PD), using the binary dependent variable `default_flag` together with regressors known at the time of loan origination (before default): gross_approval, term_in_months, naics_code_2, project_state, size_bucket, processing_bucket.

For model training, `class_weight='balanced'` was set to weight loans properly, and the dataset was split into 80% training and 20% test. Results were evaluated with AUC and KS, yielding very favorable values that indicated strong predictive power (AUC=0.865, KS=0.632).

Finally, a `pd_score` (probability of default) was calculated for each loan (`pd_scores.csv`), loans were sorted by PD and divided into 10 groups (deciles) (`decile_summary.csv`). For each decile we measured: number of loans, number of defaults, default rate (ODR), cumulative % of defaults, and volume.

The top deciles concentrate most defaults in a small fraction of the volume, enabling a bank to focus risk management on the most exposed segments with reduced cost.

---

### 5. Share
To effectively communicate the results, an interactive Power BI dashboard was designed with three main pages, targeted at different business audiences.

resources:  
📂 /dashboard/ → `dashboard.pbix`  
📂 /docs/ → `executive_dashboard.PNG`, `risk_dashboard.PNG`, `cohorts_dashboard.PNG`

### A) Executive Overview
![Executive Overview](/docs/executive_dashboard.PNG)

- Objective: provide a general overview of the SBA loan portfolio.  
- Content: key metrics (approved, ODR, charge-off), time trends, distribution by state (map), NAICS sectors, loan size, and program type.  
- Key insight: the average ODR is stable, but risk concentrations exist in certain states and industries.  

### B) Risk (PD Model)
![Risk Model](/docs/risk_dashboard.PNG)

- Objective: show the performance of the trained logistic model.  
- Content: decile table, default rate by decile, cumulative capture curve, AUC and KS metrics, map with average PD by state.  
- Key insight: deciles 9–10 capture ~81% of defaults with only ~20% of the volume, allowing for an efficient operational cut-off.  

### C) Cohorts / Vintages
![Cohorts](/docs/cohorts_dashboard.PNG)

- Objective: analyze risk trends by origination cohorts.  
- Content: ODR evolution by approval month/year (optional State and Industry), broken down by loan size and program type.  
- Key insight: performance differences are observed across loan generations depending on program type and total loan amount.  

---

### 6. Act

### Objective
Reduce charge-off losses without significantly sacrificing the volume of approved loans.

### What we did
- Full ETL and data cleaning (SBA FOIA, snapshot 2025-06-30).  
- Created metrics and KPIs by cohorts, industries, and states.  
- Built a logistic probability of default (PD) model, segmented into deciles.  

### Key Results
- AUC=0.865, KS=0.632 → robust model, strong discrimination power.  
- Cut-off decile ≥9 → captures ~81% of defaults with only ~20% of the volume.  
- Cut-off decile ≥8 → captures ~90% of defaults with ~30% of the volume.  

### Observed Patterns
- Higher risk in Community Advantage programs.  
- Transportation and Warehousing sector with elevated ODR.  
- Nevada with above-average default incidence.  

### Recommendation
Adopt an operational cut-off at decile ≥9, complemented with:  
- Manual review of loans in ≥9.  
- Stricter amount/tenor limits for ≥9.  

### Limitations
- Temporal censoring (future defaults not yet observed).  
- Model estimates default risk, not expected loss.  

### Next Steps
- Integrate LGD and EAD to estimate Expected Loss. 
- Stress testing with macroeconomic scenarios.  


## 🚀 How to Reproduce the Project
To clone and run the project locally:

```bash
git clone https://github.com/your-username/Small-Business-Credit-Risk.git
cd Small-Business-Credit-Risk

# Create virtual environment
python3 -m venv .venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
