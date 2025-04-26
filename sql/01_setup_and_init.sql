-- PostgreSQL Anonymizer Setup and Initialization
-- This file contains SQL commands for setting up and initializing PostgreSQL Anonymizer

-- Initialize the extension
SELECT anon.init();

-- Check if the extension is working with a simple test
SELECT anon.partial_email('john.doe@example.com');

-- Check the version of the extension
SELECT anon.version();

-- Check if the extension is properly initialized
SELECT anon.is_initialized();

-- List available anonymization functions
-- Run this to see all available functions in the anon schema
\df anon.*
