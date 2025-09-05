-- ANALYZE PHASE 

-- EDA (Exploratory Data Analysis):

-- 1 -- Probabilidad de impago
SELECT COUNT(*) AS total, SUM(default_flag) AS num_defaults, CAST(SUM(default_flag) AS FLOAT)/COUNT(*) AS default_rate_pct
FROM modeling_loans;

/*  El numero total de prestamos es de 330353, de los cuales 3737 entraron en default. 
	Podemos observar que el dataset está desbalanceado: ~1.1% de los préstamos tienen default. */

-- 2 -- Probabilidad de impago por sector
SELECT naics_code_2, COUNT(*) AS total, SUM(default_flag) AS num_defaults, 
CAST(SUM(default_flag) AS FLOAT)/COUNT(*) AS default_rate_pct 
FROM modeling_loans
GROUP BY naics_code_2
ORDER BY default_rate_pct DESC
LIMIT 5;

/*  Podemos observar que el sector con mayor tasa de impago pertenece a el sector de Transporte y Almacenamiento,
	que incluye industrias que ofrecen transporte de pasajeros y carga, almacenamiento y depósito de mercancías, 
	transporte panorámico y turístico, y actividades de apoyo relacionadas con los medios de transporte.  */
	
-- 3 -- Distribución de prestamos según montos
SELECT size_bucket, COUNT(*) total_loans 
FROM modeling_loans
GROUP BY size_bucket
ORDER BY total_loans DESC;

/*  Si observamos por rango de cantidad prestada, se han realizado una mayor cantidad de prestamos dentro del rango
	350k-2M, seguidamente de prestamos inferiores a 50k y 50-150k. Prestamos multimillonarios son bastante escasos a
	comparación de los demás montos. En general, la distribución de los montos de préstamo está fuertemente sesgada
	hacia valores bajos: 0-150k > 350k-2M  */
	
-- 4 -- Probabilidad de impago según montos
SELECT size_bucket, COUNT(*) AS total, SUM(default_flag) AS num_defaults, 
CAST(SUM(default_flag) AS FLOAT)/COUNT(*) AS default_rate_pct 
FROM modeling_loans
GROUP BY size_bucket
ORDER BY default_rate_pct DESC;

/*  Seguidamente, se observa una correlación negativa donde, a mayor rango de cantidad prestada menor es el porcentage
	de impago  */
	
-- 5 -- Probabilidad de impago según Estado
SELECT project_state, COUNT(*) AS total, SUM(default_flag) AS num_defaults, 
CAST(SUM(default_flag) AS FLOAT)/COUNT(*) AS default_rate_pct 
FROM modeling_loans
GROUP BY project_state
ORDER BY default_rate_pct DESC
LIMIT 5;

/*  Si observamos por estado, Nevada, Los Angeles y Florida se posicionan con un mayor riesgo de impago, pero no podemos 
	concluir una significancia real.  */
	
-- 6 -- Probabilidad de default según plazos
WITH month_bucket AS (	SELECT 	*,
								CASE WHEN term_in_months <= 60 THEN '≤60'
			 						 WHEN term_in_months BETWEEN 61 AND 120 THEN '61-120'
			 						 WHEN term_in_months BETWEEN 121 AND 240 THEN '121-240'
			 						 WHEN term_in_months BETWEEN 241 AND 300 THEN '241-300'
			 						 WHEN term_in_months >300 THEN '>300' END AS term_months_bucket
						FROM modeling_loans  )
SELECT term_months_bucket, COUNT(*) AS total, SUM(default_flag) AS num_defaults, 
CAST(SUM(default_flag) AS FLOAT)/COUNT(*) AS default_rate_pct   
FROM month_bucket
GROUP BY term_months_bucket
ORDER BY default_rate_pct DESC;

/*  Al observar los plazos de prestamo, podemos observar una correlación negativa donde, a mayor plazo menor es la
	tasa de impago. Hay que tener en cuenta la ventana corta qe estamos observando, 2020-2025, por lo que es probable
	que sea información sesgada  */
	
-- 7 -- Probabilidad de impago según tipo de proceso del préstamo
SELECT processing_bucket, COUNT(*) AS total, SUM(default_flag) AS num_defaults, 
CAST(SUM(default_flag) AS FLOAT)/COUNT(*) AS default_rate_pct 
FROM modeling_loans
GROUP BY processing_bucket
ORDER BY default_rate_pct DESC; 

/*  Finalmente, se observa una probabilidad de impago considerable frente a los prestamos procesados mediante por 
	"COMMUNITY ADVANTAGE", un programa de préstamos de la Small Business Administration (SBA) que apoya a pequeñas empresas,
	tanto nuevas como existentes, en ciertas áreas geográficas, enfocándose en negocios que no califican para financiación 
	tradicional pero que poseen el potencial de éxito. El riesgo es bastante elevado en este tipo de prestamos, con un
	porcentaje de impago observado de ~4.9%  */