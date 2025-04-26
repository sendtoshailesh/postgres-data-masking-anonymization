# Troubleshooting PostgreSQL Anonymizer

This document provides solutions for common issues encountered when using PostgreSQL Anonymizer.

## Installation Issues

### Extension Not Found

**Problem:** Error when creating the extension
```
ERROR: could not open extension control file "/usr/share/postgresql/14/extension/anon.control": No such file or directory
```

**Solution:**
```bash
# Check if the extension files are installed
ls $(pg_config --sharedir)/extension/anon*

# Install the extension if missing
sudo apt install postgresql-14-anonymizer  # Debian/Ubuntu
sudo yum install postgresql_anonymizer_14  # RHEL/CentOS
```

### Initialization Failure

**Problem:** The extension is installed but initialization fails
```
ERROR: anon extension is not initialized
```

**Solution:**
```sql
-- Initialize the extension
SELECT anon.init();

-- Check initialization status
SELECT anon.is_initialized();
```

## Permission Issues

### Function Access Denied

**Problem:** Users can't access anonymization functions
```
ERROR: permission denied for function partial_email
```

**Solution:**
```sql
-- Grant usage on the anon schema
GRANT USAGE ON SCHEMA anon TO masked_user;

-- For materialized views, pre-compute the masked data
CREATE MATERIALIZED VIEW masked_data AS
SELECT id, anon.partial_email(email) AS email FROM users;

GRANT SELECT ON masked_data TO masked_user;
```

### Dynamic Masking Not Working

**Problem:** Dynamic masking is configured but users still see unmasked data

**Solution:**
```sql
-- Check if the role is properly marked as masked
SELECT objname, label FROM pg_seclabels WHERE provider = 'anon' AND objname = 'masked_user';

-- Ensure masking is updated after changes
SELECT anon.mask_update();

-- Verify column masking rules
SELECT relname, attname, label FROM pg_seclabels
JOIN pg_class ON pg_seclabels.objoid = pg_class.oid
JOIN pg_attribute ON pg_class.oid = pg_attribute.attrelid 
                  AND pg_seclabels.objsubid = pg_attribute.attnum
WHERE provider = 'anon';
```

## Function Errors

### Invalid Function Parameters

**Problem:** Function errors with parameter mismatches
```
ERROR: function anon.partial(text, integer, integer) does not exist
```

**Solution:**
```sql
-- Check the correct function signature
\df anon.partial

-- Use the correct parameters
-- For anon.partial, the correct signature is:
SELECT anon.partial('text', 3, '***', 2);  -- prefix_length, padding, suffix_length
```

### Missing Functions

**Problem:** Some functions mentioned in documentation aren't available

**Solution:**
```sql
-- Check if the extension is properly initialized
SELECT anon.is_initialized();

-- List available functions
\df anon.*

-- Update to the latest version if functions are missing
```

## Performance Issues

### Slow Masking Operations

**Problem:** Masking operations are too slow for large datasets

**Solution:**
```sql
-- Use materialized views instead of regular views
CREATE MATERIALIZED VIEW masked_employees_mat AS
SELECT id, anon.partial_email(email) AS email FROM employees;

-- Create indexes on frequently queried columns
CREATE INDEX ON masked_employees_mat (id);

-- Schedule refreshes during low-usage periods
REFRESH MATERIALIZED VIEW masked_employees_mat;
```

### High CPU Usage

**Problem:** Anonymization functions cause high CPU usage

**Solution:**
```sql
-- Use simpler masking functions
-- Instead of complex randomization:
SELECT anon.partial(ssn, 3, '***', 2) FROM employees;  -- Less CPU intensive

-- Process large tables in batches
DO $$
DECLARE
    batch_size INT := 10000;
    max_id INT;
    current_id INT := 0;
BEGIN
    SELECT MAX(id) INTO max_id FROM large_table;
    WHILE current_id <= max_id LOOP
        -- Process batch
        UPDATE large_table 
        SET email = anon.partial_email(email)
        WHERE id > current_id AND id <= current_id + batch_size;
        
        current_id := current_id + batch_size;
        COMMIT;
    END LOOP;
END $$;
```

## Docker-Specific Issues

### Container Connection Issues

**Problem:** Unable to connect to the PostgreSQL container

**Solution:**
```bash
# Check if the container is running
docker ps

# Check container logs
docker logs pg-anon

# Ensure port mapping is correct
docker port pg-anon

# Try connecting with explicit parameters
PGPASSWORD=mysecretpassword psql -h localhost -p 5433 -U postgres -d postgres
```

### Data Persistence

**Problem:** Data is lost when the container restarts

**Solution:**
```bash
# Create a volume for data persistence
docker volume create pg_anon_data

# Run container with the volume
docker run -d --name pg-anon \
  -e POSTGRES_PASSWORD=mysecretpassword \
  -p 5433:5432 \
  -v pg_anon_data:/var/lib/postgresql/data \
  registry.gitlab.com/dalibo/postgresql_anonymizer:stable
```

## Debugging Tips

### Check Extension Status

```sql
-- Check if extension is installed
SELECT * FROM pg_extension WHERE extname = 'anon';

-- Check extension version
SELECT anon.version();

-- Check initialization status
SELECT anon.is_initialized();
```

### Examine Masking Rules

```sql
-- List all masking rules
SELECT 
    relname AS table_name, 
    attname AS column_name, 
    label AS masking_rule
FROM pg_seclabel
JOIN pg_class ON pg_seclabel.objoid = pg_class.oid
JOIN pg_attribute ON pg_class.oid = pg_attribute.attrelid 
                  AND pg_seclabel.objsubid = pg_attribute.attnum
WHERE provider = 'anon';

-- List masked roles
SELECT objname AS role_name, label AS masking_status
FROM pg_seclabels
WHERE provider = 'anon' AND classoid = 'pg_authid'::regclass;
```

### Test Functions Individually

```sql
-- Test each function with sample data
SELECT anon.partial_email('test@example.com');
SELECT anon.partial('123-45-6789', 3, '***', 2);
SELECT anon.fake_address();
```
