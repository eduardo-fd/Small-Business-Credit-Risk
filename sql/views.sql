-- VIEW LIST

-- Creamos vistas con las siguientes métricas:

	  		-- approved_cnt: Número de préstamos aprovados
			-- default_cnt: Número de incumplimientos (Default)
			-- default_rate: Tasa de incumplimiento observado (odr)
			-- chargeoff_sum: Saldo cancelado (irrecuperable)
			-- avg_amount: Promedio de la cantidad prestada
			
	  -- Segmentadas por:

	  -- Mes
CREATE VIEW agg_m AS
WITH aggregation AS (	SELECT	approval_ym,
						COUNT(*) AS approved_cnt, SUM(default_flag) AS default_cnt,
						SUM(gross_charge_off_amount) AS chargeoff_sum, ROUND(AVG(gross_approval), 2) AS avg_amount
						FROM fact_loans
						GROUP BY approval_ym)
SELECT	approval_ym, approved_cnt, default_cnt, CAST(default_cnt AS FLOAT)/CAST(approved_cnt AS FLOAT) AS default_rate, 
		chargeoff_sum, avg_amount
FROM aggregation;

	  -- Mes, Estado
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

	  -- Mes, NAICS
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

	  -- Mes, Monto de prestamo
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

	  -- Mes, Método de transmisión
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

-- Creamos el dataset para el modelo de predicción de impago
CREATE VIEW modeling_loans AS
SELECT loan_id, default_flag, gross_approval, term_in_months, naics_code_2, project_state, size_bucket, processing_bucket
FROM fact_loans;

SELECT * FROM modeling_loans; -- Una vez creado lo exportamos en formato CSV para el EDA y modelado en python

-- Exportamos también las vistas creadas
SELECT * FROM agg_m;
SELECT * FROM agg_m_state;
SELECT * FROM agg_m_naics;
SELECT * FROM agg_m_size;
SELECT * FROM agg_m_process;