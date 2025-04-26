-- PostgreSQL Anonymizer Masking Views
-- This file contains SQL commands for creating masked views of sensitive data

-- Create a masked view of the employees table
CREATE VIEW masked_employees AS
SELECT 
    id,
    first_name,
    last_name,
    anon.partial_email(email) AS email,
    anon.partial(ssn, 3, '***', 2) AS ssn,
    anon.random_int_between(50000, 100000) AS salary,
    anon.fake_address() AS address,
    anon.partial(phone, 0, '***', 4) AS phone
FROM employees;

-- Create a materialized view for better performance
CREATE MATERIALIZED VIEW masked_employees_mat AS 
SELECT * FROM masked_employees;

-- Create a masked view of the patients table
CREATE VIEW masked_patients AS
SELECT 
    id,
    anon.fake_first_name() || ' ' || anon.fake_last_name() AS patient_name,
    date_of_birth,
    anon.partial(ssn, 0, '***-**-', 4) AS ssn,
    diagnosis,
    anon.partial(insurance_id, 4, '-XXX', 0) AS insurance_id,
    anon.random_int_between(500, 5000)::DECIMAL(10,2) AS treatment_cost
FROM patients;

-- Create a materialized view of masked patients
CREATE MATERIALIZED VIEW masked_patients_mat AS 
SELECT * FROM masked_patients;

-- Create a masked view of financial transactions
CREATE VIEW masked_transactions AS
SELECT 
    id,
    anon.partial(account_number, 2, '******', 2) AS account_number,
    transaction_date,
    -- Randomize amount within 10% of original
    amount * (1 + anon.random_int_between(-10, 10) / 100.0) AS amount,
    description,
    anon.partial(credit_card_number, 0, '****-****-****-', 4) AS credit_card_number,
    anon.partial(routing_number, 3, '***', 3) AS routing_number
FROM transactions;

-- Create a k-anonymous view of patient demographics
CREATE VIEW k_anonymous_patients AS
SELECT 
    -- Generalize age into age groups
    CASE 
        WHEN age < 30 THEN '20-29'
        WHEN age < 40 THEN '30-39'
        ELSE '40+'
    END AS age_group,
    -- Truncate zip code to first 3 digits
    substring(zip_code, 1, 3) AS zip_prefix,
    gender,
    condition
FROM patient_demographics
GROUP BY age_group, zip_prefix, gender, condition
HAVING COUNT(*) >= 2;

-- Refresh materialized views when data changes
REFRESH MATERIALIZED VIEW masked_employees_mat;
REFRESH MATERIALIZED VIEW masked_patients_mat;
