-- PostgreSQL Anonymizer Pseudonymization
-- This file contains SQL commands for implementing pseudonymization techniques

-- Create a basic pseudonymization function
CREATE OR REPLACE FUNCTION get_pseudonym(value TEXT) 
RETURNS TEXT AS $$
BEGIN
    RETURN anon.pseudo_first_name(value) || ' ' || anon.pseudo_last_name(value);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a pseudonymization table for storing mappings
CREATE TABLE pseudonyms (
    original_value TEXT PRIMARY KEY,
    pseudonym TEXT
);

-- Create a function for consistent pseudonymization with storage
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

-- Create tables with relationships for cross-table pseudonymization demo
CREATE TABLE medical_records (
    id SERIAL PRIMARY KEY,
    patient_id INTEGER REFERENCES patients(id),
    visit_date DATE,
    notes TEXT
);

-- Insert sample data
INSERT INTO medical_records (patient_id, visit_date, notes) VALUES
(1, '2023-01-15', 'Regular checkup for John Smith'),
(1, '2023-06-20', 'Follow-up visit for John Smith'),
(2, '2023-02-10', 'Initial consultation for Jane Doe');

-- Create a view with consistent pseudonymization across tables
CREATE VIEW pseudonymized_medical_records AS
SELECT 
    mr.id AS record_id,
    p.id AS patient_id,
    get_pseudonym(p.patient_name) AS patient_name,
    mr.visit_date,
    regexp_replace(mr.notes, p.patient_name, get_pseudonym(p.patient_name)) AS notes
FROM medical_records mr
JOIN patients p ON mr.patient_id = p.id;

-- Create a table for storing salts
CREATE TABLE anon.salt (
    id SERIAL PRIMARY KEY,
    name TEXT UNIQUE,
    value TEXT
);

-- Insert a global salt for consistent pseudonymization across databases
INSERT INTO anon.salt (name, value) VALUES ('global_salt', 'my-organization-salt');

-- Create a function that uses the global salt
CREATE OR REPLACE FUNCTION consistent_pseudo(text) RETURNS TEXT AS $$
DECLARE
    salt_value TEXT;
BEGIN
    SELECT value INTO salt_value FROM anon.salt WHERE name = 'global_salt';
    RETURN anon.pseudo_first_name($1, salt_value);
END;
$$ LANGUAGE plpgsql;

-- Example queries
-- SELECT id, get_pseudonym(patient_name) AS patient_name, diagnosis FROM patients;
-- SELECT * FROM pseudonymized_medical_records;
-- SELECT id, consistent_pseudo(patient_name) AS patient_name FROM patients;
