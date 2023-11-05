BEGIN;

CREATE TABLE IF NOT EXISTS email_schema.emails (
  email_id BIGSERIAL PRIMARY KEY,
  subject TEXT,
  sender VARCHAR(100) CHECK (sender ~* '^[^@]+@[^@]+\.[^@]+$'), -- Regex for basic email validation
  recipient VARCHAR(100) CHECK (recipient ~* '^[^@]+@[^@]+\.[^@]+$'),
  sent_time TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW(), -- Default to the current timestamp
  body_text TEXT,
  ip_address INET,
  x_originating_ip INET,
  received TEXT,
  user_agent VARCHAR(255),
  authentication_results TEXT,
  dkim_signature TEXT
);

-- Creating the 'attachments' table within the 'email_schema'.
CREATE TABLE IF NOT EXISTS email_schema.attachments (
  attachment_id BIGSERIAL PRIMARY KEY,
  email_id BIGINT NOT NULL REFERENCES email_schema.emails(email_id) ON DELETE CASCADE,
  file_name TEXT NOT NULL,
  file_type TEXT NOT NULL, -- assuming every attachment must have a file type
  file_size BIGINT NOT NULL CHECK (file_size >= 0), -- assuming file size must be non-negative
  content BYTEA, -- consider storing only a reference to the file location if they're large
  CONSTRAINT fk_attachments_email_id FOREIGN KEY (email_id) REFERENCES email_schema.emails(email_id)
);

-- Index for attachments to improve lookup performance on the email_id foreign key
CREATE INDEX IF NOT EXISTS idx_attachments_email_id ON email_schema.attachments(email_id);

-- Creating the 'email_attachment_mapping' table for a many-to-many relationship between emails and attachments
CREATE TABLE IF NOT EXISTS email_schema.email_attachment_mapping (
  email_id BIGINT NOT NULL,
  attachment_id BIGINT NOT NULL,
  PRIMARY KEY (email_id, attachment_id),
  FOREIGN KEY (email_id) REFERENCES email_schema.emails(email_id) ON DELETE RESTRICT,
  FOREIGN KEY (attachment_id) REFERENCES email_schema.attachments(attachment_id) ON DELETE RESTRICT
);

COMMENT ON TABLE email_schema.email_attachment_mapping IS 'Maps many-to-many relationships between emails and attachments.';

-- Individual indexes for each foreign key, if frequent querying by single column
CREATE INDEX IF NOT EXISTS idx_email_attachment_mapping_email_id ON email_schema.email_attachment_mapping(email_id);
CREATE INDEX IF NOT EXISTS idx_email_attachment_mapping_attachment_id ON email_schema.email_attachment_mapping(attachment_id);

-- Including error handling for constraint violations during inserts or updates to this table
DO $$
BEGIN
  -- Assuming we have operations here that involve the email_attachment_mapping table
EXCEPTION
  WHEN foreign_key_violation THEN
    RAISE WARNING 'Foreign key constraint violated: %', SQLERRM;
    -- Additional handling logic here, such as rollback to a savepoint or logging the event
  WHEN unique_violation THEN
    RAISE WARNING 'Unique constraint violated: %', SQLERRM;
    -- Handle unique constraint violations
  WHEN OTHERS THEN
    RAISE WARNING 'An unexpected error occurred: %', SQLERRM;
    -- Handle other unexpected errors
END;
$$;


-- Creating the 'email_status' table to track the state of emails
CREATE TABLE IF NOT EXISTS email_schema.email_status (
  status_id SERIAL PRIMARY KEY,
  email_id BIGINT NOT NULL REFERENCES email_schema.emails(email_id) ON DELETE CASCADE,
  status TEXT NOT NULL CHECK (status IN ('sent', 'received', 'read', 'error', 'pending')), -- Add more statuses as needed
  updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE email_schema.email_status IS 'Tracks the status and state changes of emails.';

-- Index for email_status to improve lookup performance on the email_id foreign key
CREATE INDEX IF NOT EXISTS idx_email_status_email_id ON email_schema.email_status(email_id);

-- Index for frequently used status queries
CREATE INDEX IF NOT EXISTS idx_email_status_status ON email_schema.email_status(status);

-- Adding error handling for operations on the email_status table
DO $$
BEGIN
  -- Placeholder for operations on the email_status table
EXCEPTION
  WHEN foreign_key_violation THEN
    RAISE WARNING 'Foreign key constraint violated: %', SQLERRM;
    -- Handle foreign key constraint violation
  WHEN check_violation THEN
    RAISE WARNING 'Check constraint violated: %', SQLERRM;
    -- Handle check constraint violation
  WHEN unique_violation THEN
    RAISE WARNING 'Unique constraint violated: %', SQLERRM;
    -- Handle unique constraint violations
  WHEN OTHERS THEN
    RAISE WARNING 'An unexpected error occurred: %', SQLERRM;
    -- Handle other unexpected errors
END;
$$;


-- Adding a foreign key constraint to the 'email_status' table
DO $$
BEGIN
  ALTER TABLE email_schema.email_status
  ADD CONSTRAINT fk_email_status_email_id
  FOREIGN KEY (email_id) REFERENCES email_schema.emails(email_id)
  ON DELETE RESTRICT;
EXCEPTION
  WHEN duplicate_object THEN
    RAISE NOTICE 'The constraint fk_email_status_email_id already exists.';
  WHEN undefined_table THEN
    RAISE NOTICE 'The table email_schema.emails does not exist.';
  WHEN undefined_column THEN
    RAISE NOTICE 'The column email_id does not exist in table email_schema.emails.';
  WHEN OTHERS THEN
    RAISE NOTICE 'An unexpected error occurred: %', SQLERRM;
END;
$$;

-- Creating the 'users' table for user management.
CREATE TABLE IF NOT EXISTS email_schema.users (
  user_id SERIAL PRIMARY KEY,                  
  email VARCHAR(255) UNIQUE NOT NULL,          
  created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP 
);

-- Adding new columns with foreign keys, which could fail if the users table or columns don't exist
ALTER TABLE email_schema.emails
  ADD COLUMN IF NOT EXISTS sender_user_id INT,
  ADD COLUMN IF NOT EXISTS recipient_user_id INT;

-- Adding the foreign key constraints separately, allowing for individual error handling
ALTER TABLE email_schema.emails
  ADD CONSTRAINT IF NOT EXISTS fk_emails_sender_user_id
  FOREIGN KEY (sender_user_id) REFERENCES email_schema.users(user_id)
  ON DELETE SET NULL;

ALTER TABLE email_schema.emails
  ADD CONSTRAINT IF NOT EXISTS fk_emails_recipient_user_id
  FOREIGN KEY (recipient_user_id) REFERENCES email_schema.users(user_id)
  ON DELETE SET NULL;

-- Creating indexes, which are unlikely to fail due to a unique violation
CREATE INDEX IF NOT EXISTS idx_emails_sender_user_id ON email_schema.emails(sender_user_id);
CREATE INDEX IF NOT EXISTS idx_emails_recipient_user_id ON email_schema.emails(recipient_user_id);

EXCEPTION
  WHEN undefined_table THEN
    RAISE NOTICE 'The operation failed because a required table does not exist.';
  WHEN undefined_column THEN
    RAISE NOTICE 'The operation failed because a required column does not exist.';
  WHEN datatype_mismatch THEN
    RAISE NOTICE 'The operation failed because of a datatype mismatch.';
  WHEN OTHERS THEN
    RAISE NOTICE 'An unexpected error occurred: %', SQLERRM;
    -- Rollback could be considered for unexpected errors
    ROLLBACK;

DO $$
BEGIN
  -- Attempt to add foreign key constraints
  ALTER TABLE email_schema.emails
  ADD CONSTRAINT fk_emails_sender_user_id
  FOREIGN KEY (sender_user_id) REFERENCES email_schema.users(user_id)
  ON DELETE RESTRICT,
  ADD CONSTRAINT fk_emails_recipient_user_id
  FOREIGN KEY (recipient_user_id) REFERENCES email_schema.users(user_id)
  ON DELETE RESTRICT;

EXCEPTION
  WHEN undefined_table OR undefined_column THEN
    INSERT INTO email_schema.error_log (error_message, error_timestamp) VALUES (SQLERRM, CURRENT_TIMESTAMP);
    RAISE NOTICE 'One of the tables or columns involved in the foreign key constraints does not exist.';
    ROLLBACK;
  WHEN foreign_key_violation THEN
    INSERT INTO email_schema.error_log (error_message, error_timestamp) VALUES (SQLERRM, CURRENT_TIMESTAMP);
    RAISE NOTICE 'Existing data violates the foreign key constraint being added.';
    ROLLBACK;
  WHEN duplicate_object THEN
    INSERT INTO email_schema.error_log (error_message, error_timestamp) VALUES (SQLERRM, CURRENT_TIMESTAMP);
    RAISE NOTICE 'A constraint with the same name already exists.';
    ROLLBACK;
  WHEN OTHERS THEN
    INSERT INTO email_schema.error_log (error_message, error_timestamp) VALUES (SQLERRM, CURRENT_TIMESTAMP);
    RAISE NOTICE 'An unexpected error occurred: %', SQLERRM;
    -- Handle the exception, maybe rollback to a savepoint or log the error
    ROLLBACK; -- Uncomment if you decide to rollback the transaction on error
END;
$$;


-- Assuming you have a users table with user_id as a primary key
-- Update the 'performed_by' column to be a foreign key
ALTER TABLE email_schema.audit_log
ADD CONSTRAINT fk_audit_log_performed_by
FOREIGN KEY (performed_by) REFERENCES email_schema.users(user_id);

-- Now the function with improved error handling and foreign key relation
CREATE OR REPLACE FUNCTION email_schema.audit_log_trigger()
RETURNS TRIGGER AS $$
BEGIN
  -- Attempt to log the audit data
  IF TG_OP = 'DELETE' THEN
    INSERT INTO email_schema.audit_log(action, performed_by, detail)
    VALUES (TG_OP, OLD.sender_user_id, 'Email ' || TG_OP || ' with ID ' || OLD.email_id);
  ELSE
    INSERT INTO email_schema.audit_log(action, performed_by, detail)
    VALUES (TG_OP, NEW.sender_user_id, 'Email ' || TG_OP || ' with ID ' || NEW.email_id);
  END IF;
  RETURN NEW;
EXCEPTION
  WHEN unique_violation THEN
    -- Handle unique constraint violation
    RAISE NOTICE 'A unique constraint was violated: %', SQLERRM;
    RETURN NEW;
  WHEN foreign_key_violation THEN
    -- Handle foreign key violation
    RAISE NOTICE 'A foreign key constraint was violated: %', SQLERRM;
    RETURN NEW;
  WHEN OTHERS THEN
    -- Handle other unexpected errors
    RAISE NOTICE 'An unexpected error occurred: %', SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- Then, define the trigger that uses the function.
DROP TRIGGER IF EXISTS emails_audit_trigger ON email_schema.emails;
CREATE TRIGGER emails_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON email_schema.emails
FOR EACH ROW EXECUTE FUNCTION email_schema.audit_log_trigger();


COMMIT;