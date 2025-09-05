# Small Business Credit Risk – SBA 7(a) Loans

## 📌 Descripción
Este proyecto analizó el desempeño y riesgo crediticio de préstamos garantizados por la **U.S. Small Business Administration (SBA)**, específicamente bajo el programa **7(a)**.  
El objetivo fue construir un pipeline **end-to-end** (E2E) que abarque desde la preparación e importación de los datos hasta la generación de vistas agregadas y una tabla de hechos lista para análisis y visualización.

---

## 📊 Origen de los datos
- Fuente: [SBA Open Data Portal](https://data.sba.gov/en/dataset/7-a-504-foia)  
- Dataset: *FOIA – 7(a) Loans (FY2020 – Present)*  
- Diccionario oficial: disponible en la misma fuente  
- Fecha de descarga: 24/08/2025  

La base de datos pública 7(a) & 504 FOIA, publicada por la U.S. Small Business Administration (SBA), agencia federal de los Estados Unidos, es un conjunto de información que contiene registros históricos y actuales sobre préstamos otorgados bajo los programas 7(a) y 504. Estos datos se publican en cumplimiento de la Ley de Libertad de Información (FOIA) y se acompañan de un diccionario de datos que facilita su interpretación. 

Este estudio explora los datos mas recientes del periodo 2020-2025 con datos que están organizados en formato tabular CSV, donde cada fila corresponde a un préstamo aprobado bajo el programa SBA 7(a), que es el generalista para las PYMEs. Las columnas contienen información sobre el prestatario, la entidad financiera, montos de aprobación, condiciones de interés, estado del préstamo y fechas clave (aprobación, primer desembolso, pago total, cancelación). Se recomienda consultar el diccionario para más información.

El dataset inicial bruto cuanta con 44 columnas y 330705 filas, 

---

## 🎯 Objetivo del proyecto PENDIENTE
Responder a las siguientes preguntas principales:
- ¿Qué factores influyen más en la probabilidad de default (incumplimiento)?  
- ¿Existen diferencias en tasas de default según estado, sector económico o tamaño del préstamo? y tipo de transacción?
- ¿Cómo evolucionan los préstamos aprobados y los defaults a lo largo del tiempo?  

---

## 🛠️ Herramientas utilizadas
- **Excel**: Diccionario, exploración inicial y mapeo rápido.
- **PostgreSQL**: importación, limpieza, transformación/creación de métricas, consultas de agregación y feature engineering.  
- **Power BI**: visualización interactiva de métricas e insights.  
- **Python**: modelo logístico simple para estimar PD (Probability of Default).  

---

## 📂 Estructura del repositorio PENDIENTE
- data/ # CSV originales (raw) y limpios (clean)
- sql/ # Scripts SQL: schema, cleaning, views
- powerbi/ # Dashboard Power BI (archivo .pbix)
- notebooks/ # Python notebooks (logit opcional)
- README.md # Documentación principal del proyecto

---

## 🔄 Metodología (Case Study Roadmap)

### 1. Ask PENDIENTE
- Se definió como objetivo central analizar el **riesgo crediticio** en los préstamos SBA 7(a).  
- Pregunta clave: *¿Qué factores afectan a la probabilidad de default?*
- Que conclusiones y recomendaciones podemos extraer de este análisis?

---

### 2. Prepare
- Los datos se descargaron desde el portal oficial de la SBA.
- Se verificó la confiabilidad de la fuente (cumple con criterios ROCCC).  
- Se almacenaron en PostgreSQL para asegurar integridad y consistencia. Se creó la base de datos **Small-Business Credit Risk** junto con la tabla inicial **sba_loans**.
- Se documentaron problemas iniciales de formato en campos de fecha y valores vacíos:
    - Validación de recuento de filas respecto al CSV original.
    - Revisión de formatos en campos de fecha (ApprovalDate, PaidInFullDate, FirstDisbursementDate).
    - Detección de valores vacíos ('') y duplicados.
    - Conversión de variables a tipos apropiados: NUMERIC(10,2) para montos, DATE para fechas, SMALLINT para plazos, etc.

Para la importación se utilizó el siguiente formato:
- Formato: CSV
- Cabecera: Sí (HEADER)
- Delimitador: coma (,)
- Comillas de texto y escape: comillas dobles (")

A continuación se definen 2 vias para continuar en la siguiente fase:

1. **Via rápida**: *cargar datos limpios* y ejecutar *esquema final*
    - fact_loans_schema.sql
    - fact_loans.csv
    - views.sql (ejecuta queries de creación de vistas)

2. **Paso a paso**: *cargar datos sucios*, ejecutar *esquema inicial* y limpieza de datos (documentado en **Process**)
    - sba_loans_schema.sql
    - sba_loans_raw.csv (no incluido por tamaño) disponible en SBA Open Data Portal
    - cleaning_data.sql (ejecutar queries de limpieza)
    - views.sql (ejecuta queries de creación de vistas)

---

### 3. Process
Se identificaron algunas incidencias menores durante la primera importación de datos:
- Fechas vacías o con formato inconsistente (""), se establecen temporalmente columnas afectadas a formato TEXT.
- Valores con decimales en columnas que conceptualmente son enteras, se establece temporalmente formato FLOAT en la columna afectada.

Estas inconsistencias fueron corregidas en el proceso de limpieza y tipificación

#### 3.1 Limpieza de datos
- Se eliminaron duplicados.  
- Se normalizaron casillas vacías a `NULL`.  
- Se corrigieron columnas de fecha (`PaidInFullDate`, `FirstDisbursementDate`).  
- Se convirtieron variables a tipos adecuados (`INT`, `DATE`, `NUMERIC`).  

#### 3.2 Feature Engineering
- Creación de `approval_ym` (año-mes de aprobación).  
- Creación de `size_bucket` (rangos de monto aprobado).  
- Creación de `default_flag` (indicador de default).  
- Creación de `processing_code` y `processing_bucket` (categorización de métodos de aprobación).  
- Derivación de `naics_code_2` (sector económico a 2 dígitos).  

#### 3.3 Tabla de hechos
- Se creó `fact_loans` con 16 variables principales para análisis:
  - Identificador (`loan_id`)
  - Fechas (`approval_date`, `approval_ym`, `approval_m`)
  - Monto aprobado (`gross_approval`)
  - Estado (`project_state`, `borr_state`, `bank_state`)
  - Sector (`naics_code`, `naics_code_2`)
  - Plazo (`term_in_months`)
  - Buckets (`size_bucket`)
  - Riesgo (`default_flag`, `gross_charge_off_amount`)
  - Procesamiento (`processing_code`, `processing_bucket`)

#### 3.4 Vistas agregadas
Se definieron vistas SQL para análisis agregado:
- `agg_m`: métricas por mes  
- `agg_m_state`: métricas por mes y estado  
- `agg_m_naics`: métricas por mes y sector  
- `agg_m_size`: métricas por mes y bucket de monto  
- `agg_m_process`: métricas por mes y método de procesamiento  


### 4. Analyze

#### 4.1 Exploratory Data Analysis
Se realizó EDA tanto en SQL como en Python (histogramas y checklist), de los cuales se extrayeron los siguientes insights:

- Dataset desbalanceado, con un ~1.1% de los préstamos en default
- Mayor tasa de impago en el sector de Transporte y Almacenamiento
- Distribución de los montos de préstamo fuertemente sesgada hacia valores bajos (pocos prestamos grandes/multimillonarios)
- Correlación negativa entre montos de préstamo y probabilidad de impago
- Estados con mayor tasa de impago: Nevada, Los Angeles y Florida
- Correlación negativa entre plazo del préstamo y tasa de impago. No obstante descartamos esta hipótesis debido a la ventana corta observada 2020-2025 (plazos largos pueden no haber madurado)
- Alta tasa de impago en los programas de "COMMUNITY ADVANTAGE" (mayor riesgo asumido)

#### 4.2 Modelo logístico (PD)
Además, se creó un modelo que predice cual es la probabilidad de default (PD), utilizando la variable binaria dependiente 'default_flag' junto con las variables regresoras conocidas justo en el momento de originar el préstamo (antes de default): gross_approbal, term_in_months, naics_code_2, project_state, size_bucket, processing_bucket. Para el entrenamiento de el modelo se estableció class_weight='balanced' para ponderar los préstamos y se dividió el dataset en un 80% entrenamiento y un 20% test. 

Se evaluaron los resultados con AUS y KS, de los cuales se obtuvieron valores muy favorables que indicarón una capacidad predictica robusta (AUC=0.865, KS=0.632).

Finalmente se calculó un pd_score (probabilidad de default) para cada préstamo, se ordenaron los préstamos por PD y se dividieron en 10 grupos (deciles). En cada decil se midió: el número de préstamos, número de defaults, tasa de default (ODR), % acumulado de defaults y volumen. De aqui se extrayeron 'pd_scores.csv' y 'decile_summary.csv' que almacenamos en la carpeta /outputs.


🚧 Proyecto en curso – Documentación y dashboard final en desarrollo (ETA: Septiembre 2025).


### CLONAR REPO:
cd Small-Business-Credit-Risk
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt