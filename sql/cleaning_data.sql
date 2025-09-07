-- PROCESS PHASE 

-- Data transformation:

-- 1 -- Remove whitespace from the "Program" column
UPDATE sba_loans
SET program = TRIM(program);

	 -- Then convert column "Program" to VARCHAR(2)
ALTER TABLE sba_loans
ALTER COLUMN program TYPE VARCHAR(2)
USING program::VARCHAR(2);

-- 2 -- Convert column "JobsSupported" to INT
ALTER TABLE sba_loans
ALTER COLUMN jobs_supported TYPE INT
USING jobs_supported::INT;

/*  NOTE: If the data was imported with all columns as TYPE TEXT,  
    first set the column "JobsSupported" to TYPE FLOAT, and then to TYPE INT.  */
	
-- 3 -- Replace empty cells of the column "PaidInFullDate" to null values
UPDATE sba_loans
SET paid_in_full_date = NULL
WHERE paid_in_full_date = '';

	 -- Then convert column "PaidInFullDate" to type DATE
ALTER TABLE sba_loans
ALTER COLUMN paid_in_full_date TYPE DATE
USING paid_in_full_date::DATE;

-- 4 -- Replace empty cells of the column "FirstDisbursementDate" to null values
UPDATE sba_loans
SET first_disbursement_date = NULL
WHERE first_disbursement_date = '';

	 -- Finally convert column "FirstDisbursementDate" to type DATE
ALTER TABLE sba_loans
ALTER COLUMN first_disbursement_date TYPE DATE
USING first_disbursement_date::DATE;


/* With the data already integrated and loaded into the database,  
   we move on to data cleaning, creation, and filtering. */


-- Data cleaning:

-- 1 -- Delete duplicates and create table "sba_loans_nodup"
CREATE TABLE sba_loans_nodup AS
SELECT DISTINCT *
FROM sba_loans;

-- 2 -- Empy cells in column "project_county" and "business_type" detected
SELECT DISTINCT project_county FROM sba_loans_nodup
ORDER BY project_county; --FLAG: empty cells

SELECT DISTINCT business_type FROM sba_loans_nodup; -- FLAG: empty cells

	 -- Clean whitespaces and convert empty cells to type NULL
UPDATE sba_loans_nodup
SET project_county = NULL
WHERE TRIM(project_county) = '';

UPDATE sba_loans_nodup
SET business_type = NULL
WHERE TRIM(business_type) = '';

-- 3 -- Null values in column "naics_description" detected
	 -- (For now this does not affect our analysis, we will map it later if necessary)
SELECT DISTINCT naics_description FROM sba_loans_nodup
ORDER BY naics_description DESC; --FLAG NULL

-- 4 -- Check that there are no anomalies in the dates
SELECT first_disbursement_date, approval_date FROM sba_loans_nodup
WHERE first_disbursement_date < approval_date; --CHECK

-- 5 -- Perform some extra checks
SELECT	MIN(gross_approval), MAX(gross_approval),
		MIN(approval_date), MAX(approval_date),
		MIN(jobs_supported), MAX(jobs_supported),
		MIN(initial_interest_rate), MAX(initial_interest_rate)
FROM sba_loans_nodup; --CHECK


-- Creation of columns:

-- 1 -- Create a unique ID for each loan
ALTER TABLE sba_loans_nodup
ADD COLUMN loan_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY;

-- 2 -- Create a column that references the loan approval month
ALTER TABLE sba_loans_nodup
ADD COLUMN approval_m INT;

UPDATE sba_loans_nodup
SET approval_m = CASE	
                 	 WHEN EXTRACT(YEAR FROM approval_date) <> 2019 
                	 THEN EXTRACT(MONTH FROM approval_date)::INT
                  	 ELSE NULL
                 END;
-- 3 -- Create a column with the year-month (and day 1 for later grouping by date) of loan approval
ALTER TABLE sba_loans_nodup
ADD COLUMN approval_ym DATE;

UPDATE sba_loans_nodup
SET approval_ym = 	CAST(CONCAT(EXTRACT(YEAR FROM approval_date),'-', 
					EXTRACT(MONTH FROM approval_date),'-01') AS DATE);

-- 4 -- Create a column with the 2-digit NAICS code to perform a sectoral analysis
ALTER TABLE sba_loans_nodup
ADD COLUMN naics_code_2 CHAR(2);

UPDATE sba_loans_nodup
SET naics_code_2 = LEFT(naics_code,2);

-- 5 -- Create a categorical column that classifies loans by approved amount (≤50k, 50–150k, 150–350k, 350k–2M, >2M),
	 -- which will allow us to analyze credit risk behavior by loan size
ALTER TABLE sba_loans_nodup
ADD COLUMN size_bucket VARCHAR(10);

UPDATE sba_loans_nodup
SET size_bucket = CASE	WHEN gross_approval <= 50000 THEN '≤50k'
						WHEN gross_approval BETWEEN 50001 AND 150000 THEN '50-150k'
						WHEN gross_approval BETWEEN 150001 AND 350000 THEN '150-350k'
						WHEN gross_approval BETWEEN 350001 AND 2000000 THEN '350-2M'
						ELSE '>2M' END;

-- 6 -- Create a variable "default_flag" (BINARY BOOLEAN), which takes the value 1 if the loan  
	 -- recorded a charge-off and FALSE otherwise. This will allow us to directly calculate  
	 -- default rates on the portfolio
ALTER TABLE sba_loans_nodup
ADD COLUMN default_flag SMALLINT;

UPDATE sba_loans_nodup
SET default_flag = CASE WHEN gross_charge_off_amount > 0 THEN 1 ELSE 0 END;

-- 7 -- Standardize the "processing_method" column according to the abbreviation code
ALTER TABLE sba_loans_nodup
ADD COLUMN processing_code CHAR(3);

UPDATE sba_loans_nodup
SET processing_code = CASE WHEN processing_method = '7a General' THEN '7AG'
		 	 WHEN processing_method = '7a with EWCP' THEN '7EW'
			 WHEN processing_method = '7a with WCP' THEN 'WCP'
			 WHEN processing_method = 'Builders Line of Credit (CAPLine)' THEN 'SGC'
			 WHEN processing_method = 'Community Advantage Initiative' THEN 'CAI'
			 WHEN processing_method = 'Community Advantage International Trade' THEN 'CAT'
			 WHEN processing_method = 'Community Advantage RLOC' THEN 'CAR'
			 WHEN processing_method = 'Community Advantage Recovery Loan' THEN 'CRL'
			 WHEN processing_method = 'Contract Loan Line of Credit (CAPLine)' THEN 'CTR'
			 WHEN processing_method = 'Export Express' THEN 'EXP'
			 WHEN processing_method = 'International Trade Loans' THEN 'ITR'
			 WHEN processing_method = 'Preferred Lenders Program' THEN 'PLP'
			 WHEN processing_method = 'Preferred Lenders with EWCP' THEN 'PLW'
			 WHEN processing_method = 'Preferred Lenders with WCP' THEN 'PWC'
			 WHEN processing_method = 'SBA Express Program' THEN 'SBX'
			 WHEN processing_method = 'Seasonal Line of Credit (CAPLine)' THEN 'SLC'
			 WHEN processing_method = 'Standard Asset Base Working Capital Line of Credit (CAPLine)' THEN 'STC'
		END;
		
-- 8 -- Group the different processing methods into main categories  
	 -- (STANDARD, EXPORT/TRADE, COMMUNITY ADVANTAGE, CAPLINES, EXPRESS, PLP)
ALTER TABLE sba_loans_nodup
ADD COLUMN processing_bucket VARCHAR(20);

UPDATE sba_loans_nodup
SET processing_bucket = CASE	WHEN processing_code = '7AG' THEN 'STANDARD'
								WHEN processing_code = '7EW' THEN 'EXPORT/TRADE'
								WHEN processing_code = 'CAI' THEN 'COMMUNITY ADVANTAGE'
								WHEN processing_code = 'CAR' THEN 'COMMUNITY ADVANTAGE'
								WHEN processing_code = 'CAT' THEN 'COMMUNITY ADVANTAGE'
								WHEN processing_code = 'CRL' THEN 'COMMUNITY ADVANTAGE'
								WHEN processing_code = 'CTR' THEN 'CAPLINES'
								WHEN processing_code = 'EXP' THEN 'EXPRESS'
								WHEN processing_code = 'ITR' THEN 'EXPORT/TRADE'
								WHEN processing_code = 'PLP' THEN 'PLP'
								WHEN processing_code = 'PLW' THEN 'PLP'
								WHEN processing_code = 'PWC' THEN 'PLP'
								WHEN processing_code = 'SBX' THEN 'EXPRESS'
								WHEN processing_code = 'SGC' THEN 'CAPLINES'
								WHEN processing_code = 'SLC' THEN 'CAPLINES'
								WHEN processing_code = 'STC' THEN 'CAPLINES'
								WHEN processing_code = 'WCP' THEN 'CAPLINES' 
								ELSE NULL END;

-- 9 -- Create a table with the main study columns
DROP TABLE IF EXISTS fact_loans;
CREATE TABLE fact_loans AS
SELECT	loan_id, approval_date, approval_ym, approval_m, gross_approval, project_state,
		borr_state, bank_state, naics_code, naics_code_2, term_in_months, size_bucket,
		gross_charge_off_amount, default_flag, processing_code, processing_bucket
FROM sba_loans_nodup;

SELECT * FROM fact_loans; -- we get a table with 16 columns

-- 10 -- Finally, restore the original name "sba_loans" to the final table "sba_loans_nodup"
DROP TABLE IF EXISTS sba_loans;
ALTER TABLE sba_loans_nodup RENAME TO sba_loans;


-- Data filtering:

-- 1 -- Remove unnecessary columns
ALTER TABLE sba_loans
DROP COLUMN IF EXISTS "borr_city",
DROP COLUMN IF EXISTS "as_of_date",
DROP COLUMN IF EXISTS "program",
DROP COLUMN IF EXISTS "borr_name",
DROP COLUMN IF EXISTS "borr_street",
DROP COLUMN IF EXISTS "location_id",
DROP COLUMN IF EXISTS "bank_street",
DROP COLUMN IF EXISTS "bank_city",
DROP COLUMN IF EXISTS "bank_fdic_number",
DROP COLUMN IF EXISTS "bank_ncua_number",
DROP COLUMN IF EXISTS "congressional_district",
DROP COLUMN IF EXISTS "sba_district_office",
DROP COLUMN IF EXISTS "bank_zip",
DROP COLUMN IF EXISTS "franchise_code",
DROP COLUMN IF EXISTS "sold_second_market_ind",
DROP COLUMN IF EXISTS "processing_method";

-- Create the views found in the file "views.sql"

/* With this, we conclude the PROCESS PHASE, having 2 tables ("fact_loans", "sba_loans")  
   and 5 views (agg_m, agg_m_naics, agg_m_process, agg_m_size, agg_m_state) available for further analysis */