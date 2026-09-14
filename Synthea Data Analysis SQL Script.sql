-- Created Data Tables
CREATE TABLE patients (
    Id VARCHAR(100) PRIMARY KEY,
    BIRTHDATE DATE,
    DEATHDATE DATE,
    SSN VARCHAR(100),
    DRIVERS VARCHAR(100),
    PASSPORT VARCHAR(100),
    PREFIX VARCHAR(20),
    FIRST VARCHAR(100),
    MIDDLE VARCHAR(100),
    LAST VARCHAR(100),
    SUFFIX VARCHAR(20),
    MAIDEN VARCHAR(100),
    MARITAL VARCHAR(10),
    RACE VARCHAR(50),
    ETHNICITY VARCHAR(50),
    GENDER VARCHAR(10),
    BIRTHPLACE VARCHAR(100),
    ADDRESS VARCHAR(100),
    CITY VARCHAR(50),
    STATE VARCHAR(50),
    COUNTY VARCHAR(50),
    FIPS VARCHAR(20),
    ZIP VARCHAR(20),
    LAT NUMERIC,
    LON NUMERIC,
    HEALTHCARE_EXPENSES NUMERIC,
    HEALTHCARE_COVERAGE NUMERIC,
    INCOME NUMERIC
);

CREATE TABLE encounters (
    Id VARCHAR(100) PRIMARY KEY,
    START TIMESTAMP,
    STOP TIMESTAMP,
    PATIENT VARCHAR(100),
    ORGANIZATION VARCHAR(100),
    PROVIDER VARCHAR(100),
    PAYER VARCHAR(100),
    ENCOUNTERCLASS VARCHAR(50),
    CODE VARCHAR(100),
    DESCRIPTION VARCHAR(255),
    BASE_ENCOUNTER_COST NUMERIC,
    TOTAL_CLAIM_COST NUMERIC,
    PAYER_COVERAGE NUMERIC,
    REASONCODE VARCHAR(100),
    REASONDESCRIPTION VARCHAR(255)
);

CREATE TABLE conditions (
    START DATE,
    STOP DATE,
    PATIENT VARCHAR(100),
    ENCOUNTER VARCHAR(100),
    CODE VARCHAR(100),
    DESCRIPTION VARCHAR(255)
);

CREATE TABLE medications (
    START TIMESTAMP,
    STOP TIMESTAMP,
    PATIENT VARCHAR(100),
    PAYER VARCHAR(100),
    ENCOUNTER VARCHAR(100),
    CODE VARCHAR(100),
    DESCRIPTION VARCHAR(255),
    BASE_COST NUMERIC,
    PAYER_COVERAGE NUMERIC,
    DISPENSES INT,
    TOTALCOST NUMERIC,
    REASONCODE VARCHAR(100),
    REASONDESCRIPTION VARCHAR(255)
);

CREATE TABLE procedures (
    DATE TIMESTAMP,
    PATIENT VARCHAR(100),
    ENCOUNTER VARCHAR(100),
    CODE VARCHAR(100),
    DESCRIPTION VARCHAR(255),
    BASE_COST NUMERIC,
    REASONCODE VARCHAR(100),
    REASONDESCRIPTION VARCHAR(255)
);

-- Load data into the tables
COPY patients 
FROM '/Users/GS/Downloads/synthea-master/output/csv/patients.csv' 
DELIMITER ',' 
CSV HEADER;

COPY encounters 
FROM '/Users/GS/Downloads/synthea-master/output/csv/encounters.csv' 
DELIMITER ',' 
CSV HEADER;

COPY conditions 
FROM '/Users/GS/Downloads/synthea-master/output/csv/conditions.csv' 
DELIMITER ',' 
CSV HEADER;

COPY medications 
FROM '/Users/GS/Downloads/synthea-master/output/csv/medications.csv' 
DELIMITER ',' 
CSV HEADER;

COPY procedures 
FROM '/Users/GS/Downloads/synthea-master/output/csv/procedures.csv' 
DELIMITER ',' 
CSV HEADER;

-- Join the patients and conditions together
SELECT
    p.FIRST,
    p.LAST,
    p.BIRTHDATE,
    c.DESCRIPTION AS diagnosis,
    c.START AS diagnosis_date
FROM patients p
JOIN conditions c
    ON p.Id = c.PATIENT
LIMIT 20;

-- Only want to filter out emergency readmissions & filter out wellness visits
SELECT 
    PATIENT,
    START AS admission_date,
    STOP AS discharge_date,
    ENCOUNTERCLASS,
    LEAD(START) OVER (PARTITION BY PATIENT ORDER BY START) AS next_admission
FROM encounters
WHERE ENCOUNTERCLASS IN ('emergency', 'inpatient', 'urgentcare')

/*
   Calculates the days between visits
   Calculate readmission rate
   Flag 30 day readmission, dropping patients that passed away
   Adds demographic, geographic and diagnostic columns needed for analysis
   
*/

WITH AcuteEncounters AS (
    SELECT 
        e.Id AS encounter_id,
        e.PATIENT AS patient_id,
        e.START AS admit_date,
        e.STOP AS discharge_date,
        e.ENCOUNTERCLASS,
        p.DEATHDATE,
        p.GENDER,
        p.CITY,
        p.COUNTY,
        EXTRACT(YEAR FROM AGE(e.START, p.BIRTHDATE)) AS age_at_admission
    FROM encounters e
    JOIN patients p ON e.PATIENT = p.Id
    WHERE e.ENCOUNTERCLASS IN ('emergency', 'inpatient', 'urgentcare')
),
ReadmissionCalc AS (
    SELECT 
        encounter_id,
        patient_id,
        admit_date,
        discharge_date,
        DEATHDATE,
        GENDER,
        CITY,
        COUNTY,
        age_at_admission,
        LEAD(admit_date) OVER (PARTITION BY patient_id ORDER BY admit_date) AS next_admit_date,
        ROW_NUMBER() OVER (PARTITION BY patient_id ORDER BY admit_date) - 1 AS prior_admissions
    FROM AcuteEncounters
)
SELECT 
    r.patient_id,
    r.encounter_id,
    c.DESCRIPTION AS primary_diagnosis,
    r.age_at_admission,
    r.GENDER,
    r.CITY,
    r.COUNTY,
    CAST(r.admit_date AS DATE) AS admit_date,
    CAST(r.discharge_date AS DATE) - CAST(r.admit_date AS DATE) AS length_of_stay,
    r.prior_admissions,
    CASE 
        WHEN (CAST(r.next_admit_date AS DATE) - CAST(r.discharge_date AS DATE)) <= 30 THEN 1 
        ELSE 0 
    END AS is_30d_readmission,
    COUNT(proc.CODE) AS procedure_count
FROM ReadmissionCalc r
LEFT JOIN procedures proc ON r.encounter_id = proc.ENCOUNTER
LEFT JOIN conditions c ON r.encounter_id = c.ENCOUNTER
WHERE r.DEATHDATE IS NULL OR r.DEATHDATE > r.discharge_date
GROUP BY 
    r.patient_id, 
    r.encounter_id, 
    c.DESCRIPTION, 
    r.age_at_admission, 
    r.GENDER, 
    r.CITY, 
    r.COUNTY, 
    r.admit_date, 
    r.discharge_date, 
    r.next_admit_date,
    r.prior_admissions
ORDER BY 
    r.patient_id, 
    r.admit_date;