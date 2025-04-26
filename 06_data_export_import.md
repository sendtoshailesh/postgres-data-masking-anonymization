# Data Export and Import with PostgreSQL Anonymizer

This document covers techniques for exporting and importing anonymized data.

## Exporting Anonymized Data

### Using Regular pg_dump with Views

```bash
# Export a masked view
docker exec pg-anon pg_dump -d postgres -U postgres -t masked_employees_mat > masked_employees_dump.sql

# Export the entire database
docker exec pg-anon pg_dump -d postgres -U postgres > full_database_dump.sql
```

### Using pg_dump_anon (PostgreSQL Anonymizer's Tool)

```bash
# Export with default masking rules
docker exec pg-anon pg_dump_anon -d postgres -U postgres > anonymized_dump.sql

# Export with specific masking rules
docker exec pg-anon pg_dump_anon -d postgres -U postgres \
  --mask="employees.email=anon.partial_email(email)" \
  --mask="employees.ssn=anon.partial(ssn, 3, '***', 2)" \
  > custom_anonymized_dump.sql
```

## Importing Anonymized Data

```bash
# Import into a new database
docker exec -i pg-anon psql -U postgres -c "CREATE DATABASE anonymized_db;"
docker exec -i pg-anon psql -U postgres -d anonymized_db < anonymized_dump.sql

# Import into an existing database
docker exec -i pg-anon psql -U postgres -d postgres < masked_employees_dump.sql
```

## Creating Anonymized Copies of Production Data

```bash
# Create an anonymized copy of a production database
# Step 1: Export the production data with anonymization
docker exec pg-anon pg_dump_anon -d postgres -U postgres \
  --mask="employees.email=anon.partial_email(email)" \
  --mask="employees.ssn=anon.partial(ssn, 3, '***', 2)" \
  --mask="employees.salary=anon.random_int_between(50000, 100000)" \
  --mask="employees.address=anon.fake_address()" \
  --mask="employees.phone=anon.partial(phone, 0, '***', 4)" \
  > production_anonymized.sql

# Step 2: Import into a development or test database
docker exec -i pg-anon psql -U postgres -c "CREATE DATABASE dev_db;"
docker exec -i pg-anon psql -U postgres -d dev_db < production_anonymized.sql
```

## Scheduled Anonymized Exports

Create a script for scheduled anonymized exports:

```bash
#!/bin/bash
# File: /Users/mshailes/Documents/my-proj/MyPostgreSQL/export_anonymized_data.sh

# Set the date for the filename
DATE=$(date +%Y%m%d)

# Export anonymized data
docker exec pg-anon pg_dump -d postgres -U postgres -t masked_employees_mat > anonymized_export_$DATE.sql

# Optional: compress the export
gzip anonymized_export_$DATE.sql

# Optional: upload to a secure location
# scp anonymized_export_$DATE.sql.gz user@remote-server:/backup/
```

Make the script executable:

```bash
chmod +x /Users/mshailes/Documents/my-proj/MyPostgreSQL/export_anonymized_data.sh
```

Schedule with cron:

```bash
# Add to crontab (runs daily at 2 AM)
0 2 * * * /Users/mshailes/Documents/my-proj/MyPostgreSQL/export_anonymized_data.sh
```

## Data Transfer Between Environments

```bash
# Export from production with anonymization
docker exec pg-prod pg_dump_anon -d postgres -U postgres \
  --mask="customers.email=anon.partial_email(email)" \
  --mask="customers.credit_card=anon.partial(credit_card, 0, '****', 4)" \
  > prod_to_dev_data.sql

# Import to development
docker exec -i pg-dev psql -U postgres -d postgres < prod_to_dev_data.sql
```

## Selective Data Export

```bash
# Export only specific tables with anonymization
docker exec pg-anon pg_dump -d postgres -U postgres \
  -t employees -t departments \
  --column-inserts | \
  sed -e "s/'[^']*@[^']*'/'masked_email@example.com'/g" \
  -e "s/'[0-9]\{3\}-[0-9]\{2\}-[0-9]\{4\}'/'XXX-XX-XXXX'/g" \
  > selective_anonymized_dump.sql
```
