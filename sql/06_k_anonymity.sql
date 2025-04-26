-- PostgreSQL Anonymizer K-Anonymity
-- This file contains SQL commands for implementing k-anonymity techniques

-- Create generalization functions for different data types
CREATE OR REPLACE FUNCTION generalize_age(age INTEGER) 
RETURNS TEXT AS $$
BEGIN
    RETURN CASE 
        WHEN age < 18 THEN '<18'
        WHEN age BETWEEN 18 AND 30 THEN '18-30'
        WHEN age BETWEEN 31 AND 45 THEN '31-45'
        WHEN age BETWEEN 46 AND 65 THEN '46-65'
        ELSE '65+'
    END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION generalize_zip(zip_code TEXT, level INTEGER) 
RETURNS TEXT AS $$
BEGIN
    RETURN CASE 
        WHEN level = 1 THEN LEFT(zip_code, 1) || '****'
        WHEN level = 2 THEN LEFT(zip_code, 2) || '***'
        WHEN level = 3 THEN LEFT(zip_code, 3) || '**'
        ELSE zip_code
    END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Create a basic k-anonymous view (k=2)
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

-- Create a function that finds the minimum generalization level needed for k-anonymity
CREATE OR REPLACE FUNCTION find_k_anonymous_level(
    table_name TEXT, 
    column_name TEXT, 
    k INTEGER
) RETURNS INTEGER AS $$
DECLARE
    level INTEGER := 0;
    count_min INTEGER;
    query TEXT;
BEGIN
    FOR level IN 1..5 LOOP
        query := format('
            SELECT MIN(count) FROM (
                SELECT COUNT(*) as count 
                FROM %I 
                GROUP BY generalize_zip(%I, %s)
            ) AS counts', 
            table_name, column_name, level);
        
        EXECUTE query INTO count_min;
        
        IF count_min >= k THEN
            RETURN level;
        END IF;
    END LOOP;
    
    RETURN 5; -- Maximum generalization if k-anonymity cannot be achieved
END;
$$ LANGUAGE plpgsql;

-- Create a function to create an adaptive k-anonymous view
CREATE OR REPLACE FUNCTION create_k_anonymous_view(
    source_table TEXT,
    target_view TEXT,
    k INTEGER
) RETURNS VOID AS $$
DECLARE
    zip_level INTEGER;
BEGIN
    -- Find minimum generalization levels
    zip_level := find_k_anonymous_level(source_table, 'zip_code', k);
    
    -- Create the view with appropriate generalization
    EXECUTE format('
        CREATE OR REPLACE VIEW %I AS
        SELECT 
            generalize_age(age) AS age_group,
            generalize_zip(zip_code, %s) AS zip_code,
            gender,
            condition
        FROM %I
        GROUP BY 
            generalize_age(age),
            generalize_zip(zip_code, %s),
            gender,
            condition
        HAVING COUNT(*) >= %s',
        target_view, zip_level, source_table, zip_level, k);
END;
$$ LANGUAGE plpgsql;

-- Create a k-anonymous view with k=3
SELECT create_k_anonymous_view('patient_demographics', 'k3_anonymous_patients', 3);

-- Create an l-diverse view (l=2)
CREATE VIEW l_diverse_patients AS
WITH diversity AS (
    SELECT 
        generalize_age(age) AS age_group,
        substring(zip_code, 1, 3) AS zip_prefix,
        gender,
        COUNT(DISTINCT condition) AS distinct_conditions
    FROM patient_demographics
    GROUP BY 
        generalize_age(age),
        substring(zip_code, 1, 3),
        gender
)
SELECT 
    pd.id,
    d.age_group,
    d.zip_prefix,
    d.gender,
    pd.condition
FROM patient_demographics pd
JOIN diversity d ON 
    generalize_age(pd.age) = d.age_group AND
    substring(pd.zip_code, 1, 3) = d.zip_prefix AND
    pd.gender = d.gender
WHERE d.distinct_conditions >= 2;

-- Function to measure k-anonymity
CREATE OR REPLACE FUNCTION measure_k_anonymity(
    table_name TEXT,
    quasi_identifiers TEXT[]
) RETURNS INTEGER AS $$
DECLARE
    k INTEGER;
    query TEXT;
BEGIN
    query := format('
        SELECT MIN(count) FROM (
            SELECT COUNT(*) as count 
            FROM %I 
            GROUP BY %s
        ) AS counts', 
        table_name, array_to_string(quasi_identifiers, ', '));
    
    EXECUTE query INTO k;
    RETURN k;
END;
$$ LANGUAGE plpgsql;

-- Example query to measure k-anonymity
-- SELECT measure_k_anonymity(
--     'patient_demographics', 
--     ARRAY['generalize_age(age)', 'substring(zip_code, 1, 3)', 'gender']
-- );
