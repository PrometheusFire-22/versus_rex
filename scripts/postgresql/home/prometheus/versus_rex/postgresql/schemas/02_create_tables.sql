-- Use this script to create the necessary tables for storing emails and their attachments.
-- It is designed to be modular and easily expandable for future needs.

-- Creating the 'emails' table to store email information.
CREATE TABLE IF NOT EXISTS emails (
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

-- Index on commonly searched fields to improve query performance.
CREATE INDEX IF NOT EXISTS idx_emails_sender ON emails(sender);
CREATE INDEX IF NOT EXISTS idx_emails_recipient ON emails(recipient);
CREATE INDEX IF NOT EXISTS idx_emails_sent_time ON emails(sent_time);
CREATE INDEX IF NOT EXISTS idx_emails_sender ON emails(sender);
CREATE INDEX IF NOT EXISTS idx_emails_recipient ON emails(recipient);
CREATE INDEX IF NOT EXISTS idx_emails_sent_time ON emails(sent_time);
CREATE INDEX IF NOT EXISTS idx_emails_ip_address ON emails(ip_address);
CREATE INDEX IF NOT EXISTS idx_emails_x_originating_ip ON emails(x_originating_ip);


-- Creating the 'attachments' table to store attachment information.
CREATE TABLE IF NOT EXISTS attachments (
  attachment_id SERIAL PRIMARY KEY,           -- A unique identifier for each attachment.
  email_id INT,                               -- The identifier of the email this attachment is associated with.
  file_name TEXT,                             -- The file name of the attachment.
  file_type TEXT,                             -- The MIME type of the attachment.
  file_size INT,                              -- The size of the attachment file in bytes.
  FOREIGN KEY (email_id) REFERENCES emails(email_id) -- A foreign key that references the 'emails' table.
);

-- Index on the 'email_id' foreign key to speed up searches for all attachments of an email.
CREATE INDEX IF NOT EXISTS idx_attachments_email_id ON attachments(email_id);
CREATE INDEX IF NOT EXISTS idx_attachments_file_name ON attachments(file_name);
CREATE INDEX IF NOT EXISTS idx_attachments_file_type ON attachments(file_type);

-- Creating the 'email_attachment_mapping' table to allow a many-to-many relationship between emails and attachments.
CREATE TABLE IF NOT EXISTS email_attachment_mapping (
  email_id INT,                               -- The identifier of the email.
  attachment_id INT,                          -- The identifier of the attachment.
  PRIMARY KEY (email_id, attachment_id),      -- Composite primary key to ensure uniqueness.
  FOREIGN KEY (email_id) REFERENCES emails(email_id), -- Foreign key to reference 'emails' table.
  FOREIGN KEY (attachment_id) REFERENCES attachments(attachment_id) -- Foreign key to reference 'attachments' table.
);

-- Index to improve the performance of lookups and joins using the 'email_id' field.
CREATE INDEX IF NOT EXISTS idx_email_attachment_mapping_email_id ON email_attachment_mapping(email_id);

-- Index to improve the performance of lookups and joins using the 'attachment_id' field.
CREATE INDEX IF NOT EXISTS idx_email_attachment_mapping_attachment_id ON email_attachment_mapping(attachment_id)

-- Adding comments to the 'emails' table
COMMENT ON TABLE emails IS 'Stores information about each email message.';

-- Adding comments to the columns of the 'emails' table
COMMENT ON COLUMN emails.email_id IS 'Unique identifier for each email.';
COMMENT ON COLUMN emails.subject IS 'Subject line of the email.';
COMMENT ON COLUMN emails.sender IS 'Email address of the sender.';
COMMENT ON COLUMN emails.recipient IS 'Email address of the intended recipient.';
COMMENT ON COLUMN emails.sent_time IS 'Date and time the email was sent.';
COMMENT ON COLUMN emails.body_text IS 'The plain text body of the email message.';
COMMENT ON COLUMN emails.ip_address IS 'IP address from where the email was sent.';
COMMENT ON COLUMN emails.x_originating_ip IS 'Originating IP address included in the email header.';
COMMENT ON COLUMN emails.received IS 'Full "Received" header chain from the email.';
COMMENT ON COLUMN emails.user_agent IS 'The "User-Agent" header, indicating the email client used.';
COMMENT ON COLUMN emails.authentication_results IS 'Authentication results from the email header.';
COMMENT ON COLUMN emails.dkim_signature IS 'DKIM signature header from the email, if present.';

-- Adding comments to the 'attachments' table
COMMENT ON TABLE attachments IS 'Stores information about each file attached to emails.';

-- Adding comments to the columns of the 'attachments' table
COMMENT ON COLUMN attachments.attachment_id IS 'Unique identifier for each attachment.';
COMMENT ON COLUMN attachments.email_id IS 'Identifier of the email to which this attachment is linked.';
COMMENT ON COLUMN attachments.file_name IS 'The original file name of the attachment.';
COMMENT ON COLUMN attachments.file_type IS 'The MIME type of the attachment.';
COMMENT ON COLUMN attachments.file_size IS 'The size of the attachment file in bytes.';

-- Adding comments to the 'email_attachment_mapping' table
COMMENT ON TABLE email_attachment_mapping IS 'Maps emails to their attachments for emails with multiple attachments.';

-- Adding comments to the columns of the 'email_attachment_mapping' table
COMMENT ON COLUMN email_attachment_mapping.email_id IS 'Identifier of the email associated with the attachment.';
COMMENT ON COLUMN email_attachment_mapping.attachment_id IS 'Identifier of the attachment associated with the email.';

-- It's good practice to add comments to your database schema as it helps future developers,
-- or anyone interacting with the database, understand the schema more quickly and thoroughly.
-- These comments should provide clear, concise information about the purpose and use of each table and column.


-- The script ends here. All tables are created and ready to be used.
