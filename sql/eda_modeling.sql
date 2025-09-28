-- ANALYZE PHASE 

-- Exloratorty Data Analysis (EDA):
SELECT * FROM fact_loans;

-- 1 -- Default rate
SELECT COUNT(*) AS total, SUM(default_flag) AS num_defaults, CAST(SUM(default_flag) AS FLOAT)/COUNT(*) AS default_rate
FROM fact_loans;

/*  The total number of loans is 330,353, of which 3,737 defaulted.  
    We can see that the dataset is imbalanced: ~1.1% of the loans are in default. */

-- 2 -- Probability of default by sector
WITH sector_data AS (SELECT naics_code_2, COUNT(*) AS total, SUM(default_flag) AS num_defaults, 
							CAST(SUM(default_flag) AS FLOAT)/COUNT(*) AS default_rate_sector
					 FROM fact_loans
					 GROUP BY naics_code_2)	
SELECT naics_code_2, total, num_defaults, default_rate_sector
FROM sector_data
WHERE default_rate_sector > (SELECT CAST(SUM(default_flag) AS FLOAT)/COUNT(*) AS default_rate
							 FROM fact_loans) * 1.2
ORDER BY default_rate_sector DESC;
	 -- We set a 20% lift threshold relative to the portfolio average default rate

/*  We can see that the naics code with above average default rate with a 20% lift are the 48, 22 and 49,
	related to the sectors of: Transportation and Warehousing (48-49), and Utilities (49). */

-- 3 -- Distribution of loans by amount
SELECT size_bucket, COUNT(*) total_loans 
FROM fact_loans
GROUP BY size_bucket
ORDER BY total_loans DESC;

/*  Looking at loan amount ranges, most loans fall within the 350k–2M range,  
    followed by loans below 50k and those between 50–150k.  
    Multi-million loans are quite rare compared to other amounts.  
    Overall, the loan amount distribution is heavily skewed toward lower values: 0–150k > 350k–2M  */

-- 4 -- Probability of default by loan amount
SELECT size_bucket, COUNT(*) AS total, SUM(default_flag) AS num_defaults, 
CAST(SUM(default_flag) AS FLOAT)/COUNT(*) AS default_rate_pct 
FROM fact_loans
GROUP BY size_bucket
ORDER BY default_rate_pct DESC;

SELECT size_bucket, COUNT(*) AS total, SUM(default_flag) AS num_defaults, 
CAST(SUM(default_flag) AS FLOAT)/COUNT(*) AS default_rate_pct
FROM fact_loans
GROUP BY size_bucket
HAVING 
		CAST(SUM(default_flag) AS FLOAT)/COUNT(*) 
		>
		(SELECT CAST(SUM(default_flag) AS FLOAT)/COUNT(*) AS default_rate		
		 FROM fact_loans) * 1.2
ORDER BY default_rate_pct DESC;

/*  We can observe a negative correlation: the higher the loan amount range, the lower the default percentage. 
	Also, the default_rate than are higher than the average + 20% lift are the loans below 50k and between 50-150k. */

-- 5 -- Probability of default by state

SELECT project_state, COUNT(*) AS total, SUM(default_flag) AS num_defaults, 
CAST(SUM(default_flag) AS FLOAT)/COUNT(*) AS default_rate_pct 
FROM fact_loans
GROUP BY project_state
HAVING 
		CAST(SUM(default_flag) AS FLOAT)/COUNT(*) 
		>
		(SELECT CAST(SUM(default_flag) AS FLOAT)/COUNT(*) AS default_rate		
		 FROM fact_loans) * 1.2
ORDER BY default_rate_pct DESC;

/*  States that show a default_rate above the average with a 20% lift are:
	- NV → Nevada
	- LA → Louisiana
	- FL → Florida
	- NY → New York
	- HI → Hawaii
	- CA → California
	- IL → Illinois
	- SD → South Dakota
	- NJ → New Jersey
	- AZ → Arizona
*/

-- 6 -- Probability of default by loan term
WITH month_bucket AS (	SELECT 	*,
								CASE WHEN term_in_months <= 60 THEN '≤60'
			 						 WHEN term_in_months BETWEEN 61 AND 120 THEN '61-120'
			 						 WHEN term_in_months BETWEEN 121 AND 240 THEN '121-240'
			 						 WHEN term_in_months BETWEEN 241 AND 300 THEN '241-300'
			 						 WHEN term_in_months >300 THEN '>300' END AS term_months_bucket
						FROM fact_loans  )
SELECT term_months_bucket, COUNT(*) AS total, SUM(default_flag) AS num_defaults, 
CAST(SUM(default_flag) AS FLOAT)/COUNT(*) AS default_rate_pct   
FROM month_bucket
GROUP BY term_months_bucket
ORDER BY default_rate_pct DESC;

/*  Looking at loan terms, we observe a negative correlation: the longer the term,  
    the lower the default rate. We have to keep in mind the short window we are analyzing (2020–2025),  
    so the information is likely biased.  */

-- 7 -- Probability of default by loan processing type
SELECT processing_bucket, COUNT(*) AS total, SUM(default_flag) AS num_defaults, 
CAST(SUM(default_flag) AS FLOAT)/COUNT(*) AS default_rate 
FROM fact_loans
GROUP BY processing_bucket
HAVING 
		CAST(SUM(default_flag) AS FLOAT)/COUNT(*) 
		>
		(SELECT CAST(SUM(default_flag) AS FLOAT)/COUNT(*) AS default_rate		
		 FROM fact_loans) * 1.2
ORDER BY default_rate DESC; 

/*  Finally, we observe a significant probability of default for loans processed through  
    "COMMUNITY ADVANTAGE" a Small Business Administration (SBA) loan program that supports  
    small businesses, both new and existing, in certain geographic areas.  
    It focuses on businesses that do not qualify for traditional financing but show potential for success.  
    The risk is quite high in this type of loan, with an observed default rate of ~4.9%. 
	Also, "EXPRESS" programs tend to have an above average default rate + 20% lift, and should be taken also into
	account at origination.
*/