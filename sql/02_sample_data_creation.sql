-- PostgreSQL Anonymizer Sample Data Creation
-- This file contains SQL commands for creating sample tables with sensitive data

-- Create a table with employee data
CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    first_name TEXT,
    last_name TEXT,
    email TEXT,
    ssn TEXT,
    salary INTEGER,
    address TEXT,
    phone TEXT
);

-- Insert sample employee data
INSERT INTO employees (first_name, last_name, email, ssn, salary, address, phone)
VALUES 
('John', 'Smith', 'john.smith@example.com', '123-45-6789', 75000, '123 Main St, Anytown, USA', '555-123-4567'),
('Jane', 'Doe', 'jane.doe@example.com', '987-65-4321', 85000, '456 Oak Ave, Somewhere, USA', '555-987-6543'),
('Bob', 'Johnson', 'bob.johnson@example.com', '456-78-9012', 65000, '789 Pine Rd, Nowhere, USA', '555-456-7890');

-- Create a table with healthcare data
CREATE TABLE patients (
    id SERIAL PRIMARY KEY,
    patient_name TEXT,
    date_of_birth DATE,
    ssn TEXT,
    diagnosis TEXT,
    insurance_id TEXT,
    treatment_cost DECIMAL(10,2)
);

-- Insert sample patient data
INSERT INTO patients (patient_name, date_of_birth, ssn, diagnosis, insurance_id, treatment_cost)
VALUES 
('John Smith', '1985-03-15', '123-45-6789', 'Hypertension', 'INS-987654', 1250.75),
('Jane Doe', '1972-11-08', '987-65-4321', 'Type 2 Diabetes', 'INS-876543', 2340.50),
('Bob Johnson', '1990-07-22', '456-78-9012', 'Asthma', 'INS-765432', 890.25);

-- Create a table with financial data
CREATE TABLE transactions (
    id SERIAL PRIMARY KEY,
    account_number TEXT,
    transaction_date TIMESTAMP,
    amount DECIMAL(10,2),
    description TEXT,
    credit_card_number TEXT,
    routing_number TEXT
);

-- Insert sample transaction data
INSERT INTO transactions (account_number, transaction_date, amount, description, credit_card_number, routing_number)
VALUES 
('1234567890', '2025-04-15 10:30:00', 125.50, 'Grocery Store', '4111-1111-1111-1111', '021000021'),
('0987654321', '2025-04-16 14:45:00', 75.25, 'Gas Station', '5555-5555-5555-4444', '071000013'),
('5432167890', '2025-04-17 09:15:00', 250.00, 'Electronics Store', '3782-822463-10005', '026009593');

-- Create a table for k-anonymity demonstration
CREATE TABLE patient_demographics (
    id SERIAL PRIMARY KEY,
    age INTEGER,
    zip_code TEXT,
    gender TEXT,
    condition TEXT
);

-- Insert sample demographic data
INSERT INTO patient_demographics (age, zip_code, gender, condition)
VALUES 
(32, '12345', 'M', 'Hypertension'),
(33, '12345', 'M', 'Diabetes'),
(45, '23456', 'F', 'Asthma'),
(28, '34567', 'F', 'Diabetes'),
(29, '34567', 'F', 'Hypertension');
