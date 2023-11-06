-- ! Module: Role and Permission Management
-- ? This module handles the creation of roles and setting their permissions.

-- * Defining role names as variables for easy maintenance and updates
-- @param READ_ONLY_ROLE The name of the read-only role
-- @param DATA_ENTRY_ROLE The name of the data-entry role
-- @param SCHEMA_NAME The name of the schema to grant permissions to
DO $$
DECLARE
    READ_ONLY_ROLE text := 'read_only';
    DATA_ENTRY_ROLE text := 'data_entry';
    SCHEMA_NAME text := 'email_schema'; -- Replace with environment variable if needed
BEGIN
    -- Create roles if they do not exist
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = READ_ONLY_ROLE) THEN
        CREATE ROLE read_only;
        RAISE NOTICE 'Role created: %', READ_ONLY_ROLE;
    END IF;

    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = DATA_ENTRY_ROLE) THEN
        CREATE ROLE data_entry;
        RAISE NOTICE 'Role created: %', DATA_ENTRY_ROLE;
    END IF;

    -- Grant connect on the database to each role
    -- ? Replace 'your_database' with the actual database name
    GRANT CONNECT ON DATABASE current_database TO read_only, data_entry;

    -- Grant usage on the schema to each role
    GRANT USAGE ON SCHEMA SCHEMA_NAME TO read_only, data_entry;

    -- Grant select on all tables in the schema to the read-only role
    -- * This grants select on future tables as well
    ALTER DEFAULT PRIVILEGES IN SCHEMA SCHEMA_NAME GRANT SELECT ON TABLES TO READ_ONLY_ROLE;

    -- Grant insert on specific tables to the data entry role
    -- * Adjust the table list as per the actual tables requiring insert permissions
    GRANT INSERT ON TABLE SCHEMA_NAME.emails, SCHEMA_NAME.attachments TO DATA_ENTRY_ROLE;

    -- Set default privileges for future objects in the schema for the read-only role
    ALTER DEFAULT PRIVILEGES IN SCHEMA SCHEMA_NAME FOR ROLE DATA_ENTRY_ROLE GRANT SELECT ON TABLES TO READ_ONLY_ROLE;

    RAISE NOTICE 'Roles and permissions have been configured successfully.';
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'An unexpected error occurred: %', SQLERRM;
        -- Optionally, log the error to a table if error logging is set up
        -- INSERT INTO SCHEMA_NAME.error_log (error_message) VALUES (SQLERRM);
END $$;
-- ! End of Role and Permission Management Module
