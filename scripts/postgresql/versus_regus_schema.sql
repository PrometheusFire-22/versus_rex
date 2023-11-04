-- Use this file to create the schema for the email and attachment handling system

-- Create the schema (if not exists)
CREATE SCHEMA IF NOT EXISTS email_system;

-- Switch to the schema
SET search_path TO email_system;

-- Users table to store user information and avoid redundancy in the emails table
CREATE TABLE IF NOT EXISTS users (
    user_id SERIAL PRIMARY KEY,
    email_address VARCHAR(255) UNIQUE NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE
);

-- Emails table
CREATE TABLE IF NOT EXISTS emails (
    email_id SERIAL PRIMARY KEY,
    sender_id INT REFERENCES users(user_id), -- Foreign key to reference users table
    recipient_id INT REFERENCES users(user_id), -- Foreign key to reference users table
    subject TEXT,
    body TEXT, -- Consider using full-text search indexing on this column
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    received_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    read BOOLEAN DEFAULT FALSE,
    important BOOLEAN DEFAULT FALSE,
    tags TEXT[], -- Array of tags for categorization
    metadata JSONB, -- JSONB for flexible unstructured data
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE -- Soft delete implementation
);

-- Attachments table
CREATE TABLE IF NOT EXISTS attachments (
    attachment_id SERIAL PRIMARY KEY,
    email_id INT REFERENCES emails(email_id) ON DELETE CASCADE, -- Cascading delete
    file_name TEXT NOT NULL,
    file_type TEXT CHECK (file_type IN ('pdf', 'docx', 'xlsx', 'png', 'jpeg')), -- ENUM like restriction
    file_size BIGINT,
    file_content BYTEA, -- Consider encrypting this column for security
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE -- Soft delete implementation
);

-- Indexes to improve search performance
CREATE INDEX IF NOT EXISTS idx_emails_subject ON emails USING GIN (subject gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_emails_body ON emails USING GIN (body gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_emails_tags ON emails USING GIN (tags gin_trgm_ops);

-- Audit trigger function
CREATE OR REPLACE FUNCTION audit_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to set the updated_at column
CREATE TRIGGER set_timestamp
BEFORE UPDATE ON emails
FOR EACH ROW
EXECUTE FUNCTION audit_timestamp();

-- Trigger to set the updated_at column for attachments
CREATE TRIGGER set_timestamp
BEFORE UPDATE ON attachments
FOR EACH ROW
EXECUTE FUNCTION audit_timestamp();

-- Views for simplified access (if needed)
-- CREATE VIEW v_emails AS
-- SELECT * FROM emails WHERE deleted_at IS NULL;

-- Stored procedures (examples)
-- CREATE OR REPLACE PROCEDURE mark_email_read(email_id INT)
-- LANGUAGE plpgsql AS $$
-- BEGIN
--     UPDATE emails SET read = TRUE WHERE email_id = email_id;
-- END;
-- $$;

-- Comments for documentation
COMMENT ON TABLE users IS 'Table for storing user information including email addresses';
COMMENT ON TABLE emails IS 'Table for storing email messages with metadata and status flags';
COMMENT ON TABLE attachments IS 'Table for storing email attachments with file metadata';
