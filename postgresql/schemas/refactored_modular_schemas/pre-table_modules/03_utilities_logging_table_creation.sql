-- TODO: Set the schema name as a session variable before running this script
-- \set SCHEMA_NAME 'your_schema_name'

-- Step 3: Create the error_log table
DO $$
BEGIN
    -- Check if the schema exists before creating the table
    IF NOT EXISTS (SELECT schema_name FROM information_schema.schemata WHERE schema_name = :SCHEMA_NAME) THEN
        RAISE NOTICE 'Schema % does not exist. Create the schema before creating tables.', :SCHEMA_NAME;
        -- TODO: Consider whether you want to automatically create the schema if not exists
    ELSE
        -- Create the error_log table in the specified schema
        EXECUTE format('
            CREATE TABLE IF NOT EXISTS %I.error_log (
                error_id SERIAL PRIMARY KEY,
                error_timestamp TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                error_message TEXT
            )', :SCHEMA_NAME);
        RAISE NOTICE 'Table %I.error_log created successfully.', :SCHEMA_NAME;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        -- TODO: Ensure that error logging to error_log table is established
        RAISE NOTICE 'An error occurred while creating error_log table: %', SQLERRM;
END $$;

-- Step 4: Create the audit_log table
DO $$
BEGIN
    -- Check if the schema exists before creating the table
    IF NOT EXISTS (SELECT schema_name FROM information_schema.schemata WHERE schema_name = :SCHEMA_NAME) THEN
        RAISE NOTICE 'Schema % does not exist. Create the schema before creating tables.', :SCHEMA_NAME;
        -- TODO: Consider whether you want to automatically create the schema if not exists
    ELSE
        -- Create the audit_log table in the specified schema
        EXECUTE format('
            CREATE TABLE IF NOT EXISTS %I.audit_log (
                audit_id SERIAL PRIMARY KEY,
                action_timestamp TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                user_id INT, -- Replace with actual method to capture user ID
                action_type TEXT,
                table_name TEXT,
                record_id BIGINT,
                old_value JSONB,
                new_value JSONB
            )', :SCHEMA_NAME);
        RAISE NOTICE 'Table %I.audit_log created successfully.', :SCHEMA_NAME;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        -- TODO: Ensure that error logging to error_log table is established
        RAISE NOTICE 'An error occurred while creating audit_log table: %', SQLERRM;
END $$;
