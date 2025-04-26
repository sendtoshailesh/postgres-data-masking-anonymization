# Creating Sample Data for PostgreSQL Anonymizer

This document provides examples of creating sample data to demonstrate PostgreSQL Anonymizer functionality.

## Creating a Sample Table with Sensitive Data

```sql
-- Create employees table with sensitive data
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

-- Insert sample data
INSERT INTO employees (first_name, last_name, email, ssn, salary, address, phone)
VALUES 
('John', 'Smith', 'john.smith@example.com', '123-45-6789', 75000, '123 Main St, Anytown, USA', '555-123-4567'),
('Jane', 'Doe', 'jane.doe@example.com', '987-65-4321', 85000, '456 Oak Ave, Somewhere, USA', '555-987-6543'),
('Bob', 'Johnson', 'bob.johnson@example.com', '456-78-9012', 65000, '789 Pine Rd, Nowhere, USA', '555-456-7890');

-- View the data
SELECT * FROM employees;
```

## Creating Additional Sample Tables

For healthcare data example:

```sql
-- Create a table for healthcare data
CREATE TABLE patients (
    id SERIAL PRIMARY KEY,
    patient_name TEXT,
    date_of_birth DATE,
    medical_record_number TEXT,
    diagnosis TEXT,
    insurance_id TEXT,
    treatment_cost DECIMAL(10,2)
);

-- Insert sample data
INSERT INTO patients (patient_name, date_of_birth, medical_record_number, diagnosis, insurance_id, treatment_cost)
VALUES 
('Alice Williams', '1985-03-15', 'MRN-12345', 'Hypertension', 'INS-987654', 1250.75),
('Bob Miller', '1972-11-08', 'MRN-23456', 'Type 2 Diabetes', 'INS-876543', 2340.50),
('Carol Davis', '1990-07-22', 'MRN-34567', 'Asthma', 'INS-765432', 890.25);
```

For financial data example:

```sql
-- Create a table for financial data
CREATE TABLE transactions (
    id SERIAL PRIMARY KEY,
    account_number TEXT,
    transaction_date TIMESTAMP,
    amount DECIMAL(10,2),
    description TEXT,
    credit_card_number TEXT,
    routing_number TEXT
);

-- Insert sample data
INSERT INTO transactions (account_number, transaction_date, amount, description, credit_card_number, routing_number)
VALUES 
('1234567890', '2025-04-15 10:30:00', 125.50, 'Grocery Store', '4111-1111-1111-1111', '021000021'),
('0987654321', '2025-04-16 14:45:00', 75.25, 'Gas Station', '5555-5555-5555-4444', '071000013'),
('5432167890', '2025-04-17 09:15:00', 250.00, 'Electronics Store', '3782-822463-10005', '026009593');
```
