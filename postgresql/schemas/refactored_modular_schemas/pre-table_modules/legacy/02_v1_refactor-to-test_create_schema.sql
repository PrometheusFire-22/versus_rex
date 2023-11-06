-- 02_create_schema.sql

-- Use this script to create the schema needed for the email project database.
-- This should be run after initializing the database and creating the user.

-- Replace 'email_schema' with the actual name you want for your schema.
-- Ensure to replace 'your_username' with the username you created in the init script.

BEGIN;

-- Check if the role 'oedypus' exists and has the necessary privileges.
-- You may need to create the role or grant it the right permissions before executing this script.

-- Creating the schema
CREATE SCHEMA IF NOT EXISTS email_schema
    AUTHORIZATION oedypus;

-- Set the default search path for the 'oedypus' role.
-- This line is optional and should be used if you want 'oedypus' to access this schema by default.
ALTER ROLE oedypus SET search_path TO email_schema;

COMMIT;


-- The script ends here. The schema is created, and the role is set to use it by default.
