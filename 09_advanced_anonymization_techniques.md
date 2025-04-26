# Advanced Anonymization Techniques with PostgreSQL Anonymizer

This document provides detailed explanations of advanced anonymization techniques available in PostgreSQL Anonymizer.

## Pseudonymization for Data Consistency

Pseudonymization is a sophisticated anonymization technique that replaces identifying information with artificial identifiers (pseudonyms) in a consistent manner. Unlike random masking or generalization, pseudonymization ensures that the same input value always produces the same output value across all occurrences in the database.

### How Pseudonymization Works

The core principle of pseudonymization is deterministic transformation - each unique input value maps to a specific output value that remains consistent throughout the database. This preserves data relationships and referential integrity while protecting the original identifiers.

```sql
-- Create a pseudonymization function
CREATE OR REPLACE FUNCTION get_pseudonym(value TEXT) 
RETURNS TEXT AS $$
BEGIN
    RETURN anon.pseudo_first_name(value) || ' ' || anon.pseudo_last_name(value);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Apply pseudonymization
SELECT id, get_pseudonym(patient_name) AS patient_name, diagnosis 
FROM patients;
```

In this example:
- `anon.pseudo_first_name()` and `anon.pseudo_last_name()` are deterministic functions
- Given the same input (e.g., "John Smith"), they will always return the same output (e.g., "Robert Williams")
- This consistency is maintained across queries, tables, and even database sessions

### The Technical Implementation

PostgreSQL Anonymizer implements pseudonymization using cryptographic hash functions with salting. Here's how it works under the hood:

1. **Hashing**: The original value is hashed using a cryptographic algorithm
2. **Salting**: A salt value is added to prevent rainbow table attacks
3. **Mapping**: The hash is mapped to a value from a dictionary (names, addresses, etc.)
4. **Consistency**: The same input + salt always produces the same output

```sql
-- Example of how PostgreSQL Anonymizer implements pseudonymization internally
CREATE OR REPLACE FUNCTION anon.pseudo_first_name(text, text DEFAULT NULL)
RETURNS text AS $$
DECLARE
  v_salt text;
  v_oid bigint;
  v_result text;
BEGIN
  -- Get or create a salt
  IF $2 IS NULL THEN
    SELECT value INTO v_salt FROM anon.salt WHERE name = 'first_name';
  ELSE
    v_salt := $2;
  END IF;
  
  -- Generate a deterministic OID based on input and salt
  v_oid := anon.projection_to_oid($1, v_salt, 1000);
  
  -- Map the OID to a dictionary value
  SELECT first_name INTO v_result FROM anon.first_names WHERE oid = v_oid;
  
  RETURN v_result;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
```

### Advanced Pseudonymization Techniques

#### 1. Format-Preserving Pseudonymization

Format-preserving pseudonymization maintains the format of the original data:

```sql
-- Create a format-preserving pseudonymization function for credit cards
CREATE OR REPLACE FUNCTION pseudo_credit_card(cc_number TEXT) 
RETURNS TEXT AS $$
DECLARE
    last_four TEXT := RIGHT(cc_number, 4);
    card_type TEXT;
    pseudo_number TEXT;
BEGIN
    -- Determine card type based on first digit
    CASE LEFT(cc_number, 1)
        WHEN '4' THEN card_type := '4'; -- Visa starts with 4
        WHEN '5' THEN card_type := '5'; -- Mastercard starts with 5
        WHEN '3' THEN card_type := '3'; -- Amex starts with 3
        ELSE card_type := '9';
    END CASE;
    
    -- Generate deterministic but pseudonymized first digits
    pseudo_number := card_type || anon.pseudo_string(cc_number, 'cc_salt', LENGTH(cc_number) - 5);
    
    -- Keep the last 4 digits for verification purposes
    RETURN pseudo_number || last_four;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
```

#### 2. Cross-Table Pseudonymization

Ensuring consistency across multiple tables is crucial for maintaining referential integrity:

```sql
-- Create tables with relationships
CREATE TABLE patients (
    id SERIAL PRIMARY KEY,
    patient_name TEXT,
    date_of_birth DATE
);

CREATE TABLE medical_records (
    id SERIAL PRIMARY KEY,
    patient_id INTEGER REFERENCES patients(id),
    visit_date DATE,
    notes TEXT
);

-- Insert sample data
INSERT INTO patients (patient_name, date_of_birth) VALUES 
('John Smith', '1985-03-15'),
('Jane Doe', '1972-11-08');

INSERT INTO medical_records (patient_id, visit_date, notes) VALUES
(1, '2023-01-15', 'Regular checkup for John Smith'),
(1, '2023-06-20', 'Follow-up visit for John Smith'),
(2, '2023-02-10', 'Initial consultation for Jane Doe');

-- Create a view with consistent pseudonymization across tables
CREATE VIEW pseudonymized_medical_records AS
SELECT 
    mr.id AS record_id,
    p.id AS patient_id,
    anon.pseudo_first_name(p.patient_name) || ' ' || anon.pseudo_last_name(p.patient_name) AS patient_name,
    mr.visit_date,
    regexp_replace(mr.notes, p.patient_name, 
                  anon.pseudo_first_name(p.patient_name) || ' ' || anon.pseudo_last_name(p.patient_name)) AS notes
FROM medical_records mr
JOIN patients p ON mr.patient_id = p.id;
```

### Benefits of Pseudonymization

1. **Referential Integrity**: Maintains relationships between tables and within text fields
2. **Data Utility**: Preserves the structure and patterns in the data
3. **Consistency**: Ensures the same entity is represented by the same pseudonym throughout the database
4. **Reversibility Option**: Can be designed to be reversible with the proper key (though this reduces security)
5. **Regulatory Compliance**: Recognized by GDPR and other regulations as a valid protection measure

## K-Anonymity for Statistical Data

K-anonymity is a sophisticated privacy-preserving technique specifically designed for statistical and analytical data. It addresses the fundamental challenge of maintaining data utility for analysis while preventing the identification of individuals.

### The Core Concept of K-Anonymity

K-anonymity ensures that for any combination of quasi-identifiers (attributes that, while not unique identifiers themselves, could potentially identify an individual when combined), there are at least k records with those same values. This makes it impossible to distinguish between at least k individuals in the dataset.

```sql
-- Create a table with quasi-identifiers
CREATE TABLE patient_demographics (
    id SERIAL PRIMARY KEY,
    age INTEGER,
    zip_code TEXT,
    gender TEXT,
    condition TEXT
);

-- Insert sample data
INSERT INTO patient_demographics (age, zip_code, gender, condition)
VALUES 
(32, '12345', 'M', 'Hypertension'),
(33, '12345', 'M', 'Diabetes'),
(45, '23456', 'F', 'Asthma'),
(28, '34567', 'F', 'Diabetes'),
(29, '34567', 'F', 'Hypertension');

-- Create a k-anonymous view (k=2)
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
```

In this example, we've applied two key techniques:
1. **Generalization** of age values into broader age groups
2. **Suppression** of specific zip code digits (keeping only the first 3)

The `HAVING COUNT(*) >= 2` clause ensures that only combinations that appear at least twice (k=2) are included in the view.

### Implementation Techniques

#### 1. Generalization Hierarchies

Generalization involves replacing specific values with more general ones. PostgreSQL Anonymizer provides functions to implement generalization:

```sql
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
```

#### 2. Adaptive K-Anonymity

Adaptive k-anonymity dynamically adjusts the level of generalization to achieve the desired k value:

```sql
-- Create a function that finds the minimum generalization level needed
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
```

### Advanced K-Anonymity Concepts

#### 1. L-Diversity

K-anonymity can be vulnerable to homogeneity attacks if all k records share the same sensitive attribute. L-diversity addresses this by ensuring diversity in sensitive attributes:

```sql
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
```

#### 2. T-Closeness

T-closeness further enhances privacy by ensuring that the distribution of sensitive attributes within each equivalence class is similar to the overall distribution.

### Measuring K-Anonymity

PostgreSQL Anonymizer provides functions to measure the level of k-anonymity in your data:

```sql
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
```

### Benefits and Limitations of K-Anonymity

#### Benefits:
1. **Formal Privacy Guarantee**: Provides a mathematically provable level of anonymity
2. **Maintains Data Structure**: Preserves the structure and relationships in the data
3. **Configurable Privacy Level**: The k parameter can be adjusted based on sensitivity
4. **Regulatory Recognition**: Recognized by many privacy regulations as a valid technique
5. **Statistical Utility**: Preserves aggregate statistics and distributions

#### Limitations:
1. **Susceptible to Background Knowledge Attacks**: Additional external information can reduce privacy
2. **Information Loss**: Higher k values lead to more generalization and information loss
3. **Homogeneity Problem**: Addressed by l-diversity and t-closeness extensions
4. **Computational Complexity**: Finding optimal k-anonymous solutions is NP-hard
5. **Dynamic Data Challenges**: Maintaining k-anonymity as data changes can be difficult

## Understanding Security Labels in PostgreSQL Anonymizer

Security labels are a powerful feature in PostgreSQL Anonymizer that enable dynamic masking based on user roles.

### How Security Labels Work

```sql
SECURITY LABEL FOR anon ON COLUMN patients.ssn IS 'MASKED WITH FUNCTION anon.partial(ssn, 0, ''***-**-'', 4)';
```

This SQL statement applies a security label to the `ssn` column in the `patients` table, defining how it should be dynamically masked when accessed by users with masking enabled. Let's break down each component:

1. `SECURITY LABEL FOR anon` - This indicates we're using PostgreSQL's security label system with the "anon" provider (PostgreSQL Anonymizer). Security labels are metadata attached to database objects.

2. `ON COLUMN patients.ssn` - Specifies that we're applying this label to the "ssn" column in the "patients" table.

3. `IS 'MASKED WITH FUNCTION anon.partial(ssn, 0, ''***-**-'', 4)'` - This defines the masking rule:
   - `MASKED WITH FUNCTION` - Indicates that this column should be dynamically masked using a function
   - `anon.partial(ssn, 0, ''***-**-'', 4)` - The function and parameters to use for masking:
     - `ssn` - The column value to mask
     - `0` - Keep 0 characters from the beginning
     - `''***-**-''` - Replace the hidden part with this string (note the doubled single quotes for escaping)
     - `4` - Keep the last 4 digits
     - Result: A SSN like "123-45-6789" becomes "***-**-6789"

The key difference between this approach and using a view is that this is a **dynamic masking** technique. When security labels are applied:

1. The data in the original table remains unchanged
2. Users with the "MASKED" role label will automatically see the masked version when they query the table directly
3. Users without the "MASKED" role label will see the original data
4. The masking happens transparently at query time

For this to take effect, you need to:

1. Apply security labels to columns you want to mask
2. Apply the "MASKED" security label to roles that should see masked data:
   ```sql
   SECURITY LABEL FOR anon ON ROLE doctor IS 'MASKED';
   ```
3. Update the masking rules:
   ```sql
   SELECT anon.mask_update();
   ```

This approach is particularly powerful because:
- It doesn't require creating and maintaining separate views
- It applies consistently across all queries to the original table
- It can be selectively applied to different user roles
- The original data remains intact and accessible to privileged users
