-- 02_create_schema.sql

-- Use this script to create the schema needed for the email project database.
-- This should be run after initializing the database and creating the user.

-- Replace 'email_schema' with the actual name you want for your schema.
-- Ensure to replace 'your_username' with the username you created in the init script.

BEGIN;

-- Creating the schema
CREATE SCHEMA IF NOT EXISTS email_schema
    AUTHORIZATION oedypus;

-- Optionally, you can set the default search path for the user to include the new schema.
-- This ensures that the user will look in the correct schema when referencing tables without a prefix.
ALTER ROLE oedypus SET search_path TO email_schema, public;

COMMIT;

-- The script ends here. The schema is created, and the role is set to use it by default.
