BEGIN;

-- Step 1: Create the schema if not exists
CREATE SCHEMA IF NOT EXISTS email_schema;

-- Step 2: Define roles and permissions
-- Create a read-only role
CREATE ROLE read_only;

-- Create a data entry role with insert privileges
CREATE ROLE data_entry;

-- Grant connect on the database to each role
-- Replace 'your_database' with the actual database name
GRANT CONNECT ON DATABASE your_database TO read_only, data_entry;

-- Grant usage on the schema to each role
GRANT USAGE ON SCHEMA email_schema TO read_only, data_entry;

-- Grant select on all tables to the read-only role
GRANT SELECT ON ALL TABLES IN SCHEMA email_schema TO read_only;

-- Grant insert on specific tables to the data entry role
GRANT INSERT ON email_schema.emails, email_schema.attachments TO data_entry;

-- Set default privileges for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA email_schema
GRANT SELECT ON TABLES TO read_only;

-- Step 3: Create the error_log table
CREATE TABLE IF NOT EXISTS email_schema.error_log (
  error_id SERIAL PRIMARY KEY,
  error_timestamp TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  error_message TEXT
);

-- Step 4: Create the audit_log table
CREATE TABLE IF NOT EXISTS email_schema.audit_log (
  audit_id SERIAL PRIMARY KEY,
  action_timestamp TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  user_id INT, -- Assuming you have a way to capture the user ID performing the action
  action_type TEXT,
  table_name TEXT,
  record_id BIGINT, -- Assuming that all your record IDs will be BIGINT
  old_value JSONB,
  new_value JSONB
);

-- Step 5: Create the 'emails' table and associated indexes within the 'email_schema'.
DO $$
BEGIN
    -- Create the 'emails' table with proper validation and types
    CREATE TABLE IF NOT EXISTS email_schema.emails (
      email_id BIGSERIAL PRIMARY KEY,
      subject TEXT,
      sender VARCHAR(255) CHECK (sender ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'), -- Email validation regex
      recipient VARCHAR(255) CHECK (recipient ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
      sent_time TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW(),
      body_text TEXT,
      ip_address INET,
      x_originating_ip INET,
      received TEXT,
      user_agent VARCHAR(255),
      authentication_results TEXT,
      dkim_signature TEXT,
      sender_user_id INT,
      recipient_user_id INT
      -- Consider adding a comment here about additional fields that may be needed in the future
    );

    -- Create indexes to optimize search and lookups
    CREATE INDEX IF NOT EXISTS idx_emails_sender_user_id ON email_schema.emails(sender_user_id);
    CREATE INDEX IF NOT EXISTS idx_emails_recipient_user_id ON email_schema.emails(recipient_user_id);
    CREATE INDEX IF NOT EXISTS idx_emails_sent_time ON email_schema.emails(sent_time);
    CREATE INDEX IF NOT EXISTS idx_emails_sender ON email_schema.emails(sender);
    CREATE INDEX IF NOT EXISTS idx_emails_recipient ON email_schema.emails(recipient);

EXCEPTION
    -- Log and handle exceptions related to index creation
    WHEN undefined_table THEN
        INSERT INTO email_schema.error_log (error_message) VALUES ('Attempted to create index on undefined table.');
    WHEN undefined_column THEN
        INSERT INTO email_schema.error_log (error_message) VALUES ('Attempted to create index on undefined column.');
    WHEN duplicate_object THEN
        INSERT INTO email_schema.error_log (error_message) VALUES ('Attempted to create a duplicate index.');
    WHEN OTHERS THEN
        INSERT INTO email_schema.error_log (error_message) VALUES ('Unexpected error occurred while creating indexes: ' || SQLERRM);
        RAISE; -- Re-raise the exception to ensure proper transaction handling
END;
$$ LANGUAGE plpgsql;


-- Step 4: Define a function to log changes to the 'emails' table
CREATE OR REPLACE FUNCTION email_schema.log_emails_changes()
RETURNS TRIGGER AS $$
BEGIN
  -- Example of capturing the user ID from a session variable (adjust as needed for your application context)
  DECLARE
    v_user_id INT := current_setting('myapp.current_user_id')::INT;

  -- Insert a log entry for the operation performed
  IF TG_OP = 'DELETE' THEN
    INSERT INTO email_schema.audit_log(user_id, action_type, table_name, record_id, old_value, new_value)
    VALUES (v_user_id, TG_OP, 'emails', OLD.email_id, row_to_json(OLD), NULL);
    RETURN OLD;
  ELSE
    INSERT INTO email_schema.audit_log(user_id, action_type, table_name, record_id, old_value, new_value)
    VALUES (v_user_id, TG_OP, 'emails', COALESCE(NEW.email_id, OLD.email_id), row_to_json(OLD), row_to_json(NEW));
    RETURN NEW;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Step 5: Create a trigger to log changes to the 'emails' table
CREATE TRIGGER trigger_log_emails_changes
AFTER INSERT OR UPDATE OR DELETE ON email_schema.emails
FOR EACH ROW EXECUTE FUNCTION email_schema.log_emails_changes();


-- Make sure to test the trigger functionality here.

DO $$
BEGIN
    -- Attempt to add foreign key constraints to link users with the emails they send and receive.
    ALTER TABLE email_schema.emails
      ADD CONSTRAINT fk_emails_sender_user_id
      FOREIGN KEY (sender_user_id) REFERENCES email_schema.users(user_id)
      ON DELETE SET NULL, -- If the sending user is deleted, set sender_user_id to NULL
      ADD CONSTRAINT fk_emails_recipient_user_id
      FOREIGN KEY (recipient_user_id) REFERENCES email_schema.users(user_id)
      ON DELETE SET NULL; -- If the receiving user is deleted, set recipient_user_id to NULL

EXCEPTION
    -- Handle specific exceptions that may occur during the constraint addition process
    WHEN undefined_table THEN
        INSERT INTO email_schema.error_log (error_message) VALUES ('Undefined table referenced in foreign key constraint.');
        RAISE; -- Re-raise the exception to ensure that the transaction is rolled back
    WHEN undefined_column THEN
        INSERT INTO email_schema.error_log (error_message) VALUES ('Undefined column referenced in foreign key constraint.');
        RAISE; -- Re-raise the exception to ensure that the transaction is rolled back
    WHEN duplicate_object THEN
        INSERT INTO email_schema.error_log (error_message) VALUES ('Duplicate foreign key constraint name.');
        RAISE; -- Re-raise the exception to ensure that the transaction is rolled back
    WHEN others THEN
        -- Capture any other unexpected exceptions
        INSERT INTO email_schema.error_log (error_message) VALUES ('Unexpected error occurred while adding foreign key constraints: ' || SQLERRM);
        RAISE; -- Re-raise the exception to ensure that the transaction is rolled back
END;
$$ LANGUAGE plpgsql;


-- Separate block for creating indexes with its own exception handling.
DO $$
BEGIN
    -- Add indexes on foreign key columns after adding constraints
    CREATE INDEX IF NOT EXISTS idx_emails_sender_user_id ON email_schema.emails(sender_user_id);
    CREATE INDEX IF NOT EXISTS idx_emails_recipient_user_id ON email_schema.emails(recipient_user_id);

EXCEPTION
    WHEN undefined_table THEN
        INSERT INTO email_schema.error_log (error_message) VALUES ('Attempted to create index on undefined table.');
        RAISE;
    WHEN undefined_column THEN
        INSERT INTO email_schema.error_log (error_message) VALUES ('Attempted to create index on undefined column.');
    WHEN duplicate_object THEN
        INSERT INTO email_schema.error_log (error_message) VALUES ('Attempted to create a duplicate index.');
        RAISE;
    WHEN others THEN
        INSERT INTO email_schema.error_log (error_message) VALUES ('Unexpected error occurred while creating indexes: ' || SQLERRM);
        RAISE;
END;
$$;

DO $$
BEGIN
    -- Define the 'attachments' table structure with necessary constraints
    CREATE TABLE IF NOT EXISTS email_schema.attachments (
      attachment_id BIGSERIAL PRIMARY KEY,
      email_id BIGINT NOT NULL,
      file_name TEXT NOT NULL,
      file_type TEXT NOT NULL, -- Ensures every attachment has a file type specified
      file_size BIGINT NOT NULL CHECK (file_size >= 0), -- Ensures file size is non-negative
      content BYTEA -- Stores binary data, for larger files consider file storage service
    );

    -- Establish a foreign key relationship without allowing cascade deletes
    ALTER TABLE email_schema.attachments
      ADD CONSTRAINT fk_attachments_email_id
      FOREIGN KEY (email_id) REFERENCES email_schema.emails(email_id) ON DELETE RESTRICT;

    -- Indexes to optimize query performance for joins and searches
    CREATE INDEX IF NOT EXISTS idx_attachments_email_id ON email_schema.attachments(email_id);
    CREATE INDEX IF NOT EXISTS idx_attachments_file_name ON email_schema.attachments(file_name);
    CREATE INDEX IF NOT EXISTS idx_attachments_file_type ON email_schema.attachments(file_type);

EXCEPTION
    -- Specific exception handling for the attachments table creation process
    WHEN undefined_table THEN
        -- Log an error when a referenced table is not defined
        INSERT INTO email_schema.error_log (error_message) VALUES ('Undefined table referenced during attachments table creation.');
        RAISE;
    WHEN undefined_column THEN
        -- Log an error when a referenced column is not defined
        INSERT INTO email_schema.error_log (error_message) VALUES ('Undefined column referenced during attachments table creation.');
        RAISE;
    WHEN duplicate_object THEN
        -- Log an error when a constraint or index already exists
        INSERT INTO email_schema.error_log (error_message) VALUES ('Duplicate name for a constraint or index in attachments table.');
        RAISE;
    WHEN check_violation THEN
        -- Log an error when a check constraint is violated
        INSERT INTO email_schema.error_log (error_message) VALUES ('Check constraint violation on attachments table.');
        RAISE;
    WHEN others THEN
        -- Log any other unexpected exceptions
        INSERT INTO email_schema.error_log (error_message) VALUES ('Unexpected error during attachments table creation: ' || SQLERRM);
        RAISE;
END;
$$ LANGUAGE plpgsql;


DO $$
BEGIN
    -- Creates an index on the 'email_id' column of the 'attachments' table to improve join performance, assuming the table and foreign key constraints already exist.
    CREATE INDEX IF NOT EXISTS idx_attachments_email_id ON email_schema.attachments(email_id);

EXCEPTION
    -- Logs specific exceptions with error details and re-raises the exception to halt the transaction.
    WHEN undefined_table THEN
        INSERT INTO email_schema.error_log (error_message) VALUES ('Tried to create an index on a non-existent table.');
        RAISE;
    WHEN undefined_column THEN
        INSERT INTO email_schema.error_log (error_message) VALUES ('Tried to create an index on a non-existent column.');
        RAISE;
    WHEN duplicate_object THEN
        INSERT INTO email_schema.error_log (error_message) VALUES ('Attempted to create an index that already exists.');
        RAISE;
    WHEN others THEN
        INSERT INTO email_schema.error_log (error_message) VALUES ('An unexpected error occurred during the index creation: ' || SQLERRM);
        RAISE;
END;
$$ LANGUAGE plpgsql;



DO $$
BEGIN
    -- Creates the 'email_attachment_mapping' table for managing many-to-many relationships between emails and attachments.
    CREATE TABLE IF NOT EXISTS email_schema.email_attachment_mapping (
      email_id BIGINT NOT NULL,
      attachment_id BIGINT NOT NULL,
      PRIMARY KEY (email_id, attachment_id),
      CONSTRAINT fk_email_attachment_mapping_email_id FOREIGN KEY (email_id) REFERENCES email_schema.emails(email_id) ON DELETE RESTRICT,
      CONSTRAINT fk_email_attachment_mapping_attachment_id FOREIGN KEY (attachment_id) REFERENCES email_schema.attachments(attachment_id) ON DELETE RESTRICT
    );

    -- Since email_id and attachment_id are part of the composite primary key, explicit indexes are not required.

    -- Indexes for the foreign keys, created automatically by PostgreSQL, are defined for performance on queries.
    -- Additional indexes are optional and may be defined based on query patterns.

EXCEPTION
    -- Exception handling for logging errors during table or index creation.
    WHEN duplicate_table THEN
        INSERT INTO email_schema.error_log (error_message) VALUES ('Duplicate table name detected: email_attachment_mapping.');
        RAISE;
    WHEN undefined_table THEN
        INSERT INTO email_schema.error_log (error_message) VALUES ('Foreign key references an undefined table.');
        RAISE;
    WHEN undefined_column THEN
        INSERT INTO email_schema.error_log (error_message) VALUES ('Foreign key references an undefined column.');
        RAISE;
    WHEN duplicate_object THEN
        INSERT INTO email_schema.error_log (error_message) VALUES ('Duplicate name detected for foreign key constraint or index.');
        RAISE;
    WHEN others THEN
        INSERT INTO email_schema.error_log (error_message) VALUES ('An unexpected error occurred during the creation of the email_attachment_mapping table or its indexes: ' || SQLERRM);
        RAISE;
END;
$$ LANGUAGE plpgsql;



DO $$
BEGIN
    -- Create the 'email_status' table to track the delivery status of emails.
    CREATE TABLE IF NOT EXISTS email_schema.email_status (
      status_id SERIAL PRIMARY KEY,
      email_id BIGINT NOT NULL,
      status TEXT NOT NULL CHECK (status IN ('sent', 'received', 'read', 'error', 'pending')), -- Enumerated list of possible statuses
      updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP -- Records the last update time for the status
    );

    -- Foreign key constraint is assumed to be added separately linking email_id to the emails table.

    -- Index for email_id to optimize searches and joins
    CREATE INDEX IF NOT EXISTS idx_email_status_email_id ON email_schema.email_status(email_id);

    -- Index for status to facilitate efficient querying by status type
    CREATE INDEX IF NOT EXISTS idx_email_status_status ON email_schema.email_status(status);

    -- Index for updated_at to enable quick sorting and filtering by the last updated timestamp
    CREATE INDEX IF NOT EXISTS idx_email_status_updated_at ON email_schema.email_status(updated_at);

EXCEPTION
    -- Exception handling for error logging and transaction control
    WHEN duplicate_table THEN
        INSERT INTO email_schema.error_log (error_message) VALUES ('Attempt to create a duplicate table: email_status.');
        RAISE;
    WHEN check_violation THEN
        INSERT INTO email_schema.error_log (error_message) VALUES ('Check constraint violation on email_status table.');
        RAISE;
    WHEN others THEN
        INSERT INTO email_schema.error_log (error_message) VALUES ('An unexpected error occurred during the creation of the email_status table or associated indexes: ' || SQLERRM);
        RAISE;
END;
$$ LANGUAGE plpgsql;



DO $$
BEGIN
    -- Add a foreign key constraint to the 'email_status' table referencing the 'emails' table
    ALTER TABLE email_schema.email_status
      ADD CONSTRAINT fk_email_status_email_id
      FOREIGN KEY (email_id) REFERENCES email_schema.emails(email_id)
      ON DELETE RESTRICT; -- Prevent deletion of emails that have associated statuses

    -- Create an index on the email_id column to enhance the performance of queries using the foreign key
    -- Note: While PostgreSQL automatically creates indexes on primary keys and unique constraints,
    -- it does not for foreign keys. Hence, this is required.
    CREATE INDEX IF NOT EXISTS idx_fk_email_status_email_id ON email_schema.email_status(email_id);

EXCEPTION
    -- Specific exception handling to log errors
    WHEN duplicate_object THEN
        INSERT INTO email_schema.error_log (error_message) VALUES ('Duplicate constraint or index: fk_email_status_email_id or idx_fk_email_status_email_id.');
        RAISE;
    WHEN undefined_table THEN
        INSERT INTO email_schema.error_log (error_message) VALUES ('Referenced table does not exist: email_status or emails.');
        RAISE;
    WHEN undefined_column THEN
        INSERT INTO email_schema.error_log (error_message) VALUES ('Referenced column does not exist: email_id in table email_status or emails.');
        RAISE;
    WHEN others THEN
        INSERT INTO email_schema.error_log (error_message) VALUES ('An unexpected error occurred while applying foreign key constraint or creating index on email_status table: ' || SQLERRM);
        RAISE;
END;
$$ LANGUAGE plpgsql;

COMMIT; -- Only commit if all operations in the script are successful


