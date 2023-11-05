BEGIN;

-- Creating the 'emails' table within the 'email_schema'.
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
  dkim_signature TEXT,
  sender_user_id INT,
  recipient_user_id INT
);

-- Adding foreign key constraints to the 'emails' table.
ALTER TABLE email_schema.emails
  ADD CONSTRAINT fk_emails_sender_user_id
  FOREIGN KEY (sender_user_id) REFERENCES email_schema.users(user_id)
  ON DELETE SET NULL,
  ADD CONSTRAINT fk_emails_recipient_user_id
  FOREIGN KEY (recipient_user_id) REFERENCES email_schema.users(user_id)
  ON DELETE SET NULL;

-- Creating the 'attachments' table within the 'email_schema'.
-- Note: We are ensuring that there is NO CASCADE on delete.
CREATE TABLE IF NOT EXISTS email_schema.attachments (
  attachment_id BIGSERIAL PRIMARY KEY,
  email_id BIGINT NOT NULL,
  file_name TEXT NOT NULL,
  file_type TEXT NOT NULL, -- assuming every attachment must have a file type
  file_size BIGINT NOT NULL CHECK (file_size >= 0), -- assuming file size must be non-negative
  content BYTEA -- consider storing only a reference to the file location if they're large
);

-- Foreign key constraint for attachments referencing emails without cascading deletes.
ALTER TABLE email_schema.attachments
  ADD CONSTRAINT fk_attachments_email_id
  FOREIGN KEY (email_id) REFERENCES email_schema.emails(email_id)
  ON DELETE RESTRICT;

-- Creating the 'email_attachment_mapping' table for a many-to-many relationship between emails and attachments.
-- Note: We are ensuring that there is NO CASCADE on delete.
CREATE TABLE IF NOT EXISTS email_schema.email_attachment_mapping (
  email_id BIGINT NOT NULL,
  attachment_id BIGINT NOT NULL,
  PRIMARY KEY (email_id, attachment_id),
  CONSTRAINT fk_email_attachment_mapping_email_id FOREIGN KEY (email_id) REFERENCES email_schema.emails(email_id) ON DELETE RESTRICT,
  CONSTRAINT fk_email_attachment_mapping_attachment_id FOREIGN KEY (attachment_id) REFERENCES email_schema.attachments(attachment_id) ON DELETE RESTRICT
);

-- Creating the 'email_status' table to track the state of emails.
-- Note: We are ensuring that there is NO CASCADE on delete.
CREATE TABLE IF NOT EXISTS email_schema.email_status (
  status_id SERIAL PRIMARY KEY,
  email_id BIGINT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('sent', 'received', 'read', 'error', 'pending')), -- Add more statuses as needed
  updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Foreign key constraint for email_status referencing emails without cascading deletes.
ALTER TABLE email_schema.email_status
  ADD CONSTRAINT fk_email_status_email_id
  FOREIGN KEY (email_id) REFERENCES email_schema.emails(email_id)
  ON DELETE RESTRICT;

-- Commit the changes if all operations are successful.
COMMIT;
