# Role-Based Access Control with PostgreSQL Anonymizer

This document explains how to implement role-based access control for data anonymization.

## Creating Roles with Different Access Levels

```sql
-- Create a role that will see masked data
CREATE ROLE masked_user WITH LOGIN PASSWORD 'masked_password';

-- Create a role for administrators who can see all data
CREATE ROLE admin_user WITH LOGIN PASSWORD 'admin_password';

-- Create a role for analysts who need partial access
CREATE ROLE analyst_user WITH LOGIN PASSWORD 'analyst_password';
```

## Granting Basic Permissions

```sql
-- Grant connection permissions
GRANT CONNECT ON DATABASE postgres TO masked_user, analyst_user, admin_user;

-- Grant schema usage
GRANT USAGE ON SCHEMA public TO masked_user, analyst_user, admin_user;
GRANT USAGE ON SCHEMA anon TO masked_user, analyst_user, admin_user;

-- Grant table access
GRANT SELECT ON employees TO admin_user;
GRANT SELECT ON masked_employees_mat TO masked_user, analyst_user;
```

## Implementing Dynamic Masking

```sql
-- Define masking rules for specific columns
SECURITY LABEL FOR anon ON COLUMN employees.email IS 'MASKED WITH FUNCTION anon.partial_email(email)';
SECURITY LABEL FOR anon ON COLUMN employees.ssn IS 'MASKED WITH FUNCTION anon.partial(ssn, 3, ''***'', 2)';
SECURITY LABEL FOR anon ON COLUMN employees.salary IS 'MASKED WITH FUNCTION anon.random_int_between(50000, 100000)';
SECURITY LABEL FOR anon ON COLUMN employees.address IS 'MASKED WITH FUNCTION anon.fake_address()';
SECURITY LABEL FOR anon ON COLUMN employees.phone IS 'MASKED WITH FUNCTION anon.partial(phone, 0, ''***'', 4)';

-- Activate dynamic masking for specific roles
SECURITY LABEL FOR anon ON ROLE masked_user IS 'MASKED';
SECURITY LABEL FOR anon ON ROLE analyst_user IS 'MASKED';

-- Update the masking rules
SELECT anon.mask_update();
```

## Creating Role-Specific Views

For more granular control, create different views for different roles:

```sql
-- View for analysts who need accurate salary data but masked PII
CREATE VIEW analyst_employees AS
SELECT 
    id,
    first_name,
    last_name,
    anon.partial_email(email) AS email,
    anon.partial(ssn, 3, '***', 2) AS ssn,
    salary, -- Actual salary for analysis
    anon.fake_address() AS address,
    anon.partial(phone, 0, '***', 4) AS phone
FROM employees;

-- Grant access to the analyst view
GRANT SELECT ON analyst_employees TO analyst_user;
```

## Using Materialized Views for Performance

```sql
-- Create materialized views for better performance
CREATE MATERIALIZED VIEW masked_employees_mat AS 
SELECT * FROM masked_employees;

CREATE MATERIALIZED VIEW analyst_employees_mat AS 
SELECT * FROM analyst_employees;

-- Grant access to materialized views
GRANT SELECT ON masked_employees_mat TO masked_user;
GRANT SELECT ON analyst_employees_mat TO analyst_user;

-- Refresh materialized views when data changes
REFRESH MATERIALIZED VIEW masked_employees_mat;
REFRESH MATERIALIZED VIEW analyst_employees_mat;
```

## Testing Access Control

```sql
-- Connect as masked_user
PGPASSWORD=masked_password psql -h localhost -p 5433 -U masked_user -d postgres -c "SELECT * FROM masked_employees_mat;"

-- Connect as analyst_user
PGPASSWORD=analyst_password psql -h localhost -p 5433 -U analyst_user -d postgres -c "SELECT * FROM analyst_employees_mat;"

-- Connect as admin_user
PGPASSWORD=admin_password psql -h localhost -p 5433 -U admin_user -d postgres -c "SELECT * FROM employees;"
```

## Removing Masking for Roles

```sql
-- Remove masking for a specific role
SELECT anon.unmask_role('analyst_user');

-- Remove all masking rules for all roles
SELECT anon.remove_masks_for_all_roles();
```
