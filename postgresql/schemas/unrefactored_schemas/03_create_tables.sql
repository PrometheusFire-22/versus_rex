BEGIN;

-- Use this script to create the necessary tables for storing emails and their attachments.
-- It is designed to be modular and easily expandable for future needs.

-- Ensure that the email_schema exists and is used

CREATE SCHEMA IF NOT EXISTS email_schema;
SET search_path TO email_schema;

-- Comment on the schema
COMMENT ON SCHEMA email_schema IS 'Schema for storing all email-related data including emails, attachments, and mappings.';

-- Creating the 'emails' table within the 'email_schema' to store email information.
CREATE TABLE IF NOT EXISTS email_schema.emails (
  email_id SERIAL PRIMARY KEY,                -- A unique identifier for each email.
  subject TEXT,                               -- The subject of the email.
  sender VARCHAR(255),                        -- The email address of the sender.
  recipient VARCHAR(255),                     -- The email address of the recipient.
  sent_time TIMESTAMP,                        -- The time the email was sent.
  body_text TEXT,                             -- The body of the email.
  ip_address VARCHAR(45),                     -- The primary IP address from which the email was sent.
  x_originating_ip VARCHAR(45),               -- The originating IP address if provided.
  received TEXT,                              -- To store the full 'Received' header chain.
  user_agent VARCHAR(255),                    -- The user agent information if available.
  authentication_results TEXT,                -- To store 'Authentication-Results' header information.
  dkim_signature TEXT                         -- To store 'DKIM-Signature' header information.
);

-- Comment on the 'emails' table
COMMENT ON TABLE email_schema.emails IS 'Table to store core email information.';

-- Comment on columns in the 'emails' table
COMMENT ON COLUMN email_schema.emails.email_id IS 'Unique identifier for each email.';
COMMENT ON COLUMN email_schema.emails.subject IS 'Subject line of the email.';
COMMENT ON COLUMN email_schema.emails.sender IS 'Email address of the sender.';
COMMENT ON COLUMN email_schema.emails.recipient IS 'Email address of the recipient.';
COMMENT ON COLUMN email_schema.emails.sent_time IS 'Timestamp when the email was sent.';
COMMENT ON COLUMN email_schema.emails.body_text IS 'The body content of the email in text format.';
COMMENT ON COLUMN email_schema.emails.ip_address IS 'IP address from which the email was sent.';
COMMENT ON COLUMN email_schema.emails.x_originating_ip IS 'Additional originating IP address included in the email header.';
COMMENT ON COLUMN email_schema.emails.received IS 'Header information containing the email routing details.';
COMMENT ON COLUMN email_schema.emails.user_agent IS 'Information about the email client that was used to send the email.';
COMMENT ON COLUMN email_schema.emails.authentication_results IS 'Results of the email authentication process.';
COMMENT ON COLUMN email_schema.emails.dkim_signature IS 'DomainKeys Identified Mail signature.';

-- Indexes on the 'emails' table to improve query performance.

CREATE INDEX IF NOT EXISTS email_schema.idx_emails_sender ON email_schema.emails(sender);
CREATE INDEX IF NOT EXISTS email_schema.idx_emails_recipient ON email_schema.emails(recipient);
CREATE INDEX IF NOT EXISTS email_schema.idx_emails_sent_time ON email_schema.emails(sent_time);
CREATE INDEX IF NOT EXISTS email_schema.idx_emails_ip_address ON email_schema.emails(ip_address);
CREATE INDEX IF NOT EXISTS email_schema.idx_emails_x_originating_ip ON email_schema.emails(x_originating_ip);
CREATE INDEX IF NOT EXISTS email_schema.idx_emails_received ON email_schema.emails(received);
CREATE INDEX IF NOT EXISTS email_schema.idx_emails_user_agent ON email_schema.emails(user_agent);
CREATE INDEX IF NOT EXISTS email_schema.idx_emails_authentication_results ON email_schema.emails(authentication_results);
CREATE INDEX IF NOT EXISTS email_schema.idx_emails_dkim_signature ON email_schema.emails(dkim_signature);


-- Creating the 'attachments' table within the 'email_schema'.
CREATE TABLE IF NOT EXISTS email_schema.attachments (
  attachment_id SERIAL PRIMARY KEY,           -- A unique identifier for each attachment.
  email_id INT NOT NULL,                      -- The identifier of the email this attachment is associated with.
  file_name TEXT NOT NULL,                    -- The file name of the attachment.
  file_type TEXT,                             -- The MIME type of the attachment.
  file_size BIGINT,                           -- The size of the attachment file in bytes.
  FOREIGN KEY (email_id) REFERENCES email_schema.emails(email_id) ON DELETE RESTRICT
);

-- Comment on the 'attachments' table
COMMENT ON TABLE email_schema.attachments IS 'Table to store information about email attachments.';

-- Comment on columns in the 'attachments' table
COMMENT ON COLUMN email_schema.attachments.attachment_id IS 'Unique identifier for each attachment.';
COMMENT ON COLUMN email_schema.attachments.email_id IS 'Foreign key to the email with which this attachment is associated.';
COMMENT ON COLUMN email_schema.attachments.file_name IS 'Name of the file attached.';
COMMENT ON COLUMN email_schema.attachments.file_type IS 'MIME type of the attachment.';
COMMENT ON COLUMN email_schema.attachments.file_size IS 'Size of the attachment file in bytes.';

-- Indexes on the 'attachments' table to improve query performance.
CREATE INDEX IF NOT EXISTS email_schema.idx_attachments_email_id ON email_schema.attachments(email_id);
CREATE INDEX IF NOT EXISTS email_schema.idx_attachments_file_name ON email_schema.attachments(file_name);
CREATE INDEX IF NOT EXISTS email_schema.idx_attachments_file_type ON email_schema.attachments(file_type);
CREATE INDEX IF NOT EXISTS email_schema.idx_attachments_file_size ON email_schema.attachments(file_size);

-- Assuming the 'email_attachment_mapping' table is required as the comment suggests, 
-- the table creation script should be something like this:
CREATE TABLE IF NOT EXISTS email_schema.email_attachment_mapping (
  email_id INT,
  attachment_id INT,
  PRIMARY KEY (email_id, attachment_id),
  FOREIGN KEY (email_id) REFERENCES email_schema.emails(email_id) ON DELETE RESTRICT,
  FOREIGN KEY (attachment_id) REFERENCES email_schema.attachments(attachment_id) ON DELETE RESTRICT
);

-- Comment on the 'email_attachment_mapping' table
COMMENT ON TABLE email_schema.email_attachment_mapping IS 'Table to map emails to attachments, allowing for a many-to-many relationship.';

-- Comment on columns in the 'email_attachment_mapping' table
COMMENT ON COLUMN email_schema.email_attachment_mapping.email_id IS 'Foreign key to the associated email.';
COMMENT ON COLUMN email_schema.email_attachment_mapping.attachment_id IS 'Foreign key to the associated attachment.';

-- Indexes for the 'email_attachment_mapping' table to improve query performance.
CREATE INDEX IF NOT EXISTS email_schema.idx_email_attachment_mapping_email_id ON email_schema.email_attachment_mapping(email_id);
CREATE INDEX IF NOT EXISTS email_schema.idx_email_attachment_mapping_attachment_id ON email_schema.email_attachment_mapping(attachment_id);

COMMIT; -- This will commit the transaction if all commands execute successfully
