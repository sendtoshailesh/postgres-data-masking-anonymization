# PostgreSQL Anonymizer Setup with Docker

This document outlines the steps to set up PostgreSQL Anonymizer using Docker.

## Docker Installation and Setup

```bash
# Install Docker Desktop for Mac (if not already installed)
brew install --cask docker

# Start Docker Desktop
open -a Docker

# Pull the PostgreSQL Anonymizer Docker image
docker pull registry.gitlab.com/dalibo/postgresql_anonymizer:stable

# Run the container with port forwarding (using port 5433 to avoid conflicts)
docker run -d --name pg-anon -e POSTGRES_PASSWORD=mysecretpassword -p 5433:5432 registry.gitlab.com/dalibo/postgresql_anonymizer:stable

# Verify the container is running
docker ps
```

## Connection Information

### Connection String
```bash
# Connect as postgres user
psql -h localhost -p 5433 -U postgres -d postgres
# Password: mysecretpassword

# Alternative connection with password in environment variable
PGPASSWORD=mysecretpassword psql -h localhost -p 5433 -U postgres -d postgres
```

### Initialize the Extension
```sql
-- Check if the extension is working
SELECT anon.partial_email('john.doe@example.com');

-- Initialize the extension to enable all features
SELECT anon.init();
```

## Container Management

```bash
# Stop the container
docker stop pg-anon

# Start the container again
docker start pg-anon

# Remove the container (will delete all data)
docker rm pg-anon

# Run a new container with persistent storage
docker run -d --name pg-anon \
  -e POSTGRES_PASSWORD=mysecretpassword \
  -p 5433:5432 \
  -v pg_anon_data:/var/lib/postgresql/data \
  registry.gitlab.com/dalibo/postgresql_anonymizer:stable
```
