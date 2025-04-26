-- PostgreSQL Anonymizer Dynamic Masking
-- This file contains SQL commands for implementing dynamic masking with security labels

-- Create roles with different access levels
CREATE ROLE doctor WITH LOGIN PASSWORD 'doctor_password';
CREATE ROLE researcher WITH LOGIN PASSWORD 'researcher_password';
CREATE ROLE admin_user WITH LOGIN PASSWORD 'admin_password';

-- Grant basic permissions
GRANT CONNECT ON DATABASE postgres TO doctor, researcher, admin_user;
GRANT USAGE ON SCHEMA public TO doctor, researcher, admin_user;
GRANT USAGE ON SCHEMA anon TO doctor, researcher, admin_user;

-- Grant table access
GRANT SELECT ON patients TO doctor, researcher, admin_user;
GRANT SELECT ON patient_demographics TO researcher, admin_user;
GRANT SELECT ON employees TO admin_user;

-- Define masking rules for patient data using security labels
SECURITY LABEL FOR anon ON COLUMN patients.ssn IS 'MASKED WITH FUNCTION anon.partial(ssn, 0, ''***-**-'', 4)';
SECURITY LABEL FOR anon ON COLUMN patients.insurance_id IS 'MASKED WITH FUNCTION anon.partial(insurance_id, 4, ''-XXX'', 0)';
SECURITY LABEL FOR anon ON COLUMN patients.treatment_cost IS 'MASKED WITH FUNCTION anon.random_int_between(500, 5000)::DECIMAL(10,2)';

-- Define masking rules for employee data
SECURITY LABEL FOR anon ON COLUMN employees.email IS 'MASKED WITH FUNCTION anon.partial_email(email)';
SECURITY LABEL FOR anon ON COLUMN employees.ssn IS 'MASKED WITH FUNCTION anon.partial(ssn, 3, ''***'', 2)';
SECURITY LABEL FOR anon ON COLUMN employees.salary IS 'MASKED WITH FUNCTION anon.random_int_between(50000, 100000)';
SECURITY LABEL FOR anon ON COLUMN employees.address IS 'MASKED WITH FUNCTION anon.fake_address()';
SECURITY LABEL FOR anon ON COLUMN employees.phone IS 'MASKED WITH FUNCTION anon.partial(phone, 0, ''***'', 4)';

-- Activate dynamic masking for specific roles
SECURITY LABEL FOR anon ON ROLE doctor IS 'MASKED';
SECURITY LABEL FOR anon ON ROLE researcher IS 'MASKED';

-- Update the masking rules (required after changes)
SELECT anon.mask_update();

-- Example queries to test dynamic masking
-- Connect as doctor:
-- PGPASSWORD=doctor_password psql -h localhost -p 5433 -U doctor -d postgres -c "SELECT * FROM patients;"

-- Connect as researcher:
-- PGPASSWORD=researcher_password psql -h localhost -p 5433 -U researcher -d postgres -c "SELECT * FROM patients;"

-- Connect as admin:
-- PGPASSWORD=admin_password psql -h localhost -p 5433 -U admin_user -d postgres -c "SELECT * FROM patients;"

-- Remove masking for a specific role
-- SELECT anon.unmask_role('researcher');

-- Remove all masking rules for all roles
-- SELECT anon.remove_masks_for_all_roles();
