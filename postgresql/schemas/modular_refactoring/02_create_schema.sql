-- ! Main Module: Schema Creation
-- ? This module creates the necessary schema if it does not exist.
-- * The schema is a logical grouping of database objects.

-- * Using a placeholder for schema name to be replaced by environment variable if needed
-- @param SCHEMA_NAME The name of the schema to be created
DO $$
DECLARE
    SCHEMA_NAME text := 'email_schema'; -- Replace with environment variable if needed
BEGIN
    -- ? Checks if the `email_schema` exists, and if not, it creates it.
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_namespace WHERE nspname = SCHEMA_NAME) THEN
        RAISE NOTICE 'Creating schema: %', SCHEMA_NAME;
        EXECUTE format('CREATE SCHEMA %I', SCHEMA_NAME);
    END IF;
END $$;

-- * Optionally set default permissions or ownership here
-- ! End of Schema Creation Module
