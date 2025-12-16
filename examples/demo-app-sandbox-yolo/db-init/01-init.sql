-- PostgreSQL initialization script for Pro mode
-- This script runs on first database creation

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";  -- For text search

-- Create additional schemas (optional)
-- CREATE SCHEMA IF NOT EXISTS audit;

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE sandbox_dev TO sandbox_user;

-- Create audit table (optional)
-- CREATE TABLE IF NOT EXISTS audit.audit_log (
--     id SERIAL PRIMARY KEY,
--     table_name VARCHAR(50),
--     operation VARCHAR(10),
--     old_data JSONB,
--     new_data JSONB,
--     changed_by VARCHAR(100),
--     changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
-- );

-- Log initialization
DO $$
BEGIN
    RAISE NOTICE 'Database initialized for Pro mode development';
END $$;
