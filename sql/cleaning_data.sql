-- PROCESS PHASE 

-- Transformación de datos:

-- 1 -- Eliminamos espacios en blanco de la columna "Program"
UPDATE sba_loans
SET program = TRIM(program);

	 -- Luego convertimos columna "Program" a VARCHAR(2)
ALTER TABLE sba_loans
ALTER COLUMN program TYPE VARCHAR(2)
USING program::VARCHAR(2);

-- 2 -- Convertimos columna "JobsSupported" a numeros enteros
ALTER TABLE sba_loans
ALTER COLUMN jobs_supported TYPE INT
USING jobs_supported::INT;

/*	NOTA: Si la importación de datos se realizó con todas las columnas como TYPE TEXT, 
	establece primero la columna "JobsSupported" a TYPE FLOAT, y luego a TYPE INT. */
	
-- 3 -- Remplazamos las casillas vacias de la columna "PaidInFullDate" a valores nulos
UPDATE sba_loans
SET paid_in_full_date = NULL
WHERE paid_in_full_date = '';

	 -- Luego convertimos la columna "PaidInFullDate" a tipo DATE
ALTER TABLE sba_loans
ALTER COLUMN paid_in_full_date TYPE DATE
USING paid_in_full_date::DATE;

-- 4 -- Remplazamos las casillas vacias de la columna "FirstDisbursementDate" a valores nulos
UPDATE sba_loans
SET first_disbursement_date = NULL
WHERE first_disbursement_date = '';

	 -- Finalmente convertimos la columna "FirstDisbursementDate" a tipo DATE
ALTER TABLE sba_loans
ALTER COLUMN first_disbursement_date TYPE DATE
USING first_disbursement_date::DATE;


/* Ya con los datos integrados y cargados en la base de datos, pasamos a la limpieza, 
creación y filtración de datos. */


-- Limpieza de datos:

-- 1 -- Eliminamos duplicados y creamos una nueva tabla temporal "sba_loans_nodup"
CREATE TABLE sba_loans_nodup AS
SELECT DISTINCT *
FROM sba_loans;

-- 2 -- Detectamos casillas vacias en las columnas "project_county" y "business_type"
SELECT DISTINCT project_county FROM sba_loans_nodup
ORDER BY project_county; --FLAG: casillas vacias

SELECT DISTINCT business_type FROM sba_loans_nodup; -- FLAG: casillas vacias

	 -- Limpiamos los espacios en blanco y convertimos las casillas vacias a NULL
UPDATE sba_loans_nodup
SET project_county = NULL
WHERE TRIM(project_county) = '';

UPDATE sba_loans_nodup
SET business_type = NULL
WHERE TRIM(business_type) = '';

-- 3 -- Detectamos Null values en "naics_description" 
	 -- (De momento no afecta a nuestro análisis, mapearemos luego si es necesario)
SELECT DISTINCT naics_description FROM sba_loans_nodup
ORDER BY naics_description DESC; --FLAG NULL

-- 4 -- Comprobamos que no hayan anomalías en las fechas
SELECT first_disbursement_date, approval_date FROM sba_loans_nodup
WHERE first_disbursement_date < approval_date; --CHECK

-- 5 -- Realizamos algunas comprobaciones extra
SELECT	MIN(gross_approval), MAX(gross_approval),
		MIN(approval_date), MAX(approval_date),
		MIN(jobs_supported), MAX(jobs_supported),
		MIN(initial_interest_rate), MAX(initial_interest_rate)
FROM sba_loans_nodup; --CHECK


-- Creación de columnas:

-- 1 -- Creamos un ID único para cada prestamo
ALTER TABLE sba_loans_nodup
ADD COLUMN loan_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY;

-- 2 -- Creamos una columna que haga referencia al mes de aceptación del préstamo
ALTER TABLE sba_loans_nodup
ADD COLUMN approval_m INT;

UPDATE sba_loans_nodup
SET approval_m = CASE	
                 	 WHEN EXTRACT(YEAR FROM approval_date) <> 2019 
                	 THEN EXTRACT(MONTH FROM approval_date)::INT
                  	 ELSE NULL
                 END;
-- 3 -- Creamos una columna con el año-mes (y día 1 para agrupar posteriormente por fecha) de aceptación del prestamo
ALTER TABLE sba_loans_nodup
ADD COLUMN approval_ym DATE;

UPDATE sba_loans_nodup
SET approval_ym = 	CAST(CONCAT(EXTRACT(YEAR FROM approval_date),'-', 
					EXTRACT(MONTH FROM approval_date),'-01') AS DATE);

-- 4 -- Creamos una columna con el código NAIC a 2 dígitos para realizar una exploción sectorial
ALTER TABLE sba_loans_nodup
ADD COLUMN naics_code_2 CHAR(2);

UPDATE sba_loans_nodup
SET naics_code_2 = LEFT(naics_code,2);

-- 5 -- Creamos una columna categórica que clasifique los préstamos según monto aprobado
	 -- (≤50k, 50–150k, 150–350k, 350k–2M, >2M) que nos permitirá analizar el comportamiento del
	 -- riesgo crediticio por tamaño de préstamo
ALTER TABLE sba_loans_nodup
ADD COLUMN size_bucket VARCHAR(10);

UPDATE sba_loans_nodup
SET size_bucket = CASE	WHEN gross_approval <= 50000 THEN '≤50k'
						WHEN gross_approval BETWEEN 50001 AND 150000 THEN '50-150k'
						WHEN gross_approval BETWEEN 150001 AND 350000 THEN '150-350k'
						WHEN gross_approval BETWEEN 350001 AND 2000000 THEN '350-2M'
						ELSE '>2M' END;

-- 6 -- Creamos una variable "default_flag" (BOOLEAN BINARIO), que toma el valor 1 si el préstamo
	 -- registró un cargo por incobrable y FALSE en caso contrario. Esto nos permitirá 
	 -- calcular directamente tasas de default sobre la cartera
ALTER TABLE sba_loans_nodup
ADD COLUMN default_flag SMALLINT;

UPDATE sba_loans_nodup
SET default_flag = CASE WHEN gross_charge_off_amount > 0 THEN 1 ELSE 0 END;

-- 7 -- Estandarizamos la columna "processing_method" según el código de abreviatura
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
		
-- 8 -- Agrupamos los distintos métodos de tramitación por categorías principales
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

-- 9 -- Creamos una tabla con las columnas de estudio principales
DROP TABLE IF EXISTS fact_loans;
CREATE TABLE fact_loans AS
SELECT	loan_id, approval_date, approval_ym, approval_m, gross_approval, project_state,
		borr_state, bank_state, naics_code, naics_code_2, term_in_months, size_bucket,
		gross_charge_off_amount, default_flag, processing_code, processing_bucket
FROM sba_loans_nodup;

SELECT * FROM fact_loans; -- Nos queda una tabla con 16 columnas 

-- 10 -- Finalmente devolvemos el nombre original "sba_loans" a la tabla final "sba_loans_nodup"
DROP TABLE IF EXISTS sba_loans;
ALTER TABLE sba_loans_nodup RENAME TO sba_loans;

-- Filtración de datos:

-- 1 -- Eliminamos las columnas sobrantes
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

-- Creamos las vistas que se encuentran en el archivo "views.sql"

/* Con esto damos por terminado el PROCESS PHASE, disponiendo de 2 tablas ("fact_loans", "sba_loans") y 5 vistas
(agg_m, agg_m_naics, agg_m_process, agg_m_size, agg_m_size, agg_m_state) para su posterior análisis */