# PostgreSQL Anonymizer Masking Techniques

This document outlines different approaches to implementing data masking with PostgreSQL Anonymizer.

## 1. Masking Views

Creating views that apply anonymization functions is a straightforward approach:

```sql
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

-- Query the masked view
SELECT * FROM masked_employees;
```

For better performance with complex masking functions, use materialized views:

```sql
-- Create a materialized view for better performance
CREATE MATERIALIZED VIEW masked_employees_mat AS 
SELECT * FROM masked_employees;

-- Refresh the materialized view when data changes
REFRESH MATERIALIZED VIEW masked_employees_mat;
```

## 2. Dynamic Masking with Security Labels

Dynamic masking applies masking rules based on the user's role:

```sql
-- Create a masked role
CREATE ROLE masked_user WITH LOGIN PASSWORD 'masked_password';
GRANT CONNECT ON DATABASE postgres TO masked_user;
GRANT USAGE ON SCHEMA public TO masked_user;
GRANT SELECT ON employees TO masked_user;

-- Define masking rules using security labels
SECURITY LABEL FOR anon ON COLUMN employees.email IS 'MASKED WITH FUNCTION anon.partial_email(email)';
SECURITY LABEL FOR anon ON COLUMN employees.ssn IS 'MASKED WITH FUNCTION anon.partial(ssn, 3, ''***'', 2)';
SECURITY LABEL FOR anon ON COLUMN employees.salary IS 'MASKED WITH FUNCTION anon.random_int_between(50000, 100000)';
SECURITY LABEL FOR anon ON COLUMN employees.address IS 'MASKED WITH FUNCTION anon.fake_address()';
SECURITY LABEL FOR anon ON COLUMN employees.phone IS 'MASKED WITH FUNCTION anon.partial(phone, 0, ''***'', 4)';

-- Activate dynamic masking for the role
SECURITY LABEL FOR anon ON ROLE masked_user IS 'MASKED';

-- Update the masking rules (required after changes)
SELECT anon.mask_update();
```

## 3. Static Masking (Permanent Anonymization)

Static masking permanently replaces sensitive data:

```sql
-- Create a backup before static masking
CREATE TABLE employees_backup AS SELECT * FROM employees;

-- Apply static masking
UPDATE employees SET
    email = anon.partial_email(email),
    ssn = anon.partial(ssn, 3, '***', 2),
    salary = anon.random_int_between(50000, 100000),
    address = anon.fake_address(),
    phone = anon.partial(phone, 0, '***', 4);
```

## 4. Anonymous Dumps

Create anonymized database dumps:

```bash
# Using pg_dump_anon (part of PostgreSQL Anonymizer)
docker exec pg-anon pg_dump_anon -d postgres -U postgres > anonymized_dump.sql

# Using pg_dump with masking views
docker exec pg-anon pg_dump -d postgres -U postgres -t masked_employees_mat > masked_dump.sql
```

## 5. Pseudonymization

Pseudonymization replaces identifiers with consistent pseudonyms:

```sql
-- Create a pseudonymization table
CREATE TABLE pseudonyms (
    original_value TEXT PRIMARY KEY,
    pseudonym TEXT
);

-- Create a function for consistent pseudonymization
CREATE OR REPLACE FUNCTION get_or_create_pseudonym(value TEXT) 
RETURNS TEXT AS $$
DECLARE
    existing_pseudonym TEXT;
BEGIN
    -- Check if we already have a pseudonym for this value
    SELECT pseudonym INTO existing_pseudonym FROM pseudonyms WHERE original_value = value;
    
    -- If not, create one and store it
    IF existing_pseudonym IS NULL THEN
        existing_pseudonym := 'PSEUDO-' || anon.random_string(8);
        INSERT INTO pseudonyms (original_value, pseudonym) VALUES (value, existing_pseudonym);
    END IF;
    
    RETURN existing_pseudonym;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Apply pseudonymization
SELECT id, get_or_create_pseudonym(patient_name) AS patient_name, diagnosis 
FROM patients;
```

## 6. K-Anonymity

K-anonymity ensures each combination of quasi-identifiers appears at least k times:

```sql
-- Create a k-anonymous view (k=2)
CREATE VIEW k_anonymous_survey AS
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
    income_bracket
FROM survey_data
GROUP BY age_group, zip_prefix, gender, income_bracket
HAVING COUNT(*) >= 2;
```
