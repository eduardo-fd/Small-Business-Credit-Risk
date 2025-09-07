-- VIEW LIST

-- Create views with the following metrics:

        -- approved_cnt: Number of approved loans
        -- default_cnt: Number of defaults
        -- default_rate: Observed default rate (odr)
        -- chargeoff_sum: Charged-off balance (unrecoverable)
        -- avg_amount: Average loan amount
        
-- Segmented by:

	  -- Month
CREATE VIEW agg_m AS
WITH aggregation AS (	SELECT	approval_ym,
						COUNT(*) AS approved_cnt, SUM(default_flag) AS default_cnt,
						SUM(gross_charge_off_amount) AS chargeoff_sum, ROUND(AVG(gross_approval), 2) AS avg_amount
						FROM fact_loans
						GROUP BY approval_ym)
SELECT	approval_ym, approved_cnt, default_cnt, CAST(default_cnt AS FLOAT)/CAST(approved_cnt AS FLOAT) AS default_rate, 
		chargeoff_sum, avg_amount
FROM aggregation;

	  -- Month, State
CREATE VIEW agg_m_state AS
WITH aggregation AS (	SELECT	approval_ym, project_state,
						COUNT(*) AS approved_cnt, SUM(default_flag) AS default_cnt,
						SUM(gross_charge_off_amount) AS chargeoff_sum, ROUND(AVG(gross_approval), 2) AS avg_amount
						FROM fact_loans
						GROUP BY approval_ym, project_state)
SELECT	approval_ym, project_state, approved_cnt, default_cnt, 
		CAST(default_cnt AS FLOAT)/CAST(approved_cnt AS FLOAT) AS default_rate, 
		chargeoff_sum, avg_amount
FROM aggregation;

	  -- Month, NAICS
CREATE VIEW agg_m_naics AS
WITH aggregation AS (	SELECT	approval_ym, naics_code_2,
						COUNT(*) AS approved_cnt, SUM(default_flag) AS default_cnt,
						SUM(gross_charge_off_amount) AS chargeoff_sum, ROUND(AVG(gross_approval), 2) AS avg_amount
						FROM fact_loans
						GROUP BY approval_ym, naics_code_2)
SELECT	approval_ym, naics_code_2, approved_cnt, default_cnt, 
		CAST(default_cnt AS FLOAT)/CAST(approved_cnt AS FLOAT) AS default_rate, 
		chargeoff_sum, avg_amount
FROM aggregation;

	  -- Month, Loan amount
CREATE VIEW agg_m_size AS
WITH aggregation AS (	SELECT	approval_ym, size_bucket,
						COUNT(*) AS approved_cnt, SUM(default_flag) AS default_cnt,
						SUM(gross_charge_off_amount) AS chargeoff_sum, ROUND(AVG(gross_approval), 2) AS avg_amount
						FROM fact_loans
						GROUP BY approval_ym, size_bucket)
SELECT	approval_ym, size_bucket, approved_cnt, default_cnt, 
		CAST(default_cnt AS FLOAT)/CAST(approved_cnt AS FLOAT) AS default_rate, 
		chargeoff_sum, avg_amount
FROM aggregation;

	  -- Month, Transmition method
CREATE VIEW agg_m_process AS
WITH aggregation AS (	SELECT	approval_ym, processing_bucket,
						COUNT(*) AS approved_cnt, SUM(default_flag) AS default_cnt,
						SUM(gross_charge_off_amount) AS chargeoff_sum, ROUND(AVG(gross_approval), 2) AS avg_amount
						FROM fact_loans
						GROUP BY approval_ym, processing_bucket)
SELECT	approval_ym, processing_bucket, approved_cnt, default_cnt, 
		CAST(default_cnt AS FLOAT)/CAST(approved_cnt AS FLOAT) AS default_rate, 
		chargeoff_sum, avg_amount
FROM aggregation;

-- Create the dataset for the default prediction model
CREATE VIEW modeling_loans AS
SELECT loan_id, default_flag, gross_approval, term_in_months, naics_code_2, project_state, size_bucket, processing_bucket
FROM fact_loans;

SELECT * FROM modeling_loans; -- Once created, export it in CSV format for EDA and modeling in Python

-- Export the created views as well
SELECT * FROM agg_m;
SELECT * FROM agg_m_state;
SELECT * FROM agg_m_naics;
SELECT * FROM agg_m_size;
SELECT * FROM agg_m_process;