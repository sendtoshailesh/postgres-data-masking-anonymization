-- PostgreSQL Anonymizer Data Export
-- This file contains SQL commands for exporting anonymized data

-- Export a masked view (run these commands in bash)
-- docker exec pg-anon pg_dump -d postgres -U postgres -t masked_patients > masked_patients_dump.sql

-- Export with specific masking rules using pg_dump_anon
-- docker exec pg-anon pg_dump_anon -d postgres -U postgres \
--   --mask="patients.patient_name=anon.fake_name()" \
--   --mask="patients.ssn=anon.partial(ssn, 0, '***-**-', 4)" \
--   > anonymized_patients.sql

-- Create a development database for importing anonymized data
CREATE DATABASE dev_db;

-- Import anonymized data (run these commands in bash)
-- docker exec -i pg-anon psql -U postgres -d dev_db < masked_patients_dump.sql

-- Create a scheduled export script (save as export_anonymized_data.sh)
-- #!/bin/bash
-- DATE=$(date +%Y%m%d)
-- docker exec pg-anon pg_dump -d postgres -U postgres -t masked_employees_mat > anonymized_export_$DATE.sql
-- gzip anonymized_export_$DATE.sql

-- Selective data export with sed transformation (run in bash)
-- docker exec pg-anon pg_dump -d postgres -U postgres \
--   -t employees -t departments \
--   --column-inserts | \
--   sed -e "s/'[^']*@[^']*'/'masked_email@example.com'/g" \
--   -e "s/'[0-9]\{3\}-[0-9]\{2\}-[0-9]\{4\}'/'XXX-XX-XXXX'/g" \
--   > selective_anonymized_dump.sql
