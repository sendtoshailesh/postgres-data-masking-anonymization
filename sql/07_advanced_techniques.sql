-- PostgreSQL Anonymizer Advanced Techniques
-- This file contains SQL commands for advanced anonymization techniques

-- Differential Privacy: Add noise to aggregate queries
SELECT 
    'Finance' AS department,
    AVG(salary) + anon.noise(0, 500) AS approx_avg_salary,
    COUNT(*) + anon.noise(0, 2)::INTEGER AS approx_count
FROM employees;

-- Data Synthesis: Generate synthetic data based on statistical distribution
CREATE TABLE synthetic_patients AS
SELECT
    generate_series(1, 1000) AS id,
    anon.fake_first_name() || ' ' || anon.fake_last_name() AS patient_name,
    anon.random_date_between('1940-01-01'::date, '2000-12-31'::date) AS date_of_birth,
    CASE anon.random_int_between(1, 4)
        WHEN 1 THEN 'Hypertension'
        WHEN 2 THEN 'Diabetes'
        WHEN 3 THEN 'Asthma'
        WHEN 4 THEN 'Arthritis'
    END AS diagnosis,
    'INS-' || anon.random_string(6) AS insurance_id,
    (anon.random_int_between(500, 5000))::DECIMAL(10,2) AS treatment_cost;

-- Batch Processing for large tables
DO $$
DECLARE
    batch_size INT := 10000;
    max_id INT;
    current_id INT := 0;
BEGIN
    SELECT MAX(id) INTO max_id FROM employees;
    WHILE current_id <= max_id LOOP
        -- Process batch
        UPDATE employees 
        SET email = anon.partial_email(email)
        WHERE id > current_id AND id <= current_id + batch_size;
        
        current_id := current_id + batch_size;
        COMMIT;
    END LOOP;
END $$;

-- Create a comprehensive patient dataset for healthcare research
CREATE TABLE patient_records (
    id SERIAL PRIMARY KEY,
    age INTEGER,
    gender TEXT,
    zip_code TEXT,
    ethnicity TEXT,
    income_bracket TEXT,
    diagnosis_code TEXT,
    treatment_code TEXT,
    outcome_code TEXT
);

-- Insert sample data (abbreviated)
INSERT INTO patient_records (age, gender, zip_code, ethnicity, income_bracket, diagnosis_code, treatment_code, outcome_code)
VALUES 
(45, 'M', '12345', 'White', 'Medium', 'D123', 'T456', 'O1'),
(32, 'F', '23456', 'Asian', 'High', 'D234', 'T567', 'O2'),
(67, 'M', '34567', 'Black', 'Low', 'D345', 'T678', 'O3');

-- Create a k-anonymous view for researchers
CREATE MATERIALIZED VIEW research_dataset AS
WITH quasi_counts AS (
    SELECT 
        CASE 
            WHEN age < 20 THEN '0-19'
            WHEN age BETWEEN 20 AND 39 THEN '20-39'
            WHEN age BETWEEN 40 AND 59 THEN '40-59'
            ELSE '60+'
        END AS age_group,
        gender,
        substring(zip_code, 1, 3) AS zip_region,
        CASE
            WHEN ethnicity IN ('White', 'Black', 'Asian', 'Hispanic') THEN ethnicity
            ELSE 'Other'
        END AS ethnicity_group,
        CASE
            WHEN income_bracket = 'Low' THEN 'Low'
            WHEN income_bracket = 'Medium' THEN 'Medium'
            ELSE 'High'
        END AS income_level,
        COUNT(*) AS group_size
    FROM patient_records
    GROUP BY 
        age_group, gender, zip_region, ethnicity_group, income_level
)
SELECT 
    pr.id,
    qc.age_group,
    qc.gender,
    qc.zip_region,
    qc.ethnicity_group,
    qc.income_level,
    pr.diagnosis_code,
    pr.treatment_code,
    pr.outcome_code
FROM patient_records pr
JOIN quasi_counts qc ON 
    CASE 
        WHEN pr.age < 20 THEN '0-19'
        WHEN pr.age BETWEEN 20 AND 39 THEN '20-39'
        WHEN pr.age BETWEEN 40 AND 59 THEN '40-59'
        ELSE '60+'
    END = qc.age_group
    AND pr.gender = qc.gender
    AND substring(pr.zip_code, 1, 3) = qc.zip_region
    AND CASE
        WHEN pr.ethnicity IN ('White', 'Black', 'Asian', 'Hispanic') THEN pr.ethnicity
        ELSE 'Other'
    END = qc.ethnicity_group
    AND CASE
        WHEN pr.income_bracket = 'Low' THEN 'Low'
        WHEN pr.income_bracket = 'Medium' THEN 'Medium'
        ELSE 'High'
    END = qc.income_level
WHERE qc.group_size >= 2;  -- k=2
