BEGIN;

-- Creating the 'emails' table within the 'email_schema' to store email information.
CREATE TABLE IF NOT EXISTS email_schema.emails (
  email_id BIGSERIAL PRIMARY KEY,              -- A unique identifier for each email, BIGSERIAL for large number of records.
  subject TEXT,                               -- The subject of the email.
  sender VARCHAR(100),                        -- The email address of the sender, assuming an email address won't exceed 100 characters.
  recipient VARCHAR(100),                     -- The email address of the recipient, same assumption as sender.
  sent_time TIMESTAMP WITHOUT TIME ZONE,      -- The time the email was sent. Assuming timezone is handled application-side.
  body_text TEXT,                             -- The body of the email.
  ip_address INET,                            -- The IP address from which the email was sent, using INET type for proper IP storage.
  x_originating_ip INET,                      -- The originating IP address if provided, also INET type.
  received TEXT,                              -- To store the full 'Received' header chain.
  user_agent VARCHAR(255),                    -- The user agent information if available.
  authentication_results TEXT,                -- To store 'Authentication-Results' header information.
  dkim_signature TEXT                         -- To store 'DKIM-Signature' header information.
);

-- Indexes on the 'emails' table to improve query performance.
CREATE INDEX IF NOT EXISTS idx_emails_sender ON email_schema.emails(sender);
CREATE INDEX IF NOT EXISTS idx_emails_recipient ON email_schema.emails(recipient);
-- Additional indexes omitted for brevity, but should be reviewed for actual query patterns.


- Creating the 'attachments' table within the 'email_schema'.
CREATE TABLE IF NOT EXISTS email_schema.attachments (
  attachment_id BIGSERIAL PRIMARY KEY,        -- A unique identifier for each attachment, BIGSERIAL for large datasets.
  email_id BIGINT NOT NULL REFERENCES email_schema.emails(email_id) ON DELETE CASCADE, -- Using BIGINT to match the email_id type.
  file_name TEXT NOT NULL,                    -- The file name of the attachment.
  file_type TEXT,                             -- The MIME type of the attachment.
  file_size BIGINT,                           -- The size of the attachment file in bytes, BIGINT to handle large files.
  content BYTEA                               -- To store the actual content of the attachment if needed.
);

-- Indexes on the 'attachments' table to improve query performance.
CREATE INDEX IF NOT EXISTS idx_attachments_email_id ON email_schema.attachments(email_id);
CREATE INDEX IF NOT EXISTS idx_attachments_file_name ON email_schema.attachments(file_name);
-- Additional indexes omitted for brevity.

-- Creating the 'email_attachment_mapping' table if a many-to-many relationship is needed.
-- Assuming from previous parts of the conversation that this might be needed.
CREATE TABLE IF NOT EXISTS email_schema.email_attachment_mapping (
  email_id BIGINT,
  attachment_id BIGINT,
  PRIMARY KEY (email_id, attachment_id),
  FOREIGN KEY (email_id) REFERENCES email_schema.emails(email_id) ON DELETE CASCADE,
  FOREIGN KEY (attachment_id) REFERENCES email_schema.attachments(attachment_id) ON DELETE CASCADE
);

-- Indexes for the 'email_attachment_mapping' table to improve query performance.
CREATE INDEX IF NOT EXISTS idx_email_attachment_mapping_email_id ON email_schema.email_attachment_mapping(email_id);
CREATE INDEX IF NOT EXISTS idx_email_attachment_mapping_attachment_id ON email_schema.email_attachment_mapping(attachment_id);

-- Creating the 'email_status' table to track the state of emails.
CREATE TABLE IF NOT EXISTS email_schema.email_status (
  status_id SERIAL PRIMARY KEY,                -- A unique identifier for each status.
  email_id BIGINT NOT NULL REFERENCES email_schema.emails(email_id) ON DELETE CASCADE,
  status TEXT NOT NULL,                        -- The status of the email (e.g., 'sent', 'received', 'read').
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP -- Timestamp of the status update.
);

-- Index on the 'email_status' table to improve query performance.
CREATE INDEX IF NOT EXISTS idx_email_status_email_id ON email_schema.email_status(email_id);
CREATE INDEX IF NOT EXISTS idx_email_status_status ON email_schema.email_status(status);

-- Creating the 'users' table if user management is part of the scope.
CREATE TABLE IF NOT EXISTS email_schema.users (
  user_id SERIAL PRIMARY KEY,                  -- A unique identifier for each user.
  email VARCHAR(255) UNIQUE NOT NULL,          -- The user's email address, unique to ensure no duplicates.
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP -- Timestamp of the user creation.
);

-- Index on the 'users' table to improve query performance.
CREATE INDEX IF NOT EXISTS idx_users_email ON email_schema.users(email);

-- Altering the 'emails' table to link with the 'users' table, assuming this association is required.
ALTER TABLE email_schema.emails
ADD COLUMN sender_user_id INT REFERENCES email_schema.users(user_id),
ADD COLUMN recipient_user_id INT REFERENCES email_schema.users(user_id);

-- Update the index after adding the new columns.
DROP INDEX IF EXISTS email_schema.idx_emails_sender;
DROP INDEX IF EXISTS email_schema.idx_emails_recipient;
CREATE INDEX idx_emails_sender_user_id ON email_schema.emails(sender_user_id);
CREATE INDEX idx_emails_recipient_user_id ON email_schema.emails(recipient_user_id);

-- Assuming a logging or audit mechanism is desired.
-- Creating a table to log actions or changes in the database.
CREATE TABLE IF NOT EXISTS email_schema.audit_log (
  log_id SERIAL PRIMARY KEY,                   -- A unique identifier for each log entry.
  action TEXT NOT NULL,                        -- The action performed (e.g., 'CREATE', 'UPDATE', 'DELETE').
  performed_by INT REFERENCES email_schema.users(user_id), -- The user who performed the action.
  performed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, -- Timestamp of the action.
  detail TEXT                                  -- Details of the action performed.
);

-- Index on the 'audit_log' table to improve query performance.
CREATE INDEX IF NOT EXISTS idx_audit_log_performed_by ON email_schema.audit_log(performed_by);
CREATE INDEX IF NOT EXISTS idx_audit_log_performed_at ON email_schema.audit_log(performed_at);

-- Adding a function to track changes for the audit log, assuming this is required.
CREATE OR REPLACE FUNCTION email_schema.audit_log_trigger()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO email_schema.audit_log(action, performed_by, detail)
  VALUES (TG_OP, NEW.sender_user_id, 'Email ' || TG_OP || ' with ID ' || NEW.email_id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Creating a trigger for the 'emails' table to automatically log inserts/updates/deletes
CREATE TRIGGER emails_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON email_schema.emails
FOR EACH ROW EXECUTE FUNCTION email_schema.audit_log_trigger();

-- For instance, adding a routine to clean up old audit logs
CREATE OR REPLACE FUNCTION email_schema.cleanup_audit_logs() RETURNS VOID AS $$
BEGIN
  DELETE FROM email_schema.audit_log WHERE performed_at < NOW() - INTERVAL '90 days';
END;
$$ LANGUAGE plpgsql;

-- Schedule the cleanup function to run periodically, if required
-- This requires setting up a job scheduler like pgAgent or an external cron job

-- Finalize the schema with any additional grants or role assignments
-- This is where you grant specific privileges to different database roles
-- Example:
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA email_schema TO my_role;

-- If there are any views, sequences or other schema objects, permissions for those should be set here

-- Commit the transaction if everything above is successful
COMMIT;

-- The script ends here. The database is now set up with tables, indices, functions, and triggers.
-- It's prepared for application integration and further development.


