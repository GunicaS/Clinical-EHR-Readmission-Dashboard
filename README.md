# Clinical-EHR-Readmission-Dashboard
End-to-end healthcare analytics pipeline modeling 73k+ Synthea EHR encounters. Built with PostgreSQL, validated via R statistical scripts, and visualized in Power BI to analyze Minnesota 30-day hospital readmissions.

# Healthcare Readmission Analytics & Quality Report

**Target Region:** Minnesota Healthcare Facilities  
**Dataset Scope:** 73,406 Distinct Patient Encounters  
**Primary Metric:** 30-Day Hospital Readmission Rate  

---

## Executive Summary

Hospital readmissions within 30 days of discharge serve as a critical benchmark for clinical quality, patient care transitions, and resource allocation. This report evaluates readmission patterns across Minnesota counties using synthetic Electronic Health Record (EHR) data.

Out of **73,406 distinct patient encounters**, the baseline 30-day readmission rate is **44.0%**. Empirical analysis of clinical and social drivers reveals that readmissions are heavily concentrated around specific behavioral, psychosocial, and cardiovascular conditions. **Gingivitis**, **Overdose**, and acute **Myocardial Infarction** lead primary clinical diagnoses, while **Stress**, employment conditions, and social isolation serve as top non-clinical findings. County-level filtering ($n \ge 30$) demonstrates that rural counties led by **Houston County (76%)**, **Morrison County (72%)**, and **Fillmore County (70%)** exhibit the highest relative readmission rates statewide.

---

## Business Question

> **Primary Objective:** What key clinical diagnoses, Social Determinants of Health (SDOH), and geographic hotspots drive 30-day hospital readmissions across Minnesota, and where should health systems deploy targeted intervention programs to reduce avoidable returns?

---

## Secondary Questions

* **Geographic Disparities:** Which Minnesota counties exhibit the highest relative 30-day readmission rates among those with statistically reliable sample sizes ($n \ge 30$)?
* **Clinical Drivers:** Which primary diagnoses generate the highest absolute volume of 30-day readmissions?
* **Social & Administrative Determinants:** How do non-clinical findings (e.g., stress, isolation, employment status, environmental safety) influence readmission frequency?
* **Methodological Integrity:** How does segmenting clinical diagnoses from social/administrative findings clarify operational priorities for care coordination teams?

---

## Readmission Definition

A **30-day readmission** is defined as an acute or inpatient hospital admission occurring within 30 calendar days of a previous discharge date for the same patient.

$$
\text{Readmission Flag} = \begin{cases} 1 & \text{if } (\text{Encounter Start}_{n+1} - \text{Encounter Stop}_n) \le 30 \text{ days} \\ 0 & \text{otherwise} \end{cases}
$$

* **Index Event:** The initial hospital discharge ($\text{Encounter Stop}_n$).
* **Subsequent Event:** The start date of the patient's next recorded visit ($\text{Encounter Start}_{n+1}$).
* **Exclusions:** Multi-diagnosis records within a single encounter ID are consolidated via distinct counting to prevent inflated visit volumes.

---

## Data Tables & Schema

| Field Name | Data Type | Description | Role in Analysis |
|---|---|---|---|
| `encounter_id` | String / UUID | Unique identifier for each hospital visit | Primary key for distinct visit counting |
| `patient_id` | String / UUID | Unique identifier for individual patients | Partition key for window calculations |
| `encounter_start` | Timestamp | Date and time of admission | Index date tracking |
| `encounter_stop` | Timestamp | Date and time of discharge | Discharge baseline date |
| `age_at_admission` | Integer | Calculated age at time of visit | Demographic risk profiling |
| `gender` | String | Recorded gender (`M` / `F`) | Demographic segmentation |
| `county` | String | Minnesota county of residence | Geographic mapping & filtering |
| `County Mapping` | String | Formatted location (`[County] County, Minnesota`) | Bing Maps state-bounding constraint |
| `diagnosis` | String | Recorded ICD/SNOMED clinical description | Primary clinical driver ranking |
| `finding_description` | String | Recorded SDOH or administrative observation | Social determinant isolation |
| `is_30d_readmission` | Binary (0/1) | Flag for subsequent visit $\le$ 30 days | Global KPI calculation |

---

## Methodologies

### 1. Data Extraction & Cohort Engineering (PostgreSQL)
Raw EHR tables were queried in PostgreSQL. Using SQL window functions (`LEAD`), each patient's visit history was chronologically ordered to calculate the exact days elapsed between consecutive discharges and readmissions. Demographic details were linked to build a row-level extract.

### 2. Analytical Segmentation & Quality Control (R)
Data attributes were bifurcated into **Primary Clinical Diagnoses** and **Social & Administrative Findings** to isolate biological pathologies from environmental stressors. In county-level analyses, a sample size threshold ($n \ge 30$ hospital visits) was enforced to eliminate low-volume variance. Pipeline metrics were validated in R using `dplyr` to confirm 100% mathematical consistency with database extracts.

### 3. Business Intelligence Modeling (Power BI)
The dataset was loaded into Power BI, leveraging DAX measures (`DISTINCTCOUNT`, `DIVIDE`) to prevent duplicate visit counting. Visual elements were explicitly structured to compare primary diagnoses, SDOH findings, and relative county percentages side-by-side.

---

## Actual Analysis

### 1. Top 15 Primary Clinical Drivers
Analyzing primary medical diagnoses isolates the physiological conditions driving 30-day hospital returns:

* **Dominant Clinical Driver:** **Gingivitis (disorder)** represents the single largest volume of clinical readmissions by a substantial margin.
* **Acute & Cardiovascular Events:** Acute cardiac incidents represent a critical cluster, including **Overdose (disorder)**, **Acute non-ST segment elevation myocardial infarction**, **Myocardial infarction**, **Acute ST segment elevation myocardial infarction**, and **Ischemic heart disease**.
* **Renal & Metabolic Complications:** Progressive renal impairment is prominent across **Chronic kidney disease (Stages 1, 3, and 4)** and **Proteinuria due to type 2 diabetes mellitus**.
* **Trauma & Orthopedics:** Musculoskeletal injuries represent key acute readmissions, including **Injury of knee**, **Injury of medial collateral ligament of knee**, **Fracture of bone**, and **Injury of anterior cruciate ligament**.

### 2. Top 15 Social & Administrative Drivers (SDOH)
Separating non-clinical observations reveals significant psychosocial and environmental contributors to readmission volume:

* **Psychosocial Stressors:** **Stress (finding)** is the leading non-clinical contributor (~3,900 readmissions).
* **Employment & Labor Factors:** Work-related status forms a major cluster, led by **Full-time employment** (~3,350), **Part-time employment** (~2,480), and **Not in labor force** (~1,400).
* **Social Vulnerability & Isolation:** **Limited social contact** (~1,350) and **Social isolation** (~1,300) demonstrate a clear link between poor support networks and post-discharge returns.
* **Environmental Safety & Abuse:** Domestic and environmental risk factors account for substantial volume, specifically **Reports of violence in the environment** (~800) and **Victim of intimate partner abuse** (~800).
* **Behavioral & Surgical Context:** **Severe anxiety (panic)**, **Unhealthy alcohol drinking behavior**, **Suspected lung cancer**, and surgical histories (**CABG**, **Aortic valve replacement**, **Renal transplant**) complete the top non-clinical drivers.

### 3. Geographic Readmission Rates by County ($n \ge 30$)
Filtering for counties with at least 30 hospital visits isolates regional performance variations:

| Rank | County | Relative 30-Day Readmission Rate (%) |
|---|---|---|
| 1 | **Houston County** | **~76%** |
| 2 | **Morrison County** | **~72%** |
| 3 | **Fillmore County** | **~70%** |
| 4 | **Carlton County** | **~63%** |
| 5 | **Chisago County** | **~58%** |
| 6 | **Freeborn County** | **~57%** |
| 7 | **McLeod County** | **~56%** |
| 8 | **Pipestone County** | **~56%** |
| 9 | **Norman County** | **~55%** |
| 10 | **Cook County** | **~53%** |
| 11 | **Wilkin County** | **~50%** |
| 12 | **Goodhue County** | **~50%** |
| 13 | **Jackson County** | **~49%** |
| 14 | **Anoka County** | **~47%** |
| 15 | **Washington County** | **~46%** |

*Rural southeastern and northern counties (Houston, Morrison, Fillmore, Carlton) demonstrate significantly higher relative readmission rates compared to metropolitan-adjacent counties like Anoka (47%) and Washington (46%).*

---

## Results & Strategic Recommendations

### 1. High-Risk County Post-Discharge Allocation
Prioritize care transition resources in **Houston (76%)**, **Morrison (72%)**, and **Fillmore (70%)** counties. Deploy regional nurse navigators and home health visits in these areas to mitigate rural post-discharge care gaps.

### 2. Integrated Behavioral & SDOH Interventions
Establish automated screening for **Stress**, **Social Isolation**, and **Environmental Safety/Abuse** during admission. Patients exhibiting high psychosocial stress or limited social contact should be connected to community social workers prior to discharge.

### 3. Specialized Clinical Pathways
Build targeted post-discharge protocol bundles for:
* **Cardiovascular & Acute Events:** Early follow-up clinics for myocardial infarction and overdose management.
* **Renal & Diabetic Management:** Combined nephrology and endocrinology outpatient oversight for chronic kidney disease and diabetic proteinuria cohorts.
