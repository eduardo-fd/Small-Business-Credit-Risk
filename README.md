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

La base de datos pública 7(a) & 504 FOIA, publicada por la U.S. Small Business Administration (SBA), agencia federal de los Estados Unidos, es un conjunto de información que contiene registros históricos y actuales sobre préstamos otorgados bajo los programas 7(a) y 504. Estos datos se publican en cumplimiento de la Ley de Libertad de Información (FOIA).

Este estudio explora los datos mas recientes del periodo 2020-2025 con datos que están organizados en formato tabular CSV, donde cada fila corresponde a un préstamo aprobado bajo el programa SBA 7(a), que es el programa general para las PYMEs. Las columnas contienen información sobre el prestatario, la entidad financiera, montos de aprobación, condiciones de interés, estado del préstamo y fechas clave (aprobación, primer desembolso, pago total, cancelación). Se recomienda consultar el diccionario para más información.

---

## 🎯 Objetivo del proyecto
Este proyecto tiene como objetivo investigar el riesgo de crédito en préstamos SBA 7(a) (EE. UU., 2020–2025) con el fin de mejorar la decisión de originación. Identificaremos segmentos de mayor riesgo por industria (NAICS), geografía (Estado), tamaño del préstamo y programa, y construiremos un modelo logístico (PD) sencillo y explicable que ordene a los solicitantes por probabilidad de incumplimiento.

Con base en ese ranking (deciles), definiremos un umbral de acción (cut-off) para priorizar revisión/ajustes de límite y estimaremos el impacto esperado sobre charge-off. El resultado se comunicará mediante un dashboard con KPIs de cohortes/vintages, mapas, tablas por segmento y un memo ejecutivo con recomendaciones accionables.

---

## 🛠️ Herramientas utilizadas
- **Excel**: Diccionario, exploración inicial y mapeo.
- **PostgreSQL**: Importación, limpieza, transformación/creación de métricas, consultas de agregación, feature engineering y exploratory data analysis.
- **Python**: Modelo logístico simple para estimar PD (Probability of Default).  
- **Power BI**: visualización interactiva de métricas e insights.

---

## 📂 Estructura del repositorio
data/        # CSV original (raw), limpio y dataset para modelado
sql/         # Scripts SQL: schema, cleaning, views, exploratory analysis
notebooks/   # Python notebooks con el modelo logit simple
dashboard/   # Dashboard Power BI (.pbix)
outputs/     # CSV: deciles, PD scores y agregados
docs/        # Scope of Work, capturas del dashboard y diccionario
README.md    # Documentación principal del proyecto
requirements.txt # Dependencias de Python
LICENSE      # MIT license

---

## 🔄 Metodología (Case Study Roadmap)

### 1. Ask
Se definió como objetivo central analizar el **riesgo crediticio** en los préstamos SBA 7(a).

Preguntas clave de estudio: 
- ¿Qué factores influyen más en la probabilidad de default?
- ¿Existen diferencias en tasas de default según estado, sector económico, tamaño del préstamo o tipo de programa?
- ¿Cómo evolucionan los defaults a lo largo del tiempo?
- Que conclusiones y recomendaciones podemos extraer de este análisis?

---

### 2. Prepare
En la fase de preparación se descargaron los datos desde el portal oficial de la SBA y se verificó la confiabilidad de la fuente (cumple con criterios ROCCC).
Posteriormente se almacenaron en PostgreSQL para asegurar integridad y consistencia. Para ello, se creó la base de datos **Small-Business Credit Risk** junto con la tabla inicial **sba_loans**.

Para la importación se utilizó el siguiente formato:
- Formato: CSV
- Cabecera: Sí (HEADER)
- Delimitador: coma (,)
- Comillas de texto y escape: comillas dobles (")

Se documentaron validaciones y problemas iniciales de formato en campos de fecha y valores vacíos:
    - Validación de recuento de filas respecto al CSV original.
    - Revisión de formatos en campos de fecha (ApprovalDate, PaidInFullDate, FirstDisbursementDate).
    - Detección de valores vacíos ('') y duplicados.
    - Conversión de variables a tipos apropiados: NUMERIC(10,2) para montos, DATE para fechas, SMALLINT para plazos, etc.

A continuación se definen 2 vías para continuar con el estudio:

1. **Via rápida**: Ejecutar *esquema final* y *cargar datos limpios*

📂 /data/ → `fact_loans.csv`
📂 /sql/ → `fact_loans_schema.sql`, `views.sql` (crear vistas)

2. **Paso a paso**: Ejecutar *esquema inicial* y *cargar datos sucios* (limpieza de datos documentado en **Process**)

📂 /data/ → `sba_loans_raw.csv` (no incluido por tamaño) disponible en SBA Open Data Portal
📂 /sql/ → `sba_loans_schema.sql`, `cleaning_data.sql` (limpieza de datos), `views.sql` (crear vistas)

---

### 3. Process
En la fase de procesamiento se cargan los daros y se corrigen las incidencias menores documentadas durante la primera importación de datos.
- Fechas vacías o con formato inconsistente (""): Se establecen temporalmente columnas afectadas a formato TEXT.
- Valores con decimales en columnas que conceptualmente son enteras: Se establece temporalmente formato FLOAT en la columna afectada.

recursos:
📂 /sql/ → `cleaning_data.sql`, `views.sql`

#### 3.1 Limpieza de datos
Se procedió a la limpieza de datos y chequeo inicial:

- Se convirtieron variables a tipos adecuados (`INT`, `DATE`).
- Se eliminaron duplicados.  
- Se normalizaron casillas vacías a `NULL`.  
- Se realizarón algunas comprobaciones para asegurar integridad.

#### 3.2 Feature Engineering
Se crearón columnas útiles para nuestro análisis:

- Se crea y establece un identificador único `loan_id`.
- Creación de `approval_ym` y `approval_m` (año-mes y mes de aprobación).  
- Derivación de `naics_code_2` (sector económico a 2 dígitos).
- Creación de `size_bucket` (rangos de monto aprobado).
- Creación de `default_flag` (indicador de default boleano binario).  
- Creación de `processing_code` y `processing_bucket` (categorización de métodos de aprobación).  
- Se eliminaron las columnas sobrantes e irrelevantes para el estudio.

#### 3.3 Tabla/ventana
Se creó la tabla `fact_loans` con 16 variables principales para análisis:

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
- `modeling_loans`: filtrado de datos para modelaje predictivo de PD

Finalmente se exportaron todas las vistas en formato CSV.

---

### 4. Analyze
Una vez finalizado la fase ETL y el procesamiento de datos, se realizó un análisis explorativo con el objetivo de identifcar patrones y extraer insights accionables. Seguidamente, se creó un modelo lógitico para predecir la probabilidad de default (PD) de cada préstamo.

recursos:
📂 /sql/ → `eda_modeling.sql`
📂 /notebooks/ → `pd_modeling.ipynb`

#### 4.1 Exploratory Data Analysis
Se realizó EDA tanto en SQL como en Python (histogramas y checklist final) de los cuales se extrayeron los siguientes insights:

- Dataset desbalanceado, con un ~1.1% de los préstamos en default.
- Mayor tasa de impago en el sector de Transporte y Almacenamiento.
- Distribución de los montos de préstamo fuertemente sesgada hacia valores bajos (pocos prestamos grandes/multimillonarios).
- Correlación negativa entre montos de préstamo y probabilidad de impago.
- Estados con mayor tasa de impago: Nevada, Los Angeles y Florida.
- Correlación negativa entre plazo del préstamo y tasa de impago. No obstante descartamos esta hipótesis debido a la ventana corta observada 2020-2025 (plazos largos pueden no haber madurado).
- Alta tasa de impago en los programas de "COMMUNITY ADVANTAGE" (mayor riesgo asumido).

#### 4.2 Modelo logístico (PD)
Se creó un modelo que predice cual es la probabilidad de default (PD), utilizando la variable binaria dependiente 'default_flag' junto con las variables regresoras conocidas justo en el momento de originar el préstamo (antes de default): gross_approbal, term_in_months, naics_code_2, project_state, size_bucket, processing_bucket. 

Para el entrenamiento de el modelo se estableció class_weight='balanced' para ponderar los préstamos y se dividió el dataset en un 80% entrenamiento y un 20% test. Se evaluaron los resultados con AUS y KS, de los cuales se obtuvieron valores muy favorables que indicarón una capacidad predictiva robusta (AUC=0.865, KS=0.632).

Finalmente se calculó un pd_score (probabilidad de default) para cada préstamo `pd_scores.csv`, se ordenaron los préstamos por PD y se dividieron en 10 grupos (deciles) `decile_summary.csv`. En cada decil se midió: el número de préstamos, número de defaults, tasa de default (ODR), % acumulado de defaults y volumen. 

Los deciles superiores concentran la mayoría de los defaults en una fracción reducida del volumen, lo que permitirá a un banco enfocar la gestión de riesgo en los segmentos más expuestos con un coste reducido.

---

### 5. Share
Para comunicar los resultados de manera efectiva se diseñó un dashboard interactivo en Power BI con tres páginas principales, orientadas a diferentes públicos de negocio.

recursos:
📂 /dashboard/ → `dashboard.pbix`
📂 /docs/ → `executive_dashboard.PNG`, `risk_dashboard.PNG`, `cohorts_dashboard.PNG`

### A) Executive Overview
![Executive Overview](/docs/executive_dashboard.PNG)

- Objetivo: proveer una visión general del portafolio de préstamos SBA.
- Contenido: métricas clave (aprobados, ODR, charge-off), evolución temporal, distribución por estado (mapa), sectores NAICS, tamaño del monto y tipo de programa.
- Insight destacado: el ODR promedio es estable, pero existen concentraciones de riesgo en ciertos estados y sectores.

### B) Risk (Modelo PD)
![Risk Model](/docs/risk_dashboard.PNG)

- Objetivo: mostrar el desempeño del modelo logístico entrenado.
- Contenido: tabla de deciles, tasa de default por decil, curva de captura acumulada, métricas AUC y KS, mapa con PD promedio por Estado.
- Insight destacado: los deciles 9–10 concentran aproximadamente ~81% de los defaults con solo ~20% del volumen, lo que permite definir un cut-off operativo eficiente.

### C) Cohorts / Vintages
![Cohorts](/docs/cohorts_dashboard.PNG)

- Objetivo: analizar tendencias de riesgo por cohortes de originación.
- Contenido: evolución de ODR por mes/año de aprobación (opcional Estado e Industria), con desglose por tamaño del monto y tipo de programa.
- Insight destacado: se observan diferencias de desempeño por generación de préstamos según tipo de programa y cantidad total prestada.

---

### 6. Act

### Objetivo
Reducir pérdidas por charge-off sin sacrificar significativamente el volumen de préstamos aprobados.

### Qué hicimos
- ETL completo y limpieza de datos (SBA FOIA, snapshot 2025-06-30).
- Creación de métricas y KPIs por cohortes, sectores y estados.
- Modelo de probabilidad de default (PD) logístico, segmentado en deciles.

### Resultados clave
- AUC=0.865, KS=0.632 → modelo robusto, buena capacidad de discriminación.
- Cut-off decil ≥9 → captura ~81% de defaults con solo ~20% del volumen.
- Cut-off decil ≥8 → captura ~90% de defaults con ~30% del volumen.

### Patrones observados:
- Mayor riesgo en programas Community Advantage.
- Sector Transporte y Almacenamiento con ODR elevado.
- Estado de Nevada con incidencia de defaults superior al promedio.

### Recomendación
Adoptar un cut-off operativo en decil ≥9, complementado con:
- Revisión manual de préstamos en ≥9.
- Límites de monto/tenor más estrictos para ≥9.

### Limitaciones
- Censura temporal (defaults futuros aún no observados).
- PD no calibrado a horizonte regulatorio.
- No se incluyó LGD ni EAD → el modelo estima riesgo de default, no pérdida esperada.

### Próximos pasos
- Calibración de PD a horizonte anual.
- Integración de LGD y EAD para estimar Expected Loss (EL = PD×LGD×EAD).
- Stress testing con escenarios macroeconómicos.

## 🚀 Cómo reproducir el proyecto
Para clonar y ejecutar el proyecto localmente:

```bash
git clone https://github.com/tu-usuario/Small-Business-Credit-Risk.git
cd Small-Business-Credit-Risk

# Crear entorno virtual
python3 -m venv venv
source venv/bin/activate

# Instalar dependencias
pip install -r requirements.txt